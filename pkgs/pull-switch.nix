{
  pkgs,
  lib,
  ...
}: let
  configuration = "/etc/nixos";
  git = lib.getExe pkgs.git;
in
  pkgs.writeShellScriptBin "pull-switch" ''
    ${git} -C ${configuration} pull
    sudo nixos-rebuild switch --fast --no-flake
  ''
