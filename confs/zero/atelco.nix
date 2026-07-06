{config, ...}: {
  services.atelco = {
    enable = true;
    logs = "warn,atelco=trace";

    daemons.dectd = {
      prefix = "0995";
      address = config.services.sipdect.ommip1;
    };
    daemons.authd = {};
    daemons.routed = {};
    daemons.divertd = {};
  };
}
