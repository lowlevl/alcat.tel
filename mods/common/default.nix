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

  nix = {
    settings.experimental-features = ["nix-command" "flakes"];
    gc.automatic = true;

    daemonCPUSchedPolicy = "idle";
  };

  environment = {
    enableAllTerminfo = true;

    shellAliases = let
      configuration = "/etc/nixos";
    in {
      n = "cd '${configuration}'";
      pull-switch = ''
        sudo sh -c '${lib.getExe pkgs.git} -C ${configuration} pull --rebase && nixos-rebuild switch "$@"' pull-switch
      '';
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
