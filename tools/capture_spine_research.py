#!/usr/bin/env python3
"""Capture Godot screenshots of spine-research best-per-base variants.

For each best-per-base variant in a given sequence, invokes
commons/testing/capture_multi_angle.gd which loads the map via
MapCatalogDesktop3D and saves four PNGs (above / front / left / right).
After Godot finishes, copies the `above.png` of each captured map into
the encyclopedia's spine-research gallery directory as
`<id>_godot.png`, so the gallery can show real Godot views alongside
the synthetic iso thumbnails.

Usage:
    python tools/capture_spine_research.py --sequence color
    python tools/capture_spine_research.py --sequence color --all
    python tools/capture_spine_research.py --map Color_Pillar_v3_terraced

Output:
    ada_run/captures/spine_research/<map_name>/{above,front,left,right}.png
    ada_encyclopedia/public/spine-research/<map_name>_godot.png
"""
from __future__ import annotations

import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))

from measure_artifact_aabbs import _find_godot   # noqa: E402

ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"
MIRROR_DIR = ENCYCLOPEDIA / "public" / "spine-research"
MANIFEST = MIRROR_DIR / "manifest.json"
CAPTURE_OUT = REPO / "ada_run" / "captures" / "spine_research"
CAPTURE_GD = "res://commons/testing/capture_multi_angle.gd"
RUNTIME_FLAGS = REPO / "ada_run" / "runtime_flags.json"


def _set_capture_flags() -> dict:
    """Force biome off (and any other capture-time toggles) so the
    captured images show the cube grid cleanly. Returns the previous
    flags dict so we can restore on exit."""
    prior: dict = {}
    if RUNTIME_FLAGS.exists():
        try:
            prior = json.loads(RUNTIME_FLAGS.read_text(encoding="utf-8"))
        except Exception:
            prior = {}
    capture_flags = dict(prior)
    capture_flags["biome_enabled"] = False
    # Suppress artifact spawning so big artifacts (color pillars, rainbow
    # arcs, AntColony, etc.) don't flood the frame. The cube grid reads
    # cleanly and the spawn/teleport markers stay visible.
    capture_flags["artifacts_enabled"] = False
    capture_flags["_capture_active"] = True
    RUNTIME_FLAGS.parent.mkdir(parents=True, exist_ok=True)
    RUNTIME_FLAGS.write_text(
        json.dumps(capture_flags, indent=2) + "\n", encoding="utf-8")
    return prior


def _restore_flags(prior: dict) -> None:
    """Put runtime_flags.json back to the state it was in before capture."""
    prior.pop("_capture_active", None)
    if not prior:
        prior = {"biome_enabled": True,
                 "_doc": "restored after spine-research capture"}
    RUNTIME_FLAGS.write_text(
        json.dumps(prior, indent=2) + "\n", encoding="utf-8")


def capture_one(godot: str, map_name: str, timeout: int = 90) -> bool:
    """Run capture_multi_angle.gd for one map. Returns True if the
    above.png file appears in the output dir afterward."""
    out_dir_rel = "res://ada_run/captures/spine_research"
    cmd = [
        godot, "--path", str(REPO), "--xr-mode", "off", "--no-window",
        "--script", CAPTURE_GD, "--",
        f"--mode=map", f"--target={map_name}", f"--out={out_dir_rel}",
    ]
    try:
        proc = subprocess.run(cmd, cwd=str(REPO),
                              timeout=timeout, capture_output=True)
    except subprocess.TimeoutExpired:
        print(f"  ! {map_name}: timed out")
        return False
    # iso.png (preferred), front.png, or above.png is acceptable
    # evidence the capture ran.
    out_path = None
    for angle in ("top.png", "iso.png", "front.png", "above.png"):
        candidate = CAPTURE_OUT / map_name / angle
        if candidate.exists():
            out_path = candidate; break
    if out_path is None:
        print(f"  ! {map_name}: no above.png produced (rc={proc.returncode})")
        if proc.returncode != 0 and proc.stderr:
            tail = proc.stderr.decode("utf-8", errors="ignore")[-300:]
            print(f"    stderr tail: {tail}")
        return False
    return True


def _build_composite(map_dir: Path, out_path: Path) -> bool:
    """Stitch top + iso + front + side into a 2×2 composite so the
    gallery thumb shows the map from multiple angles at once."""
    try:
        from PIL import Image, ImageDraw
    except ImportError:
        return False
    angle_paths = {a: map_dir / f"{a}.png" for a in
                   ("top", "iso", "front", "left", "right", "above", "back")}

    # Pick best image for each composite slot via fallback chain.
    fallback_chain = {
        "top":   ["top", "above", "iso", "front"],
        "iso":   ["iso", "front", "above", "top"],
        "front": ["front", "back", "iso", "above"],
        "side":  ["left", "right", "back", "iso"],
    }

    def pick(slot: str) -> Path | None:
        for a in fallback_chain[slot]:
            p = angle_paths.get(a)
            if p and p.exists(): return p
        return None

    chosen = {slot: pick(slot) for slot in fallback_chain}
    if not any(chosen.values()):
        return False

    cell = 480
    pad = 4
    composite = Image.new("RGB", (cell * 2 + pad * 3, cell * 2 + pad * 3),
                          (16, 18, 24))
    draw = ImageDraw.Draw(composite)
    layout = [
        ("top",   pad,             pad),
        ("iso",   cell + pad * 2,  pad),
        ("front", pad,             cell + pad * 2),
        ("side",  cell + pad * 2,  cell + pad * 2),
    ]
    for slot, px, py in layout:
        src = chosen.get(slot)
        if src is None: continue
        try:
            img = Image.open(src).convert("RGB")
        except Exception:
            continue
        img.thumbnail((cell, cell), Image.LANCZOS)
        x = px + (cell - img.width) // 2
        y = py + (cell - img.height) // 2
        composite.paste(img, (x, y))
        draw.text((px + 6, py + 4), slot, fill=(200, 215, 240))
    composite.save(out_path)
    return True


def mirror_to_gallery(map_name: str) -> bool:
    """Use the iso_perfect angle (true isometric, orthographic, sized
    to the map) as the gallery thumb. Falls back through other
    angles if iso_perfect.png isn't available."""
    map_dir = CAPTURE_OUT / map_name
    if not map_dir.exists():
        return False
    if not ENCYCLOPEDIA.exists():
        return False
    MIRROR_DIR.mkdir(parents=True, exist_ok=True)
    dst = MIRROR_DIR / f"{map_name}_godot.png"
    for angle in ("iso_perfect.png", "iso.png", "top.png", "front.png", "above.png"):
        src = map_dir / angle
        if src.exists():
            shutil.copy2(src, dst)
            return True
    return False


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--sequence", default="",
                   help="capture every best-per-base variant in this sequence")
    p.add_argument("--map", default="",
                   help="capture a single named map (variant id)")
    p.add_argument("--all", action="store_true",
                   help="capture every variant (not just bests)")
    p.add_argument("--mirror", action="store_true", default=True,
                   help="copy above.png into the encyclopedia public dir")
    args = p.parse_args()

    if not args.sequence and not args.map:
        p.print_help(); return 1

    if not MANIFEST.exists():
        sys.exit(f"missing {MANIFEST}")
    manifest = json.loads(MANIFEST.read_text(encoding="utf-8"))
    entries = manifest.get("entries", [])

    if args.map:
        targets = [{"id": args.map}]
    else:
        targets = [
            e for e in entries
            if e.get("sequence") == args.sequence
            and (args.all or e.get("is_best_for_base"))
        ]
    if not targets:
        print(f"no targets matched"); return 1

    godot = _find_godot()
    if not Path(godot).exists():
        sys.exit(f"godot binary not found at {godot}")
    print(f"  godot: {godot}")
    print(f"  scope: {len(targets)} maps")
    print()

    # Force biome off + capture-mode flag so the cube grid reads
    # cleanly in screenshots. Restore the user's flags on exit no
    # matter what (KeyboardInterrupt, exception, normal finish).
    prior_flags = _set_capture_flags()
    print(f"  flags: biome_enabled forced to false (prior was "
          f"{prior_flags.get('biome_enabled', True)})")
    print()

    ok = fail = 0
    try:
        for t in targets:
            name = t["id"]
            print(f"  capturing {name}…")
            if capture_one(godot, name):
                if args.mirror:
                    if mirror_to_gallery(name):
                        print(f"    mirrored to {MIRROR_DIR.name}/{name}_godot.png")
                    else:
                        print(f"    above.png written but mirror failed")
                ok += 1
            else:
                fail += 1
    finally:
        _restore_flags(prior_flags)
        print()
        print(f"  flags restored to prior state")

    print()
    print(f"=== capture sweep ===")
    print(f"  captured: {ok}")
    print(f"  failed:   {fail}")
    print(f"  output:   {CAPTURE_OUT.relative_to(REPO)}")
    if args.mirror:
        print(f"  mirror:   {MIRROR_DIR.relative_to(REPO.parent)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
