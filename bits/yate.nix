{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) types;

  cfg = config.services.yate;
in {
  options.services.yate = rec {
    enable = lib.mkEnableOption config.systemd.service.yate.description;

    nice = lib.mkOption {
      type = types.ints.between (-19) 20;
      description = "Set the `nice` level for the service";
      default = -4;
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.yate = {
      isSystemUser = true;
      group = "yate";
      extraGroups = ["telecom"];
    };
    users.groups.yate = {};

    systemd.services.yate = {
      wantedBy = ["multi-user.target"];
      after = ["network.target" "dahdi.service"];
      description = "`yate` (Yet Another Telephony Engine) daemon";

      reloadTriggers = [
      ];

      serviceConfig.Nice = cfg.nice;
      serviceConfig.User = config.users.users.yate.name;
      serviceConfig.Group = config.users.users.yate.group;
      serviceConfig.Restart = "always";

      serviceConfig.ExecStart = "${lib.getExe pkgs.yate} -F";
      serviceConfig.ExecReload = "${lib.getExe' pkgs.util-linux "kill"} -HUP $MAINPID";
    };

    environment.etc."yate" = {
      group = config.users.users.yate.group;
      mode = "0440";
      text = "";
    };
  };
}
