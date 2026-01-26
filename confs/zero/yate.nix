{
  pkgs,
  config,
  atel,
  ...
}: {
  # Set up secrets for Yate
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

  # The Yate service
  networking.firewall.allowedUDPPorts = [5060]; # open firewall for SIP listener
  services.yate = {
    enable = true;
    extraGroups = ["telecom"]; # give access to `yate` to telephony cards

    # Default configuration and debugging
    config.general.modload = "disable";
    config.configuration.warnings = true;

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

      fr.callwaiting = "440/300,0/10000"; # forgotten alias
    };
    modules.extmodule = {
      general.scripts_dir = pkgs.ascripts;

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

        echotaps = 256;
      };
    };
    modules.analog = {
      general = {
        echocancel = true;
        call-ended-playtime = 10;
      };

      "local-fxs" = {
        type = "FXS";
        spans = "tdm410:0:1-4";

        ringback = true;
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

    # Routing modules
    modules.callfork = {};
    modules.lateroute = {};
    modules.regexroute = ''
      [contexts]

      ;
      ; :: Incoming calls pre-routing ::

      ''${in_line}^pstn0$=;called=180
      ''${in_line}^epvpn0$=;called=180

      [default]

      ; Deny unauthenticated calls with `noauth`
      ''${module}^(?!analog).*$=if ''${username}^$=-;error=noauth

      ;
      ; :: Dial-out to EPVPN ::

      ^01999.\{4\}$=line/\0;line=epvpn0
      ^09.\{4\}$=line/\0;line=epvpn0

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
