{
  lib,
  pkgs,
  config,
  ...
}: let
  inherit (lib) types;

  dahdi-lib = {
    # List taken from `zoneinfo.c` in dahdi-tools
    types.tonezone = types.enum [
      "us"
      "au"
      "fr"
      "nl"
      "uk"
      "fi"
      "es"
      "jp"
      "no"
      "at"
      "nz"
      "it"
      "us-old"
      "gr"
      "tw"
      "cl"
      "se"
      "be"
      "sg"
      "il"
      "br"
      "hu"
      "lt"
      "pl"
      "za"
      "pt"
      "ee"
      "mx"
      "in"
      "de"
      "ch"
      "dk"
      "cz"
      "cn"
      "ar"
      "my"
      "th"
      "bg"
      "ve"
      "ph"
      "ru"
      "tr"
      "pa"
      "mo"
      "cr"
      "ae"
    ];

    types.span = types.submodule {
      options = {
        timingsource = lib.mkOption {
          type = types.int.u8;
          description = ''
            All T1/E1/BRI spans generate a clock signal on their transmit side. The
            <timing source> parameter determines whether the clock signal from the far
            end of the T1/E1/BRI is used as the master source of clock timing. If it is, our
            own clock will synchronise to it. T1/E1/BRI connected directly or indirectly to
            a PSTN provider (telco) should generally be the first choice to sync to. The
            PSTN will never be a slave to you. You must be a slave to it.

            Choose 1 to make the equipment at the far end of the E1/T1/BRI link the preferred
            source of the master clock. Choose 2 to make it the second choice for the master
            clock, if the first choice port fails (the far end dies, a cable breaks, or
            whatever). Choose 3 to make a port the third choice, and so on. If you have, say,
            2 ports connected to the PSTN, mark those as 1 and 2. The number used for each
            port should be different.

            If you choose 0, the port will never be used as a source of timing. This is
            appropriate when you know the far end should always be a slave to you. If
            the port is connected to a channel bank, for example, you should always be
            its master. Likewise, BRI TE ports should always be configured as a slave.
            Any number of ports can be marked as 0.

            Incorrect timing sync may cause clicks/noise in the audio, poor quality or failed
            faxes, unreliable modem operation, and is a general all round bad thing.
          '';
          default = 1;
        };

        lbo = lib.mkOption {
          type = types.ints.between 0 7;
          description = ''
            The line build-out (or LBO) is an integer, from the following table:

             0: 0 db (CSU) / 0-133 feet (DSX-1)
             1: 133-266 feet (DSX-1)
             2: 266-399 feet (DSX-1)
             3: 399-533 feet (DSX-1)
             4: 533-655 feet (DSX-1)
             5: -7.5db (CSU)
             6: -15db (CSU)
             7: -22.5db (CSU)
          '';
        };

        framing = lib.mkOption {
          type = types.enum ["d4" "esf" "cas" "ccs"];
          description = ''
            One of 'd4' or 'esf' for T1 or 'cas' or 'ccs' for E1.
            Use 'ccs' for BRI. 'd4' could be referred to as 'sf' or 'superframe'
          '';
        };

        coding = lib.mkOption {
          type = types.enum ["ami" "b8zs" "ami" "hdb3"];
          description = ''
            One of 'ami' or 'b8zs' for T1 or 'ami' or 'hdb3' for E1.
            Use 'ami' for BRI.
          '';
        };
      };
    };

    types.dynamic = types.submodule {
      options = {
        driver = lib.mkOption {
          type = types.str;
          description = "The name of the driver (e.g. eth)";
        };

        address = lib.mkOption {
          type = types.str;
          description = "The driver specific address (like a MAC for eth)";
        };

        numchans = lib.mkOption {
          type = types.int.u8;
          description = "The number of channels";
        };

        timing = lib.mkOption {
          type = types.int.u8;
          description = "The timing priority, like for a normal span.";
        };
      };
    };

    types.channels = types.submodule {
      options = {
        signaling = lib.mkOption {
          type = types.enum [
            "e&m"
            "e&me1"
            "fxsls"
            "fxsgs"
            "fxsks"
            "fxols"
            "fxogs"
            "fxoks"
            "unused"
            "clear"
            "bchan"
            "rawhdlc"
            "dchan"
            "hardhdlc"
            "nethdlc"
            "dacs"
            "dacsrbs"
          ];
          description = ''
            The signaling method for the channel range (e.g. 1,3,5 or 16-23, 29)

            e&m::
              Channel(s) are signalled using E&M signalling on a T1 line.
              Specific implementation, such as Immediate, Wink, or Feature
              Group D are handled by the userspace library.
            e&me1::
              Channel(s) are signalled using E&M signalling on an E1 line.
            fxsls::
              Channel(s) are signalled using FXS Loopstart protocol.
            fxsgs::
              Channel(s) are signalled using FXS Groundstart protocol.
            fxsks::
              Channel(s) are signalled using FXS Koolstart protocol.
            fxols::
              Channel(s) are signalled using FXO Loopstart protocol.
            fxogs::
              Channel(s) are signalled using FXO Groundstart protocol.
            fxoks::
              Channel(s) are signalled using FXO Koolstart protocol.

            unused::
              No signalling is performed, each channel in the list remains idle
            clear::
              Channel(s) are bundled into a single span.  No conversion or
              signalling is performed, and raw data is available on the master.
            bchan::
              Like 'clear' except all channels are treated individually and
              are not bundled.  'inclear' is an alias for this.
            rawhdlc::
              The DAHDI driver performs HDLC encoding and decoding on the
              bundle, and the resulting data is communicated via the master
              device.
            dchan::
              The DAHDI driver performs HDLC encoding and decoding on the
              bundle and also performs incoming and outgoing FCS insertion
              and verification.  'fcshdlc' is an alias for this.
            hardhdlc::
              The hardware driver performs HDLC encoding and decoding on the
              bundle and also performs incoming and outgoing FCS insertion
              and verification.  Is subject to limitations and support of underlying
              hardware. BRI spans serviced by the wcb4xxp driver must use hardhdlc
              channels for the signalling channels.
            nethdlc::
              The DAHDI driver bundles the channels together into an
              hdlc network device, which in turn can be configured with
              sethdlc (available separately). In 2.6.x kernels you can also optionally
              pass the name for the network interface after the channel list.
              Syntax:

                nethdlc=<channel list>[:interface name]
              Use original names, don't use the names which have been already registered
              in system e.g eth.

            dacs::
              The DAHDI driver cross connects the channels starting at
              the channel number listed at the end, after a colon
            dacsrbs::
              The DAHDI driver cross connects the channels starting at
              the channel number listed at the end, after a colon and
              also performs the DACSing of RBS bits
          '';
        };

        encoding = lib.mkOption {
          type = types.nullOr types.enum ["mulaw" "alaw" "deflaw"];
          description = ''
            Usually the channel driver sets the encoding of the PCM for the channel (mulaw / alaw. That is: g711u or g711a).
            However there are some cases where you would like to override that.
            'mulaw' and 'alaw' set different such encoding.

            'deflaw' is similar, but resets the encoding to the channel driver's default.
            It must be useful for something, I guess.
          '';
        };

        echocanceller = lib.mkOption {
          type = types.nullOr types.enum ["hwec" "mg2" "kb1" "sec2" "sec"];
          description = ''
            DAHDI uses modular echo cancellers that are configured per channel. The echo
            cancellers are compiled and installed as part of the dahdi-linux package.
            You can specify in this file the echo canceller to be used for each
            channel. The default behavior is for there to be NO echo canceller on any
            channel, so it is very important that you specify one here.
          '';
        };
      };
    };
  };

  dahdi-linux = config.boot.kernelPackages.callPackage ../pkgs/dahdi-linux.nix {};
  dahdi-tools = pkgs.callPackage ../pkgs/dahdi-tools.nix {};

  cfg = config.services.dahdi;
in {
  options.services.dahdi = rec {
    enable = lib.mkEnableOption "Management of DAHDI interfaces and kernel drivers";

    modules = lib.mkOption {
      type = types.listOf types.str;
      description = "The list of modules to be managed by the service";
    };

    defaultzone = lib.mkOption {
      type = dahdi-lib.types.tonezone;
      description = "The default tone zone to be loaded";
      default = "us";
    };
    loadzone = lib.mkOption {
      type = types.listOf dahdi-lib.types.tonezone;
      description = "A list of tone zones to be preloaded";
      default = [defaultzone.default];
    };

    spans = lib.mkOption {
      type = types.attrsOf dahdi-lib.types.span;
      description = "Spans definitions and configuration";
    };

    dynamic = lib.mkOption {
      type = types.listOf dahdi-lib.types.dynamic;
      description = "Dynamic pans definitions and configuration";
    };

    channels = lib.mkOption {
      type = types.attrsOf dahdi-lib.types.channel;
      description = "Channels definitions and configuration";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.extraModulePackages = [dahdi-linux];

    users.groups.telecom = {};

    systemd.services.dahdi = rec {
      wantedBy = ["multi-user.target"];
      after = ["network.target"];
      description = "`dahdi-linux` modules (un)loading process and userland configuration";

      reloadTriggers = [
        config.environment.etc."dahdi/system.conf".source
      ];

      serviceConfig.Type = "oneshot";
      serviceConfig.RemainAfterExit = "yes";

      preStart =
        builtins.concatStringsSep "\n"
        (builtins.map (module: ''${lib.getExe' pkgs.kmod "modprobe"} "${module}"'') cfg.modules);
      postStop =
        builtins.concatStringsSep "\n"
        (builtins.map (module: ''${lib.getExe' pkgs.kmod "rmmod"} "${module}"'') cfg.modules);

      script = "${lib.getExe' dahdi-tools "dahdi_cfg"}";
      reload = "${script}";
    };

    environment.etc."dahdi/system.conf" = {
      group = "${config.users.groups.telecom.name}";
      mode = "0660";
      text = ''
      '';
    };

    services.udev.extraRules = ''
      ACTION!="add", GOTO="dahdi_end"

      # DAHDI devices with permissions for running as non-root
      SUBSYSTEM=="dahdi", GROUP="${config.users.groups.telecom.name}", MODE="0660"

      # Backward compatible dev-paths: /dev/dahdi/<channo>
      SUBSYSTEM=="dahdi_channels", SYMLINK+="dahdi/%m"

      # Add persistant names as well
      SUBSYSTEM=="dahdi_channels", ATTRS{hardware_id}!="", SYMLINK+="dahdi/devices/%s{hardware_id}/%s{local_spanno}/%n"
      SUBSYSTEM=="dahdi_channels", ATTRS{location}!="", SYMLINK+="dahdi/devices/@%s{location}/%s{local_spanno}/%n"

      LABEL="dahdi_end"

      # Hotplug scripts
      SUBSYSTEM=="dahdi_devices", RUN+="${dahdi-tools}/share/dahdi/dahdi_handle_device"
      SUBSYSTEM=="dahdi_spans", RUN+="${dahdi-tools}/share/dahdi/dahdi_span_config"
    '';
  };
}
