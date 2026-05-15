# agenix key declarations — run from repo root (AGENIX_IDENTITY is set by .envrc):
#   cd secrets && agenix -e drogon/opencloud-admin-env.age
#
# Get drogon's SSH public key after first boot:
#   ssh-keyscan <ip> | grep ed25519
let
  desktop = "age1axl06kreggjspv9rg5wk4a40xaedln8ydv88uqg4lxxgz56hua5qx85sgl";
  drogon  = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKFzlfrsycRwl2PFf4baxUdpSMvJMLxckc2HX+A2Hrao";
in {
  "drogon/opencloud-admin-env.age".publicKeys    = [ desktop drogon ];
  "drogon/restic-password.age".publicKeys        = [ desktop drogon ];
}
