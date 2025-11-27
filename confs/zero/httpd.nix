{
  config,
  pkgs,
  lib,
  atel,
  ...
}: let
  index = let
    lines = config.services.yate.modules.accfile;
  in
    pkgs.writeTextDir "index.html" ''
      <!DOCTYPE html>
      <html>
      <head>
        <meta charset="UTF-8">
        <title>${atel.realm}</title>
      </head>
      <body>
        <code>
          <h1><pre>${atel.banner}</pre></h1>

          an experiment on building a {Nix, Yate}-based telephony system.

          <h2># Routing and dial-plan</h4>

          <p>
            The routing and dial-plan is made according to the following configuration:
            <details>
              <summary><b>regexroute.conf</b></summary>
              <blockquote>
                <pre>${config.services.yate.modules.regexroute}</pre>
              </blockquote>
            </details>
          </p>

          <p>
            The phone system also provides <b>${toString (builtins.length (builtins.attrNames lines))}</b> external connection points.
            <ul>
              ${lib.concatMapAttrsStringSep "\n" (name: blob: "<li><b>${name}:</b> connects to <i>${blob.server}</i>.</li>") lines}
            </ul>
          </p>
        </code>
      </body>
      </html>
    '';
in {
  networking.firewall.allowedTCPPorts = [80];

  services.lighttpd = {
    enable = true;

    document-root = pkgs.symlinkJoin {
      name = "http-source";
      paths = [index];
    };
  };
}
