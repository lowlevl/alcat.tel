{
  config,
  lib,
  ...
}: let
  inherit (lib) types;

  options = import ./options.nix {inherit lib;};
  cfg = config.services.sipdect;
in {
  options.services.sipdect = {
    enable = lib.mkEnableOption "Mitel SIP-DECT support";

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

    rfp = lib.mkOption {
      type = types.attrsOf options.rfp;
      description = "Configuration of individual RFPs, indexed by their MAC address";
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
    };

    services.kea.dhcp4 = {
      enable = true;

      settings = {
        interfaces-config.interfaces = lib.singleton cfg.interface;

        lease-database = {
          type = "memfile";
          name = "/var/lib/kea/dhcp4.leases";
          persist = true;
        };

        subnet4 = lib.singleton {
          subnet = "${cfg.address}/${builtins.toString cfg.mask}";
          reservations = []; # FIXME: populate RFPs
        };
      };
    };
  };
}
