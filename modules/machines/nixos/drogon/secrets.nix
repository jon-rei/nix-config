{ inputs, ... }:
{
  age.secrets.opencloudAdminEnv = {
    file  = "${inputs.self}/secrets/opencloud-admin-env.age";
    owner = "opencloud";
  };
  age.secrets.resticPassword.file = "${inputs.self}/secrets/restic-password.age";
}
