{ pkgs, ... }:
pkgs.writeShellScriptBin "autoinstall" ''
  #!/bin/sh
  read -p "Press any key to continue... " -n1 -s

  set -ex
''
