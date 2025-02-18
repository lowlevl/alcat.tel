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
    modules.extmodule = {
      general = {
        scripts_dir = "${share}/scripts/";
      };
    };
    modules.zapcard = {
      "tdm410:0:1-4" = {
        type = "FXS";
        offset = 0;
        voicechans = "1-4";
      };
    };
    modules.analog = {
      "local-fxs" = {
        type = "FXS";
        spans = "tdm410:0:1-4";

        ringback = "yes";
        call-ended-playtime = 10;
      };
    };
    modules.regexroute = ''
      [default]
      ; TODO: No routing for unauthenticated remote users
      ;''${username}^$=-;error=noauth

      ^off-hook$=external/nodata/overlapped.php;tonedetect_in=yes;interdigit=10;accept_call=true

      ^991$=tone/dial
      ^992$=tone/busy
      ^993$=tone/ring
      ^994$=tone/specdial
      ^995$=tone/congestion
      ^996$=tone/outoforder
      ^997$=tone/milliwatt
      ^998$=tone/info
      ^111$=wave/play/${share}/wave/rick-roll.slin

      ^20\([1-4]\)$=analog/local-fxs/\1

      ''${overlapped}yes^=return
      .\{10\}=-;error=noroute
      .*=;error=incomplete
    '';
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
