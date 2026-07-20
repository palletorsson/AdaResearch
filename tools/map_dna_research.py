#!/usr/bin/env python3
"""
map_dna_research.py — the auto-research runner over a map's DNA gallery.

Stage 1 (this tool): close the OBSERVATION gap. For every cast artifact in
the map's manifest that has no capture, run the serialized headless capture
(watchdog-wrapped, one Godot at a time — the 16-second rule), copy the shots
into the encyclopedia's capture library, then rebuild the map's manifest so
the gallery fills in. An entry you can SEE is an entry you can evaluate and
vary; observation precedes variation.

Usage:
  python tools/map_dna_research.py --map=Bricolage_Inventory
  python tools/map_dna_research.py --map=X --limit=5
"""
from __future__ import annotations
import json
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ENC = REPO.parent / "ada_encyclopedia" / "public"
CAPTURES = ENC / "artifact-gallery" / "captures"
MANIFESTS = ENC / "map-dna"
GODOT = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"
SHOT_DIR = Path.home() / "AppData/Roaming/Godot/app_userdata/Ada Research Zero One/multi_shots"


def capture(lookup: str) -> bool:
    out = SHOT_DIR / lookup
    report = out / "capture_report.json"
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
           f"--expect={report}", "--",
           GODOT, "--path", ".", "--xr-mode", "off", "--no-window",
           "--script", "res://commons/testing/capture_multi_angle.gd",
           "--", "--mode=artifact", f"--target={lookup}"]
    r = subprocess.run(cmd, cwd=REPO, capture_output=True, text=True, timeout=180)
    ok = report.exists()
    print(f"  capture {lookup}: {'ok' if ok else 'FAILED'}"
          + ("" if ok else f"  [{(r.stdout or r.stderr)[-120:]}]"))
    return ok


def publish(lookup: str) -> bool:
    src = SHOT_DIR / lookup
    if not src.exists():
        return False
    dst = CAPTURES / lookup
    dst.mkdir(parents=True, exist_ok=True)
    n = 0
    for png in src.glob("*.png"):
        shutil.copy2(png, dst / png.name)
        n += 1
    return n > 0


def main() -> int:
    want = None
    limit = 999
    for a in sys.argv[1:]:
        if a.startswith("--map="):
            want = a.split("=", 1)[1]
        if a.startswith("--limit="):
            limit = int(a.split("=", 1)[1])
    if not want:
        print("usage: map_dna_research.py --map=<Map> [--limit=N]")
        return 1
    mf = MANIFESTS / want / "manifest.json"
    if not mf.exists():
        print(f"no manifest for {want} — run build_map_dna.py first")
        return 1
    m = json.loads(mf.read_text(encoding="utf-8"))
    missing = [e["id"] for e in m.get("entries", [])
               if e.get("flags", {}).get("registered") and not e.get("flags", {}).get("captured")]
    print(f"{want}: {len(missing)} uncaptured cast member(s)"
          + (f", running first {limit}" if limit < len(missing) else ""))
    done = 0
    for lk in missing[:limit]:
        if capture(lk) and publish(lk):
            done += 1
    # rebuild this map's manifest so the gallery fills
    subprocess.run([sys.executable, str(REPO / "tools" / "build_map_dna.py"),
                    f"--map={want}"], cwd=REPO)
    print(f"published {done}/{min(limit, len(missing))} capture(s); manifest rebuilt")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
