{
  config,
  pkgs,
  lib,
  ...
}: let
  socket = config.services.yate.modules.extmodule."listener ctrl".path;
  database = "/var/lib/atelco/atelco.sqlite";

  ateladm = pkgs.writeShellScriptBin "ateladm" ''
    exec ${lib.getExe' pkgs.atelco "ateladm"} \
      --database sqlite://${database} \
      "$@"
  '';
  atelco = lib.getExe pkgs.atelco;

  daemons = {
    atelco-routed = "${atelco} routed ${socket} --database sqlite://${database}";
    atelco-authd = "${atelco} authd ${socket} --database sqlite://${database}";
  };
in {
  environment.systemPackages = [ateladm];
  users.users.technician.extraGroups = ["atelco"]; # give `technician` access to `ateladm`

  users.groups.atelco = {};
  users.users.atelco = {
    isSystemUser = true;
    group = "atelco";
  };

  systemd.services =
    builtins.mapAttrs (name: value: {
      description = "Atelco®©™ `${name}` daemon";

      wantedBy = ["multi-user.target"];
      requires = ["yate.service"];
      after = ["yate.service"];

      environment.RUST_LOG = "warn,atelco=trace";

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

        ExecStartPre = [
          "${lib.getExe' pkgs.execline "umask"} 0007 ${lib.getExe' pkgs.coreutils "touch"} ${database}" # create database file if required
        ];
        ExecStart = value;
      };
    })
    daemons;
}
