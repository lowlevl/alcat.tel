{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) types;

  dahdi-lib = import ./lib.nix {inherit lib pkgs;};
  dahdi-types = import ./types.nix {inherit lib;};

  dahdi-udev = pkgs.writeTextFile {
    name = "dahdi-udev";
    text = ''
      # Setup non-root access on devices
      SUBSYSTEMS=="dahdi|dahdi_channels|dahdi_devices|dahdi_spans", GROUP="${config.users.groups.telecom.name}", MODE="0660"

      # Backward compatible dev-paths: /dev/dahdi/<channo>
      SUBSYSTEM=="dahdi_channels", SYMLINK+="dahdi/%m"

      # Hardware-based dev-paths
      SUBSYSTEM=="dahdi_channels", ATTRS{location}!="", SYMLINK+="dahdi/devices/@%s{location}/%s{local_spanno}/%n"
      SUBSYSTEM=="dahdi_channels", ATTRS{hardware_id}!="", SYMLINK+="dahdi/devices/%s{hardware_id}/%s{local_spanno}/%n"
    '';
    destination = "/lib/udev/rules.d/20-dahdi.rules";
  };

  cfg = config.services.dahdi;
in {
  options.services.dahdi = {
    enable = lib.mkEnableOption config.systemd.service.dahdi.description;

    kpackage = lib.mkPackageOption pkgs "dahdi-linux" {};
    package = lib.mkPackageOption pkgs "dahdi-tools" {};

    modules = lib.mkOption {
      type = types.listOf types.str;
      description = "The list of modules to be managed by the service";
    };

    defaultzone = lib.mkOption {
      type = dahdi-types.tonezone;
      description = "The default tone zone to be loaded";
      default = "us";
    };
    loadzones = lib.mkOption {
      type = types.listOf dahdi-types.tonezone;
      description = "A list of tone zones to be preloaded";
      default = [cfg.defaultzone];
    };

    spans = lib.mkOption {
      type = types.attrsOf dahdi-types.span;
      description = "Spans definitions and configuration";
      default = {};
    };

    dynamic = lib.mkOption {
      type = types.listOf dahdi-types.dynamic;
      description = "Dynamic spans definitions and configuration";
      default = [];
    };

    channels = lib.mkOption {
      type = types.attrsOf dahdi-types.channel;
      description = "Channels definitions and configuration";
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = [cfg.kpackage];
    environment.systemPackages = [cfg.package];

    users.groups.telecom = {};

    services.udev.packages = [dahdi-udev];
    systemd.services.dahdi = rec {
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      description = "`dahdi-linux` modules management and userland configuration";

      reloadTriggers = [
        config.environment.etc."dahdi/system.conf".source
      ];

      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = "yes";

      serviceConfig.ExecStart = "${lib.getExe' cfg.package "dahdi_cfg"}";
      serviceConfig.ExecReload = serviceConfig.ExecStart;

      preStart =
        builtins.concatStringsSep "\n"
        (builtins.map (module: ''${lib.getExe' pkgs.kmod "modprobe"} "${module}"'') cfg.modules);
      postStop =
        builtins.concatStringsSep "\n"
        (builtins.map (module: ''${lib.getExe' pkgs.kmod "rmmod"} "${module}"'') cfg.modules);
    };

    environment.etc."dahdi/system.conf".source = dahdi-lib.mkSystemConfig cfg;
  };
}
