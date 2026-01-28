{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) types;

  cfg = config.services.atelco;

  socket = "/run/yate/atelco.sock";

  mkFlag = flag: value: "--${flag} '${builtins.toString value}'";
  mkFlags = attrs: lib.concatMapAttrsStringSep " " mkFlag attrs;
in {
  options.services.atelco = {
    enable = lib.mkEnableOption "Atelco®©™ daemons";
    package = lib.mkPackageOption pkgs "atelco" {};

    database = lib.mkOption {
      type = types.str;
      description = "The path to the `atelco` database file";
      default = "/var/lib/atelco/atelco.sqlite";
    };

    logs = lib.mkOption {
      type = types.str;
      description = "The log level for atelco daemons";
      default = "warn,atelco=debug";
    };

    daemons = lib.mkOption {
      type = types.attrsOf types.attrs;
      description = "Daemons to register and their parameters additionnal parameters";
      default = {};
      example = {
        routed = {};
        authd = {priority = 90;};
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = let
      ateladm = pkgs.writeShellScriptBin "ateladm" ''
        exec ${lib.getExe' cfg.package "ateladm"} \
          --database sqlite://${cfg.database} \
          "$@"
      '';
    in [ateladm];

    users.groups.atelco = {};
    users.users.atelco = {
      isSystemUser = true;
      group = "atelco";
    };

    services.yate.modules.extmodule."listener atelco" = {
      type = "unix";
      path = socket;
    };

    systemd.services = lib.mapAttrs' (name: value:
      lib.nameValuePair "atelco-${name}" {
        description = "Atelco®©™ `${name}` daemon";

        wantedBy = ["multi-user.target"];
        requires = ["yate.service"];
        after = ["yate.service"];

        environment.RUST_LOG = cfg.logs;

        startLimitBurst = 15;
        startLimitIntervalSec = 30;

        serviceConfig = {
          User = config.users.users.atelco.name;
          Group = config.users.users.atelco.group;
          SupplementaryGroups = ["yate"];

          StateDirectory = "atelco";
          StateDirectoryMode = "0775";

          Restart = "always";
          RestartSteps = "5";
          RestartMaxDelaySec = "10";

          # Create database file with `group` access
          ExecStartPre = "${lib.getExe' pkgs.execline "umask"} 0007 ${lib.getExe' pkgs.coreutils "touch"} ${cfg.database}";
          ExecStart = "${lib.getExe cfg.package} ${name} --database sqlite://${cfg.database} ${socket} ${mkFlags value}";
        };
      })
    cfg.daemons;
  };
}
