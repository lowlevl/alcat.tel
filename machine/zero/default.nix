{
  config,
  pkgs,
  lib,
  ...
}: let
  dahdi-tools = pkgs.callPackage ../../pkgs/dahdi-tools.nix {};
  rmanager = pkgs.callPackage ../../pkgs/rmanager.nix {inherit config;};

  share = pkgs.callPackage ../../share {};
in {
  imports = [
    ./hardware-configuration.nix

    ../../bits/common
    ../../bits/dahdi.nix
    ../../bits/yate.nix
  ];

  networking.hostName = "zero";

  users.users.technician.extraGroups = ["telecom"];
  environment.systemPackages = [dahdi-tools rmanager];

  services.dahdi = {
    enable = true;
    modules = ["wctdm24xxp"];

    channels."1-4".signaling = "fxoks";
    defaultzone = "fr";
  };

  services.yate = {
    enable = true;

    conf.general.modload = "disable";
    modules.rmanager = {
      general.addr = "127.0.0.1";
      general.port = 5038;
      general.color = "yes";
    };
    modules.tonedetect = null;
    modules.tonegen = {
      general.lang = config.services.dahdi.defaultzone;
    };
    modules.wavefile = null;
    modules.zapcard = {
      "tdm410:0:fxs1-4" = {
        type = "FXS";
        offset = 0;
        voicechans = "1-4";
      };
    };
    modules.analog = {
      "local-fxs" = {
        type = "FXS";
        spans = "tdm410:0:fxs1-4";
        ringback = "yes";
      };
    };
    modules.regexroute = {};
  };

  # Ring the first phone when successfully started drivers
  systemd.services.dahdi.postStart = "${lib.getExe' dahdi-tools "fxstest"} 1 ring";

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
