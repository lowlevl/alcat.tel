{ self
, pkgs
, lib
, ...
}: {
  imports = [
    (self.inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix")

    ../modules/base.nix
    ../modules/remote.nix
    ../modules/install-unattended.nix
  ];

  isoImage.squashfsCompression = null; # Disable compression for faster builds for now

  boot.loader.timeout = lib.mkForce 1;
  boot.loader.grub.timeoutStyle = "hidden";

  install-unattended = {
    enable = true;

    flake = self;
    conf = "bagley";
    disk = "main";
  };
}
