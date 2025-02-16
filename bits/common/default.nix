{pkgs, ...}: {
  imports = [
    ./locale.nix
    ./users.nix

    ./services.nix
  ];

  networking.domain = "alcat.tel";
  environment.enableAllTerminfo = true;
}
