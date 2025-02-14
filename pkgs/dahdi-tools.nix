{
  stdenv,
  lib,
  pkgs,
}: let
  dahdi = pkgs.linuxPackages.callPackage ./dahdi.nix {};
in
  stdenv.mkDerivation rec {
    pname = "dahdi-tools";
    version = "3.4.0";

    src = builtins.fetchTarball {
      url = "https://github.com/asterisk/dahdi-tools/releases/download/v${version}/dahdi-tools-${version}.tar.gz";
      sha256 = "1rb44przhc5zabs62z96pnn6i939lw2s6wdc6fqimb1vdiksag9d";
    };

    hardeningDisable = [];
    nativeBuildInputs = [pkgs.autoreconfHook pkgs.pkg-config pkgs.perl];

    configureFlags = [
      "--with-dahdi=${dahdi}/usr"
    ];
    makeFlags = [
      "OUTPATH=$(out)"
    ];

    meta = {
      description = "A set of tools for the DAHDI kernel drivers.";
      homepage = "https://github.com/asterisk/dahdi-tools";
      license = lib.licenses.gpl2;
      maintainers = [];
      platforms = lib.platforms.linux;
    };
  }
