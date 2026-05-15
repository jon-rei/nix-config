{ inputs, ... }:
{
  age.secrets.opencloudAdminEnv = {
    file  = "${inputs.self}/secrets/drogon/opencloud-admin-env.age";
    owner = "opencloud";
  };
  age.secrets.resticPassword.file       = "${inputs.self}/secrets/drogon/restic-password.age";
}
