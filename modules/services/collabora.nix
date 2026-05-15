{ pkgs, lib, ... }:
let
  domain = "office.jonrei.de";
  opencloudDomain = "cloud.jonrei.de";
in
{
  services.collabora-online = {
    enable = true;
    port = 9980;
    settings = {
      ssl.enable = false;
      ssl.termination = true;
      net.listen = "loopback";
      storage.wopi.host = [
        { allow = true; desc = opencloudDomain; regex = lib.strings.escapeRegex opencloudDomain; }
      ];
    };
    extraArgs = [
      "--o:sys_template_path=${pkgs.collabora-online}/share/coolwsd/systemplate"
    ];
  };

  fileSystems."/usr/share/fonts/collabora" =
    let
      fontDir = pkgs.symlinkJoin {
        name = "collabora-fonts";
        paths = with pkgs; [ corefonts ];
      };
    in
    {
      device = "${fontDir}/share/fonts";
      fsType = "none";
      options = [ "bind" ];
    };

  services.caddy.virtualHosts.${domain}.extraConfig = ''
    reverse_proxy http://127.0.0.1:9980
  '';
}
