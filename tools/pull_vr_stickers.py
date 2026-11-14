#!/usr/bin/env python3
"""Pull the stickers stuck and peeled in the HEADSET back into the truth.

WHY THIS EXISTS (2026-11-13). The game's sticker pad (commons/stickers/sticker_pad.gd) makes every stick and peel an
op, writes it to an OUTBOX and posts it to the encyclopedia's /api/stickers/ops (commons/stickers/sticker_data.gd).
On a desktop the POST reaches http://127.0.0.1:3003 and the truth (commons/data/stickers/placements.json) has the
op within a second. On a standalone Quest it cannot: user:// is the app's private files/ folder, and the link tunnels
only 8771/8772 (tools/vr_link.py setup_reverse), not 3003. The ops wait in

    /data/data/<pkg>/files/stickers/outbox.json   {version, device, pending: [{by, t, op}], sent: [...], refused: [...]}

until something carries them. This tool is that wire, as tools/pull_vr_feedback.py is for the comment box: it reads
the outbox with `adb shell run-as <pkg> cat` (a DEBUGGABLE export only), posts its ops to the route with the `by` each
op carries, and reports what the server said. It changes nothing on the device.

Ops are idempotent by op_id (the server remembers the ids it applied), so pulling twice, or pulling after a live
session that already posted, doubles nothing: those ops come back `skipped`. `pending` and `sent` are both posted
(`sent` was acknowledged by SOME server, perhaps another one); `refused` is never posted again.

    python tools/pull_vr_stickers.py                 # pull every known package, post, report
    python tools/pull_vr_stickers.py --dry-run       # say what would be posted; post nothing
    python tools/pull_vr_stickers.py --from-file ada_run/stickers/outbox_copy.json --dry-run   # a local copy, no adb
    python tools/pull_vr_stickers.py --url http://127.0.0.1:3003 --package=com.example.adaresearchzeroone

Exit codes: 0 posted (or nothing to post), 2 no device / no adb, 3 refused (no package could be read),
4 the route could not be reached or answered an error (the outbox on the device is untouched: run again).
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
PULLED = ROOT / "ada_run" / "stickers" / "pulled"

# StickerData.OUTBOX is "user://stickers/outbox.json"; user:// on Android is the app's files/ dir. Keep these two facts
# adjacent so a rename is caught here.
REMOTE_OUTBOX = "files/stickers/outbox.json"

DEFAULT_PACKAGES = [
    "com.example.adaresearchzeroone",
    "com.example.adaresearchzero",
]

ADB_CANDIDATES = [
    r"C:\Users\palle\AppData\Local\Android\Sdk\platform-tools\adb.exe",
]

ROUTE = "/api/stickers/ops"
MAX_BATCH = 200          # the route takes 400; the game posts 200
REFUSALS = ("no such file", "not debuggable", "unknown package", "permission denied")


def find_adb() -> str | None:
    found = shutil.which("adb")
    if found:
        return found
    for candidate in ADB_CANDIDATES:
        if os.path.exists(candidate):
            return candidate
    return None


def adb(adb_path: str, args: list[str], timeout: int = 60) -> tuple[int, str]:
    """Run adb and return (returncode, stdout+stderr as text)."""
    try:
        proc = subprocess.run([adb_path] + args, capture_output=True, text=True, timeout=timeout,
                              encoding="utf-8", errors="replace")
    except subprocess.TimeoutExpired:
        return 124, "adb timed out after %ds" % timeout
    return proc.returncode, (proc.stdout or "") + (proc.stderr or "")


def devices(adb_path: str) -> list[str]:
    _, out = adb(adb_path, ["devices"])
    serials = []
    for line in out.splitlines()[1:]:
        parts = line.split()
        if len(parts) >= 2 and parts[1] == "device":
            serials.append(parts[0])
    return serials


def remote_read(adb_path: str, base: list[str], package: str, remote_path: str) -> str | None:
    """The file's text, or None when it is not there or not readable (run-as runs as the app's own uid)."""
    code, out = adb(adb_path, base + ["shell", "run-as", package, "cat", remote_path])
    if code != 0:
        return None
    if any(bad in out.lower() for bad in REFUSALS):
        return None
    return out


def why_absent(adb_path: str, base: list[str], package: str) -> str:
    """Why remote_read returned None for this package, in one phrase (tools/pull_vr_feedback.py why_absent)."""
    code, out = adb(adb_path, base + ["shell", "run-as", package, "ls", "files"])
    lowered = out.lower()
    if "unknown package" in lowered or "is unknown" in lowered:
        return "not installed"
    if "not debuggable" in lowered:
        return "REFUSED: not debuggable, run-as cannot read it (a release export?)"
    if code != 0 or "permission denied" in lowered:
        return "REFUSED: run-as failed (%s)" % (out.strip().splitlines() or ["no output"])[0][:80]
    if "stickers" not in out.split():
        return "readable, no stickers/ yet -- nothing stuck or peeled on this install"
    return "readable, stickers/ present but outbox.json missing"


def read_outbox(text: str) -> tuple[dict | None, str]:
    """The outbox as a dict with lists pending / sent / refused of {by, t, op}, or (None, why)."""
    try:
        data = json.loads(text)
    except ValueError as e:
        return None, "not JSON (%s)" % e
    if not isinstance(data, dict):
        return None, "not an object"
    # an outbox written for a TEST SANDBOX (sticker_data.gd stamps it) is a test's journal, never the headset's: its
    # ops belong to that sandbox's copy and must not reach the truth through this route
    if str(data.get("sandbox", "") or ""):
        return None, "written for test sandbox '%s', not posted" % str(data.get("sandbox"))[:48]
    out = {"device": str(data.get("device", "")), "pending": [], "sent": [], "refused": []}
    for key in ("pending", "sent", "refused"):
        for entry in data.get(key, []) if isinstance(data.get(key), list) else []:
            if isinstance(entry, dict) and isinstance(entry.get("op"), dict) and isinstance(entry["op"].get("op_id"), str):
                out[key].append(entry)
    return out, ""


def batches(entries: list[dict], fallback_by: str) -> list[tuple[str, list[dict]]]:
    """Consecutive ops with the same `by` (the route takes one `by` per request: a peel records it), at most MAX_BATCH."""
    out: list[tuple[str, list[dict]]] = []
    for entry in entries:
        by = str(entry.get("by") or fallback_by or "someone")[:60]
        if out and out[-1][0] == by and len(out[-1][1]) < MAX_BATCH:
            out[-1][1].append(entry["op"])
        else:
            out.append((by, [entry["op"]]))
    return out


def describe(op: dict) -> str:
    kind = op.get("op", "?")
    if kind == "add":
        s = op.get("sticker", {}) if isinstance(op.get("sticker"), dict) else {}
        host = s.get("host", {}) if isinstance(s.get("host"), dict) else {}
        where = "/".join(str(host.get(k)) for k in ("kind", "id", "floor", "work", "token") if host.get(k) is not None)
        return "add %s (%s) on %s" % (s.get("id", "?"), s.get("design", "?"), where or "?")
    return "%s %s" % (kind, op.get("id", "?"))


def post(url: str, by: str, ops: list[dict], timeout: float = 30.0) -> tuple[int, dict]:
    """POST {by, ops}; (HTTP status, answer as a dict). Status 0: not reached. No Origin header: the route lets it in."""
    body = json.dumps({"by": by, "ops": ops}).encode("utf-8")
    req = urllib.request.Request(url, data=body, method="POST", headers={"Content-Type": "application/json"})
    try:
        with urllib.request.urlopen(req, timeout=timeout) as r:
            return r.status, json.loads(r.read().decode("utf-8") or "{}")
    except urllib.error.HTTPError as e:
        try:
            return e.code, json.loads(e.read().decode("utf-8") or "{}")
        except ValueError:
            return e.code, {"error": "HTTP %d" % e.code}
    except (urllib.error.URLError, OSError, ValueError) as e:
        return 0, {"error": str(e)}


def carry(label: str, outbox: dict, url: str, dry_run: bool) -> int:
    """Post one outbox's sent and pending ops, oldest first (sent were answered before anything still pending was made;
    StickerData applies them in that order too). Returns 0, or 4 when the route failed."""
    entries = outbox["sent"] + outbox["pending"]
    print("%s -- device %s: %d pending, %d sent (posted again: idempotent), %d refused (not posted)"
          % (label, outbox["device"] or "?", len(outbox["pending"]), len(outbox["sent"]), len(outbox["refused"])))
    if not entries:
        print("    nothing to post.")
        return 0
    worst = 0
    for by, ops in batches(entries, outbox["device"]):
        if dry_run:
            print("    would POST %d op(s) by %s to %s" % (len(ops), by, url))
            for op in ops:
                print("      %s  %s" % (op.get("op_id", "?"), describe(op)))
            continue
        status, answer = post(url, by, ops)
        if status != 200 or not isinstance(answer.get("results"), list):
            print("    NOT POSTED (%s): %s" % ("not reached" if status == 0 else "HTTP %d" % status, answer.get("error", answer)))
            worst = 4
            continue
        applied = sum(1 for r in answer["results"] if r.get("ok") and not r.get("skipped"))
        skipped = sum(1 for r in answer["results"] if r.get("ok") and r.get("skipped"))
        refused = [r for r in answer["results"] if not r.get("ok")]
        print("    POSTED %d op(s) by %s: %d applied, %d already there (skipped), %d refused; placements revision %s"
              % (len(ops), by, applied, skipped, len(refused), answer.get("revision")))
        for r in refused:
            print("      refused %s: %s" % (r.get("op_id"), r.get("error")))
    return worst


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--package", action="append", default=None, help="Quest package to read (repeatable). Default: the known Ada packages.")
    ap.add_argument("--serial", default=None, help="adb device serial, when several are attached.")
    ap.add_argument("--url", default=None, help="the encyclopedia (default VOID_EDITOR_URL, else http://127.0.0.1:3003)")
    ap.add_argument("--from-file", default=None, help="read this outbox.json instead of a device (a copy, or a test)")
    ap.add_argument("--dry-run", action="store_true", help="say what would be posted; post nothing, keep nothing")
    args = ap.parse_args()

    base_url = (args.url or os.environ.get("VOID_EDITOR_URL") or "http://127.0.0.1:3003").rstrip("/")
    url = base_url + ROUTE

    if args.from_file:
        path = Path(args.from_file)
        if not path.exists():
            print("no such file: %s" % path)
            return 2
        outbox, why = read_outbox(path.read_text(encoding="utf-8", errors="replace"))
        if outbox is None:
            print("%s does not read as an outbox: %s" % (path, why))
            return 3
        return carry(str(path), outbox, url, args.dry_run)

    adb_path = find_adb()
    if not adb_path:
        print("adb not found on PATH or at the known SDK location.")
        print("  A headset's stickers live on the headset. Without adb they stay there.")
        return 2
    serials = devices(adb_path)
    if not serials:
        print("no device attached (adb devices is empty).")
        print("  Plug the Quest in over USB and allow the debugging prompt in the headset.")
        return 2
    base = ["-s", args.serial or serials[0]]

    looked: list[str] = []
    read_any = False
    worst = 0
    for package in args.package or DEFAULT_PACKAGES:
        text = remote_read(adb_path, base, package, REMOTE_OUTBOX)
        if text is None:
            looked.append("%s (%s)" % (package, why_absent(adb_path, base, package)))
            continue
        read_any = True
        outbox, why = read_outbox(text)
        if outbox is None:
            looked.append("%s (outbox present but %s)" % (package, why))
            continue
        looked.append(package)
        if not args.dry_run:   # the copy read, for the record (ada_run is derived and ignored)
            PULLED.mkdir(parents=True, exist_ok=True)
            (PULLED / ("%s-%s.json" % (package, time.strftime("%Y%m%dT%H%M%S")))).write_text(text, encoding="utf-8")
        worst = max(worst, carry(package, outbox, url, args.dry_run))

    print("looked in %s of:" % REMOTE_OUTBOX)
    for entry in looked:
        print("    " + entry)
    if not read_any:
        if any("REFUSED" in entry for entry in looked):
            print("  A REFUSED package was never read: its stickers may be there. Export it debuggable (or pass")
            print("  --package for a debuggable install) before trusting this.")
            return 3
        print("  No readable install has stuck or peeled anything yet -- the wire is not broken.")
    return worst


if __name__ == "__main__":
    sys.exit(main())
