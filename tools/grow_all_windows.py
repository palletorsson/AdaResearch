"""tools/grow_all_windows.py — Phase C driver.

Reads windows.json (Phase B output), calls grow_map.py for each window
to produce a complete `commons/maps/Timeline_<sequence>_w<N>/` map.

Run:
  python tools/grow_all_windows.py --limit=3            # grow first 3 (demo)
  python tools/grow_all_windows.py --sequence=primitives  # all windows in one sequence
  python tools/grow_all_windows.py --all                  # all windows (~156 maps)
  python tools/grow_all_windows.py --dry-run              # don't actually grow

Output: commons/maps/Timeline_<sequence>_w<N>/{map_data.json, intent.md, blurb.md}
Logged to: ada_run/timeline_grow_log.json
"""
from __future__ import annotations

import argparse
import json
import random
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
WINDOWS_PATH = ROOT / "doc" / "placement_research" / "windows.json"
MAPS_DIR = ROOT / "commons" / "maps"
LOG_PATH = ROOT / "ada_run" / "timeline_grow_log.json"

sys.path.insert(0, str(ROOT / "tools"))
from grow_map import grow_map, write_map     # type: ignore
from place_artifacts import artifact_from_registry  # type: ignore


def grow_window(window: dict, seed: int = 0) -> dict | None:
    """Grow a single window into a map. Returns log entry or None on failure."""
    # Resolve each artifact's spatial_needs from the registry
    artifacts = []
    missing = []
    for a in window["artifacts"]:
        spec = artifact_from_registry(a["name"])
        if spec is None:
            missing.append(a["name"])
            continue
        artifacts.append(spec)
    if not artifacts:
        return None

    size = window["proposed_size"]
    name = f"Timeline_{window['id']}"   # e.g., Timeline_primitives_w0
    # grow_map wants `name` without the prefix — it'll add Grown_
    # We use Timeline_<id> as the bare name; grow_map prepends Grown_
    # so the folder becomes Grown_Timeline_<id>. Override to keep cleaner.

    result = grow_map(
        name=window["id"],   # produces commons/maps/Grown_<id>/
        artifacts=artifacts,
        max_width=size["width"],
        max_depth=size["depth"],
        max_height=size.get("max_height", 3),
        seed=seed,
    )
    map_path = write_map(window["id"], result)
    return {
        "window_id":         window["id"],
        "sequence":          window["sequence"],
        "phase":             window["phase"],
        "artifacts_in_window": len(window["artifacts"]),
        "artifacts_placed":  len(result["placements"]),
        "missing_from_registry": missing,
        "laid_cells":        result["laid_cells"],
        "table_cells":       result["table_cells"],
        "score":             round(result["constraint_score"], 3),
        "map_path":          str(map_path.relative_to(ROOT)),
    }


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--limit", type=int, help="grow only first N windows")
    p.add_argument("--sequence", type=str, help="grow only windows in this sequence")
    p.add_argument("--all", action="store_true", help="grow every window")
    p.add_argument("--dry-run", action="store_true")
    p.add_argument("--seed", type=int, default=0)
    args = p.parse_args()

    if not WINDOWS_PATH.exists():
        print(f"windows.json not found — run tools/window_clusterer.py first")
        return

    with open(WINDOWS_PATH, "r", encoding="utf-8") as f:
        data = json.load(f)
    windows = data["windows"]

    if args.sequence:
        windows = [w for w in windows if w["sequence"] == args.sequence]
    if args.limit and not args.all:
        windows = windows[:args.limit]
    if not args.all and not args.limit and not args.sequence:
        # Default: 3-window demo
        windows = windows[:3]

    print(f"growing {len(windows)} windows{'  (DRY RUN)' if args.dry_run else ''}")
    print()

    results = []
    for i, w in enumerate(windows):
        print(f"  [{i+1}/{len(windows)}] {w['id']:30}  "
              f"{w['n_artifacts']} artifacts  "
              f"{w['proposed_size']['width']}×{w['proposed_size']['depth']}", end="")
        if args.dry_run:
            print("   (dry-run)")
            continue
        try:
            r = grow_window(w, seed=args.seed)
        except Exception as e:
            print(f"   ERROR: {e}")
            continue
        if r is None:
            print("   SKIP (no registry hits)")
            continue
        print(f"   →  {r['laid_cells']} cells  score={r['score']:.2f}")
        if r["missing_from_registry"]:
            print(f"      missing: {r['missing_from_registry'][:5]}")
        results.append(r)

    if not args.dry_run and results:
        LOG_PATH.parent.mkdir(exist_ok=True)
        existing = []
        if LOG_PATH.exists():
            try:
                with open(LOG_PATH, "r", encoding="utf-8") as f:
                    existing = json.load(f)
            except (json.JSONDecodeError, OSError):
                existing = []
        existing.extend(results)
        with open(LOG_PATH, "w", encoding="utf-8") as f:
            json.dump(existing, f, indent=2)
        print()
        print(f"logged {len(results)} maps to {LOG_PATH.relative_to(ROOT)}")
        print(f"maps written to commons/maps/Grown_<window_id>/")


if __name__ == "__main__":
    main()
