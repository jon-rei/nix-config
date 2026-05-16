{ config, lib, pkgs, ... }:
{
  options.backup = {
    enable = lib.mkEnableOption "restic backup to Hetzner storage box";

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Paths to include in the backup.";
    };

    storageBox = lib.mkOption {
      type = lib.types.str;
      description = "Storage box SFTP address, e.g. u000000.your-storagebox.de";
    };

    storageBoxUser = lib.mkOption {
      type = lib.types.str;
      description = "Storage box username, e.g. u000000";
    };
  };

  config = lib.mkIf config.backup.enable {
    programs.ssh.extraConfig = ''
      Host storagebox
        HostName ${config.backup.storageBox}
        User ${config.backup.storageBoxUser}
        IdentityFile /etc/ssh/ssh_host_ed25519_key
        Port 23
    '';

    environment.shellAliases.restic = "sudo ${pkgs.restic}/bin/restic -r sftp:storagebox:./backups/${config.networking.hostName} -p ${config.age.secrets.resticPassword.path}";

    services.restic.backups.storagebox = {
      paths = config.backup.paths;

      repository = "sftp:storagebox:./backups/${config.networking.hostName}";

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
