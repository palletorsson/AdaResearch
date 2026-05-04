#!/usr/bin/env python3
"""
bake_best_of_scenes.py
=======================

Pre-bake every curated /dna best-of finding to a PackedScene (.tscn) so
that placing them in maps becomes instant — no live grammar simulation
at map-open time.

For each finding:
  1. Look up which artifact wrapper renders this gallery (via the same
     mapping promote_to_artifact.py uses).
  2. Build the apply_config dict (config_path, grammar, preset, …).
  3. Invoke commons/testing/bake_artifact.gd with the wrapper scene +
     config. Godot instantiates, calls apply_grid_config, waits for
     build, packs the subtree, saves the .tscn.
  4. After all bakes, the .tscn files live at:
       commons/generated/gallery_best_of/scenes/<gallery>__<entry>.tscn

Then placement uses prebaked_loader pointing at the saved scene.

Critical: bake at FULL fidelity (vr_preview=false) so the saved scene
captures the high-quality build. Loading it later is fast regardless;
the cost was paid once at bake time.

Run:
    python tools/bake_best_of_scenes.py                  # all best-of items
    python tools/bake_best_of_scenes.py --gallery facade-gallery
    python tools/bake_best_of_scenes.py --id <gallery> <entry>
    python tools/bake_best_of_scenes.py --force          # re-bake existing
"""

from __future__ import annotations
import argparse
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from measure_artifact_aabbs import _find_godot           # noqa: E402
from promote_to_artifact import (                        # noqa: E402
    GALLERY_MAP, load_best_of_manifest, load_finding_config,
)

BAKE_GD = "res://commons/testing/bake_artifact.gd"
SCENES_DIR = REPO / "commons" / "generated" / "gallery_best_of" / "scenes"

# wrapper_lookup → wrapper scene path. Same map promote_to_artifact uses.
WRAPPER_SCENE = {
    "facade_builder":        "res://commons/artifacts/facade_builder/facade_builder.tscn",
    "composition_artifact":  "res://commons/artifacts/composition_artifact/composition_artifact.tscn",
    "lsystem_artifact":      "res://commons/artifacts/lsystem_artifact/lsystem_artifact.tscn",
    "pattern_artifact":      "res://commons/artifacts/pattern_artifact/pattern_artifact.tscn",
    "rd_artifact":           "res://commons/artifacts/rd_artifact/rd_artifact.tscn",
    "trajectory_artifact":   "res://commons/artifacts/trajectory_artifact/trajectory_artifact.tscn",
    "mesh_grammar_artifact": "res://commons/artifacts/mesh_grammar_artifact/mesh_grammar_artifact.tscn",
    "chromatic_form_artifact": "res://commons/artifacts/chromatic_form_artifact/chromatic_form_artifact.tscn",
}


def bake_one(godot: str, gallery: str, entry_id: str, force: bool) -> bool:
    out_path = SCENES_DIR / f"{gallery}__{entry_id}.tscn"
    if out_path.exists() and not force:
        print(f"  skip      {gallery}__{entry_id}")
        return True

    spec = GALLERY_MAP.get(gallery)
    if not spec:
        print(f"  no-wrapper {gallery}__{entry_id}  (skipping; image-only gallery)")
        return False
    artifact = spec["artifact"]
    if artifact not in WRAPPER_SCENE:
        print(f"  unknown-wrapper {artifact}  ({gallery}__{entry_id})")
        return False

    # Build apply_config — identical to what promote_to_artifact emits, but
    # with vr_preview=false so the high-fidelity build gets baked.
    cfg = load_finding_config(gallery, entry_id)
    params = spec["params"](cfg, entry_id)
    params["vr_preview"] = False   # bake full fidelity

    out_res = f"res://commons/generated/gallery_best_of/scenes/{gallery}__{entry_id}.tscn"
    SCENES_DIR.mkdir(parents=True, exist_ok=True)

    # apply_config travels via JSON on the command line.
    apply_json = json.dumps(params)
    cmd = [
        godot, "--path", str(REPO), "--xr-mode", "off", "--no-window",
        "--script", BAKE_GD, "--",
        f"--scene={WRAPPER_SCENE[artifact]}",
        f"--apply-config={apply_json}",
        f"--out={out_res}",
        f"--wait=3",
    ]
    print(f"  bake      {gallery}__{entry_id} -> {artifact} ...", end=" ", flush=True)
    try:
        proc = subprocess.run(cmd, cwd=str(REPO), timeout=120, capture_output=True)
    except subprocess.TimeoutExpired:
        print("TIMEOUT")
        return False
    if proc.returncode != 0:
        print(f"FAIL rc={proc.returncode}")
        if proc.stderr:
            print(f"      stderr: {proc.stderr.decode('utf-8', errors='ignore')[-300:]}")
        return False
    if not out_path.exists():
        print(f"FAIL (no file at {out_path})")
        return False
    sz = out_path.stat().st_size
    print(f"OK ({sz/1024:.0f} KB)")
    return True


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--gallery", help="Bake only entries in this gallery slug")
    ap.add_argument("--id", nargs=2, metavar=("GALLERY", "ENTRY_ID"),
                    help="Bake exactly one (gallery, entry_id) pair")
    ap.add_argument("--force", action="store_true",
                    help="Re-bake even if .tscn exists")
    args = ap.parse_args()

    godot = _find_godot()
    if not godot:
        print("No Godot found. Set GODOT_EXE.")
        sys.exit(1)

    # Build the list of (gallery, entry_id) to bake.
    pairs: list[tuple[str, str]] = []
    if args.id:
        pairs.append((args.id[0], args.id[1]))
    else:
        manifest = load_best_of_manifest()
        for it in manifest.get("items", []):
            g = it.get("gallery", "")
            e = it.get("entry_id", "")
            if not g or not e: continue
            if args.gallery and g != args.gallery: continue
            pairs.append((g, e))

    if not pairs:
        print("No items to bake.")
        return

    print(f"Bake {len(pairs)} finding(s) to {SCENES_DIR.relative_to(REPO)}")
    print()
    ok = 0
    for g, e in pairs:
        if bake_one(godot, g, e, force=args.force):
            ok += 1
    print()
    print(f"Baked {ok} / {len(pairs)}")


if __name__ == "__main__":
    main()
