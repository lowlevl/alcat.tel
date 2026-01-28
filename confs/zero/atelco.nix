{...}: {
  services.atelco = {
    enable = true;
    logs = "warn,atelco=trace";

    daemons.routed = {};
    daemons.authd = {};
  };
}
