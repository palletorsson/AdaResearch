#!/usr/bin/env python3
"""
render_principle_slice.py
==========================

Take one slice of the auto_research_inventory (e.g. all stochastic
artifacts) and batch-render each through render_pattern_specimen.gd
with AABB-fit camera. Emits a per-principle gallery on the encyclopedia.

Strategy: trust the inventory's classifier; for every artifact in the
slice that has a scene file, instantiate it, let it run, snapshot.
Skip tier=D (live-only / VR) and tier=E (image-only) — those need
manual recipes.

Run:
    python tools/render_principle_slice.py --principle stochastic
    python tools/render_principle_slice.py --principle boolean --limit 20
    python tools/render_principle_slice.py --principle field --skip-existing
"""

from __future__ import annotations
import argparse
import json
import os
import shutil
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(REPO / "tools"))
from measure_artifact_aabbs import _find_godot

ENC = REPO.parent / "ada_encyclopedia"
INVENTORY_PATH = REPO / "doc" / "auto_research_inventory.json"
STAGING_DIR = REPO / "commons" / "primitive_grammar" / "_staging"
RECIPES_DIR = REPO / "commons" / "research_recipes"


def load_recipe(topic: str, artifact: str) -> dict:
    """Per-artifact override file: commons/research_recipes/<topic>__<artifact>.json
    Keys recognized: wait, camera, distance, look_at, fov, auto_fit, scene_props.
    Anything you put here merges over the auto-defaults the slicer would use."""
    p = RECIPES_DIR / f"{topic}__{artifact}.json"
    if not p.exists():
        return {}
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return {}


def slice_for_principle(inv: dict, principle: str) -> list[dict]:
    rows = inv["rows"]
    return [r for r in rows
            if r["principle"] == principle
            and r["scene"]
            and r["tier"] not in ("D", "E")]


def render_one(godot: str, row: dict, gallery_dir: Path, force: bool) -> tuple[bool, int]:
    cid = f"{row['topic']}__{row['artifact']}"
    out_png = gallery_dir / f"{cid}.png"
    out_cfg = gallery_dir / f"{cid}.json"
    if out_png.exists() and out_cfg.exists() and not force:
        return True, out_png.stat().st_size

    # Compose render-config: scene path, oblique camera, auto-fit AABB,
    # ~3-second wait so animated patterns settle into a representative frame.
    cfg = {
        "id": cid,
        "scene": "res://" + row["scene"].replace("\\", "/"),
        "camera": "oblique",
        "auto_fit": True,
        "wait": 3.0,
    }
    # Merge per-artifact override recipe if one exists.
    recipe = load_recipe(row["topic"], row["artifact"])
    if recipe:
        cfg.update(recipe)
    out_cfg.write_text(json.dumps({**row, **cfg}, indent=2) + "\n", encoding="utf-8")

    STAGING_DIR.mkdir(parents=True, exist_ok=True)
    cfg_staging = STAGING_DIR / f"{cid}.json"
    cfg_staging.write_text(json.dumps(cfg, indent=2), encoding="utf-8")

    user_out = f"user://principle_slice/{cid}.png"
    res_cfg = f"res://commons/primitive_grammar/_staging/{cid}.json"
    cmd = [
        godot, "--path", str(REPO), "--xr-mode", "off",
        "--script", "res://commons/testing/render_pattern_specimen.gd", "--",
        f"--config={res_cfg}", f"--out={user_out}", "--size=640",
    ]
    try:
        proc = subprocess.run(cmd, capture_output=True, text=True, timeout=60)
    except subprocess.TimeoutExpired:
        return False, 0
    if proc.returncode != 0:
        return False, 0

    appdata = os.environ.get("APPDATA", "")
    if not appdata:
        return False, 0
    ud = Path(appdata) / "Godot" / "app_userdata"
    src = None
    if ud.exists():
        for d in ud.iterdir():
            cand = d / "principle_slice" / f"{cid}.png"
            if cand.exists():
                src = cand; break
    if src is None:
        return False, 0
    shutil.copy2(src, out_png)
    return True, src.stat().st_size


def write_manifest(gallery_dir: Path, principle: str, rendered: list[dict]) -> None:
    entries = []
    for r in rendered:
        cid = f"{r['topic']}__{r['artifact']}"
        entries.append({
            "id": cid,
            "topic": r["topic"],
            "artifact": r["artifact"],
            "principle": r["principle"],
            "tier": r["tier"],
            "time": r["time"],
            "scale": r["scale"],
            "essence": r["essence"],
            "image": f"/{gallery_dir.name}/{cid}.png",
            "config": f"/{gallery_dir.name}/{cid}.json",
        })
    manifest = {
        "schema_version": 1,
        "version": 1,
        "principle": principle,
        "description": (
            f"Auto-rendered '{principle}' slice from the research-map "
            f"inventory. Each entry is one artifact in algorithms/*/* "
            f"classified by principle={principle}. Rendered through "
            f"render_pattern_specimen.gd with AABB-fit camera at t=3s."
        ),
        "entries": entries,
    }
    (gallery_dir / "manifest.json").write_text(
        json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    evals = gallery_dir / "evals.json"
    if not evals.exists():
        evals.write_text("{}\n", encoding="utf-8")


def main():
    ap = argparse.ArgumentParser(description=__doc__)
    ap.add_argument("--principle", required=True,
                    choices=["boolean", "grammatical", "iterative", "stochastic",
                             "optimization", "field", "geometric", "composition"])
    ap.add_argument("--limit", type=int, default=0,
                    help="Max artifacts to render (0 = no limit)")
    ap.add_argument("--skip-existing", action="store_true")
    ap.add_argument("--force", action="store_true")
    args = ap.parse_args()

    if not INVENTORY_PATH.exists():
        print(f"Inventory not found at {INVENTORY_PATH}.")
        print("Run: python tools/auto_research_inventory.py")
        sys.exit(1)
    inv = json.loads(INVENTORY_PATH.read_text(encoding="utf-8"))

    rows = slice_for_principle(inv, args.principle)
    if args.limit > 0:
        rows = rows[:args.limit]
    print(f"Slice principle={args.principle}: {len(rows)} renderable artifacts")
    if not rows:
        return

    godot = _find_godot()
    if not godot:
        print("No Godot. Set GODOT_EXE."); sys.exit(1)

    gallery_dir = ENC / "public" / f"principle-{args.principle}-gallery"
    gallery_dir.mkdir(parents=True, exist_ok=True)

    rendered: list[dict] = []
    failed: list[str] = []
    skipped: list[str] = []
    for i, row in enumerate(rows):
        cid = f"{row['topic']}__{row['artifact']}"
        if args.skip_existing and (gallery_dir / f"{cid}.png").exists():
            skipped.append(cid)
            rendered.append(row)  # still include in manifest
            continue
        ok, size = render_one(godot, row, gallery_dir, args.force)
        prefix = f"  [{i+1:3d}/{len(rows)}]"
        if ok:
            rendered.append(row)
            print(f"{prefix} OK   {cid:50s} {size//1024:5d} KB")
        else:
            failed.append(cid)
            print(f"{prefix} FAIL {cid}")

    write_manifest(gallery_dir, args.principle, rendered)
    print(f"\n  rendered: {len(rendered)} ({len(skipped)} skipped existing)")
    print(f"  failed:   {len(failed)}")
    print(f"  Gallery:  http://localhost:3003/principle-{args.principle}-gallery")
    if failed:
        print("\n  failed list:")
        for cid in failed[:20]:
            print(f"    - {cid}")


if __name__ == "__main__":
    main()
