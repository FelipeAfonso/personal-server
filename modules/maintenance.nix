{ pkgs, ... }:

let
  workspace = "/home/felipe/code/personal/personal-server-maintenance";
  settings = pkgs.writeText "rlyeh-maintenance.json" (builtins.toJSON {
    repository = "FelipeAfonso/personal-server";
    remote = "https://github.com/FelipeAfonso/personal-server.git";
    base = "main";
    branch = "maintenance/weekend-updates";
    inherit workspace;
    state = "/var/lib/rlyeh-maintenance";
    user = "felipe";
    codex = "/home/felipe/.bun/bin/codex";
    repairModel = "gpt-5.6-sol";
    reviewModel = "gpt-6-astra";
  });
  runner = pkgs.writeShellApplication {
    name = "rlyeh-maintenance";
    runtimeInputs = with pkgs; [ python3 git gh nix systemd util-linux openssh cacert iproute2 nodejs coreutils ];
    text = ''
      exec python3 ${./maintenance/runner.py} --config ${settings} "$@"
    '';
  };
in
{
  environment.systemPackages = [ runner ];
  systemd.tmpfiles.rules = [
    "d ${workspace} 0700 felipe users -"
  ];
  systemd.services.rlyeh-maintenance = {
    description = "Agent-reviewed weekend system updates";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    restartIfChanged = false;
    stopIfChanged = false;
    # Keep the trusted runner in the store. Agent subprocesses run as Felipe
    # in separate systemd sandboxes and never perform privileged activation.
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${runner}/bin/rlyeh-maintenance";
      StateDirectory = "rlyeh-maintenance";
      StateDirectoryMode = "0700";
      TimeoutStartSec = "3h50min";
      KillMode = "control-group";
      Nice = 10;
      IOSchedulingClass = "idle";
      UMask = "0077";
    };
  };
  systemd.timers.rlyeh-maintenance = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "Sun *-*-* 02:00:00 America/Sao_Paulo";
      # A missed Sunday must not trigger maintenance during a weekday boot.
      Persistent = false;
      AccuracySec = "1min";
    };
  };
}
