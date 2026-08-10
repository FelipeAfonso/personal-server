{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    # TS/Svelte world
    bun
    nodejs

    # Go
    go

    # Rust (stable)
    rustc
    cargo
    rustfmt
    clippy
    rust-analyzer

    # Odin + raylib
    odin
    raylib

    # Native build essentials (odin/rust linking, node-gyp, etc.)
    gcc
    gnumake
    pkg-config

    # Dev utilities
    gh
    lazygit
    lazydocker
    watchexec
    inotify-tools
    jwt-cli
  ];
}
