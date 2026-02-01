{lib, ...}: let
  inherit (lib) types;
in {
  rfp = types.submodule {
    options = {
      address = lib.mkOption {
        type = types.str;
        description = "The address to be assigned to the RFP";
      };
    };
  };

  ntpd = types.submodule {
    options = {
      enable = lib.mkEnableOption "Network Time Protocol support for RFPs";
    };
  };

  syslogd = types.submodule {
    options = {
      enable = lib.mkEnableOption "Syslogd support for RFPs";

      address = lib.mkOption {
        type = types.nullOr types.str;
        description = "The address of the syslogd server, or if `null` start a local server";
        default = null;
      };
      port = lib.mkOption {
        type = types.int;
        description = "The port of the syslogd server";
        default = 514;
      };
    };
  };
}
