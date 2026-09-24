#!/usr/bin/env python3
"""Export a Turso/libsql database into a local sqlite file.

Turso's /dump endpoint closes the stream after a couple of minutes, which
truncates anything beyond a few tens of MB. This pulls the data through the
Hrana HTTP pipeline API instead, table by table, in pages small enough that
no single request runs long. Rows wider than CHUNK are fetched on their
own, big columns in substr() pieces, so a 14 MB document row still comes
through in short requests.

First try: one read transaction, held open with the baton the server hands
back, so every table comes from the same snapshot. Turso rolls that
transaction back if a request takes more than ~9 s (a slow page counts as
"idle"), so pages are sized by measured throughput. If the snapshot is lost
anyway, the export restarts without a transaction; tables then come from
slightly different moments, which is logged.

usage: turso-export.py <host> <out.sqlite>     token in $TURSO_TOKEN
"""

import base64
import gzip
import http.client
import json
import os
import sqlite3
import sys
import time

BUDGET = 128 * 1024  # bytes of row data per page until throughput is known
CHUNK = 256 * 1024  # rows wider than this are fetched alone, columns in pieces
TARGET = 2.5  # seconds per request to aim for; Turso drops the stream at ~9 s
MAX_PAGE = 2000
SKIP = ("sqlite_", "libsql_", "_litestream_")
CURRENT = {"table": "schema"}  # what the export is reading, for error messages


class StreamLost(Exception):
    """Turso forgot our transaction stream; the snapshot is gone."""


class Hrana:
    def __init__(self, host, token, stateful):
        self.host = host
        self.path = "/v2/pipeline"
        self.token = token
        self.stateful = stateful
        self.baton = None
        self.bytes = 0
        self.requests = 0
        self.conn = None
        self.latency = None  # fastest round trip seen, as the fixed cost per request

    def _post(self, payload):
        # One keep-alive connection for the whole export: a fresh TLS
        # handshake to us-east per request would dominate small pages.
        for attempt in range(2):
            if self.conn is None:
                self.conn = http.client.HTTPSConnection(self.host, timeout=600)
            try:
                self.conn.request(
                    "POST",
                    self.path,
                    body=payload,
                    headers={
                        "Authorization": f"Bearer {self.token}",
                        "Content-Type": "application/json",
                        "Accept-Encoding": "gzip",
                    },
                )
                r = self.conn.getresponse()
                raw = r.read()
                return r.status, r.getheader("Content-Encoding"), raw
            except (http.client.HTTPException, OSError):
                self.conn.close()
                self.conn = None
                if attempt:
                    raise
        raise AssertionError("unreachable")

    def run(self, *stmts):
        body = {"requests": [{"type": "execute", "stmt": s} for s in stmts]}
        if self.stateful:
            if self.baton:
                body["baton"] = self.baton
        else:
            body["requests"].append({"type": "close"})
        t0 = time.monotonic()
        status, encoding, raw = self._post(json.dumps(body).encode())
        took = time.monotonic() - t0
        self.requests += 1
        self.latency = took if self.latency is None else min(self.latency, took)
        if encoding == "gzip":
            raw = gzip.decompress(raw)
        if status != 200:
            text = raw[:500].decode(errors="replace")
            if status == 404 and "stream not found" in text:
                raise StreamLost(text)
            raise SystemExit(f"HTTP {status} from {self.host}{self.path}: {text}")
        resp = json.loads(raw)
        self.bytes += len(raw)
        self.baton = resp.get("baton")
        if resp.get("base_url"):
            base = resp["base_url"].rstrip("/")
            if base.startswith("https://"):
                base = base[len("https://"):]
            host, _, prefix = base.partition("/")
            if host != self.host:
                self.host = host
                if self.conn:
                    self.conn.close()
                    self.conn = None
            self.path = ("/" + prefix if prefix else "") + "/v2/pipeline"
        out = []
        for res in resp["results"]:
            if res["type"] != "ok":
                msg = str(res.get("error"))
                if "stream was idle" in msg or "stream not found" in msg:
                    raise StreamLost(msg)
                raise SystemExit(f"hrana error: {msg}")
            if res["response"]["type"] == "execute":
                out.append(res["response"]["result"])
        return out

    def query(self, sql, args=()):
        return self.run({"sql": sql, "args": [encode(a) for a in args]})[0]

    def close(self):
        if self.stateful:
            body = {"requests": [{"type": "close"}], "baton": self.baton}
            self._post(json.dumps(body).encode())
        if self.conn:
            self.conn.close()


def encode(v):
    if v is None:
        return {"type": "null"}
    if isinstance(v, int):
        return {"type": "integer", "value": str(v)}
    if isinstance(v, float):
        return {"type": "float", "value": v}
    if isinstance(v, bytes):
        return {"type": "blob", "base64": base64.b64encode(v).decode()}
    return {"type": "text", "value": v}


def decode(c):
    t = c["type"]
    if t == "null":
        return None
    if t == "integer":
        return int(c["value"])
    if t == "float":
        return float(c["value"])
    if t == "blob":
        s = c["base64"]
        return base64.b64decode(s + "=" * (-len(s) % 4))  # Hrana omits padding
    return c["value"]


def rows(result):
    return [[decode(c) for c in r] for r in result["rows"]]


def q(ident):
    return '"' + ident.replace('"', '""') + '"'


def log(msg):
    print(msg, file=sys.stderr, flush=True)


def main():
    host, out = sys.argv[1:3]
    token = os.environ["TURSO_TOKEN"]
    try:
        export(host, token, out, stateful=True)
        return
    except StreamLost as e:
        log(
            f"snapshot transaction lost while reading {CURRENT['table']} ({e}); "
            "exporting again without one, so tables may come from slightly "
            "different moments"
        )
    export(host, token, out, stateful=False)


def fetch_wide_row(remote, name, cols, rid):
    """One row whose columns together exceed CHUNK: small columns in one
    go, big text/blob columns in substr() pieces."""
    meta = rows(
        remote.query(
            "select "
            + ", ".join(f"typeof({q(c)}), length({q(c)})" for c in cols)
            + f" from {q(name)} where rowid = ?",
            (rid,),
        )
    )[0]
    big = [
        i
        for i, c in enumerate(cols)
        if meta[2 * i] in ("text", "blob") and (meta[2 * i + 1] or 0) > CHUNK
    ]
    small = [c for i, c in enumerate(cols) if i not in big]
    values = {}
    if small:
        got = rows(
            remote.query(
                f"select {', '.join(q(c) for c in small)} from {q(name)} where rowid = ?",
                (rid,),
            )
        )[0]
        values.update(zip(small, got))
    for i in big:
        c, typ, length = cols[i], meta[2 * i], meta[2 * i + 1]
        parts = []
        for start in range(1, length + 1, CHUNK):
            parts.append(
                rows(
                    remote.query(
                        f"select substr({q(c)}, ?, ?) from {q(name)} where rowid = ?",
                        (start, CHUNK, rid),
                    )
                )[0][0]
            )
        values[c] = "".join(parts) if typ == "text" else b"".join(parts)
    return [values[c] for c in cols]


def export(host, token, out, stateful):
    if os.path.exists(out):
        os.remove(out)
    started_at = time.monotonic()

    remote = Hrana(host, token, stateful)
    if stateful:
        # BEGIN alone doesn't pin a snapshot in SQLite; the first read does.
        # Both go in one request so nothing can slip in between.
        remote.run({"sql": "BEGIN"}, {"sql": "SELECT 1"})

    schema = rows(
        remote.query(
            "select type, name, tbl_name, sql from sqlite_master "
            "where sql is not null order by rowid"
        )
    )
    schema = [s for s in schema if not s[1].startswith(SKIP)]
    for typ, name, _, sql in schema:
        if sql.upper().startswith("CREATE VIRTUAL"):
            raise SystemExit(f"virtual table {name} is not supported by this exporter")

    local = sqlite3.connect(out)
    local.execute("PRAGMA foreign_keys=OFF")
    local.execute("PRAGMA journal_mode=OFF")
    local.execute("PRAGMA synchronous=OFF")

    tables = [s for s in schema if s[0] == "table"]
    for _, name, _, sql in tables:
        local.execute(sql)

    total = 0
    for _, name, _, sql in tables:
        CURRENT["table"] = name
        cols = [r[1] for r in rows(remote.query(f"pragma table_info({q(name)})"))]
        insert = (
            f"insert into {q(name)} ({', '.join(q(c) for c in cols)}) "
            f"values ({', '.join('?' * len(cols))})"
        )
        width = "(" + " + ".join(f"coalesce(length({q(c)}), 0)" for c in cols) + ")"
        without_rowid = "WITHOUT ROWID" in sql.upper()
        # WITHOUT ROWID tables can't be keyset-paged or addressed by rowid, so
        # they get plain offset pages and no wide-row handling. None of ours
        # are, and .dump would need the same care.
        if without_rowid:
            wide = []
            narrow_filter = ""
        else:
            wide = [r[0] for r in rows(remote.query(f"select rowid from {q(name)} where {width} > ?", (CHUNK,)))]
            narrow_filter = f" and {width} <= {CHUNK}"

        expected, avg_bytes = rows(
            remote.query(
                f"select count(*), coalesce(avg({width}), 0) from {q(name)} "
                f"where 1=1{narrow_filter}"
            )
        )[0]
        page = max(1, min(MAX_PAGE, int(BUDGET // max(avg_bytes, 1))))
        copied = 0
        last = None
        offset = 0
        while True:
            used = page
            t0 = time.monotonic()
            if without_rowid:
                res = remote.query(f"select * from {q(name)} limit ? offset ?", (used, offset))
                offset += used
                data = rows(res)
            else:
                res = remote.query(
                    f"select rowid as __rid, * from {q(name)} where rowid > ?{narrow_filter} "
                    f"order by rowid limit ?",
                    (last if last is not None else -(1 << 63), used),
                )
                data = rows(res)
                if data:
                    last = data[-1][0]
                    data = [r[1:] for r in data]
            took = time.monotonic() - t0
            got = len(data)
            if not data:
                break
            local.executemany(insert, data)
            copied += got
            # Size the next page from this one's transfer time, net of the
            # fixed per-request latency, and never more than 4x at once.
            latency = min(remote.latency, took)
            transfer = max(took - latency, 0.05)
            want = int(used * max(TARGET - latency, 0.2) / transfer)
            page = max(1, min(MAX_PAGE, used * 4, want))
            if got < used:
                break
        if copied != expected:
            msg = f"{name}: copied {copied} rows, count said {expected}"
            if stateful:
                raise SystemExit(msg)
            log(msg + " (no snapshot; the table changed during the export)")

        for rid in wide:
            local.execute(insert, fetch_wide_row(remote, name, cols, rid))
        copied += len(wide)
        total += copied
        log(f"{name}: {copied} rows" + (f" ({len(wide)} wide)" if wide else ""))

    # Indexes, views and triggers go in after the data, like .dump does.
    for typ, name, _, sql in schema:
        if typ != "table":
            local.execute(sql)
    local.commit()
    local.close()
    if stateful:
        remote.run({"sql": "COMMIT"})
    remote.close()
    log(
        f"exported {len(tables)} tables, {total} rows, "
        f"{remote.bytes / 1e6:.1f} MB in {remote.requests} requests over "
        f"{time.monotonic() - started_at:.0f}s"
        + ("" if stateful else " (without snapshot)")
    )


if __name__ == "__main__":
    main()
