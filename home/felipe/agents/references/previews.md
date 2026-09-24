# Web previews and persistent processes

Read this before starting a preview or background process. Check that the
chosen port is free. Port 3773 is reserved for T3 Code.


Felipe opens dev servers from another device on the tailnet
(`bass-pirarucu.ts.net`), so binding to `0.0.0.0` is necessary but rarely
sufficient: most modern dev servers validate the `Host` header and reject
tailnet hostnames until they are allowlisted.

- Vite / SvelteKit / Astro (Vite ≥ 6): `--host 0.0.0.0` plus
  `server: { allowedHosts: ['.bass-pirarucu.ts.net'] }` in `vite.config.ts`
  (the leading dot allows every machine on the tailnet).
- Next.js: `next dev -H 0.0.0.0` is enough. No dev-time host allowlist.
- Other stacks, same idea: webpack `devServer.allowedHosts`, Rails
  `config.hosts`, Django `ALLOWED_HOSTS`. Allow `.bass-pirarucu.ts.net`.
- Prefer committing the allowlist to the repo (it only affects dev servers)
  over uncommitted local edits, which silently vanish in fresh clones and
  worktrees. If the repo can't take the commit, apply it locally and say so.
- Hand over the URL as `http://<this-host>.bass-pirarucu.ts.net:<port>`,
  never `localhost`. Felipe is on another device.

Check the installed framework version before applying a framework-specific
recipe. Verify the response using the tailnet hostname in the Host header,
not only a request to localhost.

Run processes that must outlive the session in a named tmux session or user
unit. For example:

```sh
tmux new -d -s <task-name> '<command>'
systemd-run --user --unit <task-name> <command>
```

Check that the process stays up and serves its intended response. Report the
URL, unit or session name, and stop command. Keep persistent work on rlyeh;
transient user units and tmux sessions need recreating after a reboot. Use a
persistent service declaration for tasks that must survive reboot.

If a process you started fails, inspect its logs and repair it within the
original task's scope. Don't ask Felipe to SSH in for work you can complete.
