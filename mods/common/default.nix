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
      pull-switch = "sudo sh -c '${lib.getExe pkgs.git} -C ${configuration} pull --rebase && nixos-rebuild switch'";
    };

    systemPackages = with pkgs; [
      neovim
      btop
      file
      git
    ];
  };

  networking.domain = "alcat.tel";
}
