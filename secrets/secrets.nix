# agenix key declarations — run from repo root (AGENIX_IDENTITY is set by .envrc):
# nix develop --command agenix -e <secret-file>
let
  desktop = "age1axl06kreggjspv9rg5wk4a40xaedln8ydv88uqg4lxxgz56hua5qx85sgl";
  drogon = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFzlfrsycRwl2PFf4baxUdpSMvJMLxckc2HX+A2Hrao";

  keyList = [
    desktop
    drogon
  ];
in
{
  "nextcloud-admin-password.age".publicKeys = keyList;
  "desec-env.age".publicKeys = keyList;
  "restic-password.age".publicKeys = keyList;
}
