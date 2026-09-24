# Rlyeh

This is Felipe's always-on headless NixOS server. He works remotely. Complete
local operations yourself rather than handing him SSH commands.

- Never kill or modify `t3code.service`, its relay, port 3773, or `~/.t3`.
- System configuration lives in `~/code/personal/personal-server`. Use the
  flake for permanent changes; `nix shell` or Docker for temporary tools.
  Read this repo's instructions before changing or deploying system config.
- Put clones in `~/code/personal/`, `~/code/work/<client>/`, or `~/code/stuff/`.
  Deployments belong in `~/services/`; backups in `~/backups/`.
- Bind previews to `0.0.0.0` and provide
  `http://rlyeh.bass-pirarucu.ts.net:<port>`. Don't open firewall ports for them.
- Keep long-running work detached on rlyeh, independent of other machines.
- Remote reads are allowed. Changes to another machine must be included in
  the task. Never enable Tailscale Funnel or change tailnet membership or
  ACLs unless Felipe explicitly requests it.

Read `~/.agents/references/rlyeh.md` before system, secrets, or browser setup.
