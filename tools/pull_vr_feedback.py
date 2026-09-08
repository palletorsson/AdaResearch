#!/usr/bin/env python3
"""Pull the comments typed in the HEADSET back onto the PC.

WHY THIS EXISTS (2026-09-07). commons/bridge/feedback_writer.gd writes to
res://ada_run/desktop_feedback.md. On the desktop that is the working tree and
the write lands. In an exported build res:// is inside the .pck and is
READ-ONLY, so the write is refused and save() falls back to
user://desktop_feedback/desktop_feedback.md -- which on a Quest is
/data/data/<pkg>/files/desktop_feedback/, private to the device.

commons/bridge/vr_link.gd already said this in its header on 2026-08-31:
"every other bridge in this project (em_control.json, mapsim_control.json,
desktop_feedback.md) is a FILE poll that cannot cross to a headset at all --
user:// on the Quest is on the Quest."

Five days later the comment box shipped into Point_One -- the museum lobby, the
first room a visitor enters -- documented as "the comment lands in
ada_run/desktop_feedback.md, the file the Desktop-AI bridge already reads".
True on the desktop. In the headset, the surface the box was built for ("the
keys on the screen by laser in VR"), the comment goes to the device and no tool
in this repo has ever read it back.

So every reader of that file is blind to VR:
  - .claude/skills/ada-bridge-listener      (the whole Desktop <-> AI bridge)
  - tools/sequence_pipeline_scorer.py       stage 6, VR TESTING

Stage 6 is the head of 21 of 22 spine sequences and has read 0% for months.
It is not merely human-gated. It is unreachable from the headset: the human can
walk every map, type a comment in the lobby, and the metric still reads 0.

This tool is the wire. It does not change the game. It is additive and
idempotent -- a block already present locally, matched on its `## <ts> | <Map>`
header, is never appended twice -- so it is safe to run on a schedule.

    python tools/pull_vr_feedback.py             # pull, merge, report
    python tools/pull_vr_feedback.py --dry-run   # say what it would append
    python tools/pull_vr_feedback.py --package=com.example.adaresearchzeroone

Exit codes: 0 pulled (or nothing to pull), 2 no device / no adb, 3 refused.
"""

from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
LOCAL_MD = ROOT / "ada_run" / "desktop_feedback.md"
LOCAL_JSON = ROOT / "ada_run" / "desktop_feedback.json"

# FeedbackWriter.FALLBACK_DIR is "user://desktop_feedback"; user:// on Android is
# the app's files/ dir. Keep these two facts adjacent so a rename is caught here.
REMOTE_DIR = "files/desktop_feedback"
REMOTE_MD = REMOTE_DIR + "/desktop_feedback.md"
REMOTE_JSON = REMOTE_DIR + "/desktop_feedback.json"

# The desktop build writes res:// directly and needs no pulling. These are the
# Quest packages that have ever carried this game.
DEFAULT_PACKAGES = [
    "com.example.adaresearchzeroone",
    "com.example.adaresearchzero",
]

ADB_CANDIDATES = [
    r"C:\Users\palle\AppData\Local\Android\Sdk\platform-tools\adb.exe",
]


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
        proc = subprocess.run(
            [adb_path] + args,
            capture_output=True, text=True, timeout=timeout,
            encoding="utf-8", errors="replace",
        )
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


REFUSALS = ("no such file", "not debuggable", "unknown package", "permission denied")


def remote_read(adb_path: str, base: list[str], package: str, remote_path: str) -> str | None:
    """The file's text, or None when it is not there / not readable.

    run-as is the same trick tools/push_map_to_quest.ps1 uses: it runs as the
    app's own uid, which is the only way into a private files/ dir on a
    non-rooted device.
    """
    code, out = adb(adb_path, base + ["shell", "run-as", package, "cat", remote_path])
    if code != 0:
        return None
    lowered = out.lower()
    if any(bad in lowered for bad in REFUSALS):
        return None
    return out


def blocks_of(text: str) -> list[str]:
    """The entries in a feedback file, each the raw text after its `## ` header.

    Mirrors FeedbackWriter.read_blocks (commons/bridge/feedback_writer.gd) so
    the two implementations agree on what one entry is.
    """
    if not text:
        return []
    parts = text.replace("\r\n", "\n").split("\n## ")
    return [p for p in parts[1:]]


def header_of(block: str) -> str:
    return block.split("\n", 1)[0].strip()


def merge_markdown(local_text: str, remote_text: str) -> tuple[str, list[str]]:
    """Return (new local text, headers appended)."""
    have = {header_of(b) for b in blocks_of(local_text)}
    appended: list[str] = []
    out = local_text.replace("\r\n", "\n")
    for block in blocks_of(remote_text):
        head = header_of(block)
        if head in have:
            continue
        have.add(head)
        appended.append(head)
        if out and not out.endswith("\n"):
            out += "\n"
        out += "\n## " + block.rstrip("\n") + "\n"
    return out, appended


def merge_json(local_raw: str, remote_raw: str) -> tuple[str, int]:
    """Union the two entry lists on (timestamp, comment). Best effort."""
    def load(raw: str) -> list:
        try:
            data = json.loads(raw) if raw.strip() else {}
        except Exception:
            return []
        if isinstance(data, list):
            return data
        if isinstance(data, dict):
            entries = data.get("entries", [])
            return entries if isinstance(entries, list) else []
        return []

    local = load(local_raw)
    seen = {(str(e.get("timestamp")), str(e.get("comment"))) for e in local if isinstance(e, dict)}
    added = 0
    for entry in load(remote_raw):
        if not isinstance(entry, dict):
            continue
        key = (str(entry.get("timestamp")), str(entry.get("comment")))
        if key in seen:
            continue
        seen.add(key)
        local.append(entry)
        added += 1
    return json.dumps({"entries": local}, indent="\t", ensure_ascii=False), added


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.split("\n")[0])
    ap.add_argument("--package", action="append", default=None,
                    help="Quest package to read (repeatable). Default: the known Ada packages.")
    ap.add_argument("--dry-run", action="store_true",
                    help="Say what would be appended; write nothing.")
    ap.add_argument("--serial", default=None, help="adb device serial, when several are attached.")
    args = ap.parse_args()

    adb_path = find_adb()
    if not adb_path:
        print("adb not found on PATH or at the known SDK location.")
        print("  The headset is the only place these comments live. Without adb they stay there.")
        return 2

    serials = devices(adb_path)
    if not serials:
        print("no device attached (adb devices is empty).")
        print("  Plug the Quest in over USB and allow the debugging prompt in the headset.")
        return 2
    serial = args.serial or serials[0]
    base = ["-s", serial]

    packages = args.package or DEFAULT_PACKAGES

    total_md = 0
    total_json = 0
    looked = []
    for package in packages:
        remote_md = remote_read(adb_path, base, package, REMOTE_MD)
        looked.append(package)
        if remote_md is None:
            continue

        local_text = LOCAL_MD.read_text(encoding="utf-8") if LOCAL_MD.exists() else ""
        merged, appended = merge_markdown(local_text, remote_md)
        if appended:
            print("%s -- %d new comment(s):" % (package, len(appended)))
            for head in appended:
                print("    ## " + head)
            if not args.dry_run:
                LOCAL_MD.parent.mkdir(parents=True, exist_ok=True)
                LOCAL_MD.write_text(merged, encoding="utf-8")
            total_md += len(appended)
        else:
            print("%s -- feedback file present on the device, nothing new in it." % package)

        remote_json = remote_read(adb_path, base, package, REMOTE_JSON)
        if remote_json is not None:
            local_raw = LOCAL_JSON.read_text(encoding="utf-8") if LOCAL_JSON.exists() else ""
            merged_json, added = merge_json(local_raw, remote_json)
            if added and not args.dry_run:
                LOCAL_JSON.write_text(merged_json, encoding="utf-8")
            total_json += added

    if total_md == 0:
        print("nothing to pull.")
        print("  Looked in %s of: %s" % (REMOTE_DIR, ", ".join(looked)))
        print("  An absent directory means SEND has not been pressed in the headset yet --")
        print("  not that the wire is broken. Press SEND on the comment box in Point_One")
        print("  (the museum lobby) and run this again to prove the round trip.")
    else:
        where = "would append" if args.dry_run else "appended"
        print("%s %d comment(s) to %s" % (where, total_md, LOCAL_MD.relative_to(ROOT)))
        if total_json:
            print("  and %d entr(ies) to %s" % (total_json, LOCAL_JSON.relative_to(ROOT)))
        print("  tools/sequence_pipeline_scorer.py stage 6 and the ada-bridge-listener")
        print("  skill read that file. They can see the headset now.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
