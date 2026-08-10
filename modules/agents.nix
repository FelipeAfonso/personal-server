{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    claude-code
    codex
    opencode
  ];

  # Available for agents to self-isolate risky runs.
  virtualisation.docker.enable = true;
}
