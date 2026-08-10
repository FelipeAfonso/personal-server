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
    # BOOTSTRAP: SSH stays open on the LAN until tailscale is logged in and
    # reachable. Once `tailscale status` looks right, delete this line and
    # rebuild — after that SSH rides the tailnet only.
    allowedTCPPorts = [ 22 ];
  };

  # mosh for flaky on-the-go links (UDP range only trusted via tailnet).
  programs.mosh.enable = true;
}
