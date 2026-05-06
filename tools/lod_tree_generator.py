#!/usr/bin/env python3
"""
LOD Tree Generator for Ada Research.

Scans the codebase and generates a hierarchical Level-of-Detail tree
at doc/LOD_TREE.json. Each level provides progressively deeper context:

  LOD 0: Project overview (1 sentence)
  LOD 1: Sequences (name + description)
  LOD 2: Maps per sequence (name + description + artifacts)
  LOD 3: Artifacts (name + description + exports + key functions)
  LOD 4: Key functions per artifact (function name + purpose)

Usage:
  python tools/lod_tree_generator.py
  python tools/lod_tree_generator.py --output doc/LOD_TREE.json
"""

import json
import os
import re
import sys
import glob as globmod
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SEQUENCES_DIR = ROOT / "commons" / "maps" / "sequences"
MAPS_DIR = ROOT / "commons" / "maps"
REGISTRY_DIR = ROOT / "commons" / "artifacts" / "registry"
OUTPUT_DEFAULT = ROOT / "doc" / "LOD_TREE.json"


def load_json(path):
    """Load a JSON file, return None on failure."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def scan_all_registries():
    """Load all artifact registry files into a single lookup by lookup_name."""
    registry = {}
    if not REGISTRY_DIR.is_dir():
        return registry
    for rpath in sorted(REGISTRY_DIR.glob("*.json")):
        data = load_json(rpath)
        if not data or "artifacts" not in data:
            continue
        for key, art in data["artifacts"].items():
            if not isinstance(art, dict):
                continue  # skip comment entries like _comment
            ln = art.get("lookup_name", key)
            registry[ln] = {
                "name": art.get("name", ln),
                "description": art.get("description", ""),
                "scene": art.get("scene", ""),
                "category": art.get("category", ""),
                "tags": art.get("tags", []),
                "complexity": art.get("complexity", ""),
                "registry_file": rpath.name,
            }
    return registry


def extract_artifacts_from_map(map_dir):
    """Extract artifact lookup names from a map's interactables layer."""
    md_path = map_dir / "map_data.json"
    data = load_json(md_path)
    if not data:
        return [], None
    layers = data.get("layers", {})
    interactables = layers.get("interactables", [])
    map_info = data.get("map_info", {})

    artifacts = set()
    # Also check floor_plan.json for floor_plan_space maps
    fp_path = map_dir / "floor_plan.json"
    fp_data = load_json(fp_path)
    if fp_data:
        for room in fp_data.get("rooms", []):
            fp = room.get("floor_pattern", "")
            if fp and fp != " ":
                artifacts.add(fp)
            wp = room.get("wall_preset", "")
            if wp and wp != " ":
                artifacts.add(wp)
            for item in room.get("exhibits", []):
                if isinstance(item, str) and item.strip():
                    artifacts.add(item.strip())
                elif isinstance(item, dict):
                    a = item.get("artifact", "")
                    if a:
                        artifacts.add(a)

    for row in interactables:
        for cell in row:
            if isinstance(cell, str):
                cell = cell.strip()
                if cell and cell != " ":
                    # Handle config syntax: artifact_name{...} or artifact_name
                    name = cell.split("{")[0].split(":")[0].strip()
                    if name and not name.startswith("@") and len(name) > 1:
                        artifacts.add(name)

    return sorted(artifacts), map_info


def scan_gd_file(gd_path):
    """Extract exports, key functions, class_name, and identity from a .gd file."""
    result = {
        "class_name": "",
        "exports": [],
        "key_functions": {},
        "identity_essence": "",
    }
    try:
        with open(gd_path, "r", encoding="utf-8") as f:
            content = f.read()
    except Exception:
        return result

    # class_name
    m = re.search(r"class_name\s+(\w+)", content)
    if m:
        result["class_name"] = m.group(1)

    # @identity essence
    m = re.search(r"#\s*essence:\s*(.+)", content)
    if m:
        result["identity_essence"] = m.group(1).strip()

    # @export vars
    for m in re.finditer(r"@export[^\n]*var\s+(\w+)", content):
        result["exports"].append(m.group(1))

    # Functions (skip private helpers, keep public and _build/_ready etc)
    for m in re.finditer(r"^func\s+(\w+)\s*\(", content, re.MULTILINE):
        fname = m.group(1)
        # Skip trivial getters/setters
        if fname in ("_ready", "_process", "_physics_process", "_input"):
            continue
        # Get the docstring or first comment line after func
        pos = m.end()
        # Look for comment on same line or next lines
        after = content[pos:pos + 300]
        doc = ""
        # Check for inline comment
        lines = after.split("\n")
        for line in lines[0:3]:
            cm = re.search(r"#\s*(.+)", line)
            if cm:
                doc = cm.group(1).strip()
                break
        result["key_functions"][fname] = doc

    # Limit to 10 most important functions to keep size down
    if len(result["key_functions"]) > 10:
        # Prioritize _build, apply_grid_config, and non-underscore funcs
        fns = result["key_functions"]
        priority = {}
        for k, v in fns.items():
            if k in ("apply_grid_config", "_build"):
                priority[k] = v
            elif not k.startswith("_"):
                priority[k] = v
        # Fill remaining from _ funcs
        for k, v in fns.items():
            if k not in priority and len(priority) < 10:
                priority[k] = v
        result["key_functions"] = priority

    return result


def find_gd_file_for_artifact(lookup_name, scene_path=""):
    """Try to find the .gd file for an artifact."""
    # Strategy 1: Look in commons/artifacts/<lookup_name>/
    art_dir = ROOT / "commons" / "artifacts" / lookup_name
    if art_dir.is_dir():
        gd_files = list(art_dir.glob("*.gd"))
        # Prefer the one matching the lookup name
        for gf in gd_files:
            if gf.stem == lookup_name:
                return gf
        if gd_files:
            return gd_files[0]

    # Strategy 2: Use scene path to find .gd
    if scene_path and scene_path.startswith("res://"):
        rel = scene_path[6:]  # strip res://
        tscn_path = ROOT / rel
        gd_path = tscn_path.with_suffix(".gd")
        if gd_path.is_file():
            return gd_path
        # Try same directory, matching name
        if tscn_path.parent.is_dir():
            for gf in tscn_path.parent.glob("*.gd"):
                if gf.stem == lookup_name or gf.stem == tscn_path.stem:
                    return gf

    # Strategy 3: Broad search (limited)
    candidates = list((ROOT / "commons" / "artifacts").rglob(f"{lookup_name}.gd"))
    if candidates:
        return candidates[0]
    candidates = list((ROOT / "algorithms").rglob(f"{lookup_name}.gd"))
    if candidates:
        return candidates[0]

    return None


def scan_sequences():
    """Read all sequence JSONs, extract structured data."""
    sequences = {}
    if not SEQUENCES_DIR.is_dir():
        return sequences

    for spath in sorted(SEQUENCES_DIR.glob("*.json")):
        data = load_json(spath)
        if not data or "sequences" not in data:
            continue
        seqs = data["sequences"]
        if not isinstance(seqs, dict):
            continue  # skip index files with list format
        for seq_id, seq in seqs.items():
            maps_list = seq.get("maps", [])
            content_list = seq.get("content", [])

            # Build content descriptions map: "MapName: Description"
            content_descs = {}
            for entry in content_list:
                if ":" in entry:
                    name, desc = entry.split(":", 1)
                    content_descs[name.strip()] = desc.strip()

            sequences[seq_id] = {
                "name": seq.get("name", seq_id),
                "description": seq.get("description", ""),
                "truth": seq.get("truth", ""),
                "layer": seq.get("layer", ""),
                "difficulty": seq.get("difficulty", ""),
                "maps": maps_list,
                "content_descriptions": content_descs,
                "prerequisites": seq.get("prerequisites", []),
                "unlocks": seq.get("unlocks", []),
            }
    return sequences


def build_map_node(map_name, content_desc, artifact_registry):
    """Build LOD 2 node for a single map."""
    map_dir = MAPS_DIR / map_name
    artifacts_in_map, map_info = extract_artifacts_from_map(map_dir)

    # Get dimensions
    dims = ""
    if map_info:
        d = map_info.get("dimensions", {})
        if d:
            dims = f"{d.get('width', '?')}x{d.get('depth', '?')}"

    node = {
        "id": map_name,
        "lod2": content_desc or f"Map: {map_name}",
    }
    if dims:
        node["dimensions"] = dims
    if artifacts_in_map:
        node["artifacts"] = artifacts_in_map

    return node


def build_artifact_node(lookup_name, artifact_registry, deep_scan=False):
    """Build LOD 3/4 node for an artifact."""
    reg = artifact_registry.get(lookup_name, {})
    desc = reg.get("description", "")

    # Truncate description to 120 chars to keep tree compact
    short_desc = desc[:120].rstrip() if desc else f"Artifact: {lookup_name}"
    if len(desc) > 120:
        short_desc += "..."

    node = {
        "id": lookup_name,
        "lod3": short_desc,
    }
    cat = reg.get("category", "")
    if cat:
        node["category"] = cat

    if deep_scan:
        scene = reg.get("scene", "")
        gd_path = find_gd_file_for_artifact(lookup_name, scene)
        if gd_path:
            is_commons = "commons" in str(gd_path) and "artifacts" in str(gd_path)
            rel_path = str(gd_path.relative_to(ROOT)).replace("\\", "/")
            node["file"] = rel_path

            # Only do expensive scan for commons/artifacts (procedural ones)
            if is_commons:
                gd_info = scan_gd_file(gd_path)
                if gd_info["class_name"]:
                    node["class_name"] = gd_info["class_name"]
                if gd_info["exports"]:
                    node["exports"] = gd_info["exports"][:6]
                if gd_info["key_functions"]:
                    fns = dict(list(gd_info["key_functions"].items())[:5])
                    node["lod4"] = fns
                if gd_info["identity_essence"]:
                    node["essence"] = gd_info["identity_essence"]

    return node


def build_lod_tree(deep_scan_artifacts=True):
    """Assemble the full LOD tree from the codebase."""
    print("Scanning artifact registries...")
    artifact_registry = scan_all_registries()
    print(f"  Found {len(artifact_registry)} artifacts in registry")

    print("Scanning sequences...")
    sequences = scan_sequences()
    print(f"  Found {len(sequences)} sequences")

    # Count maps
    all_maps = set()
    for seq in sequences.values():
        all_maps.update(seq["maps"])

    # Also count maps that exist on disk but aren't in any sequence
    disk_maps = set()
    if MAPS_DIR.is_dir():
        for d in MAPS_DIR.iterdir():
            if d.is_dir() and (d / "map_data.json").is_file():
                disk_maps.add(d.name)

    orphan_maps = disk_maps - all_maps

    print(f"  {len(all_maps)} maps in sequences, {len(orphan_maps)} orphan maps on disk")

    # Build tree
    tree = {
        "meta": {
            "generated": str(Path(__file__).name),
            "version": "1.0",
            "description": "Level-of-Detail tree for Ada Research. Use tools/lod_query.py to navigate.",
        },
        "lod0": {
            "summary": (
                "Ada Research: a Godot 4 VR/desktop game teaching algorithms "
                "through interactive 3D spaces. QFEP (Queer Feminist Enactivist "
                "Pedagogy) framework. Content chain: Sequence -> Map -> Artifact."
            ),
            "stats": {
                "sequences": len(sequences),
                "maps_in_sequences": len(all_maps),
                "maps_on_disk": len(disk_maps),
                "artifacts_registered": len(artifact_registry),
            },
            "key_paths": {
                "sequences": "commons/maps/sequences/*.json",
                "maps": "commons/maps/<MapName>/map_data.json",
                "registries": "commons/artifacts/registry/*.json",
                "grid_system": "commons/grid/GridSystem.gd",
                "curriculum": "commons/maps/curriculum_spine.json",
            },
            "children": [],
        },
    }

    # Collect all artifacts referenced across all maps for deep scan decisions
    heavily_used = set()

    # Build sequence nodes (LOD 1)
    for seq_id in sorted(sequences.keys()):
        seq = sequences[seq_id]
        print(f"  Processing sequence: {seq_id} ({len(seq['maps'])} maps)")

        seq_node = {
            "id": seq_id,
            "lod1": f"{seq['name']}: {seq['description'][:150]}",
            "truth": seq.get("truth", ""),
            "layer": seq.get("layer", ""),
            "difficulty": seq.get("difficulty", ""),
            "map_count": len(seq["maps"]),
            "prerequisites": seq.get("prerequisites", []),
            "unlocks": seq.get("unlocks", []),
            "children": [],
        }

        # Build map nodes (LOD 2)
        seq_artifacts = set()
        for map_name in seq["maps"]:
            content_desc = seq["content_descriptions"].get(map_name, "")
            map_node = build_map_node(map_name, content_desc, artifact_registry)
            seq_node["children"].append(map_node)
            if "artifacts" in map_node:
                seq_artifacts.update(map_node["artifacts"])

        # Build artifact detail nodes (LOD 3/4) for this sequence
        # Deep scan artifacts that are in commons/artifacts (procedural ones)
        artifact_children = []
        for art_name in sorted(seq_artifacts):
            if art_name in artifact_registry:
                heavily_used.add(art_name)
                do_deep = deep_scan_artifacts
                art_node = build_artifact_node(art_name, artifact_registry, deep_scan=do_deep)
                artifact_children.append(art_node)

        if artifact_children:
            seq_node["artifact_details"] = artifact_children

        tree["lod0"]["children"].append(seq_node)

    # Add orphan maps as a compact list (no artifact scanning to save space)
    if orphan_maps:
        orphan_node = {
            "id": "_orphan_maps",
            "lod1": f"Orphan Maps: {len(orphan_maps)} maps on disk not assigned to any sequence.",
            "map_count": len(orphan_maps),
            "map_names": sorted(orphan_maps),
        }
        tree["lod0"]["children"].append(orphan_node)

    # Count unplaced artifacts (registered but not found in any scanned map)
    unplaced = set(artifact_registry.keys()) - heavily_used
    if unplaced:
        tree["lod0"]["unplaced_artifact_count"] = len(unplaced)

    return tree


def main():
    import argparse

    parser = argparse.ArgumentParser(description="Generate LOD tree for Ada Research")
    parser.add_argument(
        "--output", "-o",
        default=str(OUTPUT_DEFAULT),
        help="Output path for LOD_TREE.json",
    )
    parser.add_argument(
        "--no-deep-scan",
        action="store_true",
        help="Skip scanning .gd files for exports/functions (faster)",
    )
    args = parser.parse_args()

    output_path = Path(args.output)
    output_path.parent.mkdir(parents=True, exist_ok=True)

    tree = build_lod_tree(deep_scan_artifacts=not args.no_deep_scan)

    # Check size
    raw = json.dumps(tree, indent=2, ensure_ascii=False)
    size_kb = len(raw.encode("utf-8")) / 1024

    print(f"\nTree size: {size_kb:.0f} KB")
    if size_kb > 500:
        print("WARNING: Tree exceeds 500KB target. Consider --no-deep-scan.")

    with open(output_path, "w", encoding="utf-8") as f:
        f.write(raw)

    print(f"Written to: {output_path}")

    # Print summary
    stats = tree["lod0"]["stats"]
    print(f"\nSummary:")
    print(f"  Sequences: {stats['sequences']}")
    print(f"  Maps in sequences: {stats['maps_in_sequences']}")
    print(f"  Maps on disk: {stats['maps_on_disk']}")
    print(f"  Artifacts registered: {stats['artifacts_registered']}")
    seq_count = len([c for c in tree["lod0"]["children"] if c["id"] != "_orphan_maps"])
    print(f"  Sequence nodes built: {seq_count}")


if __name__ == "__main__":
    main()
