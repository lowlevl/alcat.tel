{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./services.nix
    ./locale.nix
    ./users.nix
  ];

  environment = {
    enableAllTerminfo = true;

    shellAliases = let
      configuration = "/etc/nixos";
    in {
      n = "cd '${configuration}'";
      pull-switch = "${lib.getExe pkgs.git} -C ${configuration} pull --rebase && sudo nixos-rebuild switch --fast";
    };
  };

  networking.domain = "alcat.tel";
}
