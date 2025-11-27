{
  lib,
  stdenv,
  fetchFromGitHub,
  perl,
  autoreconfHook,
  pkg-config,
  newt,
  man,
  asciidoc,
  makeWrapper,
  dahdi-linux,
}: let
  version = "3.4.0";
  hash = "sha256-O+NisMAmXXijJx6eOL5CAPWpAKQNeDlU7agUhvdvopE=";
in
  stdenv.mkDerivation {
    pname = "dahdi-tools";
    inherit version;

    buildInputs = [perl];
    nativeBuildInputs = [autoreconfHook pkg-config newt man asciidoc makeWrapper];
    enableParallelBuilding = true;

    src = fetchFromGitHub {
      owner = "asterisk";
      repo = "dahdi-tools";
      rev = "${version}";
      inherit hash;
    };

    patches = [
      ./00-add-fxstest.patch
    ];

    configureFlags = [
      "--with-dahdi=${dahdi-linux.dev}/usr"
    ];
    buildFlags = [
      "all"
      "doc"
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
      maintainers = [];
      license = lib.licenses.gpl2;
      platforms = lib.platforms.linux;
      homepage = "https://github.com/asterisk/dahdi-tools";
      description = "Userland tools for the DAHDI kernel drivers.";
    };
  }
