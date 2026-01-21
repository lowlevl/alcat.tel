{...}: {
  systemd.tmpfiles.settings."99-wave" = {
    "/wave".d = {
      group = "yate";
      mode = "775";
    };

    "/wave/static".L = {
      argument = builtins.toString ./wave;
    };
  };
}
