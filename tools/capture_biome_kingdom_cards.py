#!/usr/bin/env python3
"""capture_biome_kingdom_cards.py — refresh the six biome kingdom cards.

The /biome-gallery page shows one card per kingdom, each a Godot capture of
`Biome_Gallery_<Kingdom>` (that kingdom's algos at tiers 1/3/5, a halo edge, a
mute cell). Those card PNGs are untracked render artifacts — regenerated, not
committed — and until now they were copied BY HAND, one `front.png` at a time.
That is exactly how they went stale: the fauna card kept showing the old
segmented grub for a day after `fauna:dna` became an SDF body, and the whole
batch missed the presence stain + seating fix that landed later. This script is
the one command that rebuilds all six on the current renderer so they cannot
silently rot.

The card is the FRONT angle — the eye-level "museum shelf" elevation, halo
strips standing at the back, specimens in a row on the floor (NOT the iso the
principals use). It copies `front.png` -> public/biome-gallery/<id>.png and then
rebuilds biome_gallery.json.

Serialized and watchdog-wrapped (the second Godot dies on the user:// lock; a
headless --mode=map run can hit a transient teardown crash — so each map gets
ONE retry before it is called a real failure).

  python tools/capture_biome_kingdom_cards.py            # all six kingdoms
  python tools/capture_biome_kingdom_cards.py fauna      # just these ids
  python tools/capture_biome_kingdom_cards.py --no-rebuild
"""
import os
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, os.path.join(ROOT, "tools"))
import build_biome_gallery  # noqa: E402  (KINGDOMS + main, single-sourced)

CARD_DIR = os.path.normpath(os.path.join(
    ROOT, "..", "ada_encyclopedia", "public", "biome-gallery"))
USERDATA = os.path.join(os.environ.get("APPDATA", ""), "Godot", "app_userdata",
                        "Ada Research Zero One", "multi_shots")
GODOT = "C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe"


def map_name(kingdom_id):
    # matches build_biome_gallery: k["map"] = f"Biome_Gallery_{id.capitalize()}"
    return "Biome_Gallery_" + kingdom_id.capitalize()


def capture_card(kingdom_id):
    """Capture one kingdom's gallery map and copy its front.png to the card.
    Returns (ok: bool, attempts: int, reason: str)."""
    name = map_name(kingdom_id)
    if not os.path.isfile(os.path.join(ROOT, "commons", "maps", name, "map_data.json")):
        return False, 0, "no map_data.json"
    shots = os.path.join(USERDATA, name)
    src = os.path.join(shots, "front.png")
    dst = os.path.join(CARD_DIR, kingdom_id + ".png")
    for attempt in (1, 2):
        if os.path.isdir(shots):
            shutil.rmtree(shots, ignore_errors=True)  # never copy a stale front.png
        cmd = [sys.executable, os.path.join(ROOT, "tools", "godot_watchdog.py"),
               "--expect=" + os.path.join(shots, "capture_report.json"), "--",
               GODOT, "--path", ".", "--xr-mode", "off", "--no-window",
               "--script", "res://commons/testing/capture_multi_angle.gd", "--",
               "--mode=map", "--target=" + name]
        r = subprocess.run(cmd, cwd=ROOT, capture_output=True, text=True, timeout=300)
        if os.path.isfile(src):
            shutil.copyfile(src, dst)
            return True, attempt, ""
        if attempt == 1:
            print(f"  transient crash (rc={r.returncode}) — retrying once...")
    return False, 2, f"no front.png after retry (rc={r.returncode})"


def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    rebuild = "--no-rebuild" not in sys.argv
    ids = [k["id"] for k in build_biome_gallery.KINGDOMS]
    if args:
        unknown = [a for a in args if a not in ids]
        if unknown:
            print(f"unknown kingdom(s): {', '.join(unknown)}  (known: {', '.join(ids)})")
            return 2
        ids = [a for a in ids if a in args]
    os.makedirs(CARD_DIR, exist_ok=True)
    ok = 0
    for i, kid in enumerate(ids, 1):
        print(f"[{i}/{len(ids)}] {map_name(kid)}")
        good, attempts, reason = capture_card(kid)
        if good:
            ok += 1
            note = "" if attempts == 1 else f" (after {attempts} attempts)"
            print(f"  ok -> public/biome-gallery/{kid}.png{note}")
        else:
            print(f"  FAIL {kid}: {reason}")
    print(f"{ok}/{len(ids)} cards captured.")
    if rebuild:
        build_biome_gallery.main()
    else:
        print("Skipped manifest rebuild (--no-rebuild). Run: python tools/build_biome_gallery.py")
    return 0 if ok == len(ids) else 1


if __name__ == "__main__":
    raise SystemExit(main())
