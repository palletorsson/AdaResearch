"""One floor of every sequence, played on the desktop in the real tower (2026-11-07, Palle: "test one map in each
sequence in desktop because i only tested the beginning").

Each floor runs in its own game, opened the way tools/launch_void_desktop.py opens it (gl_compatibility, --xr-mode off,
--void-start-floor), driven by tools/probes/sample_void_desktop.gd: wait for the floor's works, stand 3 s, walk forward
2.5 s, two photographs. A floor FAILS on a script error, a hang or crash, works that never built, a death, falling
through, or a body that cannot move. Output: ada_run/sequence-sample/<floor>/ + report.json.

    python tools/test_sequence_sample_desktop.py               # the middle floor of each sequence in spine.json
    python tools/test_sequence_sample_desktop.py --floors=6,17 --jobs=3
"""
from __future__ import annotations

import json
import os
import re
import subprocess
import sys
from concurrent.futures import ThreadPoolExecutor
from pathlib import Path

from void_trial_runtime import stage_runtime

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "ada_run/sequence-sample"
GODOT = os.environ.get("GODOT_EXE", "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
ERR = re.compile(r"SCRIPT ERROR|Parse Error|Invalid call|Invalid access|Cannot call method|Nonexistent function|null instance")


def targets() -> list[tuple[str, int]]:
    spine = json.loads((ROOT / "commons/void/spine.json").read_text(encoding="utf-8"))
    asked = next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--floors=")), "")
    seq_of = {f["floor"]: f["sequence"] for f in spine["floors"]}
    if asked:
        return [(seq_of.get(int(x), "?"), int(x)) for x in asked.split(",") if x.strip()]
    return [(q["id"], q["floors"][len(q["floors"]) // 2]) for q in spine["sequences"] if q["floors"]]


def run(stage: Path, seq: str, floor: int, slot: int) -> dict:
    out = OUT / f"{floor:03d}"
    out.mkdir(parents=True, exist_ok=True)
    for stale in ("sample.json", "stand.png", "walk.png", "godot.log"):
        (out / stale).unlink(missing_ok=True)
    with (out / "engine.log").open("w", encoding="utf8") as stream:
        code = subprocess.run([sys.executable, str(ROOT / "tools/godot_watchdog.py"), "--expect=" + str(out / "sample.json"),
                               "--grace=240", "--stall=120", "--",
                               GODOT, "--log-file", str(out / "godot.log"), "--windowed", "--position", f"{3200 + slot * 40},3200",
                               "--resolution", "1280x800", "--rendering-method", "gl_compatibility", "--xr-mode", "off",
                               "--path", str(stage), "--script", "res://tools/probes/sample_void_desktop.gd", "--", "--no-bridges",
                               f"--void-start-floor={floor}", "--play-output=" + out.as_posix()],
                              stdout=stream, stderr=subprocess.STDOUT, timeout=900, creationflags=subprocess.CREATE_NO_WINDOW).returncode
    text = (out / "engine.log").read_text(encoding="utf8", errors="replace")
    if (out / "godot.log").exists():
        text += (out / "godot.log").read_text(encoding="utf8", errors="replace")
    errors = sorted({l.strip()[:220] for l in text.splitlines() if ERR.search(l)})
    row = {"sequence": seq, "floor": floor, "exit": code, "errors": errors}
    try:
        row.update(json.loads((out / "sample.json").read_text(encoding="utf8")))
    except (OSError, ValueError):
        row["problems"] = ["did not report (hang or crash), exit %d" % code]
        return row
    problems = []
    if errors:
        problems.append("%d script error line(s)" % len(errors))
    if not row["built"]:
        problems.append("works never built: " + ", ".join(row["missing"][:6]))
    if row["deaths"]:
        problems.append("died: " + ", ".join(map(str, row["deaths"])))
    if row["fell_m"] > 1.0 or row["walked"][1] < -1.0:
        problems.append("fell %.1f m" % max(row["fell_m"], -row["walked"][1]))
    ways = row.get("other_ways") or {}
    if row["walk_m"] < 0.5 and not any(v > 0.5 for v in ways.values()):
        problems.append("boxed in: %.2f m ahead, %s" % (row["walk_m"], ", ".join("%s %.2f" % kv for kv in ways.items())))
    elif row["walk_m"] < 0.5:
        row["note"] = "a work stands in front of the arrival (%.2f m ahead); free to the %s" % (
            row["walk_m"], ", ".join(k for k, v in ways.items() if v > 0.5))
    row["problems"] = problems
    return row


def main() -> int:
    sys.stdout.reconfigure(encoding="utf8")
    jobs = int(next((a.split("=", 1)[1] for a in sys.argv if a.startswith("--jobs=")), "3"))
    todo = targets()
    stage = stage_runtime()
    print(f"{len(todo)} floors, {jobs} at a time", flush=True)
    rows = []
    with ThreadPoolExecutor(jobs) as pool:
        futures = [pool.submit(run, stage, seq, floor, i % jobs) for i, (seq, floor) in enumerate(todo)]
        for f in futures:
            r = f.result()
            rows.append(r)
            mark = "ok  " if not r["problems"] else "FAIL"
            print(f"{mark} {r['floor']:3d} {r['sequence']:22s} {r.get('map', ''):40s} "
                  f"walk {r.get('walk_m', 0):.1f} m  fps {r.get('fps_stand', 0):.0f}  {'; '.join(r['problems']) or r.get('note', '')}", flush=True)
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / "report.json").write_text(json.dumps(rows, indent=2, ensure_ascii=False), encoding="utf8")
    bad = [r for r in rows if r["problems"]]
    print(f"{len(rows) - len(bad)}/{len(rows)} floors play")
    return 1 if bad else 0


if __name__ == "__main__":
    sys.exit(main())
