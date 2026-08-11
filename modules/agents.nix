{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    claude-code
    codex
    opencode
  ];

  # Available for agents to self-isolate risky runs.
  virtualisation.docker.enable = true;

  # T3 Code server: `bunx t3 connect` (run once, credential in ~felipe/.t3)
  # provisions its OWN self-updating systemd user service (t3code.service,
  # ~/.t3/runtime/service-launcher.mjs) wired to the T3 Connect relay. Don't
  # add a competing system-level server — two instances fight over ~/.t3 and
  # steal the relay tunnel from each other. All the flake needs to provide is
  # lingering, so the user service runs from boot without an SSH session.
  users.users.felipe.linger = true;
}
