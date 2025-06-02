{
  config,
  pkgs,
  ...
}: let
  sources = import ../sources.nix;
in {
  networking.firewall.allowedTCPPorts = [80];

  services.lighttpd = {
    enable = true;

    document-root = pkgs.symlinkJoin {
      name = "http-source";
      paths = [
        (pkgs.writeTextDir "index.html" ''
           <!DOCTYPE html>
          <html>
          <head>
            <title>${sources.realm}</title>
          </head>
          <body>
            <code>
              <h1><pre>${sources.banner}</pre></h1>

              an experiment on building a {Nix, Yate}-based telephony system.

              <h4>Routing and dial-plan</h4>

              The routing and dial-plan is made according to the following configuration:
              <details>
                <summary>regexroute.conf</summary>
                <pre>${config.services.yate.modules.regexroute}</pre>
              </details>
            </code>
          </body>
          </html>
        '')
      ];
    };
  };
}
