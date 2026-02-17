#!/usr/bin/env python3
"""
prioritize_maps.py — Find maps that are actually in the game (referenced by sequences),
validate them, and catalog every artifact they use.

Usage:
    python scripts/prioritize_maps.py                # Full report
    python scripts/prioritize_maps.py --artifacts    # Just artifact catalog
    python scripts/prioritize_maps.py --orphans      # Maps NOT in any sequence
    python scripts/prioritize_maps.py --json         # Machine-readable output
"""

import argparse
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"
SEQ_DIR = MAPS_DIR / "sequences"

# Import the validator
sys.path.insert(0, str(REPO / "scripts"))
from validate_map import validate_map, load_artifact_keys, parse_artifact_cell, safe_print


def load_all_sequences() -> dict:
    """Load all sequence files. Returns {seq_id: {name, maps, file}}."""
    sequences = {}

    for f in sorted(SEQ_DIR.glob("*.json")):
        if f.name in ("sequence_index.json",):
            continue
        try:
            data = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue

        # Format 1: {"sequences": {"id": {..., "maps": [...]}}}
        if "sequences" in data and isinstance(data["sequences"], dict):
            for seq_id, seq_data in data["sequences"].items():
                if isinstance(seq_data, dict) and "maps" in seq_data:
                    sequences[seq_id] = {
                        "name": seq_data.get("name", seq_id),
                        "maps": seq_data["maps"],
                        "file": f.name,
                    }

        # Format 2: {"maps": [...]} at top level
        elif "maps" in data and isinstance(data["maps"], list):
            seq_id = f.stem
            sequences[seq_id] = {
                "name": data.get("name", seq_id),
                "maps": data["maps"],
                "file": f.name,
            }

    return sequences


def extract_artifacts_from_map(map_path: Path) -> list[dict]:
    """Extract all artifact references from a map_data.json."""
    artifacts = []
    try:
        data = json.loads(map_path.read_text(encoding="utf-8"))
    except Exception:
        return artifacts

    interactables = data.get("layers", {}).get("interactables", [])
    for z, row in enumerate(interactables):
        for x, cell in enumerate(row):
            c = str(cell).strip()
            if not c or c == " ":
                continue
            parsed = parse_artifact_cell(c)
            if parsed:
                artifacts.append({
                    "name": parsed["name"],
                    "rotation": parsed["rotation"],
                    "position": (x, z),
                    "map": map_path.parent.name,
                })
    return artifacts


def main():
    parser = argparse.ArgumentParser(description="Prioritize in-game maps and their artifacts")
    parser.add_argument("--artifacts", action="store_true", help="Show artifact catalog only")
    parser.add_argument("--orphans", action="store_true", help="Show maps NOT in any sequence")
    parser.add_argument("--missing", action="store_true", help="Show sequence maps that don't exist on disk")
    parser.add_argument("--json", action="store_true", help="JSON output")
    parser.add_argument("--validate", action="store_true", help="Run validator on in-game maps")
    args = parser.parse_args()

    sequences = load_all_sequences()

    # Collect all in-game map names
    in_game_maps = {}  # map_name -> [seq_ids]
    missing_maps = {}  # map_name -> [seq_ids]  (referenced but no folder)

    for seq_id, seq_data in sequences.items():
        for map_name in seq_data["maps"]:
            map_path = MAPS_DIR / map_name / "map_data.json"
            if map_path.is_file():
                in_game_maps.setdefault(map_name, []).append(seq_id)
            else:
                missing_maps.setdefault(map_name, []).append(seq_id)

    # Collect all map folders on disk
    all_map_folders = set()
    for d in MAPS_DIR.iterdir():
        if d.is_dir() and (d / "map_data.json").is_file():
            if "sequences" not in str(d) and "Structure_Examples" not in str(d):
                all_map_folders.add(d.name)

    orphan_maps = all_map_folders - set(in_game_maps.keys())

    # Collect artifacts from in-game maps
    artifact_usage = {}  # artifact_name -> {maps: set, count: int}
    all_in_game_artifacts = []

    for map_name in sorted(in_game_maps.keys()):
        map_path = MAPS_DIR / map_name / "map_data.json"
        arts = extract_artifacts_from_map(map_path)
        for a in arts:
            name = a["name"]
            if name not in artifact_usage:
                artifact_usage[name] = {"maps": set(), "count": 0}
            artifact_usage[name]["maps"].add(map_name)
            artifact_usage[name]["count"] += 1
        all_in_game_artifacts.extend(arts)

    # Check which artifacts are in registry
    registry = load_artifact_keys()
    registered = {name for name in artifact_usage if name in registry}
    unregistered = {name for name in artifact_usage if name not in registry}

    # --- Output ---

    if args.json:
        output = {
            "summary": {
                "total_sequences": len(sequences),
                "in_game_maps": len(in_game_maps),
                "orphan_maps": len(orphan_maps),
                "missing_maps": len(missing_maps),
                "unique_artifacts": len(artifact_usage),
                "registered_artifacts": len(registered),
                "unregistered_artifacts": len(unregistered),
            },
            "sequences": {k: {"name": v["name"], "maps": v["maps"], "file": v["file"]}
                         for k, v in sequences.items()},
            "in_game_maps": {k: v for k, v in sorted(in_game_maps.items())},
            "missing_maps": {k: v for k, v in sorted(missing_maps.items())},
            "orphan_maps": sorted(orphan_maps),
            "artifacts": {
                name: {"count": info["count"], "maps": sorted(info["maps"]),
                       "in_registry": name in registry}
                for name, info in sorted(artifact_usage.items(), key=lambda x: -x[1]["count"])
            },
            "unregistered_artifacts": sorted(unregistered),
        }
        print(json.dumps(output, indent=2))
        return 0

    if args.orphans:
        safe_print(f"\nOrphan maps (not in any sequence): {len(orphan_maps)}")
        safe_print("=" * 50)
        for m in sorted(orphan_maps):
            safe_print(f"  {m}")
        return 0

    if args.missing:
        safe_print(f"\nMissing maps (in sequences but no folder): {len(missing_maps)}")
        safe_print("=" * 50)
        for m, seqs in sorted(missing_maps.items()):
            safe_print(f"  {m}  (in: {', '.join(seqs)})")
        return 0

    if args.artifacts:
        safe_print(f"\nArtifacts used in-game: {len(artifact_usage)}")
        safe_print(f"  In registry:  {len(registered)}")
        safe_print(f"  NOT in registry: {len(unregistered)}")
        safe_print("=" * 50)

        if unregistered:
            safe_print(f"\nUNREGISTERED artifacts (priority to fix):")
            for name in sorted(unregistered):
                info = artifact_usage[name]
                safe_print(f"  {name}  (used {info['count']}x in {len(info['maps'])} maps)")

        safe_print(f"\nAll artifacts by usage:")
        for name, info in sorted(artifact_usage.items(), key=lambda x: -x[1]["count"]):
            reg = "OK" if name in registry else "!!"
            safe_print(f"  [{reg}] {name}: {info['count']}x in {len(info['maps'])} maps")
        return 0

    if args.validate:
        safe_print(f"\nValidating {len(in_game_maps)} in-game maps...")
        safe_print("=" * 50)
        results = []
        for map_name in sorted(in_game_maps.keys()):
            map_path = MAPS_DIR / map_name / "map_data.json"
            r = validate_map(map_path)
            results.append(r)

        by_grade = {"A": [], "B": [], "C": [], "F": []}
        for r in results:
            g = r["score"].get("grade", "F")
            by_grade.setdefault(g, []).append(r["map"])

        for grade in ["F", "C", "B", "A"]:
            maps = by_grade.get(grade, [])
            if maps:
                safe_print(f"\n[{grade}] ({len(maps)} maps):")
                for m in maps:
                    safe_print(f"  {m}")

        safe_print(f"\n{'='*50}")
        safe_print(f"IN-GAME VALIDATION SUMMARY")
        safe_print(f"{'='*50}")
        safe_print(f"Total in-game maps: {len(results)}")
        for g in ["A", "B", "C", "F"]:
            safe_print(f"  [{g}]: {len(by_grade.get(g, []))}")
        return 0

    # Default: full overview
    safe_print(f"\n{'='*50}")
    safe_print(f"ADARESEARCH MAP PRIORITY REPORT")
    safe_print(f"{'='*50}")
    safe_print(f"")
    safe_print(f"Sequences:           {len(sequences)}")
    safe_print(f"In-game maps:        {len(in_game_maps)}  (maps referenced by sequences)")
    safe_print(f"Missing maps:        {len(missing_maps)}  (referenced but no map_data.json)")
    safe_print(f"Orphan maps:         {len(orphan_maps)}  (exist on disk, not in any sequence)")
    safe_print(f"Total map folders:   {len(all_map_folders)}")
    safe_print(f"")
    safe_print(f"Unique artifacts:    {len(artifact_usage)}  (used across in-game maps)")
    safe_print(f"  In registry:       {len(registered)}")
    safe_print(f"  NOT in registry:   {len(unregistered)}")
    safe_print(f"")

    safe_print(f"SEQUENCES ({len(sequences)}):")
    safe_print(f"-" * 50)
    for seq_id, seq_data in sorted(sequences.items()):
        map_count = len(seq_data["maps"])
        found = sum(1 for m in seq_data["maps"] if m in in_game_maps)
        safe_print(f"  {seq_id}: {seq_data['name']} ({found}/{map_count} maps found)")

    if missing_maps:
        safe_print(f"\nMISSING MAPS (top priority - sequences reference these):")
        safe_print(f"-" * 50)
        for m, seqs in sorted(missing_maps.items()):
            safe_print(f"  {m}  (needed by: {', '.join(seqs)})")

    if unregistered:
        safe_print(f"\nUNREGISTERED ARTIFACTS (used in-game but not in registry):")
        safe_print(f"-" * 50)
        for name in sorted(unregistered):
            info = artifact_usage[name]
            map_list = ", ".join(sorted(info["maps"])[:5])
            if len(info["maps"]) > 5:
                map_list += f" +{len(info['maps'])-5} more"
            safe_print(f"  {name}  ({info['count']}x in: {map_list})")

    return 0


if __name__ == "__main__":
    sys.exit(main())
