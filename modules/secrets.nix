# sops-nix wiring. Dormant until the private secrets repo exists —
# see README "Secrets" for the bootstrap order. Once the `secrets` flake
# input is uncommented in flake.nix, uncomment the block below.
{ ... }:

{
  # sops = {
  #   defaultSopsFile = "${inputs.secrets}/rlyeh.yaml";
  #   age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
  #   secrets.tailscale-authkey = { };
  # };
  # services.tailscale.authKeyFile = config.sops.secrets.tailscale-authkey.path;
}
