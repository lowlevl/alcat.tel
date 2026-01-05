{
  pkgs,
  config,
  atel,
  ...
}: {
  sops = {
    ## SSL certificate and key for SIP over SSL
    secrets."ssl/cert" = {
      owner = config.systemd.services.yate.serviceConfig.User;
      path = "/etc/yate/ssl/cert.pem";
    };
    secrets."ssl/key" = {
      owner = config.systemd.services.yate.serviceConfig.User;
      path = "/etc/yate/ssl/key.pem";
    };

    ## Credentials for the `pstn0` line
    secrets."pstn0/username" = {};
    secrets."pstn0/password" = {};

    templates."pstn0.conf" = {
      owner = config.systemd.services.yate.serviceConfig.User;
      content = ''
        username=${config.sops.placeholder."pstn0/username"}
        password=${config.sops.placeholder."pstn0/password"}
      '';
    };

    ## Credentials for the `epvpn0` line
    secrets."epvpn0/username" = {};
    secrets."epvpn0/password" = {};

    templates."epvpn0.conf" = {
      owner = config.systemd.services.yate.serviceConfig.User;
      content = ''
        username=${config.sops.placeholder."epvpn0/username"}
        password=${config.sops.placeholder."epvpn0/password"}
      '';
    };
  };

  networking.firewall.allowedUDPPorts = [5060]; # open firewall for SIP listener

  # The Yate telephony engine service
  services.yate = {
    enable = true;

    # Default configuration and debugging
    config.general.modload = "disable";
    config.configuration.warnings = true;
    config.ygi = {
      sndpath = "${pkgs.atel-resources}/wave";
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
      general.scripts_dir = "${pkgs.atel-resources}/scripts/";

      "listener ctrl" = {
        type = "unix";
        path = "/run/yate/ctrl.sock";
      };
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

    # Routing using `regexroute`
    modules.regexroute = ''
      [contexts]

      ;
      ; :: Incoming calls pre-routing ::

      ''${in_line}^pstn0$=;called=181
      ''${in_line}^epvpn0$=;called=181

      [default]

      ; Deny unauthenticated calls (but allow `analog` calls) with `noauth`
      ''${module}^(?!analog).*$=if ''${authenticated}^$=-;error=noauth

      ;
      ; :: Dial-out to EPVPN ::

      ^01999.\{4\}$=line/\0;line=epvpn0
      ^09.\{4\}$=line/\0;line=epvpn0

      ;
      ; :: Reserved phone numbers with vanity ::

      ; [INFO]: The infoline service
      ^4636$=external/nodata/infoline.tcl

      ;
      ; :: Automated services ::

      ^811$=wave/play/${pkgs.atel-resources}/wave/music/rick-roll.slin
      ^812$=wave/play/${pkgs.atel-resources}/wave/music/woop-woop.slin
      ^813$=wave/play/${pkgs.atel-resources}/wave/le-temps-des-tempetes.slin

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
}
