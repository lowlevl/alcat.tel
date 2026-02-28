{
  config,
  pkgs,
  lib,
  ...
}: {
  # NOTE: forward `syslog` to `journald`
  services.rsyslogd.defaultConfig = ''
    $OmitLocalLogging on # disable using syslog socket from `journald`

    module(load="omjournal")

    template(name="journal" type="list") {
      property(name="msg" outname="MESSAGE")
      property(name="timestamp" outname="SYSLOG_TIMESTAMP")
      property(name="fromhost-ip" outname="SOURCE_IP")
      property(name="syslogseverity" outname="PRIORITY")
      property(name="syslogfacility" outname="SYSLOG_FACILITY")
      # property(name="syslogtag" outname="SYSLOG_IDENTIFIER")

      constant(value="sipdect" outname="SYSLOG_IDENTIFIER")
    }

    action(type="omjournal" template="journal")
  '';

  # FIXME: NTPd still does not work

  services.sipdect = {
    enable = true;
    openFirewall = true;

    interfaces = ["enp2s0f0"];
    address = "10.127.0.254";
    mask = 24;

    ntpd.enable = true;
    syslogd.enable = true;

    rfp."00:30:42:22:ad:e9".address = "10.127.0.1";

    provisioning = {
      "ipdect.cfg" = pkgs.writeText "ipdect.cfg" ''
        <SetEULAConfirm confirm="1" />

        # set PARK from PARK service
        <SetPARK park="1F102A7158" />

        <SetSysToneScheme toneScheme="FR" />
        <SetDECTRegDomain regDomain="EMEA" />
        # reduce power to 100mW rather than 250mW
        <SetDECTPowerLimit enable="1" />
        # remove encryption for now
        <SetDECTEncryption enable="0" />
        <SetDECTAuthCode ac="0000" />

        <SetBasicSIP
          transportProt="UDP"
          proxyServer="${config.services.sipdect.address}" proxyPort="5060"
          regServer="${config.services.sipdect.address}" regPort="5060" regPeriod="60" />

        # populate users for wildcard association
        ${lib.join "\n" (builtins.genList (
            id: ''
              <CreateFixedPP>
                <user
                  uid="${builtins.toString (id + 1)}"
                  num="pp${builtins.toString (id + 1)}" />
                <pp ipei="" />
              </CreateFixedPP>
            ''
          )
          25)}

        <SetDECTSubscriptionMode mode="Wildcard" timeout="60" />
      '';
    };
  };
}
