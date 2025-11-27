{
  lib,
  stdenv,
  fetchFromGitHub,
  yate,
  php,
  tcl,
}: let
  yate-tcl = fetchFromGitHub {
    owner = "bef";
    repo = "yate-tcl";
    rev = "f306cedf1b4760e2d8c02cf4159f7018172349fe";
    sha256 = "E37vAiOsmn0lhZPwKNXyLx7czEihvKcotJGDkQyMQpM=";
  };
in
  stdenv.mkDerivation {
    name = "at";

    nativeBuildInputs = [];
    buildInputs = [php tcl];

    sourceRoot = ".";
    srcs = [
      ./scripts
      ./wave
    ];

    dontBuild = true;
    installPhase = ''
      runHook preInstall
      install -m 0755 -D scripts/* -t $out/scripts/
      mkdir -p $out/wave/ && cp -vr wave/* $out/wave/
      runHook postInstall
    '';
    postInstall = let
      links = [
        # Yate's library files
        "${yate}/share/yate/scripts/libyate.php"
        "${yate}/share/yate/scripts/libyateivr.php"
        "${yate}/share/yate/scripts/libyatechan.php"
        "${yate}/share/yate/scripts/libvoicemail.php"
        "${yate}/share/yate/scripts/libeliza.js"
        "${yate}/share/yate/scripts/libchatbot.js"
        "${yate}/share/yate/scripts/eliza.js"
        "${yate}/share/yate/scripts/libyate.py"
        "${yate}/share/yate/scripts/Yate.pm"

        # Bef's ygi library
        "${yate-tcl}/ygi"
      ];
    in
      builtins.concatStringsSep "\n" (
        builtins.map (path: "ln -v -s ${path} $out/scripts/$(basename ${path})") links
      );

    meta = {
      maintainers = [];
      license = lib.licenses.gpl3;
      platforms = lib.platforms.all;
      description = "The resources in the alcat.tel system";
    };
  }
