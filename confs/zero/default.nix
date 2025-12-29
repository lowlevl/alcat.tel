{pkgs, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    ./yate.nix
    ./atelco.nix

    ./httpd.nix
  ];

  networking.hostName = "zero";
  environment.systemPackages = [pkgs.dahdi-tools pkgs.rmanager];

  # Secrets management outside of the Nix store
  sops.defaultSopsFile = ../../secrets.yaml;
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  # Drivers and configuration for telephony cards
  services.dahdi = {
    enable = true;
    modules = ["wctdm24xxp"];

    channels."1-4".signaling = "fxoks";
    defaultzone = "fr";
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
