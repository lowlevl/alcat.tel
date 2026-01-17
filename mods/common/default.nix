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

    # do not degrade service while rebuilding
    daemonCPUSchedPolicy = "idle";
    daemonIOSchedClass = "idle";

    # automatic garbage-collect
    gc.automatic = true;
  };

  environment = {
    enableAllTerminfo = true;

    shellAliases = let
      configuration = "/etc/nixos";
    in {
      n = "cd '${configuration}'";
      pull-switch = "time sudo sh -c '${lib.getExe pkgs.git} -C ${configuration} pull --rebase && nixos-rebuild switch -L'";
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
