{
  lib,
  pkgs,
  ...
}: {
  mkSystemConfig = cfg: let
    formatter = pkgs.formats.iniWithGlobalSection {listsAsDuplicateKeys = true;};
  in
    formatter.generate "system.conf" {
      globalSection =
        {
          loadzone = cfg.loadzones;
          defaultzone = cfg.defaultzone;

          span =
            lib.mapAttrsToList (id: cfg: "${id},${cfg.timing},${cfg.lbo},${cfg.framing},${cfg.coding}" + lib.optionalString cfg.yellow ",yellow")
            cfg.spans;
          dynamic =
            lib.map (cfg: "${cfg.driver},${cfg.address},${cfg.numchans},${cfg.timing}")
            cfg.dynamic;
        }
        // lib.zipAttrs (lib.mapAttrsToList (id: cfg: {${cfg.signaling} = id;}) (lib.filterAttrs (id: cfg: cfg.signaling != null) cfg.channels))
        // lib.zipAttrs (lib.mapAttrsToList (id: cfg: {${cfg.encoding} = id;}) (lib.filterAttrs (id: cfg: cfg.encoding != null) cfg.channels))
        // lib.zipAttrs (lib.mapAttrsToList (id: cfg: {echocanceller = "${cfg.echocanceller},${id}";}) (lib.filterAttrs (id: cfg: cfg.echocanceller != null) cfg.channels));
    };
}
