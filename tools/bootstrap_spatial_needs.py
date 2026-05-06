#!/usr/bin/env python3
"""
Bootstrap spatial_needs for all artifacts from existing registry data.

Reads footprint, size_group, geometry_spec, and @identity to infer
spatial_needs for each artifact. Writes back to registry JSON files.

The spatial_needs schema:

  "spatial_needs": {
    "platform": "none" | "table" | "pedestal" | "sunken",
    "footprint_cells": 1-5,
    "clearance": { "front": N, "back": N, "left": N, "right": N },
    "player_position": "front" | "around" | "above" | "any",
    "wall_backing": true/false,
    "orientation": "face_approach" | "face_center" | "any",
    "isolation": 0-3,        (0=cluster OK, 3=needs own room)
    "cluster_with": [],      (related artifact lookup_names)
    "preferred_zone": "entry" | "middle" | "end" | "any"
  }

Usage:
  python tools/bootstrap_spatial_needs.py --dry-run       # preview
  python tools/bootstrap_spatial_needs.py                  # write to registry
  python tools/bootstrap_spatial_needs.py --artifact coin_toss  # single
"""

import argparse
import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from lib.plan_utils import ROOT, load_all_registries, find_gd_file, parse_gdscript

REGISTRY_DIR = ROOT / "commons" / "artifacts" / "registry"

# Infer platform from artifact characteristics
PEDESTAL_KEYWORDS = ["pedestal", "tray", "stand", "mount", "pillar"]
TABLE_KEYWORDS = ["table", "desk", "workbench", "station", "console"]
SUNKEN_KEYWORDS = ["pool", "pit", "well", "arena", "floor"]

# Infer isolation from identity
ISOLATION_KEYWORDS = {
    3: ["contemplat", "meditat", "alone", "silence", "solitary"],
    2: ["focus", "single", "dedicated", "careful"],
    1: ["group", "collection", "set"],
    0: ["cluster", "together", "pair", "companion"],
}


def infer_spatial_needs(lookup_name: str, reg_entry: dict, gd_info: dict) -> dict:
    """Infer spatial_needs from existing data."""

    params = reg_entry.get("parameters", {})
    geo = reg_entry.get("geometry_spec", {})
    identity = gd_info.get("identity", {})
    desc = reg_entry.get("description", "").lower()
    tags = reg_entry.get("tags", [])
    size_group = params.get("size_group", "standard")
    existing_fp = params.get("footprint", [1, 1, 1])

    needs = {
        "platform": "none",
        "footprint_cells": 3,
        "clearance": {"front": 1, "back": 1, "left": 1, "right": 1},
        "player_position": "front",
        "wall_backing": False,
        "orientation": "face_approach",
        "isolation": 0,
        "cluster_with": [],
        "preferred_zone": "any",
    }

    # ── Platform ──────────────────────────────────────────────
    if any(kw in desc for kw in PEDESTAL_KEYWORDS):
        needs["platform"] = "pedestal"
    elif any(kw in desc for kw in TABLE_KEYWORDS):
        needs["platform"] = "table"
    elif any(kw in desc for kw in SUNKEN_KEYWORDS):
        needs["platform"] = "sunken"
    elif "grab" in desc or "pick" in desc or "toss" in desc:
        needs["platform"] = "pedestal"

    # Migrate existing table flag
    if params.get("table"):
        needs["platform"] = "table"

    # ── Footprint cells ───────────────────────────────────────
    if params.get("footprint_cells"):
        needs["footprint_cells"] = params["footprint_cells"]
    elif size_group == "compact":
        needs["footprint_cells"] = 1
    elif size_group == "standard":
        needs["footprint_cells"] = 2
    elif size_group == "room_scale":
        needs["footprint_cells"] = 3
    elif size_group == "environment":
        needs["footprint_cells"] = 5
    else:
        # Infer from metric footprint
        if existing_fp and len(existing_fp) >= 2:
            max_dim = max(existing_fp[0], existing_fp[2] if len(existing_fp) > 2 else existing_fp[0])
            needs["footprint_cells"] = max(1, min(5, round(max_dim)))

    # ── Clearance ─────────────────────────────────────────────
    # Interactive artifacts need front clearance for the player
    if "interactive" in tags or "grab" in tags:
        needs["clearance"]["front"] = 2
    if "vr" in tags:
        needs["clearance"]["front"] = 2
        needs["clearance"]["left"] = 2
        needs["clearance"]["right"] = 2

    # Large artifacts need more clearance
    if needs["footprint_cells"] >= 4:
        for d in ["front", "back", "left", "right"]:
            needs["clearance"][d] = max(needs["clearance"][d], 2)

    # ── Player position ───────────────────────────────────────
    if "surround" in desc or "walk around" in desc or "360" in desc:
        needs["player_position"] = "around"
    elif "look down" in desc or "above" in desc or "top" in desc:
        needs["player_position"] = "above"
    elif "grab" in desc or "button" in desc or "slider" in desc or "panel" in desc:
        needs["player_position"] = "front"
    else:
        needs["player_position"] = "front"

    # ── Wall backing ──────────────────────────────────────────
    if "panel" in desc or "screen" in desc or "display" in desc or "board" in desc:
        needs["wall_backing"] = True
    elif "poster" in desc or "painting" in desc or "frame" in desc:
        needs["wall_backing"] = True

    # ── Orientation ───────────────────────────────────────────
    if needs["wall_backing"]:
        needs["orientation"] = "face_approach"
    elif needs["player_position"] == "around":
        needs["orientation"] = "any"
    else:
        needs["orientation"] = "face_approach"

    # ── Isolation ─────────────────────────────────────────────
    essence = identity.get("essence", "").lower()
    truth = identity.get("truth", "").lower()
    combined = f"{desc} {essence} {truth}"

    for level in [3, 2, 1, 0]:
        if any(kw in combined for kw in ISOLATION_KEYWORDS[level]):
            needs["isolation"] = level
            break

    # ── Cluster with ──────────────────────────────────────────
    rels = identity.get("relationships", "")
    if rels:
        # Extract artifact names from relationship text
        # Simple heuristic: words that look like lookup_names (lowercase with underscores)
        import re
        candidates = re.findall(r'\b([a-z][a-z0-9_]+)\b', rels)
        needs["cluster_with"] = [c for c in candidates if len(c) > 4 and c != lookup_name][:5]

    # ── Preferred zone ────────────────────────────────────────
    complexity = reg_entry.get("complexity", "")
    if complexity == "beginner" or "intro" in desc or "basic" in desc:
        needs["preferred_zone"] = "entry"
    elif complexity == "advanced" or "complex" in desc or "synthesis" in desc:
        needs["preferred_zone"] = "end"
    else:
        needs["preferred_zone"] = "any"

    return needs


def main():
    parser = argparse.ArgumentParser(description="Bootstrap spatial_needs for artifacts")
    parser.add_argument("--artifact", help="Single artifact")
    parser.add_argument("--dry-run", action="store_true", help="Preview, don't write")
    parser.add_argument("--force", action="store_true", help="Overwrite existing spatial_needs")
    args = parser.parse_args()

    print("Loading registries...")
    registry = load_all_registries()
    print(f"  {len(registry)} artifacts")

    targets = [args.artifact] if args.artifact else sorted(registry.keys())
    updated = 0
    skipped = 0

    # Group by registry file for batch writing
    file_updates = {}

    for lookup in targets:
        reg = registry.get(lookup)
        if not reg:
            continue

        # Skip if already has spatial_needs and not forcing
        if reg.get("spatial_needs") and not args.force:
            skipped += 1
            continue

        # Parse GDScript for identity
        gd_path = find_gd_file(lookup, reg.get("scene", ""))
        gd_info = parse_gdscript(gd_path) if gd_path else {}

        needs = infer_spatial_needs(lookup, reg, gd_info)

        if args.dry_run:
            print(f"  {lookup}: fp={needs['footprint_cells']} platform={needs['platform']} "
                  f"isolation={needs['isolation']} zone={needs['preferred_zone']} "
                  f"wall={needs['wall_backing']} cluster={needs['cluster_with'][:3]}")
            updated += 1
            continue

        # Queue update
        reg_file = reg.get("_registry_file", "")
        if reg_file not in file_updates:
            file_updates[reg_file] = []
        file_updates[reg_file].append((lookup, reg.get("_registry_key", lookup), needs))
        updated += 1

    # Write updates
    if not args.dry_run:
        for reg_file, updates in file_updates.items():
            reg_path = REGISTRY_DIR / reg_file
            if not reg_path.is_file():
                continue
            data = json.loads(reg_path.read_text(encoding="utf-8"))
            if "artifacts" not in data:
                continue

            for lookup, key, needs in updates:
                if key in data["artifacts"] and isinstance(data["artifacts"][key], dict):
                    data["artifacts"][key]["spatial_needs"] = needs

            reg_path.write_text(json.dumps(data, indent="\t", ensure_ascii=False) + "\n", encoding="utf-8")
            print(f"  Updated {reg_file}: {len(updates)} artifacts")

    print(f"\nDone. Updated: {updated}, Skipped: {skipped}")


if __name__ == "__main__":
    main()
