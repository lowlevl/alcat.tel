{...}: {
  # Drivers and configuration for telephony cards
  services.dahdi = {
    enable = true;
    modules = ["wctdm24xxp"];

    defaultzone = "fr";
    channels."1-4".signaling = "fxoks";
    channels."1-4".echocanceller = "oslec";
  };
}
