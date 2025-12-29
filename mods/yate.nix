{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) types;

  cfg = config.services.yate;

  enabledModules = lib.mapAttrs' (name: module: lib.nameValuePair "${name}.yate" true) cfg.modules;
  configSpecs = lib.filterAttrs (name: cnf: cnf != null) cfg.modules;
  configFns =
    lib.mapAttrs (
      name: cnf:
        if builtins.isString cnf
        then cfg.package.mkConfigRaw cnf
        else if builtins.isAttrs cnf && !builtins.hasAttr "__functor" cnf
        then cfg.package.mkConfig cnf
        else cnf
    )
    configSpecs;
in {
  options.services.yate = {
    enable = lib.mkEnableOption config.systemd.service.yate.description;
    package = lib.mkPackageOption pkgs "yate" {};

    nodename = lib.mkOption {
      type = types.str;
      description = "The name of the node in clustered configuation";
      default = config.networking.hostName;
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
    users.groups.yate = {};
    users.users.yate = {
      isSystemUser = true;
      group = "yate";
      extraGroups = ["telecom"];
    };

    systemd.services.yate = {
      description = "`yate` (Yet Another Telephony Engine) daemon";

      wantedBy = ["multi-user.target"];
      wants = ["network-online.target" "dahdi.service" "sops-nix.service"];
      after = ["network-online.target" "dahdi.service" "sops-nix.service"];

      reloadTriggers = let
        files = ["yate"] ++ lib.mapAttrsToList (name: value: name) configSpecs;
      in
        lib.map (name: config.environment.etc."yate/${name}.conf".source) files;

      serviceConfig = {
        User = config.users.users.yate.name;
        Group = config.users.users.yate.group;
        Restart = "always";
        Nice = -4;

        RuntimeDirectory = "yate"; # populate `/run/yate` for sockets

        ExecReload = "${lib.getExe' pkgs.util-linux "kill"} -HUP $MAINPID";
        ExecStart = "${lib.getExe cfg.package} -c /etc/yate -F -N ${cfg.nodename}";
      };
    };

    environment.etc =
      {"yate/yate.conf".source = cfg.package.mkConfig ({modules = enabledModules;} // cfg.config) "yate.conf";}
      // lib.concatMapAttrs (name: fn: {"yate/${name}.conf".source = fn "${name}.conf";}) configFns;
  };
}
