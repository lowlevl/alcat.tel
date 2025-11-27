{
  lib,
  yate,
  writeText,
  ...
}: let
  toINI = lib.generators.toINI {listsAsDuplicateKeys = true;};
in rec {
  mkConfig = config: mkConfigRaw (toINI config);
  mkConfigRaw = config: filename: writeText filename config;
  mkConfigExt = config: filename: writeText filename ((builtins.readFile "${yate}/etc/yate/${filename}") + "\n" + (toINI config));
}
