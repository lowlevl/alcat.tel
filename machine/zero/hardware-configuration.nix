{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")

    "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/refs/tags/v1.11.0.tar.gz"}/module.nix"
    ./disk-config.nix
  ];

  boot.initrd.availableKernelModules = ["sata_sil" "ohci_pci" "ehci_pci" "pata_atiixp" "usb_storage" "usbhid" "sd_mod" "sr_mod"];
  boot.initrd.kernelModules = [];
  boot.kernelModules = [];
  boot.extraModulePackages = [];

  networking.useDHCP = lib.mkDefault true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
