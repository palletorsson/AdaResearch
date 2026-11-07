"""Measure what you can stand on, floor by floor, in the built Void tower (2026-11-07).

Runs tools/probes/void_floor_occupancy.gd in the real game and writes
commons/data/void_floor_occupancy.json (DERIVED, tracked): per floor an 84 x 36 grid of 0.5 m cells, run-length
coded, each cell the height in cm of the first surface a ray meets (0 = bare slab), 254 = too high to stand
(furniture, a table, a raised work), 255 = nothing (a shaft). Each floor carries the sha1 of its rooms.json record,
so tools/artifact_timeline.py can tell a measurement from a stale one.

A floor that hangs the game (the watchdog kills it after 120 s of silence) is recorded as unmeasured and the run
goes on from the next floor. tools/artifact_timeline.py uses the measurement where it is fresh and falls back to
its footprint model elsewhere.

    python tools/measure_void_occupancy.py                 # every floor whose measurement is missing or stale
    python tools/measure_void_occupancy.py --all           # every floor
    python tools/measure_void_occupancy.py --floors=1,39
"""
from __future__ import annotations

import hashlib
import json
import os
import subprocess
import sys
from datetime import datetime, timezone
from pathlib import Path

from void_trial_runtime import stage_runtime

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "commons/data/void_floor_occupancy.json"
WORK = ROOT / "ada_run/void-occupancy"
GODOT = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")


def floor_hash(record: dict) -> str:
    return hashlib.sha1(json.dumps(record, sort_keys=True, ensure_ascii=False).encode("utf-8")).hexdigest()[:16]


def load() -> dict:
    try:
        return json.loads(OUT.read_text(encoding="utf-8"))
    except (OSError, ValueError):
        return {"floors": {}}


def write(doc: dict) -> None:
    lines = ["{", f'  "_doc": {json.dumps(doc["_doc"])},', f'  "measured_at": {json.dumps(doc["measured_at"])},',
             f'  "unmeasured": {json.dumps(doc.get("unmeasured", []))},', '  "floors": {']
    keys = sorted(doc["floors"], key=int)
    for i, k in enumerate(keys):
        lines.append(f"    {json.dumps(k)}: {json.dumps(doc['floors'][k], separators=(',', ':'))}" + ("," if i < len(keys) - 1 else ""))
    lines += ["  }", "}"]
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8", newline="\n")


def main() -> int:
    sys.stdout.reconfigure(encoding="utf8")
    rooms = json.loads((ROOT / "commons/void/rooms.json").read_text(encoding="utf-8"))["floors"]
    hashes = {str(i): floor_hash(f) for i, f in enumerate(rooms)}
    doc = load()
    asked = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--floors=")), "")
    if asked:
        todo = [int(x) for x in asked.split(",") if x.strip()]
    elif "--all" in sys.argv:
        todo = list(range(len(rooms)))
    else:
        todo = [i for i in range(len(rooms)) if doc["floors"].get(str(i), {}).get("hash") != hashes[str(i)]]
    print(f"measuring {len(todo)} floors")
    WORK.mkdir(parents=True, exist_ok=True)
    lines = WORK / "occupancy.jsonl"
    lines.unlink(missing_ok=True)
    stage = stage_runtime()
    unmeasured, left = [], list(todo)
    while left:
        log = WORK / "engine.log"
        with log.open("w", encoding="utf8") as stream:
            subprocess.run([sys.executable, str(ROOT / "tools/godot_watchdog.py"), "--expect=" + str(WORK), "--grace=300", "--stall=120", "--",
                            GODOT, "--path", str(stage), "--xr-mode", "off", "--resolution", "640x400", "--position", "3200,3200",
                            "--script", "res://tools/probes/void_floor_occupancy.gd", "--", "--out=" + lines.as_posix(),
                            "--floors=" + ",".join(map(str, left))],
                           stdout=stream, stderr=subprocess.STDOUT, timeout=7200, creationflags=subprocess.CREATE_NO_WINDOW)
        text = log.read_text(encoding="utf8", errors="replace")
        before = len(left)
        done = set()
        if lines.exists():
            for row in lines.read_text(encoding="utf8").splitlines():
                if row.strip():
                    r = json.loads(row)
                    done.add(r["floor"])
                    doc["floors"][str(r["floor"])] = {**{k: r[k] for k in ("nx", "nz", "x0", "z0", "step", "rle")}, "hash": hashes[str(r["floor"])]}
        started = [int(l.split()[-1]) for l in text.splitlines() if l.startswith("[occupancy] start")]
        hung = next((f for f in reversed(started) if f not in done), None)
        left = [f for f in left if f not in done]
        if hung is not None:
            print(f"floor {hung} did not finish - recorded as unmeasured")
            unmeasured.append(hung)
            left = [f for f in left if f != hung]
        elif left and len(left) == before:   # a crash after some floors: go on with the rest
            print("the game stopped before any floor was measured; log tail:\n" + text[-2000:])
            unmeasured += left
            break
        print(f"measured {len(done)} this pass, {len(left)} left")
    doc["_doc"] = ("DERIVED by tools/measure_void_occupancy.py in the built tower - never edit. Per floor an nx x nz grid of "
                   "step-m cells from (x0, z0), run-length coded [value, count, ...]: cm of the first surface a ray meets "
                   "(0 = slab), 254 = too high to stand, 255 = nothing. `hash` = sha1 of the floor's rooms.json record.")
    doc["measured_at"] = datetime.now(timezone.utc).isoformat(timespec="seconds")
    doc["unmeasured"] = sorted(set(doc.get("unmeasured", [])) - {int(k) for k in doc["floors"] if doc["floors"][k].get("hash") == hashes[k]} | set(unmeasured))
    write(doc)
    print(f"{OUT.relative_to(ROOT)}: {len(doc['floors'])} floors, unmeasured {doc['unmeasured']}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
