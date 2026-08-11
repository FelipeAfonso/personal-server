{ config, ... }:

{
  services.openssh = {
    enable = true;
    openFirewall = false;
    settings = {
      PasswordAuthentication = false;
      KbdInteractiveAuthentication = false;
      PermitRootLogin = "no";
    };
  };

  services.tailscale.enable = true;

  networking.firewall = {
    enable = true;
    trustedInterfaces = [ "tailscale0" ];
    allowedUDPPorts = [ config.services.tailscale.port ];
  };

  # mosh for flaky on-the-go links (UDP range only trusted via tailnet).
  programs.mosh.enable = true;

  # The private secrets repo is fetched during rebuilds via this alias,
  # authenticating with the machine's own host key (a read-only deploy key
  # on GitHub). Plain github.com is untouched so user identities still win.
  programs.ssh.extraConfig = ''
    Host github.com-secrets
      HostName github.com
      User git
      IdentityFile /etc/ssh/ssh_host_ed25519_key
      IdentitiesOnly yes
      HostKeyAlias github.com
  '';
  programs.ssh.knownHosts."github.com".publicKey =
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
}
