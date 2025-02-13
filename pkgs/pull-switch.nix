{
  pkgs,
  lib,
  ...
}: let
  configuration = "/etc/nixos";

  git = lib.getExe pkgs.git;
  beep = lib.getExe pkgs.beep;
in
  pkgs.writeShellScriptBin "pull-switch" ''
    ${git} -C ${configuration} pull
    ${beep}

    sudo nixos-rebuild switch --fast --no-flake
    ${beep} -f 420 -l 250 \
    	-n -f 440 -l 500 \
	-n -f 880 -l 250
  ''
