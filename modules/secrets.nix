# sops-nix wiring. Secrets live in the private FelipeAfonso/secrets repo
# (flake input), encrypted for felipe's personal age key and for this host's
# age key derived from its SSH host key — see README "Secrets".
{ config, inputs, ... }:

{
  sops = {
    defaultSopsFile = "${inputs.secrets}/rlyeh.yaml";
    age.sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
    secrets = {
      # Still a placeholder value; only consulted when the node is logged
      # out (e.g. a reinstall), so fill it before relying on auto-join.
      tailscale-authkey = { };
      github-pat = { };
    };
  };
  services.tailscale.authKeyFile = config.sops.secrets.tailscale-authkey.path;
}
