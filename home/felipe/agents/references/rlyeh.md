# Rlyeh operations

Read this for system changes, secrets, or browser setup on rlyeh. The machine
has no display or compositor. Browser work uses `xvfb-run chromium` with
screenshots. Check the available browser tools before choosing a workflow.

The system is defined by `~/code/personal/personal-server`. Read its local
instructions, then edit the flake on a task branch. Never install permanent
system packages imperatively. For temporary tools, use `nix shell` or Docker.

The repo's required validation is `nix flake check` and a build of
`.#nixosConfigurations.rlyeh.config.system.build.toplevel`. Merge and deploy
only with the authorization required by the repo. The deployment command is:

```sh
sudo nixos-rebuild switch --flake ~/code/personal/personal-server#rlyeh
```

Passwordless sudo is configured. Use a dry activation when needed to inspect
service changes before switching. Protect T3 Code throughout deployment and
check that the intended service or installed files match the new source.

Secrets are provided by sops-nix under `/run/secrets/`. Read only the values
required for the task and do not print or commit them. Agent CLIs and `gh`
have been configured here; verify access when a task needs it.

`~/services/` holds deployments rather than source checkouts. `~/backups/`
holds flake-managed backups. Go's module cache is under `~/.local/share/go`.

User lingering is enabled. Named tmux sessions and transient user units
outlive logins but need recreating after a reboot. Use a declared service for
work that must survive reboot. Read `previews.md` before launching a process
and `fleet.md` for network or remote-machine operations.
