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
    at-routing = "${atelco} routing ${socket} --database sqlite://${database}";
  };
in {
  environment.systemPackages = [ateladm];

  users.groups.atelco = {};
  users.users.atelco = {
    isSystemUser = true;
    group = "atelco";
    extraGroups = ["yate"];
  };

  # give `technician` access to `ateladm`
  users.users.technician.extraGroups = ["atelco"];

  systemd.services =
    builtins.mapAttrs (name: value: {
      description = "Atelco®©™ `${name}` daemon";

      wantedBy = ["multi-user.target"];
      requires = ["yate.service"];
      after = ["yate.service"];

      environment.RUST_LOG = "warn,atelco=trace";

      serviceConfig = {
        StateDirectory = "atelco";
        StateDirectoryMode = "0775";

        User = config.users.users.atelco.name;
        Group = config.users.users.atelco.group;

        Restart = "always";
        RestartSteps = "10";
        RestartMaxDelaySec = "5";

        ExecStartPre = [
          "+${lib.getExe' pkgs.coreutils "chmod"} g+w ${socket}" # set-up yate's socket
          "${lib.getExe' pkgs.execline "umask"} 0007 ${lib.getExe' pkgs.coreutils "touch"} ${database}" # create database file if required
        ];
        ExecStart = value;
      };
    })
    daemons;
}
