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
    python3 # node-gyp needs it (t3/node-pty native builds)
    node-gyp

    # Dev utilities
    gh
    turso-cli
    # Vercel CLI isn't in nixpkgs; wrap the npm package via npx (cached
    # under ~/.npm after first run).
    (writeShellScriptBin "vercel" ''
      exec ${nodejs}/bin/npx --yes vercel@latest "$@"
    '')
    lazygit
    lazydocker
    watchexec
    inotify-tools
    jwt-cli
  ];
}
