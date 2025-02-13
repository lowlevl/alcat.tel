{pkgs, ...}: {
  imports = [
    ./security.nix

    ./locale.nix
    ./users.nix
    ./ssh.nix

    ./beep.nix
  ];

  networking.domain = "alcat.tel";

  environment.systemPackages = with pkgs; [
    (pkgs.callPackage ../pkgs/pull-switch.nix {})

    neovim
    btop
  ];
}
