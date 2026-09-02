# Scheduled off-site copies of hosted databases, pulled onto rlyeh.
#
# niterra-app (Turso): every 4h, GET the database's /dump endpoint (the same
# SQL text `turso db shell .dump` produces), check it loads into a scratch
# sqlite, gzip it into ~felipe/backups/turso/niterra-app/, then drop copies
# older than a week. Pruning only runs after a successful dump, so a broken
# token or a Turso outage never shrinks the set that's already on disk.
#
# Restore: zcat niterra-app-<stamp>.sql.gz | sqlite3 restored.db
# Logs:    journalctl -u turso-backup-niterra-app
# Run now: sudo systemctl start turso-backup-niterra-app
{ config, pkgs, ... }:

let
  dbHost = "niterra-app-felipeafonso.aws-us-east-1.turso.io";
  backupDir = "/home/felipe/backups/turso/niterra-app";
  keepDays = 7;

  backup = pkgs.writeShellApplication {
    name = "turso-backup-niterra-app";
    runtimeInputs = with pkgs; [ curl gzip sqlite coreutils findutils gnugrep gnused ];
    text = ''
      dir=${backupDir}
      stamp=$(date -u +%Y%m%dT%H%MZ)
      out="$dir/niterra-app-$stamp.sql.gz"
      mkdir -p "$dir"
      work=$(mktemp -d -p "$dir" .partial.XXXXXX)
      trap 'rm -rf "$work"' EXIT

      # Token comes in via systemd LoadCredential; hand it to curl through a
      # config file on stdin so it never shows up in argv.
      #
      # --compressed matters: Turso closes the /dump stream after roughly
      # three minutes, and uncompressed the 16 MB dump only got 10 MB through
      # before the cut. Gzipped on the wire it finishes in about a minute.
      # If the database outgrows that window the sqlite check below fails
      # the run instead of keeping a truncated file.
      printf 'header = "Authorization: Bearer %s"\n' "$(cat "$CREDENTIALS_DIRECTORY/token")" \
        | curl --config - --fail --silent --show-error --location --compressed \
            --retry 3 --retry-all-errors --max-time 1500 \
            --output "$work/dump.sql" "https://${dbHost}/dump"

      if ! grep -q '^CREATE TABLE' "$work/dump.sql"; then
        echo "dump has no CREATE TABLE statements, refusing to keep it" >&2
        head -c 500 "$work/dump.sql" >&2
        exit 1
      fi
      tables=$(sqlite3 -bail :memory: ".read $work/dump.sql" \
        "select count(*) from sqlite_master where type = 'table'")

      gzip -9 -c "$work/dump.sql" > "$work/dump.sql.gz"
      mv "$work/dump.sql.gz" "$out"
      ln -sfn "$(basename "$out")" "$dir/latest.sql.gz"
      rm -f "$dir/LAST-RUN-FAILED"
      echo "wrote $out ($(stat -c %s "$out") bytes gz, $tables tables)"

      find "$dir" -maxdepth 1 -name 'niterra-app-*.sql.gz' \
        -mmin +$((${toString keepDays} * 24 * 60)) -print -delete | sed 's/^/pruned /'
    '';
  };
in
{
  sops.secrets.turso-niterra-app-token = { };

  systemd.services.turso-backup-niterra-app = {
    description = "Dump the niterra-app Turso database to ${backupDir}";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    onFailure = [ "turso-backup-niterra-app-failed.service" ];
    serviceConfig = {
      Type = "oneshot";
      User = "felipe";
      Group = "users";
      LoadCredential = "token:${config.sops.secrets.turso-niterra-app-token.path}";
      ExecStart = "${backup}/bin/turso-backup-niterra-app";
      TimeoutStartSec = "30min";
      Nice = 10;
    };
  };

  # Nobody reads journalctl on a headless box, so a failed run leaves a
  # marker next to the backups where it'll be seen. The next good run
  # removes it.
  systemd.services.turso-backup-niterra-app-failed = {
    description = "Leave a failure marker in ${backupDir}";
    serviceConfig = {
      Type = "oneshot";
      User = "felipe";
      Group = "users";
    };
    script = ''
      mkdir -p ${backupDir}
      printf 'turso-backup-niterra-app failed at %s\nsee: journalctl -u turso-backup-niterra-app\n' \
        "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > ${backupDir}/LAST-RUN-FAILED
    '';
  };

  systemd.timers.turso-backup-niterra-app = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "00/4:00"; # 00:00, 04:00, ... local time
      Persistent = true; # catch up a run missed while the box was off
      RandomizedDelaySec = "5min";
    };
  };
}
