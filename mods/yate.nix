{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) types;

  enabledModules = lib.mapAttrs' (name: module: lib.nameValuePair "${name}.yate" true) cfg.modules;
  configSpecs = lib.filterAttrs (name: cnf: cnf != null) cfg.modules;
  configFns =
    lib.mapAttrs (
      name: cnf:
        if builtins.isString cnf
        then pkgs.yate.mkConfigRaw cnf
        else if builtins.isAttrs cnf && !builtins.hasAttr "__functor" cnf
        then pkgs.yate.mkConfig cnf
        else cnf
    )
    configSpecs;

  cfg = config.services.yate;
in {
  options.services.yate = {
    enable = lib.mkEnableOption config.systemd.service.yate.description;

    niceness = lib.mkOption {
      type = types.ints.between (-19) 20;
      description = "The niceness priority to run the service with";
      default = -4;
    };

    config = lib.mkOption {
      type = types.attrsOf types.attrs;
      description = "The configuration for the daemon (yate.conf)";
      default = {};
    };

    modules = lib.mkOption {
      type = types.attrsOf (types.nullOr (types.oneOf [
        types.str
        types.attrs
        (types.functionTo types.package)
      ]));
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
      after = ["network.target" "dahdi.service" "sops-nix.service"];
      description = "`yate` (Yet Another Telephony Engine) daemon";

      reloadTriggers = let
        files = ["yate"] ++ lib.mapAttrsToList (name: value: name) configSpecs;
      in
        lib.map (name: config.environment.etc."yate/${name}.conf".source) files;

      serviceConfig.LogsDirectory = "yate";
      serviceConfig.RuntimeDirectory = "yate";

      serviceConfig.Type = "forking";
      serviceConfig.Nice = cfg.niceness;
      serviceConfig.User = config.users.users.yate.name;
      serviceConfig.Group = config.users.users.yate.group;
      serviceConfig.Restart = "always";
      serviceConfig.PIDFile = "/run/${serviceConfig.RuntimeDirectory}/yate.pid";

      serviceConfig.ExecStart = "${lib.getExe pkgs.yate} -c /etc/yate -F -d -p ${serviceConfig.PIDFile} -l /var/log/${serviceConfig.LogsDirectory}/yate.log";
      serviceConfig.ExecReload = "${lib.getExe' pkgs.util-linux "kill"} -HUP $MAINPID";
    };

    environment.etc =
      {"yate/yate.conf".source = pkgs.yate.mkConfig ({modules = enabledModules;} // cfg.config) "yate.conf";}
      // lib.concatMapAttrs (name: fn: {"yate/${name}.conf".source = fn "${name}.conf";}) configFns;
  };
}
