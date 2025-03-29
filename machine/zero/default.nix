{
  config,
  pkgs,
  lib,
  ...
}: let
  sources = import ../../sources.nix;

  resources = pkgs.callPackage ../../resources {};

  dahdi-tools = pkgs.callPackage ../../pkgs/dahdi-tools {};
  rmanager = pkgs.callPackage ../../pkgs/yate/rmanager.nix {};
  yate = pkgs.callPackage ../../pkgs/yate {};
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

  ## SSL certificate and key for SIPS
  sops.secrets."ssl/cert" = {
    owner = config.systemd.services.yate.serviceConfig.User;
    path = "/etc/yate/ssl/cert.pem";
  };
  sops.secrets."ssl/key" = {
    owner = config.systemd.services.yate.serviceConfig.User;
    path = "/etc/yate/ssl/key.pem";
  };

  ## Credentials for the `pstn0` line
  sops.secrets."pstn0/username" = {};
  sops.secrets."pstn0/password" = {};
  sops.templates."pstn0.conf" = {
    owner = config.systemd.services.yate.serviceConfig.User;
    content = ''
      username=${config.sops.placeholder."pstn0/username"}
      password=${config.sops.placeholder."pstn0/password"}
    '';
  };

  ## Credentials for the `epvpn0` line
  sops.secrets."epvpn0/username" = {};
  sops.secrets."epvpn0/password" = {};
  sops.templates."epvpn0.conf" = {
    owner = config.systemd.services.yate.serviceConfig.User;
    content = ''
      username=${config.sops.placeholder."epvpn0/username"}
      password=${config.sops.placeholder."epvpn0/password"}
    '';
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
    config.general.modload = "disable";
    config.configuration.warnings = true;
    config.ygi = {
      sndpath = "${resources}/wave";
      sndformats = "slin";
    };

    modules.rmanager = yate.mkConfig {
      general.addr = "127.0.0.1";
      general.port = 5038;
      general.color = true;
      general.prompt = "\"\${configname}@\${nodename}> \"";
    };

    # Audio processing and sources
    modules.tonedetect = null;
    modules.wavefile = null;
    modules.tonegen = yate.mkConfigExt {
      general.lang = config.services.dahdi.defaultzone;
    };
    modules.extmodule = yate.mkConfig {
      general.scripts_dir = "${resources}/scripts/";
    };

    # Hardware configuration
    modules.zapcard = yate.mkConfig {
      "tdm410:0:1-4" = {
        type = "FXS";
        offset = 0;
        voicechans = "1-4";
      };
    };
    modules.analog = yate.mkConfig {
      "local-fxs" = {
        type = "FXS";
        spans = "tdm410:0:1-4";

        ringback = true;
        call-ended-playtime = 10;
      };
    };

    # SIP-related parameters, including SRTP, SIPS and DTMF passthrough
    modules.openssl = yate.mkConfig {};
    modules.ysipchan = yate.mkConfig {
      general = {
        realm = "alcat.tel's telephony network";
        useragent = "alcat.tel/v1.3.3.7";
        dtmfmethods = "rfc2833,info";

        ssl_certificate_file = "ssl/cert.pem";
        ssl_key_file = "ssl/key.pem";
        secure = true;
      };
    };
    modules.yrtpchan = yate.mkConfig {};
    modules.accfile = yate.mkConfig {
      pstn0 = {
        enabled = true;
        protocol = "sip";
        server = "sbc6.fr.sip.ovh";
        "[$require ${config.sops.templates."pstn0.conf".path}]" = null;
      };

      epvpn0 = {
        enabled = true;
        protocol = "sip";
        server = "hg.eventphone.de";
        sips = true;
        "[$require ${config.sops.templates."epvpn0.conf".path}]" = null;
      };
    };

    # Routing
    modules.regexroute = yate.mkConfigPrefix ''
      [contexts]

      ; Treat `sip` incoming calls with extra care
      ''${module}^sip$=include sip

      ;
      ; :: Incoming calls pre-routing ::

      ''${in_line}^pstn0$=;called=888
      ''${in_line}^epvpn0$=;called=888

      [sip]

      ; Reject unauthenticated calls with `noauth`
      ''${username}^$=-;error=noauth

      ; TODO: Ensure the `caller` value is equivalent to the authenticated username
      ;.*=;caller=''${username}

      [default]

      ;
      ; :: Service numbers ::

      ^991$=tone/dial
      ^992$=tone/busy
      ^993$=tone/ring
      ^994$=tone/specdial
      ^995$=tone/congestion
      ^996$=tone/outoforder
      ^997$=tone/milliwatt
      ^998$=tone/info
      ^999\(.\)$=tone/probe/\1

      ;
      ; :: Automated services ::

      ^811$=wave/play/${resources}/wave/music/rick-roll.slin
      ^812$=wave/play/${resources}/wave/music/woop-woop.slin

      ^888$=external/nodata/hotline.tcl

      ;
      ; :: Local analog phones (FXS) ::

      ^18\([1-4]\)$=analog/local-fxs/\1

      ;
      ; :: Dial-out to EPVPN ::

      ^01999.\{4\}$=line/\0;line=epvpn0
      ^09.\{4\}$=line/\0;line=epvpn0

      ;
      ; :: `off-hook` calls routing using `overlapped.php`

      ''${overlapped}yes=goto overlapped
      ^off-hook$=external/nodata/overlapped.php;tonedetect_in=yes;interdigit=10;accept_call=true

      [overlapped]

      ; Limit overlapped dialing to `10` digits
      .\{10\}=-;error=noroute
      .*=;error=incomplete

    '' {};
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
