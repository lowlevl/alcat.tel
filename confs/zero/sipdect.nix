{...}: {
  services.sipdect = {
    enable = true;

    interfaces = ["enp2s0f0"];
    address = "10.127.0.254";
    mask = 24;

    ntpd.enable = true;
    syslogd.enable = true;

    rfp."00304222ADE9" = {
      address = "10.127.0.1";
      omm1 = true;
    };
  };
}
