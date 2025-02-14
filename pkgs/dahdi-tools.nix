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

    patches = [
      ./dahdi-tools-00-add-tools.patch
    ];

    hardeningDisable = [];
    nativeBuildInputs = [pkgs.autoreconfHook pkgs.pkg-config pkgs.man pkgs.asciidoc pkgs.makeWrapper];
    buildInputs = [pkgs.perl];

    configureFlags = [
      "--with-dahdi=${dahdi}/usr"
    ];
    makeFlags = [
      "OUTPATH=$(out)"
    ];

    postBuild = ''
      make docs
    '';
    postFixup = let
      programs = [
        "dahdi_genconf"
        "dahdi_hardware"
        "dahdi_registration"
        "lsdahdi"
        "twinstar"
        "xpp_blink"
        "xpp_sync"
      ];
    in
      builtins.concatStringsSep "\n" (builtins.map (program: ''wrapProgram "$out/bin/${program}" --prefix PERL5LIB : "$out/share/perl5"'') programs);

    meta = {
      description = "A set of tools for the DAHDI kernel drivers.";
      homepage = "https://github.com/asterisk/dahdi-tools";
      license = lib.licenses.gpl2;
      maintainers = [];
      platforms = lib.platforms.linux;
    };
  }
