#!/usr/bin/env python3
"""Map-grammar auto-research driver.

Reads tools/map_grammar/research_configs.json, runs each config through
the grammar's operations, writes a full map_data.json into commons/maps/
matching the project's schema, and mirrors a thumbnail + manifest into
the encyclopedia for the /galleries/map-grammar gallery.

Usage:
    python tools/map_grammar_research.py
    python tools/map_grammar_research.py --id mg_bsp_classic    # one config
    python tools/map_grammar_research.py --force                # overwrite

The Three.js detail page in the encyclopedia loads each map by name from
the regular /api/maps endpoint, so the saved JSON IS the source of truth.
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(REPO / "tools"))
from map_grammar import run_config, to_map_data_json   # noqa: E402
from iso_voxel_render import render_iso                # noqa: E402

CONFIG_PATH = REPO / "tools" / "map_grammar" / "research_configs.json"
MAPS_DIR = REPO / "commons" / "maps"
ENCYCLOPEDIA = REPO.parent / "ada_encyclopedia"
GALLERY_DIR = ENCYCLOPEDIA / "public" / "map-grammar-gallery"


def load_configs() -> list[dict]:
    return json.loads(CONFIG_PATH.read_text(encoding="utf-8"))["configs"]


def main() -> int:
    p = argparse.ArgumentParser()
    p.add_argument("--id", default="", help="run only this config id")
    p.add_argument("--force", action="store_true",
        help="overwrite existing map_data.json")
    p.add_argument("--seed", type=int, default=42)
    p.add_argument("--cell-px", type=int, default=14)
    p.add_argument("--library", default="",
        help="alt config library JSON (e.g. next-gen queue)")
    p.add_argument("--append", action="store_true",
        help="append --library configs to manifest instead of replacing")
    args = p.parse_args()

    if args.library:
        lib_path = Path(args.library)
        if not lib_path.is_absolute():
            lib_path = REPO / lib_path
        configs = json.loads(lib_path.read_text(encoding="utf-8"))["configs"]
    else:
        configs = load_configs()
    if args.id:
        configs = [c for c in configs if c.get("id") == args.id]
    if not configs:
        print("no configs to run"); return 1

    write_gallery = ENCYCLOPEDIA.exists()
    if write_gallery:
        GALLERY_DIR.mkdir(parents=True, exist_ok=True)
    manifest_entries: list[dict] = []
    written = 0
    skipped = 0

    for cfg in configs:
        cid = cfg.get("id")
        if not cid: continue
        out_dir = MAPS_DIR / cid
        map_path = out_dir / "map_data.json"
        if map_path.exists() and not args.force:
            print(f"  - {cid:30s} exists (skip; use --force to overwrite)")
            skipped += 1
        else:
            state = run_config(cfg, seed=args.seed)
            data = to_map_data_json(
                state, cid,
                description=cfg.get("notes", ""),
                config_id=cid,
                ops=cfg.get("ops", []),
            )
            out_dir.mkdir(parents=True, exist_ok=True)
            map_path.write_text(json.dumps(data, indent=2), encoding="utf-8")
            print(f"  + {cid:30s} -> {map_path.relative_to(REPO)}")
            written += 1

        # Render iso thumbnail for the gallery + per-map alongside.
        # Re-run config (idempotent) to get heights for the renderer.
        state = run_config(cfg, seed=args.seed)
        thumb_local = out_dir / "map_iso.png"
        render_iso(state.structure, thumb_local, cell_px=args.cell_px,
                   utilities=state.utilities, interactables=state.interactables)

        if write_gallery:
            png_name = f"{cid}.png"
            cfg_name = f"{cid}.json"
            render_iso(state.structure, GALLERY_DIR / png_name,
                       cell_px=args.cell_px,
                       utilities=state.utilities,
                       interactables=state.interactables)
            (GALLERY_DIR / cfg_name).write_text(json.dumps({
                "id": cid,
                "notes": cfg.get("notes", ""),
                "rows": state.rows,
                "cols": state.cols,
                "ops": cfg.get("ops", []),
            }, indent=2), encoding="utf-8")
            manifest_entries.append({
                "id": cid,
                "notes": cfg.get("notes", ""),
                "image": f"/map-grammar-gallery/{png_name}",
                "config": f"/map-grammar-gallery/{cfg_name}",
                "map_name": cid,
                "grid_dims": [state.cols, state.rows],
                "rule_count": len(cfg.get("ops", []) or []),
                "rating": None,
            })

    if write_gallery and manifest_entries:
        existing_path = GALLERY_DIR / "manifest.json"
        existing_entries: list[dict] = []
        if existing_path.exists():
            try:
                existing_entries = json.loads(existing_path.read_text(
                    encoding="utf-8")).get("entries", []) or []
            except Exception:
                existing_entries = []
        new_ids = {e["id"] for e in manifest_entries}
        # Keep prior entries IF the underlying map_data.json still exists;
        # otherwise the entry is stale (deleted or moved) and would show
        # as broken without a real reason.
        def map_exists(eid: str) -> bool:
            return (MAPS_DIR / (eid) / "map_data.json").exists()
        merged = [e for e in existing_entries
                  if e.get("id") not in new_ids and map_exists(e.get("id", ""))]
        merged.extend(manifest_entries)
        manifest = {
            "schema_version": 1,
            "version": 1,
            "description": ("Map-grammar gallery — full maps composed by "
                          "the operation grammar. Each entry IS a real "
                          "map at commons/maps/<id>/map_data.json. "
                          "Click to load in the Three.js voxel viewer."),
            "entries": merged,
        }
        existing_path.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
        print(f"\nwrote {existing_path}  ({len(merged)} total entries)")
    print(f"\n=== summary ===  written: {written}  skipped: {skipped}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
