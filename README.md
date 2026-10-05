# personal-server

Pure NixOS flake defining **rlyeh** — a headless, agent-focused mini PC.
The repo *is* the machine: packages, services, disk layout, and dotfiles are
all declared here. There is no imperative setup; the only deploy command is
`nixos-rebuild switch --flake .#rlyeh`.

Fleet canon (tailnet `bass-pirarucu.ts.net`): `rlyeh` (this server) · `miskatonic` (desktop) · `yuggoth` (MacBook) · `necronomicon` (iPhone). The agent prompts in `home/felipe/agents/` carry the same map.

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
  backups.nix                 Turso dumps (4h, df-dd-api daily) -> ~/backups/turso/<db>, 7-day retention
home/felipe/                  home-manager: zsh, tmux, nvim, starship, lazygit, opencode, bin scripts
  agents/                     global prompts for claude/codex/opencode, shared model table (models.md), vendored skills (unslop, plan-html-workflow)
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

## Shared agent instructions

`home/felipe/agents/` owns the shared instructions for Claude, Codex, and
OpenCode. Each installed file combines its client instructions, `models.md`,
`workflow.md`, and the machine's operating notes. Change common policy in
`workflow.md`; keep client tool details in `<cli>-global.md`.

Check the copies in another fleet repository before deploying:

```sh
python3 scripts/sync-agent-prompts.py ../personal-desktop
```

The check exits with status 1 if a shared file differs or is missing. To copy
updates, switch the target repo to a task branch and add `--write`. The script
refuses to overwrite uncommitted changes in the target files. It also syncs
the planning skill's instructions and shared references. Machine notes and
`references/rlyeh.md` stay in their own repo.
Commit and review the changes in both repos before deployment.

Keep the always-loaded files short. Procedures live in `agents/references/`
and install under `~/.agents/references/`; the global instructions say when
to read each file. Shared references sync to the desktop, while each machine
owns its own operations reference. Check the links as part of deployment.
The [model catalog brief](home/felipe/agents/references/model-usage.md) explains
expected usage under the current routing policy, without claiming measured
usage or vendor capabilities.

Rlyeh installs these files through Home Manager during `nixos-rebuild switch`.
On miskatonic, `./export_current --agents-only` installs the agent files
without exporting unrelated desktop configs. After deploying, compare all
three installed files with the concatenated sources. Existing conversations
may still contain earlier instructions; start a fresh session for the new
policy.

## Weekend maintenance

`rlyeh-maintenance.timer` starts on the machine every Sunday at 02:00
America/Sao_Paulo. Runs end by 06:00. Missed runs do not catch up on weekdays.
No laptop, T3 session, or desktop app needs to be open.

The store-owned runner creates a separate clone under
`~/code/personal/personal-server-maintenance/`, updates `nixpkgs`, `disko`,
`home-manager`, and `sops-nix`, and keeps the private secrets input pinned.
It runs `nix flake check` and builds the full system. A failed build gets
one repair attempt from GPT-5.6 Sol at high effort; GPT-6 Astra independently
reviews the final changes at high effort. Both use the existing Codex account
login. Missing models, expired authentication, and quota failures stop the run;
there is no paid API fallback. Models follow the installed bucket catalog;
weekly usage is currently unknown, so the normal Reasoning preference applies.

Agents run as Felipe in temporary systemd services with a private PID
namespace, a read-only system, and access to their checkout and Codex state.
Docker, privileged Nix sockets, systemd buses, host keys, secrets, T3 files,
and the user service configuration are hidden. Network connections to the
machine's own addresses are blocked. Codex authentication and session state
remain shared with Felipe's existing account. The trusted runner performs
the builds, GitHub delivery, merge, and privileged activation. Agent repairs
can change only the lockfile and dependency declarations in `modules/dev.nix`
and `modules/headless-gfx.nix`. Broader repairs need a separate task.

Successful, reviewed updates reuse one maintenance branch and fast-forward
only the verified commit onto the unchanged remote `main`. No PR is created,
following this repository's delivery workflow. Activation must pass a
dry run. A deployment retry must match the exact system closure and Git tree
of a recorded approval; an empty update diff alone cannot authorize a new
system. Home Manager activation is allowed only when neither generation
manages T3 files or relay units. Actual stops or restarts of T3, its relay,
the user manager, SSH, Tailscale, or networking remain for a separate
maintenance decision. Reboots are always deferred. Deployment verifies SSH,
Tailscale, and the same T3 launcher and listener processes and service
definitions. An independent ten-minute watchdog restores
the previous system if activation or health checks fail. The previous system
and current candidate have GC roots; run evidence and failed clones remain
available without pinning every old system closure.

Inspect scheduling and the latest result:

```sh
systemctl list-timers rlyeh-maintenance.timer
sudo cat /var/lib/rlyeh-maintenance/status.json
journalctl -u rlyeh-maintenance.service
```

Check authentication, the pinned build, the sandboxed reviewer, and T3 health without updating,
merging, or deploying:

```sh
sudo rlyeh-maintenance --preflight
```

Starting the service manually still enforces the Sunday 02:00-06:00 window.
To pause maintenance, stop `rlyeh-maintenance.timer`; remove its `wantedBy`
declaration and rebuild for a permanent pause.

## Validation

- `nix flake check` and
  `nix build .#nixosConfigurations.rlyeh.config.system.build.toplevel`
  must pass before an install or config change lands.
- Post-install smoke test: `ssh rlyeh` over tailnet; `tmux`; `nvim` (plugins
  restore via vim.pack from the lockfile — needs neovim ≥ 0.12, add the
  neovim-nightly overlay if nixpkgs lags); `claude --version`; `go version`;
  `cargo --version`; `bun --version`; `odin version`;
  `xvfb-run bash -c 'import -window root /tmp/x.png' && file /tmp/x.png`.
