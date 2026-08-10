# personal-server

Pure NixOS flake defining **rlyeh** — a headless, agent-focused mini PC.
The repo *is* the machine: packages, services, disk layout, and dotfiles are
all declared here. There is no imperative setup; the only deploy command is
`nixos-rebuild switch --flake .#rlyeh`.

Fleet canon: `rlyeh` (this server) · `miskatonic` (desktop) · MacBook TBD.

```
flake.nix                     inputs: nixpkgs-unstable, disko, home-manager, sops-nix (+ private secrets, dormant)
hosts/rlyeh/
  default.nix                 host wiring, user, sudo policy, home-manager entry
  disko.nix                   declarative disk: ESP + btrfs @root/@home/@nix/@swap, zstd
  hardware-configuration.nix  PLACEHOLDER until first install (see step 3)
modules/
  core.nix                    nix settings, gc, tz/locale, zram, base tools
  network.nix                 sshd (key-only), tailscale, firewall (tailnet-first)
  agents.nix                  claude-code, codex, opencode, docker
  dev.nix                     go, rust, bun, node, odin + raylib, build essentials
  headless-gfx.nix            xvfb-run, headless chromium, capture tools, fonts
  secrets.nix                 sops-nix wiring (dormant until secrets repo exists)
home/felipe/                  home-manager: zsh, tmux, nvim, starship, lazygit, opencode, bin scripts
```

## Design decisions (short version)

- **Headless.** No compositor. Web validation = headless chromium; native/game
  validation = `xvfb-run <cmd>` + `import`/`ffmpeg` capture. Humans needing a
  GUI: `ssh -X rlyeh chromium` paints onto your local display. If real remote
  desktop is ever wanted, add Sunshine + Moonlight — not built today.
- **Access.** Everything rides Tailscale. SSH is key-only, root login off.
  Passwordless sudo for `felipe`: single-human box, keeps unattended agent
  runs from stalling. Agents run as the user; docker exists for self-isolation.
- **Disk.** Btrfs subvolumes with zstd. Snapshot `/home` before letting an
  agent do something scary: `sudo btrfs subvolume snapshot -r /home /home/.snap-$(date +%s)`
- **Secrets** live in a separate **private** repo (`FelipeAfonso/secrets`),
  sops-encrypted with age even though the repo is private. This repo stays
  public and credential-free so a bare machine can clone it.

## Install (from the desktop, machine booted on a NixOS installer USB)

Prereqs on the driving machine: `nix` installed (`sh <(curl -L https://nixos.org/nix/install) --daemon`),
SSH agent loaded, this repo cloned.

1. Boot rlyeh from a NixOS ISO USB. Get its LAN IP (`ip a` on the console).
   Set a root password on the installer: `sudo passwd`.
2. **Verify the disk device**: `ssh root@<ip> lsblk`. If the NVMe is not
   `/dev/nvme0n1`, fix `hosts/rlyeh/disko.nix` first. This is the
   wipe-the-wrong-disk footgun — check it.
3. Install (partitions with disko, generates real hardware config into the
   repo, installs, reboots):

   ```sh
   nix run github:nix-community/nixos-anywhere -- \
     --flake .#rlyeh \
     --generate-hardware-config nixos-generate-config ./hosts/rlyeh/hardware-configuration.nix \
     root@<installer-ip>
   ```

4. Commit the generated `hardware-configuration.nix`.
5. First boot: SSH in over the LAN (`ssh felipe@<ip>` — LAN SSH is open until
   the tailnet is up, see `modules/network.nix`), then:
   - `sudo tailscale up` → open the printed URL in your local browser.
   - Once `tailscale status` is healthy, delete the `allowedTCPPorts = [ 22 ]`
     bootstrap line in `modules/network.nix`, rebuild, and SSH via the tailnet
     from then on: `ssh rlyeh`.
   - Change the initial password: `passwd`.
6. Steady state: edit flake → `sudo nixos-rebuild switch --flake .#rlyeh`
   (on the box, or from the desktop with `--target-host rlyeh`). A full
   reinstall is step 3 again.

## Secrets (one-time bootstrap)

1. Create the **private** GitHub repo `FelipeAfonso/secrets`.
2. Generate a personal age key: `age-keygen -o ~/.config/sops/age/keys.txt`.
3. After rlyeh's first boot, derive its host age key:
   `ssh-keyscan rlyeh | ssh-to-age`.
4. Copy `.sops.yaml` from this repo into the secrets repo, replacing both
   placeholder keys with the real ones.
5. Create `rlyeh.yaml` in the secrets repo:
   `sops rlyeh.yaml` → add e.g. `tailscale-authkey`, API keys, tokens.
6. Back here: uncomment the `secrets` input in `flake.nix` and the block in
   `modules/secrets.nix`, then rebuild. Secrets appear under `/run/secrets/`,
   never in the world-readable nix store.

Note: fetching the private input needs GitHub SSH auth on whatever machine
runs the rebuild. Rebuilding from the desktop (agent forwarding) covers this;
for rebuilds on rlyeh itself, add an SSH key for rlyeh to GitHub (deploy key
on the secrets repo is enough).

## Signing into things (headless auth cheat-sheet)

No browser runs on rlyeh; your local browser does the work.

- **Device-code flows** (`claude`, `gh auth login`, `tailscale up`): run the
  command in SSH/tmux, open the printed URL in your local browser, approve.
  The remote terminal unblocks on its own.
- **Localhost-callback flows** (`codex login`, listens on `localhost:1455`):

  ```sh
  ssh -L 1455:localhost:1455 rlyeh
  codex login   # then open the printed localhost URL in your LOCAL browser
  ```

- **Stubborn apps**: log in on another machine and copy the credential file
  (e.g. `~/.claude/.credentials.json`), or park the key in the secrets repo.
- **Actually seeing a GUI**: `ssh -X rlyeh chromium` (slow but real), or
  `xvfb-run <app>` + `import -window root shot.png` for agent-style captures.

## Validation

- `nix flake check` and
  `nix build .#nixosConfigurations.rlyeh.config.system.build.toplevel`
  must pass before an install or config change lands.
- Post-install smoke test: `ssh rlyeh` over tailnet; `tmux`; `nvim` (plugins
  restore via vim.pack from the lockfile — needs neovim ≥ 0.12, add the
  neovim-nightly overlay if nixpkgs lags); `claude --version`; `go version`;
  `cargo --version`; `bun --version`; `odin version`;
  `xvfb-run bash -c 'import -window root /tmp/x.png' && file /tmp/x.png`.
