{ config, lib, ... }:
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
    services.restic.backups.storagebox = {
      paths = config.backup.paths;

      repository = "sftp:${config.backup.storageBoxUser}@${config.backup.storageBox}:/backups/${config.networking.hostName}";

      extraOptions = [
        "sftp.command='ssh ${config.backup.storageBoxUser}@${config.backup.storageBox} -i /etc/ssh/ssh_host_ed25519_key -s sftp'"
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
