{
  stdenv,
  pkgs,
  lib,
  ...
}: let
  dahdi-linux = pkgs.linuxPackages.callPackage ../dahdi-linux {};
in
  stdenv.mkDerivation (finalAttrs: rec {
    pname = "yate";
    version = "6.4.1-2";

    nativeBuildInputs = [
      pkgs.autoreconfHook
      pkgs.pkg-config
    ];
    buildInputs = [
      pkgs.openssl.dev
      pkgs.sqlite.dev
      pkgs.libtiff.dev
      pkgs.spandsp.dev
      pkgs.speex.dev
      pkgs.gsm
    ];
    enableParallelBuilding = false; # Breaks the libminiwebrtc.a's `ar` call

    passthru = import ./passthru.nix {
      inherit pkgs lib;
      self = finalAttrs.finalPackage;
    };

    src = pkgs.fetchFromGitHub {
      owner = "lowlevl";
      repo = "${pname}";
      rev = "c32d90f5a78b8b0e0e787a42ec75d4e39b634643";
      sha256 = "e/CzVbc2ldp1mZMiRrvcFsdRY2gyVzUNWxdtfdXAc5I=";
    };

    preConfigure = ''
      configureFlagsArray+=(
        # Use `CFLAGS` because `CPPFLAGS` is not propagated correctly
        "CFLAGS=-I${dahdi-linux}/usr/include"
      )
      ./yate-config.sh
    '';
    configureFlags = [
      "--with-doxygen=${lib.getExe pkgs.doxygen}"
      "--with-spandsp=${pkgs.spandsp.dev}/include"
      "--with-libspeex=${pkgs.speex.dev}/include"
      "--with-libgsm=${pkgs.gsm}/include/gsm"
      "--enable-sse2=yes"
      "--verbose"
    ];

    meta = {
      description = "Yet another telephony engine";
      homepage = "https://yate.ro/";
      # Yate's license is GPL with an exception for linking with
      # OpenH323 and PWlib (licensed under MPL).
      license = lib.licenses.gpl2Only;
      maintainers = [];
      platforms = lib.platforms.linux;
      mainProgram = "yate";
    };
  })
