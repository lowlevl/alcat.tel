{
  config,
  pkgs,
  lib,
  ...
}: let
  inherit (lib) types;

  options = import ./options.nix {inherit lib;};
  cfg = config.services.sipdect;
in {
  options.services.sipdect = {
    enable = lib.mkEnableOption "Mitel SIP-DECT support";

    openFirewall = lib.mkOption {
      type = types.bool;
      description = "Whether to open ports in the firewall for Mitel SIP-DECT services";
      default = false;
    };

    interfaces = lib.mkOption {
      type = types.listOf types.str;
      description = "The names of the physical interfaces where the SIP-DECT can be connected";
      default = [];
    };
    interface = lib.mkOption {
      type = types.str;
      description = "The name of the bridged interface where RFPs are connected";
      default = "sipdect0";
    };

    address = lib.mkOption {
      type = types.str;
      description = "The address on the bridged interface";
    };
    mask = lib.mkOption {
      type = types.int;
      description = "The subnet mask on the bridged interface";
    };

    ntpd = lib.mkOption {
      type = options.syslogd;
      description = "The configuration of the NTP service";
      default = {};
    };
    syslogd = lib.mkOption {
      type = options.syslogd;
      description = "The configuration of the `syslog` service";
      default = {};
    };

    ommip1 = lib.mkOption {
      type = types.nullOr types.str;
      description = "The IP of the main OpenMobility Manager, if `null` the first RFP is selected";
      default = null;
    };
    ommip2 = lib.mkOption {
      type = types.nullOr types.str;
      description = "The IP of the standby OpenMobility Manager";
      default = null;
    };

    rfp = lib.mkOption {
      type = types.attrsOf options.rfp;
      description = "Configuration of individual RFPs, indexed by their MAC address";
      default = {};
    };

    provisioning = lib.mkOption {
      type = types.attrsOf types.path;
      description = "Files on the provisioning TFTP server";
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    networking = {
      bridges.${cfg.interface} = {
        inherit (cfg) interfaces;
      };

      interfaces.${cfg.interface}.ipv4.addresses = lib.singleton {
        inherit (cfg) address;
        prefixLength = cfg.mask;
      };

      firewall.allowedUDPPorts = lib.optionals cfg.openFirewall (
        [67]
        ++ lib.optional (cfg.provisioning != {}) 69
        ++ lib.optional cfg.ntpd.enable 123
        ++ lib.optional (cfg.syslogd.enable && cfg.syslogd.address == null) cfg.syslogd.port
      );
    };

    services.rsyslogd = lib.mkIf (cfg.syslogd.enable && cfg.syslogd.address == null) {
      enable = true;

      extraConfig = ''
        module(load="imudp")
        input(type="imudp" port="${builtins.toString cfg.syslogd.port}" address="${cfg.address}")
      '';
    };

    services.openntpd = lib.mkIf cfg.ntpd.enable {
      enable = true;

      extraConfig = ''
        listen on ${cfg.address}
      '';
    };

    services.dnsmasq = {
      enable = true;

      resolveLocalQueries = lib.mkDefault false;
      settings = {
        interface = cfg.interface;
        port = 0; # disable DNS server

        dhcp-authoritative = true;
        dhcp-range = "${cfg.address},static";
        dhcp-host = lib.mapAttrsToList (mac: rfp: "${mac},${rfp.address}") cfg.rfp;

        dhcp-option = let
          ommip1 =
            if cfg.ommip1 != null
            then cfg.ommip1
            else lib.elemAt (lib.mapAttrsToList (mac: rfp: rfp.address) cfg.rfp) 0;

          syslogip =
            if cfg.syslogd.address != null
            then cfg.syslogd.address
            else cfg.address;
          syslogport = builtins.toString cfg.syslogd.port;
        in
          [
            "224,OpenMobility"
            "vendor:OpenMobility,10,${ommip1}"
          ]
          ++ lib.optional (cfg.ommip2 != null) "vendor:OpenMobility,19,${cfg.ommip2}"
          ++ lib.optional cfg.syslogd.enable "vendor:OpenMobility,14,${syslogip}"
          ++ lib.optional cfg.syslogd.enable "vendor:OpenMobility,15,${syslogport}"
          ++ lib.optional (cfg.provisioning != {}) "66,tftp://${cfg.address}"
          ++ lib.optional cfg.ntpd.enable "42,${cfg.address}";

        enable-tftp = cfg.provisioning != {};
        tftp-root = let
          drv = pkgs.runCommand "provisioning-files" {} ''
            mkdir -v $out
            ${lib.concatMapAttrsStringSep "\n"
              (destination: source: "ln -vs ${source} $out/${destination}")
              cfg.provisioning}
          '';
        in
          builtins.toString drv;
      };
    };
  };
}
