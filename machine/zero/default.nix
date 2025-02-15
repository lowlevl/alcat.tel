{
  config,
  pkgs,
  ...
}: let
  dahdi-linux = config.boot.kernelPackages.callPackage ../../pkgs/dahdi-linux.nix {};
  dahdi-tools = pkgs.callPackage ../../pkgs/dahdi-tools.nix {};
in {
  imports = [
    ./hardware-configuration.nix

    "${builtins.fetchTarball "https://github.com/nix-community/disko/archive/refs/tags/v1.11.0.tar.gz"}/module.nix"
    ./disk-config.nix

    ../../common
  ];

  networking.hostName = "zero";

  boot.extraModulePackages = [dahdi-linux];
  boot.kernelModules = ["wctdm24xxp"];

  environment.systemPackages = [dahdi-tools pkgs.pciutils];

  services.udev.extraRules = ''
    ACTION!="add",	GOTO="dahdi_add_end"

    # DAHDI devices with ownership/permissions for running as non-root
    SUBSYSTEM=="dahdi",		OWNER="asterisk", GROUP="asterisk", MODE="0660"

    # Backward compat names: /dev/dahdi/<channo>
    SUBSYSTEM=="dahdi_channels",	SYMLINK+="dahdi/%m"

    # Add persistant names as well
    SUBSYSTEM=="dahdi_channels", ATTRS{hardware_id}!="",	SYMLINK+="dahdi/devices/%s{hardware_id}/%s{local_spanno}/%n"
    SUBSYSTEM=="dahdi_channels", ATTRS{location}!="",	SYMLINK+="dahdi/devices/@%s{location}/%s{local_spanno}/%n"

    LABEL="dahdi_add_end"
  '';

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
