# Scheduled off-site copies of hosted databases, pulled onto rlyeh.
#
# Turso: on its schedule, each database below is copied into a local sqlite
# file (see backups/turso-export.py), written out as a .dump, gzipped into
# ~felipe/backups/turso/<name>/, and copies older than a week are dropped.
# Pruning only runs after a successful export, so a broken token or a
# Turso outage never shrinks the set that's already on disk.
#
# Every distinct schedule is one service + timer (turso-backups-<schedule>)
# that walks its databases one after another: exports that run side by
# side compete for bandwidth, and Turso drops a transaction stream whose
# request takes more than ~9 s.
#
# Each database has its own read-only, non-expiring token in the secrets
# repo (turso-<name>-token), minted with:
#   turso db tokens create <name> --expiration none --read-only
#
# Restore: zcat <name>-<stamp>.sql.gz | sqlite3 restored.db
# Logs:    journalctl -u 'turso-backups-*'
# Run now: sudo systemctl start turso-backups-every4h   (or -daily)
{ config, lib, pkgs, ... }:

let
  # systemd OnCalendar strings, local time. Daily sits between two runs of
  # the 4h group so the two never overlap.
  schedules = {
    every4h = "00/4:00";
    daily = "03:00";
  };
  databases = {
    niterra-app = {
      host = "niterra-app-felipeafonso.aws-us-east-1.turso.io";
      schedule = "every4h";
    };
    niterra-backend = {
      host = "niterra-backend-felipeafonso.aws-us-east-2.turso.io";
      schedule = "every4h";
    };
    # 43 MB gzipped per copy; a week of 4h copies would be 1.8 GB.
    df-dd-api = {
      host = "df-dd-api-felipeafonso.aws-us-east-2.turso.io";
      schedule = "daily";
    };
    crisalida = {
      host = "crisalida-felipeafonso.aws-us-east-1.turso.io";
      schedule = "every4h";
    };
  };
  backupRoot = "/home/felipe/backups/turso";
  keepDays = 7;

  # One database: export, dump, gzip, prune. Its own executable rather than
  # a shell function so `set -e` still applies when the loop below calls it
  # under `if`.
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
  # Usage: turso-backups <unit-name> <name> <host> [<name> <host>...]
  backupAll = pkgs.writeShellApplication {
    name = "turso-backups";
    runtimeInputs = with pkgs; [ coreutils ];
    text = ''
      unit=$1
      shift
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
          printf '%s export failed at %s\nsee: journalctl -u %s\n' \
            "$name" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "$unit" > ${backupRoot}/"$name"/LAST-RUN-FAILED
        fi
      done
      exit $failed
    '';
  };

  inGroup = key: lib.filterAttrs (_: db: db.schedule == key) databases;
  unitName = key: "turso-backups-${key}";
in
{
  assertions = [{
    assertion = lib.all (db: schedules ? ${db.schedule}) (lib.attrValues databases);
    message = "modules/backups.nix: every database's schedule must be a key of `schedules`";
  }];

  sops.secrets = lib.mapAttrs' (name: _: lib.nameValuePair "turso-${name}-token" { }) databases;

  systemd.services = lib.mapAttrs' (key: _:
    let
      dbs = inGroup key;
      args = lib.concatStringsSep " " (lib.mapAttrsToList (name: db: "${name} ${db.host}") dbs);
    in
    lib.nameValuePair (unitName key) {
      description = "Dump the ${key} Turso databases to ${backupRoot}";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      serviceConfig = {
        Type = "oneshot";
        User = "felipe";
        Group = "users";
        LoadCredential = lib.mapAttrsToList
          (name: _: "${name}:${config.sops.secrets."turso-${name}-token".path}")
          dbs;
        ExecStart = "${backupAll}/bin/turso-backups ${unitName key} ${args}";
        TimeoutStartSec = "2h";
        Nice = 10;
      };
    }) schedules;

  systemd.timers = lib.mapAttrs' (key: calendar:
    lib.nameValuePair (unitName key) {
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnCalendar = calendar;
        Persistent = true; # catch up a run missed while the box was off
        RandomizedDelaySec = "5min";
      };
    }) schedules;
}
