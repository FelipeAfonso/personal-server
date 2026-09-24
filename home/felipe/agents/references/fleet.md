# Fleet operations

Read this for remote-machine work or network administration. Tailnet hosts
resolve through MagicDNS. Prefer names over hardcoded addresses.

| Host | Purpose | Tailscale IP | OS |
| --- | --- | --- | --- |
| rlyeh | Always-on agent server | 100.91.212.25 | NixOS |
| miskatonic | Felipe's desktop | 100.91.60.55 | CachyOS |
| yuggoth | Intermittently online laptop | 100.120.128.70 | macOS |
| necronomicon | iPhone | 100.114.0.102 | iOS |

Each full name is `<host>.bass-pirarucu.ts.net`. SSH as `felipe` using the
loaded keys. Read-only inspection is allowed. Editing, installation, and
restarts on another machine must be included in the user's task. Report what
you changed there. Do not make rlyeh depend on another machine being online.

Keep long-running or scheduled work on rlyeh. Read `previews.md` in this
directory before starting processes. When a file needs to reach Felipe's
desktop, copy it to an appropriate location on miskatonic and report the path.

Rlyeh's source is `~/code/personal/personal-server` on rlyeh. Read that repo's
instructions before changing it. After an authorized merge and deployment:

```sh
ssh rlyeh 'sudo nixos-rebuild switch --flake ~/code/personal/personal-server#rlyeh'
```

The desktop's source is `~/code/personal/personal-desktop` on miskatonic.
Use `./export_current --agents-only` for agent files, and a full export only
when the task includes the other desktop configurations. Laptop configuration
lives in personal-laptop; verify its current checkout before using it.

On rlyeh, `modules/network.nix` trusts `tailscale0`. Dev previews do not need
new firewall holes. SSH is key-only, with root login disabled. Docker ports
bind on `0.0.0.0`; inspect the current firewall if exposure matters to the task
rather than assuming every interface or future configuration is identical.

`tailscale serve` can provide HTTPS within the tailnet. Inspect existing
routes before changing them. Never enable `tailscale funnel`, run
`tailscale up/down/logout`, or change ACLs without an explicit request.
Never modify T3 Code's service, relay, port 3773, or `~/.t3` on either host.
