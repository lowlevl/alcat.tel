{
  pkgs,
  lib,
  ...
}: let
  telnet = lib.getExe' pkgs.busybox "telnet";
  initool = lib.getExe pkgs.initool;
in
  pkgs.writeShellScriptBin "rmanager"
  ''
    config=/etc/yate/rmanager.conf

    addr=$(${initool} get "$config" general addr -v)
    port=$(${initool} get "$config" general port -v)

    ${telnet} $addr $port
  ''
