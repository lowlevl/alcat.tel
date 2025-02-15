{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) types;

  dahdi-linux = config.boot.kernelPackages.callPackage ../pkgs/dahdi-linux.nix {};
  dahdi-tools = pkgs.callPackage ../pkgs/dahdi-tools.nix {};

  cfg = config.services.dahdi;
in {
  options.services.dahdi = {
    enable = lib.mkEnableOption "Management of DAHDI interfaces and kernel drivers";

    modules = lib.mkOption {
      type = types.listOf types.str;
      description = "The list of modules to be managed by the service";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = [dahdi-linux];

    users.groups.telecom = {};

    systemd.services.dahdi = rec {
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      description = "`dahdi-linux` modules (un)loading process and userland configuration";

      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = "yes";

      preStart =
        builtins.concatStringsSep "\n"
        (builtins.map (module: ''${lib.getExe' pkgs.kmod "modprobe"} "${module}"'') cfg.modules);
      postStop =
        builtins.concatStringsSep "\n"
        (builtins.map (module: ''${lib.getExe' pkgs.kmod "rmmod"} "${module}"'') cfg.modules);

      script = "${lib.getExe' dahdi-tools "dahdi_cfg"}";
      reload = script;
    };

    environment.etc."dahdi/system.conf" = {
      group = config.users.groups.telecom.name;
      text = ''
      '';
    };

    services.udev.extraRules = ''
      ACTION!="add", GOTO="dahdi_end"

      # DAHDI devices with permissions for running as non-root
      SUBSYSTEM=="dahdi", GROUP="${config.users.groups.telecom.name}", MODE="0660"

      # Backward compatible dev-paths: /dev/dahdi/<channo>
      SUBSYSTEM=="dahdi_channels", SYMLINK+="dahdi/%m"

      # Add persistant names as well
      SUBSYSTEM=="dahdi_channels", ATTRS{hardware_id}!="", SYMLINK+="dahdi/devices/%s{hardware_id}/%s{local_spanno}/%n"
      SUBSYSTEM=="dahdi_channels", ATTRS{location}!="", SYMLINK+="dahdi/devices/@%s{location}/%s{local_spanno}/%n"

      LABEL="dahdi_end"

      # Hotplug scripts
      SUBSYSTEM=="dahdi_devices", RUN+="${dahdi-tools}/share/dahdi/dahdi_handle_device"
      SUBSYSTEM=="dahdi_spans", RUN+="${dahdi-tools}/share/dahdi/dahdi_span_config"
    '';
  };
}
