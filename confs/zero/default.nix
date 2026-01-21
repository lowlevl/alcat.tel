{...}: {
  imports = [
    # Base stuff
    ./hardware-configuration.nix
    ./disk-config.nix

    # Misc stuff
    ./wave.nix

    # Telephony stuff
    ./dahdi.nix
    ./yate.nix
    ./atelco.nix
  ];

  networking.hostName = "zero";

  # Secrets management outside of the Nix store
  sops.defaultSopsFile = ../../secrets.yaml;
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
