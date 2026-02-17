#!/usr/bin/env python3
"""
curriculum_report.py — Report on maps actually in the game, based on
curriculum_spine.json + lab_evolution.

Scopes:
  --spine       Only spine sequences (the main path)
  --branches    Spine + branch sequences
  --lab         Lab evolution maps
  --all         Everything in curriculum (default)
  --artifacts   Artifact catalog for in-curriculum maps
  --validate    Run validator on in-curriculum maps
  --json        Machine-readable output
"""

import argparse
import json
import sys
from pathlib import Path
from collections import OrderedDict

REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"
SEQ_DIR = MAPS_DIR / "sequences"
SPINE_FILE = MAPS_DIR / "curriculum_spine.json"
LAB_DIR = MAPS_DIR / "Lab"

sys.path.insert(0, str(REPO / "scripts"))
from validate_map import validate_map, load_artifact_keys, parse_artifact_cell, safe_print


def load_spine():
    data = json.loads(SPINE_FILE.read_text(encoding="utf-8"))
    return data


def load_sequence_maps(seq_name: str) -> list[str]:
    """Load map names from a sequence file."""
    seq_file = SEQ_DIR / f"{seq_name}.json"
    if not seq_file.is_file():
        return []
    try:
        data = json.loads(seq_file.read_text(encoding="utf-8"))
    except Exception:
        return []

    # Format: {"sequences": {"name": {..., "maps": [...]}}}
    if "sequences" in data and isinstance(data["sequences"], dict):
        for seq_id, seq_data in data["sequences"].items():
            if isinstance(seq_data, dict) and "maps" in seq_data:
                return seq_data["maps"]

    # Format: {"maps": [...]}
    if "maps" in data and isinstance(data["maps"], list):
        return data["maps"]

    return []


def collect_spine_sequences(spine_data) -> list[dict]:
    """Get ordered spine sequences."""
    seqs = spine_data.get("spine", {}).get("sequences", [])
    return sorted(seqs, key=lambda s: s.get("order", 999))


def collect_branch_sequences(spine_data) -> dict:
    """Get all branch sequences keyed by parent."""
    branches = {}
    bp = spine_data.get("branches", {}).get("branch_points", {})
    for parent, info in bp.items():
        if isinstance(info, dict):
            for child in info.get("unlocks", []):
                branches[child] = {"parent": parent, "type": "branch_point"}

    bc = spine_data.get("branches", {}).get("branch_chains", {})
    for parent, info in bc.items():
        if isinstance(info, dict):
            for child in info.get("unlocks", []):
                branches[child] = {"parent": parent, "type": "branch_chain"}

    return branches


def collect_lab_maps(spine_data) -> list[dict]:
    """Get lab evolution entries."""
    return spine_data.get("lab_evolution", {}).get("actual_progression", [])


def extract_artifacts_from_map(map_path: Path) -> list[dict]:
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
                    "map": map_path.parent.name if map_path.parent.name != "Lab" else f"Lab/{map_path.stem}",
                })
    return artifacts


def main():
    parser = argparse.ArgumentParser(description="Curriculum priority report")
    parser.add_argument("--spine", action="store_true", help="Spine sequences only")
    parser.add_argument("--branches", action="store_true", help="Spine + branches")
    parser.add_argument("--lab", action="store_true", help="Lab evolution maps only")
    parser.add_argument("--artifacts", action="store_true", help="Artifact catalog")
    parser.add_argument("--validate", action="store_true", help="Run validator")
    parser.add_argument("--json", action="store_true", help="JSON output")
    args = parser.parse_args()

    spine_data = load_spine()
    spine_seqs = collect_spine_sequences(spine_data)
    branch_seqs = collect_branch_sequences(spine_data)
    lab_progression = collect_lab_maps(spine_data)

    # Determine which sequences to include
    if args.spine:
        target_seqs = OrderedDict((s["name"], {"type": "spine", "order": s["order"], "phase": s["phase"]}) for s in spine_seqs)
    elif args.lab:
        target_seqs = OrderedDict()  # lab-only mode
    else:
        # spine + branches
        target_seqs = OrderedDict((s["name"], {"type": "spine", "order": s["order"], "phase": s["phase"]}) for s in spine_seqs)
        for name, info in branch_seqs.items():
            target_seqs[name] = {"type": "branch", "parent": info["parent"]}

    # Collect all map paths
    all_maps = OrderedDict()  # map_name -> {path, sequences, type}

    for seq_name, seq_info in target_seqs.items():
        map_names = load_sequence_maps(seq_name)
        for m in map_names:
            map_path = MAPS_DIR / m / "map_data.json"
            if m not in all_maps:
                all_maps[m] = {
                    "path": map_path,
                    "exists": map_path.is_file(),
                    "sequences": [],
                    "type": seq_info["type"],
                }
            all_maps[m]["sequences"].append(seq_name)

    # Lab maps
    lab_maps = OrderedDict()
    for entry in lab_progression:
        lab_file = entry.get("lab_file", "")
        if lab_file:
            lab_path = LAB_DIR / lab_file
            lab_maps[lab_file] = {
                "path": lab_path,
                "exists": lab_path.is_file(),
                "after": entry.get("after", "none"),
                "added": entry.get("added", []),
            }

    # --- Validation ---
    results = {}
    if args.validate:
        for m, info in all_maps.items():
            if info["exists"]:
                results[m] = validate_map(info["path"])
        for lf, info in lab_maps.items():
            if info["exists"]:
                results[f"Lab/{lf}"] = validate_map(info["path"])

    # --- Artifacts ---
    artifact_usage = {}
    if args.artifacts or not args.lab:
        for m, info in all_maps.items():
            if info["exists"]:
                arts = extract_artifacts_from_map(info["path"])
                for a in arts:
                    name = a["name"]
                    if name not in artifact_usage:
                        artifact_usage[name] = {"maps": set(), "count": 0}
                    artifact_usage[name]["maps"].add(m)
                    artifact_usage[name]["count"] += 1

        for lf, info in lab_maps.items():
            if info["exists"]:
                arts = extract_artifacts_from_map(info["path"])
                for a in arts:
                    name = a["name"]
                    if name not in artifact_usage:
                        artifact_usage[name] = {"maps": set(), "count": 0}
                    artifact_usage[name]["maps"].add(f"Lab/{lf}")
                    artifact_usage[name]["count"] += 1

    registry = load_artifact_keys()
    registered = {n for n in artifact_usage if n in registry}
    unregistered = {n for n in artifact_usage if n not in registry}

    # --- JSON output ---
    if args.json:
        output = {
            "spine_sequences": [s["name"] for s in spine_seqs],
            "branch_sequences": dict(branch_seqs),
            "total_sequences": len(target_seqs),
            "total_maps": len(all_maps),
            "maps_found": sum(1 for m in all_maps.values() if m["exists"]),
            "maps_missing": [m for m, i in all_maps.items() if not i["exists"]],
            "lab_maps": len(lab_maps),
            "lab_found": sum(1 for l in lab_maps.values() if l["exists"]),
            "unique_artifacts": len(artifact_usage),
            "registered": len(registered),
            "unregistered": sorted(unregistered),
        }
        if args.validate:
            by_grade = {}
            for name, r in results.items():
                g = r["score"].get("grade", "F")
                by_grade.setdefault(g, []).append(name)
            output["validation"] = by_grade
        print(json.dumps(output, indent=2))
        return 0

    # --- Human output ---

    safe_print(f"\n{'='*60}")
    safe_print(f"CURRICULUM PRIORITY REPORT")
    safe_print(f"{'='*60}")

    # Spine
    safe_print(f"\nSPINE ({len(spine_seqs)} sequences):")
    safe_print(f"{'-'*60}")
    for s in spine_seqs:
        name = s["name"]
        maps = load_sequence_maps(name)
        found = sum(1 for m in maps if (MAPS_DIR / m / "map_data.json").is_file())
        phase = s.get("phase", "?")
        safe_print(f"  {s['order']:2d}. {name:<30s} [{phase}] {found}/{len(maps)} maps")

    # Branches
    if not args.spine and not args.lab:
        safe_print(f"\nBRANCHES ({len(branch_seqs)} sequences):")
        safe_print(f"{'-'*60}")
        for name, info in sorted(branch_seqs.items()):
            maps = load_sequence_maps(name)
            found = sum(1 for m in maps if (MAPS_DIR / m / "map_data.json").is_file())
            safe_print(f"  {name:<30s} (from {info['parent']}) {found}/{len(maps)} maps")

    # Lab evolution
    safe_print(f"\nLAB EVOLUTION ({len(lab_maps)} stages):")
    safe_print(f"{'-'*60}")
    for lf, info in lab_maps.items():
        exists = "OK" if info["exists"] else "MISSING"
        added = ", ".join(info["added"]) if info["added"] else "(layout change)"
        safe_print(f"  [{exists}] after {info['after']:<22s} -> {lf}")
        if info["added"]:
            safe_print(f"         adds: {added}")

    # Map totals
    total = len(all_maps)
    found = sum(1 for m in all_maps.values() if m["exists"])
    missing = [m for m, i in all_maps.items() if not i["exists"]]
    safe_print(f"\nMAP TOTALS:")
    safe_print(f"{'-'*60}")
    safe_print(f"  Sequence maps: {found}/{total} found")
    safe_print(f"  Lab maps:      {sum(1 for l in lab_maps.values() if l['exists'])}/{len(lab_maps)} found")
    if missing:
        safe_print(f"\n  MISSING MAPS:")
        for m in missing:
            seqs = all_maps[m]["sequences"]
            safe_print(f"    {m}  (needed by: {', '.join(seqs)})")

    # Artifacts
    safe_print(f"\nARTIFACTS (across curriculum):")
    safe_print(f"{'-'*60}")
    safe_print(f"  Unique artifacts: {len(artifact_usage)}")
    safe_print(f"  In registry:      {len(registered)}")
    safe_print(f"  NOT in registry:  {len(unregistered)}")

    if unregistered and args.artifacts:
        safe_print(f"\n  UNREGISTERED ({len(unregistered)}):")
        for name in sorted(unregistered):
            info = artifact_usage[name]
            maps_list = ", ".join(sorted(info["maps"])[:3])
            if len(info["maps"]) > 3:
                maps_list += f" +{len(info['maps'])-3}"
            safe_print(f"    {name}  ({info['count']}x in: {maps_list})")

    # Validation
    if args.validate:
        safe_print(f"\nVALIDATION:")
        safe_print(f"{'-'*60}")
        by_grade = {"A": [], "B": [], "C": [], "F": []}
        for name, r in results.items():
            g = r["score"].get("grade", "F")
            by_grade.setdefault(g, []).append(name)

        for g in ["A", "B", "C", "F"]:
            count = len(by_grade.get(g, []))
            safe_print(f"  [{g}]: {count}")

        if by_grade.get("F"):
            safe_print(f"\n  GRADE F (broken):")
            for m in by_grade["F"]:
                safe_print(f"    {m}")

    return 0


if __name__ == "__main__":
    sys.exit(main())
