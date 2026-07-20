#!/usr/bin/env python3
"""
cabinet_bench.py — the fast loop for the cabinet family.

Palle 2026-07-20: "can we speed up the dev process of improving the artifacts?"

Yes. The old loop was ~20 Godot boots per pass — one headless capture per
artifact (~12s each) plus a probe boot. This collapses it to ONE boot that
shoots every canon member, tiles the shots into a single contact sheet, and
runs the grammar gate. So the loop is now: edit .gd → cabinet_bench → read
ONE image + the gate table → repeat.

Steps:
  1. one Godot boot: commons/testing/capture_cabinet_family.gd shoots all
     members to user://cabinet_family/<artifact>.png
  2. tile them into doc/reports/cabinet_contact_sheet.png (labelled grid)
  3. run tools/check_cabinet_grammar.py against the latest probe report

Usage:
  python tools/cabinet_bench.py            # capture + tile + gate
  python tools/cabinet_bench.py --tile     # just re-tile existing shots
  python tools/cabinet_bench.py --no-gate  # skip the grammar gate
"""
from __future__ import annotations
import argparse
import json
import os
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
GODOT = os.environ.get("GODOT_EXE",
                       r"C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe")
USERDIR = Path(os.environ.get("APPDATA", "")) / "Godot" / "app_userdata" / \
    "Ada Research Zero One"
SHOTS = USERDIR / "cabinet_family"
CANON = REPO / "commons" / "data" / "cabinet_grammar.json"
SHEET = REPO / "doc" / "reports" / "cabinet_contact_sheet.png"


def capture() -> bool:
    """One Godot boot → a front shot of every member."""
    done = SHOTS / "_done.txt"
    if done.exists():
        done.unlink()
    cmd = [sys.executable, str(REPO / "tools" / "godot_watchdog.py"),
           f"--expect={done}", "--",
           GODOT, "--path", str(REPO), "--xr-mode", "off", "--no-window",
           "--script", "res://commons/testing/capture_cabinet_family.gd"]
    print("· one boot, all members …")
    r = subprocess.run(cmd, cwd=str(REPO))
    return done.exists()


def tile() -> bool:
    """Tile the per-member shots into one labelled contact sheet."""
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        print("  (Pillow not installed — shots are in %s, skipping sheet)" % SHOTS)
        return False
    members = [m["artifact"] for m in
               json.loads(CANON.read_text(encoding="utf-8")).get("members", [])]
    imgs = [(m, SHOTS / f"{m}.png") for m in members if (SHOTS / f"{m}.png").exists()]
    if not imgs:
        print("  no shots found in", SHOTS)
        return False
    cols = 3
    rows = (len(imgs) + cols - 1) // cols
    cell = 440
    label_h = 26
    sheet = Image.new("RGB", (cols * cell, rows * (cell + label_h)), (18, 18, 22))
    draw = ImageDraw.Draw(sheet)
    for i, (name, path) in enumerate(imgs):
        im = Image.open(path).convert("RGB")
        im.thumbnail((cell, cell))
        cx = (i % cols) * cell + (cell - im.width) // 2
        cy = (i // cols) * (cell + label_h) + label_h + (cell - im.height) // 2
        sheet.paste(im, (cx, cy))
        draw.text(((i % cols) * cell + 8, (i // cols) * (cell + label_h) + 6),
                  f"{i+1}. {name}", fill=(220, 224, 232))
    SHEET.parent.mkdir(parents=True, exist_ok=True)
    sheet.save(SHEET)
    print("  contact sheet:", SHEET, f"({len(imgs)} members)")
    return True


def gate() -> None:
    subprocess.run([sys.executable, str(REPO / "tools" / "check_cabinet_grammar.py")],
                   cwd=str(REPO))


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--tile", action="store_true", help="only re-tile existing shots")
    ap.add_argument("--no-gate", action="store_true", help="skip the grammar gate")
    args = ap.parse_args()

    if not args.tile:
        if not capture():
            print("capture failed (no _done.txt) — see the Godot log")
            return 1
    tile()
    if not args.no_gate:
        gate()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
