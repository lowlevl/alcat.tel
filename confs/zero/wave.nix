{pkgs, ...}: {
  systemd.tmpfiles.settings."99-wave" = {
    "/wave".d = {
      group = "yate";
      mode = "775";
    };

    "/wave/ro".L = {
      argument = "${pkgs.atel-resources}/wave";
    };
  };
}
