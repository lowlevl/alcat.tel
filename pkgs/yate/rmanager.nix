{
  lib,
  writeShellScriptBin,
  initool,
  busybox,
  ...
}:
writeShellScriptBin "rmanager" ''
  config=/etc/yate/rmanager.conf

  addr=$(${lib.getExe initool} get "$config" general addr -v)
  port=$(${lib.getExe initool} get "$config" general port -v)

  ${lib.getExe' busybox "telnet"} $addr $port
''
