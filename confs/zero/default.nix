{
  config,
  pkgs,
  lib,
  atel,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./disk-config.nix

    ./httpd.nix
  ];

  networking.hostName = "zero";

  environment.systemPackages = [pkgs.dahdi-tools pkgs.rmanager];
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
  systemd.services.dahdi.postStart = "${lib.getExe' pkgs.dahdi-tools "fxstest"} 1 ring";

  # The Yate telephony service
  services.yate = {
    enable = true;

    # Default configuration and debugging
    config.general.modload = "disable";
    config.configuration.warnings = true;
    config.ygi = {
      sndpath = "${pkgs.atel}/wave";
      sndformats = "slin";
    };

    modules.rmanager = {
      general.addr = "127.0.0.1";
      general.port = 5038;
      general.color = true;
      general.prompt = "\"\${configname}@\${nodename}> \"";
    };

    # Audio processing and sources
    modules.tonedetect = null;
    modules.wavefile = null;
    modules.tonegen = pkgs.yate.mkConfigExt {
      general.lang = config.services.dahdi.defaultzone;
    };
    modules.extmodule = {
      general.scripts_dir = "${pkgs.atel}/scripts/";
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

        ringback = true;
        call-ended-playtime = 10;
      };
    };

    # SIP-related parameters, including SRTP, SIPS and DTMF passthrough
    modules.openssl = {};
    modules.ysipchan = {
      general = {
        realm = atel.realm;
        useragent = "alcat.tel/v1.3.3.7";
        dtmfmethods = "rfc2833,info";

        ssl_certificate_file = "ssl/cert.pem";
        ssl_key_file = "ssl/key.pem";
        secure = true;
      };
    };
    modules.yrtpchan = {};
    modules.accfile = {
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
    modules.regexroute = ''
      [contexts]

      ; Treat `sip` incoming calls with extra care
      ''${module}^sip$=include sip

      ;
      ; :: Incoming calls pre-routing ::

      ''${in_line}^pstn0$=;called=181
      ''${in_line}^epvpn0$=;called=181

      [sip]

      ; Reject unauthenticated calls with `noauth`
      ''${username}^$=-;error=noauth

      ; TODO: Ensure the `caller` value is equivalent to the authenticated username
      ;.*=;caller=''${username}

      [default]

      ;
      ; :: Dial-out to EPVPN ::

      ^01999.\{4\}$=line/\0;line=epvpn0
      ^09.\{4\}$=line/\0;line=epvpn0

      ;
      ; :: Local analog phones (FXS) ::

      ^18\([1-4]\)$=analog/local-fxs/\1

      ;
      ; :: Reserved phone numbers with vanity ::

      ; [INFO]: The infoline service
      ^4636$=external/nodata/infoline.tcl

      ;
      ; :: Automated services ::

      ^811$=wave/play/${pkgs.atel}/wave/music/rick-roll.slin
      ^812$=wave/play/${pkgs.atel}/wave/music/woop-woop.slin
      ^813$=wave/play/${pkgs.atel}/wave/le-temps-des-tempetes.slin

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
      ; :: `off-hook` calls handler using `overlapped.php`

      ''${overlapped}yes=goto overlapped
      ^off-hook$=external/nodata/overlapped.php;tonedetect_in=yes;interdigit=10;accept_call=true

      [overlapped]

      ; Limit overlapped dialing to `10` digits
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
