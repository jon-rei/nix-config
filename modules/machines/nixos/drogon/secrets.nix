{ inputs, ... }:
{
  age.secrets.opencloudEnv = {
    file  = "${inputs.self}/secrets/opencloud-env.age";
    owner = "opencloud";
  };
}
