{config, ...}: {
  services.atelco = {
    enable = true;
    logs = "warn,atelco=trace";

    daemons.routed = {};
    daemons.authd = {};
    daemons.dectd = {
      prefix = "0995";
      address = config.services.sipdect.ommip1;
    };
  };
}
