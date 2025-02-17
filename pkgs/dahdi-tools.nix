{
  stdenv,
  lib,
  pkgs,
}: let
  dahdi-linux = pkgs.linuxPackages.callPackage ./dahdi-linux.nix {};
in
  stdenv.mkDerivation rec {
    pname = "dahdi-tools";
    version = "3.4.0";

    hardeningDisable = [];
    nativeBuildInputs = [pkgs.autoreconfHook pkgs.pkg-config pkgs.newt pkgs.man pkgs.asciidoc pkgs.makeWrapper];
    buildInputs = [pkgs.perl];

    src = pkgs.fetchFromGitHub {
      owner = "asterisk";
      repo = "${pname}";
      rev = "${version}";
      sha256 = "O+NisMAmXXijJx6eOL5CAPWpAKQNeDlU7agUhvdvopE=";
    };

    patches = [
      ./dahdi-tools-00-add-fxstest.patch
    ];

    configureFlags = [
      "--with-dahdi=${dahdi-linux}/usr"
    ];
    buildFlags = [
      "all" "doc"
    ];
    installFlags = [
      "OUTPATH=$(out)"
    ];

    postPatch = ''
      echo "${version}" > .version
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
      description = "Userland tools for the DAHDI kernel drivers.";
      homepage = "https://github.com/asterisk/dahdi-tools";
      license = lib.licenses.gpl2;
      maintainers = [];
      platforms = lib.platforms.linux;
    };
  }
