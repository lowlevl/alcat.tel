{
  config,
  pkgs,
  ...
}: let
  dahdi = config.boot.kernelPackages.callPackage ../../pkgs/dahdi.nix {};
  dahdi-tools = pkgs.callPackage ../../pkgs/dahdi-tools.nix {};
in {
  imports = [
    ./hardware-configuration.nix

    "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/refs/tags/v1.11.0.tar.gz"}/module.nix"
    ./disk-config.nix

    ../../common
  ];

  networking.hostName = "zero";

  boot.extraModulePackages = [dahdi];
  boot.kernelModules = ["wctdm"];

  environment.systemPackages = [dahdi-tools];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
