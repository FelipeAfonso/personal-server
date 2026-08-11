{ pkgs, ... }:

let
  # Persistent install of the t3 CLI for the t3-serve service below.
  t3Dir = "/home/felipe/.local/share/t3-serve";
  t3Install = pkgs.writeShellScript "t3-install" ''
    set -euo pipefail
    export HOME=/home/felipe
    # node-pty's postinstall shells out to node-gyp/python3/cc; systemd units
    # don't get the system profile on PATH, so add it explicitly.
    export PATH=/run/current-system/sw/bin:$PATH
    mkdir -p ${t3Dir}
    cd ${t3Dir}
    [ -f package.json ] || echo '{ "name": "t3-serve", "private": true }' > package.json
    ${pkgs.bun}/bin/bun add t3@nightly
  '';
  # A previous failed install can leave the t3 bin present but node-pty
  # unbuilt — check for the native artifact, not just the entrypoint.
  t3Healthy = ''
    [ -x ${t3Dir}/node_modules/.bin/t3 ] \
      && { [ -d ${t3Dir}/node_modules/node-pty/prebuilds/linux-x64 ] \
        || [ -f ${t3Dir}/node_modules/node-pty/build/Release/pty.node ]; }
  '';
in
{
  environment.systemPackages = with pkgs; [
    claude-code
    codex
    opencode
  ];

  # Available for agents to self-isolate risky runs.
  virtualisation.docker.enable = true;

  # T3 Code headless server, reachable from other devices through the T3
  # Connect relay (authorized once via `bunx t3 connect`, credential lives in
  # ~felipe/.t3). Binds loopback only; the relay and the desktop app's SSH
  # port-forward are the ways in. Runs as a login shell so spawned agents see
  # the same PATH/env as an interactive session. The CLI is installed into a
  # persistent dir (not bunx's /tmp cache) and tracks the `nightly` dist-tag,
  # same channel as the desktop app; the update timer below keeps them close.
  systemd.services.t3-serve = {
    description = "T3 Code headless server";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      User = "felipe";
      Group = "users";
      WorkingDirectory = "/home/felipe/code";
      ExecStartPre = "${pkgs.writeShellScript "t3-ensure-installed" ''
        if ! { ${t3Healthy} }; then ${t3Install}; fi
      ''}";
      ExecStart = "${pkgs.zsh}/bin/zsh -l -c 'exec ${t3Dir}/node_modules/.bin/t3 serve --no-browser'";
      Restart = "always";
      RestartSec = 5;
    };
  };

  # Nightly publishes every few hours; re-resolve the tag on the same cadence
  # and bounce the server only on an actual version change. NOTE: a bounce
  # kills any provider sessions running at that moment.
  systemd.services.t3-serve-update = {
    description = "Update t3 to current nightly, restart t3-serve if changed";
    serviceConfig.Type = "oneshot";
    script = ''
      ver() { ${pkgs.nodejs}/bin/node -p 'require("${t3Dir}/node_modules/t3/package.json").version' 2>/dev/null || echo none; }
      before=$(ver)
      ${pkgs.util-linux}/bin/runuser -u felipe -- ${t3Install}
      after=$(ver)
      if [ "$before" != "$after" ]; then
        echo "t3 $before -> $after, restarting t3-serve"
        ${pkgs.systemd}/bin/systemctl restart t3-serve.service
      else
        echo "t3 $before is current"
      fi
    '';
  };
  systemd.timers.t3-serve-update = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnBootSec = "15min";
      OnUnitActiveSec = "1h";
      RandomizedDelaySec = "10min";
    };
  };
}
