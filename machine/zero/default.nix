{
  config,
  pkgs,
  lib,
  ...
}: let
  sources = import ../../sources.nix;

  dahdi-tools = pkgs.callPackage ../../pkgs/dahdi-tools {};
  rmanager = pkgs.callPackage ../../pkgs/yate/rmanager.nix {inherit config;};
  yate = pkgs.callPackage ../../pkgs/yate {};

  share = pkgs.callPackage ../../share {};
in {
  imports = [
    sources.disko
    sources.sops-nix

    ./hardware-configuration.nix
    ./disk-config.nix

    ../../bits/common
    ../../bits/dahdi
    ../../bits/yate.nix
  ];

  networking.hostName = "zero";

  environment.systemPackages = [dahdi-tools rmanager];
  users.users.technician.extraGroups = ["telecom"];

  # Secrets management outside of the Nix store
  sops.defaultSopsFile = ../../secrets.yaml;
  sops.age.sshKeyPaths = ["/etc/ssh/ssh_host_ed25519_key"];

  sops.secrets."sip0/server" = {};
  sops.secrets."sip0/username" = {};
  sops.secrets."sip0/password" = {};
  sops.templates."sip0.conf" = {
    content = ''
      [sip0]
      server=${config.sops.placeholder."sip0/server"}
      username=${config.sops.placeholder."sip0/username"}
      password=${config.sops.placeholder."sip0/password"}
    '';
    owner = config.users.users.yate.name;
    path = "/etc/yate/sip0.conf";
  };

  # Drivers and configuration for telephony cards
  services.dahdi = {
    enable = true;
    modules = ["wctdm24xxp"];

    channels."1-4".signaling = "fxoks";
    defaultzone = "fr";
  };

  # Ring the first phone when successfully started drivers
  systemd.services.dahdi.postStart = "${lib.getExe' dahdi-tools "fxstest"} 1 ring";

  # The Yate telephony service
  services.yate = {
    enable = true;

    # Default configuration and debugging
    conf.general.modload = "disable";
    modules.rmanager = {
      general.addr = "127.0.0.1";
      general.port = 5038;
      general.color = "yes";
    };

    # Audio processing and sources
    modules.tonedetect = null;
    modules.wavefile = null;
    modules.tonegen =
      ''
        [general]
        lang=${config.services.dahdi.defaultzone}
      ''
      + builtins.readFile "${yate}/etc/yate/tonegen.conf";
    modules.extmodule = {
      general.scripts_dir = "${share}/scripts/";
    };

    # Hardware configuration
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

    # External trunks and lines
    modules.accfile = ''
      $include sip0.conf

      [sip0]
      enabled=yes
      protocol=sip
    '';

    # Routing
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
      ^999$=tone/noise

      ^111$=wave/play/${share}/wave/rick-roll.slin
      ^17$=wave/play/${share}/wave/woop-woop.slin

      ^20\([1-4]\)$=analog/local-fxs/\1

      ''${overlapped}yes^=return
      .\{10\}=-;error=noroute
      .*=;error=incomplete
    '';
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
