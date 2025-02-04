{ lib
, pkgs
, ...
}:
let
  autoinstall = pkgs.callPackage ../pkgs/autoinstall.nix { };
  flake = "github:lowlevl/phooone#hermes";
in
{
  imports = [
    ../modules/common.nix
    ../modules/remote.nix
  ];

  isoImage.squashfsCompression = null; # Disable compression for faster builds for now

  boot.loader.timeout = lib.mkForce 1;
  boot.loader.grub.timeoutStyle = "hidden";

  services.getty = {
    autologinUser = lib.mkForce null;
    extraArgs = [ "--skip-login" ];

    helpLine = lib.mkForce ''
      This is an automatic installation for a system based on a flake hosted at `${flake}`,
      it will partition the disks and provision the system using `disko-install`.

      [!!] This will erase everything on the system.
    '';

    loginProgram = "${autoinstall}/bin/autoinstall";
  };
}
