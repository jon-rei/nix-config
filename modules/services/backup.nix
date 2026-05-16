{ config, lib, pkgs, inputs, ... }:
let
  user = config.age.secrets.storageboxUser.path;
  host = "${user}.your-storagebox.de";
in
{
  options.backup = {
    enable = lib.mkEnableOption "restic backup to Hetzner storage box";

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Paths to include in the backup.";
    };
  };

  config = lib.mkIf config.backup.enable {
    age.secrets.resticPassword.file = "${inputs.self}/secrets/restic-password.age";
    age.secrets.storageboxUser.file = "${inputs.self}/secrets/storagebox-user.age";

    programs.ssh.extraConfig = ''
      Host storagebox
        HostName ${host}
        User ${user}
        IdentityFile /etc/ssh/ssh_host_ed25519_key
        Port 23
    '';

    environment.shellAliases.restic = "sudo ${pkgs.restic}/bin/restic -r sftp:storagebox:./backups/${host} -p ${config.age.secrets.resticPassword.path}";

    services.restic.backups.storagebox = {
      paths = config.backup.paths;

      repository = "sftp:storagebox:./backups/${host}";

      extraOptions = [
        "sftp.command='ssh storagebox -s sftp'"
      ];

      passwordFile = config.age.secrets.resticPassword.path;

      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };

      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];

      initialize = true;
    };
  };
}
