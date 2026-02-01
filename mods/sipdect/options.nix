{lib, ...}: let
  inherit (lib) types;
in {
  rfp = types.submodule {
    options = {
      address = lib.mkOption {
        type = types.str;
        description = "The address to be assigned to the RFP";
      };

      omm1 = lib.mkOption {
        type = types.bool;
        description = "Set the RFP to operate as `omm1` (main-OMM)";
        default = false;
      };

      omm2 = lib.mkOption {
        type = types.bool;
        description = "Set the RFP to operate as `omm2` (standby-OMM)";
        default = false;
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
    };
  };
}
