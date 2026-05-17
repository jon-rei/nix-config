{
  config,
  lib,
  inputs,
  ...
}:
let
  storageboxUser = "u525833";
  storageboxHost = "${storageboxUser}.your-storagebox.de";
in
{
  options.backup = {
    enable = lib.mkEnableOption "restic backup to Hetzner storage box";

    paths = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Paths to include in the backup.";
    };
  };

  config = lib.mkIf config.backup.enable {
    motd.services = [ "restic-backups-storagebox.timer" ];
    age.secrets.resticPassword.file = "${inputs.self}/secrets/restic-password.age";

    programs.ssh.extraConfig = ''
      Host ${storageboxHost}
        Port 23
        IdentityFile /etc/ssh/ssh_host_ed25519_key
        StrictHostKeyChecking accept-new
    '';

    services.restic.backups.storagebox = {
      paths = config.backup.paths;
      repository = "sftp://${storageboxUser}@${storageboxHost}/./backups/${config.networking.hostName}";
      passwordFile = config.age.secrets.resticPassword.path;
      extraBackupArgs = [ "--compression auto" ];
      backupPrepareCommand = "restic-storagebox unlock || true";
      timerConfig = {
        OnCalendar = "daily";
        Persistent = true;
      };
      pruneOpts = [
        "--keep-daily 7"
        "--keep-weekly 4"
        "--keep-monthly 3"
      ];
      runCheck = true;
      initialize = true;
    };
  };
}
