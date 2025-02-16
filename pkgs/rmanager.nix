{
  config,
  pkgs,
  lib,
  ...
}: let
  telnet = lib.getExe' pkgs.busybox "telnet";
in
  pkgs.writeShellScriptBin "rmanager"
  ''
    ${telnet} ${config.services.yate.modules.rmanager.general.addr} ${builtins.toString config.services.yate.modules.rmanager.general.port}
  ''
