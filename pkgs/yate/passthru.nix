{
  self,
  lib,
  pkgs,
  ...
}: let
  toINI = lib.generators.toINI {listsAsDuplicateKeys = true;};
in rec {
  mkConfig = config: mkConfigRaw (toINI config);
  mkConfigRaw = config: filename: pkgs.writeText filename config;
  mkConfigExt = config: filename: pkgs.writeText filename ((builtins.readFile "${self}/etc/yate/${filename}") + "\n" + (toINI config));
}
