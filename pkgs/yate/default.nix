{
  lib,
  stdenv,
  callPackage,
  fetchFromGitHub,
  openssl,
  sqlite,
  libtiff,
  spandsp,
  speex,
  gsm,
  doxygen,
  autoreconfHook,
  pkg-config,
  dahdi-linux,
  ...
}: let
  version = "05c1518de2f4f75eebe55abf1c038425f58bd51e";
  hash = "sha256-7LR+a5oHtHvdlaPnrl84qFeiOzMr2kjMiylMTjZEcsg=";
in
  stdenv.mkDerivation (finalAttrs: {
    pname = "yate";
    inherit version;

    buildInputs = [
      openssl.dev
      sqlite.dev
      libtiff.dev
      spandsp.dev
      speex.dev
      gsm
    ];
    nativeBuildInputs = [
      autoreconfHook
      pkg-config
    ];
    enableParallelBuilding = true;

    src = fetchFromGitHub {
      owner = "lowlevl";
      repo = "yate";
      rev = version;
      inherit hash;
    };

    passthru = callPackage ./passthru.nix {};

    preConfigure = ''
      configureFlagsArray+=(
        # Use `CFLAGS` because `CPPFLAGS` is not propagated correctly
        "CFLAGS=-I${dahdi-linux.dev}/usr/include"
      )
      ./yate-config.sh
    '';
    configureFlags = [
      "--with-doxygen=${lib.getExe doxygen}"
      "--with-spandsp=${spandsp.dev}/include"
      "--with-libspeex=${speex.dev}/include"
      "--with-libgsm=${gsm}/include/gsm"
      "--enable-sse2=yes"
      "--verbose"
    ];

    meta = {
      maintainers = [];
      # Yate's license is GPL with an exception for linking with
      # OpenH323 and PWlib (licensed under MPL).
      license = lib.licenses.gpl2Only;
      platforms = lib.platforms.linux;
      mainProgram = "yate";
      homepage = "https://yate.ro/";
      description = "Yet another telephony engine";
    };
  })
