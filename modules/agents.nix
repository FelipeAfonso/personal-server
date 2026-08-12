{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    claude-code
    codex
    opencode
  ];

  # Agent CLIs must stay updatable by T3 Code's provider auto-update, whose
  # update commands assume user-level installs (~/.local/bin, ~/.bun/bin).
  # Their installers ship generic dynamically-linked binaries, which need
  # nix-ld to run on NixOS.
  programs.nix-ld.enable = true;

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
