# This machine: rlyeh (headless agent server)

You are running on **rlyeh**, Felipe's always-on headless NixOS mini PC.
Felipe operates it remotely, through T3 Code or SSH from his desktop
(`miskatonic`), his MacBook, or his phone, and is almost never at a terminal here. Be
proactive and self-sufficient: close the loop yourself instead of leaving
commands for him to run over SSH. If something a task needs isn't running,
start it; if something you set up dies, revive it and say what happened.

## Environment

- Pure-flake NixOS: the entire system is defined by `~/code/personal/personal-server`
  (public GitHub repo). System changes = edit the flake, commit + push, then
  `sudo nixos-rebuild switch --flake ~/code/personal/personal-server#rlyeh`. Never
  install system software imperatively. Add it to the flake, or use
  `nix shell nixpkgs#<pkg>` / docker for ad-hoc needs.
- Passwordless sudo. Secrets live at `/run/secrets/` (sops-nix). The
  `claude`, `codex`, `opencode`, and `gh` CLIs are already authenticated.
- Headless, no display, no compositor. Browser work: `xvfb-run chromium`
  plus screenshots.
- The T3 Code server (systemd user unit `t3code.service`, port 3773, with
  its relay tunnel) is this machine's #1 service. Never kill it, bind its
  port, or touch its unit or `~/.t3`.

## Where things live

Same split as miskatonic. Put new clones in the right bucket, never loose in
`~` or at the top of `~/code`:

- `~/code/personal/` — Felipe's own repos (personal-server, rigsmith, ...).
- `~/code/work/<client>/` — client work, one folder per client (currently
  `niterra`, which also holds loose Niterra docs next to the repos).
- `~/code/stuff/` — third-party checkouts kept around for reference (t3code).
- `~/services/` — running deployments that are not source code
  (`dfdd-staging`: binaries, env, SQLite db, logs).
- `~/backups/` — flake-managed backup output. Go's module cache is under
  `~/.local/share/go` (GOPATH), not `~/go`.

## Network: the tailnet and the fleet

Everything rides Tailscale. The tailnet is `bass-pirarucu.ts.net` with
MagicDNS on, so every machine resolves by bare hostname
(`ssh miskatonic` works, no `~/.ssh/config` needed).

| host           | what it is                                   | tailscale IP    | OS    |
| -------------- | -------------------------------------------- | --------------- | ----- |
| `rlyeh`        | this box: always-on headless agent server    | 100.91.212.25   | linux |
| `miskatonic`   | Felipe's desktop, his main workstation       | 100.91.60.55    | linux |
| `yuggoth`      | Felipe's MacBook, online intermittently      | 100.120.128.70  | macOS |
| `necronomicon` | Felipe's iPhone (SSHes in via Termius)       | 100.114.0.102   | iOS   |

Full name for any of them is `<host>.bass-pirarucu.ts.net`. rlyeh also has a
LAN address (192.168.1.x on `enp2s0`) but nothing listens there on purpose.

How the firewall works here (`modules/network.nix`):

- `tailscale0` is a trusted interface. Anything you bind on any port is
  reachable from Felipe's devices and from nowhere else. You never need to
  open firewall ports for a dev server, and you shouldn't: the only
  non-tailnet hole is Tailscale's own UDP port.
- sshd is key-only, root login off, not open on the LAN. mosh is enabled for
  flaky mobile links.
- Docker publishes ports on `0.0.0.0`, which on this box means "tailnet
  only" as well (e.g. the `dfdd-staging-valkey` container on 6390).

Rules for anything that listens:

- Bind dev servers and web UIs to `0.0.0.0` (or 100.91.212.25). A server
  bound to `127.0.0.1` is invisible to Felipe.
- Hand URLs over as `http://rlyeh.bass-pirarucu.ts.net:<port>`, never
  `localhost`. He is always on another device.
- Port 3773 belongs to T3 Code. Pick something else.
- `tailscale serve` (HTTPS on the tailnet, with a real cert) is fine to use
  when a tool insists on https. `tailscale funnel` publishes to the open
  internet: never enable it, and never run `tailscale up/down/logout` or
  change ACLs, without Felipe asking for exactly that.

The other machines:

- You can SSH into `miskatonic` (and `yuggoth` when it's online) as `felipe`
  with the keys already loaded here. Use that for reading: comparing configs,
  fetching a file, checking whether something is running. Treat them as his
  personal machines, not yours: no edits, installs, or restarts over there
  unless the task says so, and say what you touched if you do.
- `miskatonic` is where Felipe actually sits. If a result needs to land on
  his desk (a file, a screenshot), `scp` it there and tell him the path.
- Nothing on rlyeh should depend on the laptop or desktop being up. Long
  running work stays on rlyeh.

## Keep things running

- Long-lived processes must outlive your session. Start them detached with
  `tmux new -d -s <name> '<cmd>'` or `systemd-run --user --unit <name>
  <cmd>` (lingering is enabled, so user units run without a login; note
  neither tmux sessions nor transient units survive a reboot, so recreate
  them if the box was restarted). Always report the URL, the tmux/unit
  name, and how to stop it.
- Don't ask Felipe to SSH in to run or restart something you can run or
  restart yourself.
- If a tool, skill, or CLI referenced by the shared instructions above
  (e.g. postplan / plan-html-workflow) isn't installed on this machine,
  degrade gracefully (deliver plans as markdown in chat, say) instead of
  blocking on it.

## Unslop enforcement hooks

Two hooks in `~/.claude/settings.json` back the global unslop rule. A
UserPromptSubmit hook injects the rule into context every turn, and a Stop
gate (`~/.claude/hooks/unslop-stop-gate.py`) blocks ending a turn with a
substantial reply until the unslop skill was invoked via the Skill tool. If
your reply gets bounced with an unslop message, invoke the skill and
rewrite; don't try to work around the hook. The scripts are flake-managed
(`home/felipe/agents/hooks/`); the hooks block in settings.json is set by
hand because Claude Code writes to that file at runtime.
