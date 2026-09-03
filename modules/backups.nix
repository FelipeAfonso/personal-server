# Scheduled off-site copies of hosted databases, pulled onto rlyeh.
#
# Turso: every 4h, each database below is copied into a local sqlite file
# (see backups/turso-export.py), written out as a .dump, gzipped into
# ~felipe/backups/turso/<name>/, and copies older than a week are dropped.
# Pruning only runs after a successful export, so a broken token or a
# Turso outage never shrinks the set that's already on disk.
#
# The databases go one after another in a single service: exports that
# run side by side compete for bandwidth, and Turso drops a transaction
# stream whose request takes more than ~9 s.
#
# Each database has its own read-only, non-expiring token in the secrets
# repo (turso-<name>-token), minted with:
#   turso db tokens create <name> --expiration none --read-only
#
# Restore: zcat <name>-<stamp>.sql.gz | sqlite3 restored.db
# Logs:    journalctl -u turso-backups
# Run now: sudo systemctl start turso-backups
{ config, lib, pkgs, ... }:

let
  databases = {
    niterra-app = "niterra-app-felipeafonso.aws-us-east-1.turso.io";
    niterra-backend = "niterra-backend-felipeafonso.aws-us-east-2.turso.io";
    df-dd-api = "df-dd-api-felipeafonso.aws-us-east-2.turso.io";
    crisalida = "crisalida-felipeafonso.aws-us-east-1.turso.io";
  };
  backupRoot = "/home/felipe/backups/turso";
  keepDays = 7;

  # One database: export, dump, gzip, prune. Its own executable rather than
  # a shell function so `set -e` still applies when the loop below calls it
  # under `||`.
  backupOne = pkgs.writeShellApplication {
    name = "turso-backup-one";
    runtimeInputs = with pkgs; [ python3 gzip sqlite coreutils findutils gnugrep gnused ];
    text = ''
      name=$1
      host=$2
      dir=${backupRoot}/$name
      stamp=$(date -u +%Y%m%dT%H%MZ)
      out="$dir/$name-$stamp.sql.gz"
      mkdir -p "$dir"
      work=$(mktemp -d -p "$dir" .partial.XXXXXX)
      trap 'rm -rf "$work"' EXIT

      # Token comes in via systemd LoadCredential and reaches the exporter
      # through its environment, never argv.
      TURSO_TOKEN=$(cat "$CREDENTIALS_DIRECTORY/$name") \
        python3 ${./backups/turso-export.py} "$host" "$work/db.sqlite"

      sqlite3 "$work/db.sqlite" .dump > "$work/dump.sql"
      if ! grep -q '^CREATE TABLE' "$work/dump.sql"; then
        echo "dump has no CREATE TABLE statements, refusing to keep it" >&2
        exit 1
      fi
      tables=$(sqlite3 "$work/db.sqlite" \
        "select count(*) from sqlite_master where type = 'table'")

      gzip -9 -c "$work/dump.sql" > "$work/dump.sql.gz"
      mv "$work/dump.sql.gz" "$out"
      ln -sfn "$(basename "$out")" "$dir/latest.sql.gz"
      echo "wrote $out ($(stat -c %s "$out") bytes gz, $tables tables)"

      find "$dir" -maxdepth 1 -name "$name-*.sql.gz" \
        -mmin +$((${toString keepDays} * 24 * 60)) -print -delete | sed 's/^/pruned /'
    '';
  };

  # Nobody reads journalctl on a headless box, so a failed export leaves a
  # LAST-RUN-FAILED marker next to that database's backups. The next good
  # export removes it. One database failing doesn't stop the others.
  backupAll = pkgs.writeShellApplication {
    name = "turso-backups";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      failed=0
      while [ $# -ge 2 ]; do
        name=$1
        host=$2
        shift 2
        if ${backupOne}/bin/turso-backup-one "$name" "$host"; then
          rm -f ${backupRoot}/"$name"/LAST-RUN-FAILED
        else
          failed=1
          mkdir -p ${backupRoot}/"$name"
          printf '%s export failed at %s\nsee: journalctl -u turso-backups\n' \
            "$name" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" > ${backupRoot}/"$name"/LAST-RUN-FAILED
        fi
      done
      exit $failed
    '';
  };

  args = lib.concatStringsSep " " (lib.mapAttrsToList (name: host: "${name} ${host}") databases);
in
{
  sops.secrets = lib.mapAttrs' (name: _: lib.nameValuePair "turso-${name}-token" { }) databases;

  systemd.services.turso-backups = {
    description = "Dump the Turso databases to ${backupRoot}";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    serviceConfig = {
      Type = "oneshot";
      User = "felipe";
      Group = "users";
      LoadCredential = lib.mapAttrsToList
        (name: _: "${name}:${config.sops.secrets."turso-${name}-token".path}")
        databases;
      ExecStart = "${backupAll}/bin/turso-backups ${args}";
      TimeoutStartSec = "2h";
      Nice = 10;
    };
  };

  systemd.timers.turso-backups = {
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "00/4:00"; # 00:00, 04:00, ... local time
      Persistent = true; # catch up a run missed while the box was off
      RandomizedDelaySec = "5min";
    };
  };
}
