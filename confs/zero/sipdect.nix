{...}: {
  services.rsyslogd.defaultConfig = ''
    module(load="omjournal")

    template(name="journal" type="list") {
      # Emulate default journal fields
      property(name="msg" outname="MESSAGE")
      property(name="timestamp" outname="SYSLOG_TIMESTAMP")
      property(name="syslogfacility" outname="SYSLOG_FACILITY")
      property(name="syslogseverity" outname="PRIORITY")

      constant(value="sipdect" outname="SYSLOG_IDENTIFIER")
    }

    action(type="omjournal" template="journal")
  '';

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
