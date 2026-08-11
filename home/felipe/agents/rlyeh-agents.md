# This machine: rlyeh (headless agent server)

You are running on **rlyeh**, Felipe's always-on headless NixOS mini PC.
Felipe operates it remotely — through T3 Code or SSH from his desktop
(`miskatonic`) or phone — and is almost never at a terminal here. Be
proactive and self-sufficient: close the loop yourself instead of leaving
commands for him to run over SSH. If something a task needs isn't running,
start it; if something you set up dies, revive it and say what happened.

## Environment

- Pure-flake NixOS: the entire system is defined by `~/code/personal-server`
  (public GitHub repo). System changes = edit the flake, commit + push, then
  `sudo nixos-rebuild switch --flake ~/code/personal-server#rlyeh`. Never
  install system software imperatively — add it to the flake, or use
  `nix shell nixpkgs#<pkg>` / docker for ad-hoc needs.
- Passwordless sudo. Secrets live at `/run/secrets/` (sops-nix). The
  `claude`, `codex`, `opencode`, and `gh` CLIs are already authenticated.
- Headless — no display, no compositor. Browser work: `xvfb-run chromium`
  plus screenshots.
- The T3 Code server (systemd user unit `t3code.service`, port 3773, with
  its relay tunnel) is this machine's #1 service. Never kill it, bind its
  port, or touch its unit or `~/.t3`.

## Tailscale & dev URLs

- This host is `rlyeh.bass-pirarucu.ts.net` (100.91.212.25). The firewall
  trusts only the tailnet: every port you bind is reachable from Felipe's
  devices and from nowhere else.
- Anything with a web UI or dev server must be started bound to `0.0.0.0`
  (or the tailscale IP), and always hand Felipe the URL as
  `http://rlyeh.bass-pirarucu.ts.net:<port>` — never a `localhost` URL; he
  is always on another device.

## Keep things running

- Long-lived processes must outlive your session. Start them detached —
  `tmux new -d -s <name> '<cmd>'` or `systemd-run --user --unit <name>
  <cmd>` (lingering is enabled, so user units run without a login; note
  neither tmux sessions nor transient units survive a reboot — recreate
  them if the box was restarted). Always report the URL, the tmux/unit
  name, and how to stop it.
- Don't ask Felipe to SSH in to run or restart something you can run or
  restart yourself.
- If a tool, skill, or CLI referenced by the shared instructions above
  (e.g. postplan / plan-html-workflow) isn't installed on this machine,
  degrade gracefully — e.g. deliver plans as markdown in chat — instead of
  blocking on it.
