{
  self,
  lib,
  pkgs,
  ...
}: let
  toINI = lib.generators.toINI {listsAsDuplicateKeys = true;};
in {
  mkConfig = config: filename: pkgs.writeText filename (toINI config);
  mkConfigPrefix = prefix: config: filename: pkgs.writeText filename (prefix + "\n" + (toINI config));
  mkConfigExt = config: filename: pkgs.writeText filename ((builtins.readFile "${self}/etc/yate/${filename}") + "\n" + (toINI config));
}
