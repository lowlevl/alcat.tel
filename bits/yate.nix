{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) types;

  yate = pkgs.callPackage ../pkgs/yate {};

  cfg = config.services.yate;
in {
  options.services.yate = {
    enable = lib.mkEnableOption config.systemd.service.yate.description;

    niceness = lib.mkOption {
      type = types.ints.between (-19) 20;
      description = "The niceness priority to run the service with";
      default = -4;
    };

    conf = lib.mkOption {
      type = types.attrsOf types.attrs;
      description = "The configuration for the daemon (yate.conf)";
      default = {};
    };
    modules = lib.mkOption {
      type = types.attrsOf (types.nullOr (types.either types.str (types.attrsOf types.attrs)));
      description = "The configuration for the specified modules (<name>.conf)";
      default = {};
    };
  };

  config = lib.mkIf cfg.enable {
    users.users.yate = {
      isSystemUser = true;
      group = "yate";
      extraGroups = ["telecom"];
    };
    users.groups.yate = {};

    systemd.services.yate = rec {
      wantedBy = ["multi-user.target"];
      after = ["network.target" "dahdi.service"];
      description = "`yate` (Yet Another Telephony Engine) daemon";

      reloadTriggers = [
        config.environment.etc."yate".source
      ];

      serviceConfig.Type = "forking";
      serviceConfig.RuntimeDirectory = "yate";
      serviceConfig.PIDFile = "/run/yate/yate.pid";

      serviceConfig.Nice = cfg.niceness;
      serviceConfig.User = config.users.users.yate.name;
      serviceConfig.Group = config.users.users.yate.group;
      serviceConfig.Restart = "always";

      serviceConfig.ExecStart = "${lib.getExe yate} -c /etc/yate -F -d -p ${serviceConfig.PIDFile}";
      serviceConfig.ExecReload = "${lib.getExe' pkgs.util-linux "kill"} -HUP $MAINPID";
    };

    environment.etc."yate".source = let
      formatter = lib.generators.toINI {listsAsDuplicateKeys = true;};
      yateconf =
        cfg.conf
        // {
          modules = lib.mapAttrs' (name: module: lib.nameValuePair "${name}.yate" true) cfg.modules;
        };
    in
      pkgs.symlinkJoin {
        name = "yate-conf.d";
        paths =
          [(pkgs.writeTextDir "yate.conf" (formatter yateconf))]
          ++ lib.mapAttrsToList
          (name: module:
            pkgs.writeTextDir "${name}.conf" (
              if lib.isString module
              then module
              else formatter module
            ))
          (lib.filterAttrs (name: module: module != null) cfg.modules);
      };
  };
}
