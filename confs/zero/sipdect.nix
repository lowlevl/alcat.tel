{...}: {
  services.rsyslogd.defaultConfig = ''
    $OmitLocalLogging on # disable using syslog socket from `journald`

    module(load="omjournal")

    template(name="journal" type="list") {
      property(name="msg" outname="MESSAGE")
      property(name="timestamp" outname="SYSLOG_TIMESTAMP")
      property(name="syslogseverity" outname="PRIORITY")
      property(name="syslogfacility" outname="SYSLOG_FACILITY")
      # property(name="syslogtag" outname="SYSLOG_IDENTIFIER")

      constant(value="sipdect" outname="SYSLOG_IDENTIFIER")
    }

    action(type="omjournal" template="journal")
  '';

  # FIXME: NTP
  # FIXME: Provisionning TFTP
  # FIXME: Firmware TFTP

  services.sipdect = {
    enable = true;

    interfaces = ["enp2s0f0"];
    address = "10.127.0.254";
    mask = 24;

    ntpd.enable = true;
    syslogd.enable = true;

    rfp."00304222ADE9".address = "10.127.0.1";
  };
}
