{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) types;

  dahdi-lib = import ./dahdi-lib.nix {inherit lib pkgs;};

  dahdi-linux = config.boot.kernelPackages.callPackage ../pkgs/dahdi-linux.nix {};
  dahdi-tools = pkgs.callPackage ../pkgs/dahdi-tools.nix {};

  dahdi-udev = pkgs.writeTextFile {
    name = "dahdi-udev";
    text = ''
      # Setup non-root access on devices
      ACTION=="add|change", SUBSYSTEMS=="dahdi|dahdi_spans|dahdi_channels", GROUP="${config.users.groups.telecom.name}", MODE="0660"

      # Backward compatible dev-paths: /dev/dahdi/<channo>
      ACTION=="add|change", SUBSYSTEM=="dahdi_channels", SYMLINK+="dahdi/%m"

      # Hardware-based dev-paths
      ACTION=="add|change", SUBSYSTEM=="dahdi_channels", ATTRS{location}!="", SYMLINK+="dahdi/devices/@%s{location}/%s{local_spanno}/%n"
      ACTION=="add|change", SUBSYSTEM=="dahdi_channels", ATTRS{hardware_id}!="", SYMLINK+="dahdi/devices/%s{hardware_id}/%s{local_spanno}/%n"
    '';
    destination = "/lib/udev/rules.d/20-dahdi.rules";
  };

  cfg = config.services.dahdi;
in {
  options.services.dahdi = rec {
    enable = lib.mkEnableOption "Management of DAHDI interfaces and kernel drivers";

    modules = lib.mkOption {
      type = types.listOf types.str;
      description = "The list of modules to be managed by the service";
    };

    defaultzone = lib.mkOption {
      type = dahdi-lib.types.tonezone;
      description = "The default tone zone to be loaded";
      default = "us";
    };
    loadzones = lib.mkOption {
      type = types.listOf dahdi-lib.types.tonezone;
      description = "A list of tone zones to be preloaded";
      default = [cfg.defaultzone];
    };

    spans = lib.mkOption {
      type = types.attrsOf dahdi-lib.types.span;
      description = "Spans definitions and configuration";
      default = {};
    };

    dynamic = lib.mkOption {
      type = types.listOf dahdi-lib.types.dynamic;
      description = "Dynamic pans definitions and configuration";
      default = [];
    };

    channels = lib.mkOption {
      type = types.attrsOf dahdi-lib.types.channel;
      description = "Channels definitions and configuration";
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = [dahdi-linux];

    users.groups.telecom = {};

    systemd.services.dahdi = rec {
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      description = "`dahdi-linux` modules (un)loading process and userland configuration";

      reloadTriggers = [
        config.environment.etc."dahdi/system.conf".source
      ];

      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = "yes";

      preStart =
        builtins.concatStringsSep "\n"
        (builtins.map (module: ''${lib.getExe' pkgs.kmod "modprobe"} "${module}"'') cfg.modules);
      postStop =
        builtins.concatStringsSep "\n"
        (builtins.map (module: ''${lib.getExe' pkgs.kmod "rmmod"} "${module}"'') cfg.modules);

      script = "${lib.getExe' dahdi-tools "dahdi_cfg"}";
      reload = "${script}";
    };

    environment.etc."dahdi/system.conf" = {
      group = "${config.users.groups.telecom.name}";
      mode = "0440";
      source = dahdi-lib.mkSystemConfig cfg;
    };

    services.udev.packages = [dahdi-udev];
  };
}
