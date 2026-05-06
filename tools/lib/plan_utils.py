"""
plan_utils.py — Shared extraction functions for plan generation.

Aggregates data from artifact registries, GDScript source files,
sequence definitions, and map data to build rich context objects
for artifact and map plan generation.

Reuses battle-tested extraction patterns from:
  - tools/lod_tree_generator.py (registries, GD scanning, sequence parsing)
  - tools/generate_artifact_readmes.py (export/signal/method extraction)
"""

import json
import os
import re
from dataclasses import dataclass, field
from pathlib import Path
from typing import Optional

ROOT = Path(__file__).resolve().parent.parent.parent
SEQUENCES_DIR = ROOT / "commons" / "maps" / "sequences"
MAPS_DIR = ROOT / "commons" / "maps"
REGISTRY_DIR = ROOT / "commons" / "artifacts" / "registry"


# ═══════════════════════════════════════════════════════════════
# JSON / File helpers
# ═══════════════════════════════════════════════════════════════

def load_json(path) -> Optional[dict]:
    """Load a JSON file, return None on failure."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except Exception:
        return None


def read_text(path) -> str:
    """Read a text file, return empty string on failure."""
    try:
        with open(path, "r", encoding="utf-8") as f:
            return f.read()
    except Exception:
        return ""


# ═══════════════════════════════════════════════════════════════
# Registry loading
# ═══════════════════════════════════════════════════════════════

def load_all_registries() -> dict:
    """Load all artifact registry files into a lookup by lookup_name.

    Returns full registry entries (not trimmed) including geometry_spec,
    parameters, dev_themes, map_sequences, etc.
    """
    registry = {}
    if not REGISTRY_DIR.is_dir():
        return registry
    for rpath in sorted(REGISTRY_DIR.glob("*.json")):
        data = load_json(rpath)
        if not data or "artifacts" not in data:
            continue
        for key, art in data["artifacts"].items():
            if not isinstance(art, dict):
                continue
            ln = art.get("lookup_name", key)
            entry = dict(art)  # full copy
            entry["_registry_file"] = rpath.name
            entry["_registry_key"] = key
            if "lookup_name" not in entry:
                entry["lookup_name"] = ln
            registry[ln] = entry
    return registry


# ═══════════════════════════════════════════════════════════════
# GDScript parsing
# ═══════════════════════════════════════════════════════════════

def parse_gdscript(gd_path) -> dict:
    """Extract rich metadata from a GDScript file.

    Returns dict with: class_name, extends, exports, signals, methods,
    identity, dependencies, has_apply_grid_config, grid_config_params,
    line_count, doc_comment, has_process.
    """
    result = {
        "class_name": "",
        "extends": "Node3D",
        "exports": [],
        "signals": [],
        "methods": [],
        "identity": {},
        "dependencies": [],
        "has_apply_grid_config": False,
        "grid_config_params": [],
        "line_count": 0,
        "doc_comment": "",
        "has_process": False,
    }

    content = read_text(gd_path)
    if not content:
        return result

    lines = content.split("\n")
    result["line_count"] = len(lines)

    # class_name
    m = re.search(r"class_name\s+(\w+)", content)
    if m:
        result["class_name"] = m.group(1)

    # extends
    m = re.search(r"^extends\s+(\w+)", content, re.MULTILINE)
    if m:
        result["extends"] = m.group(1)

    # Doc comment (## block at top of file)
    doc_lines = []
    for line in lines:
        stripped = line.strip()
        if stripped.startswith("##"):
            doc_lines.append(stripped[2:].strip())
        elif stripped.startswith("#") and not stripped.startswith("#!"):
            continue  # skip regular comments
        elif stripped == "" or stripped.startswith("extends") or stripped.startswith("class_name"):
            continue
        else:
            break
    result["doc_comment"] = " ".join(doc_lines).strip()

    # @identity block
    identity_fields = [
        "essence", "desire", "critical_parameter", "triggers",
        "emerges", "needs", "relationships", "truth"
    ]
    for field_name in identity_fields:
        pattern = rf"#\s*@?identity\s+{field_name}:\s*(.+)"
        m = re.search(pattern, content, re.IGNORECASE)
        if not m:
            # Also try: # essence: ... (without @identity prefix)
            pattern2 = rf"#\s*{field_name}:\s*(.+)"
            m = re.search(pattern2, content, re.IGNORECASE)
        if m:
            result["identity"][field_name] = m.group(1).strip()

    # @export vars with type and default
    export_re = re.compile(
        r"@export[^\n]*?var\s+(\w+)\s*(?::\s*(\w[\w\[\]]*))?\s*(?:=\s*([^\n#]+))?",
        re.MULTILINE
    )
    for m in export_re.finditer(content):
        result["exports"].append({
            "name": m.group(1),
            "type": (m.group(2) or "").strip(),
            "default": (m.group(3) or "").strip().rstrip(","),
        })

    # Signals
    for m in re.finditer(r"^signal\s+(\w+)", content, re.MULTILINE):
        result["signals"].append(m.group(1))

    # Functions (public + important private)
    for m in re.finditer(r"^func\s+(\w+)\s*\(([^)]*)\)", content, re.MULTILINE):
        fname = m.group(1)
        args = m.group(2).strip()
        # Get doc from next comment line
        pos = m.end()
        after = content[pos:pos + 300]
        doc = ""
        for line in after.split("\n")[0:3]:
            cm = re.search(r"##?\s*(.+)", line)
            if cm:
                doc = cm.group(1).strip()
                break
        result["methods"].append({
            "name": fname,
            "args": args,
            "doc": doc,
        })

    # Dependencies (preload/load)
    for m in re.finditer(r'(?:preload|load)\s*\(\s*"([^"]+)"', content):
        dep = m.group(1)
        if dep not in result["dependencies"]:
            result["dependencies"].append(dep)

    # apply_grid_config
    agc_match = re.search(
        r"func\s+apply_grid_config\s*\([^)]*\)\s*(?:->.*?)?:\s*\n((?:\t[^\n]*\n?)+)",
        content
    )
    if agc_match:
        result["has_apply_grid_config"] = True
        body = agc_match.group(1)
        # Check if stub
        if body.strip() == "pass":
            result["grid_config_params"] = ["(stub)"]
        else:
            # Extract keys from config.has("key"), config.get("key"), config["key"]
            params = set()
            for km in re.finditer(r'(?:has|get)\s*\(\s*"(\w+)"', body):
                params.add(km.group(1))
            for km in re.finditer(r'\["(\w+)"\]', body):
                params.add(km.group(1))
            result["grid_config_params"] = sorted(params)

    # _process presence
    if re.search(r"^func\s+_process\s*\(", content, re.MULTILINE):
        result["has_process"] = True

    return result


def find_gd_file(lookup_name: str, scene_path: str = "") -> Optional[Path]:
    """Try to find the .gd file for an artifact (3-strategy approach)."""
    # Strategy 1: commons/artifacts/<lookup_name>/
    art_dir = ROOT / "commons" / "artifacts" / lookup_name
    if art_dir.is_dir():
        for gf in art_dir.glob("*.gd"):
            if gf.stem == lookup_name:
                return gf
        gd_files = list(art_dir.glob("*.gd"))
        if gd_files:
            return gd_files[0]

    # Strategy 2: Derive from scene path
    if scene_path and scene_path.startswith("res://"):
        rel = scene_path[6:]
        tscn_path = ROOT / rel
        gd_path = tscn_path.with_suffix(".gd")
        if gd_path.is_file():
            return gd_path
        if tscn_path.parent.is_dir():
            for gf in tscn_path.parent.glob("*.gd"):
                if gf.stem == lookup_name or gf.stem == tscn_path.stem:
                    return gf

    # Strategy 3: Broad search
    for search_root in [ROOT / "commons" / "artifacts", ROOT / "algorithms", ROOT / "commons" / "primitives"]:
        candidates = list(search_root.rglob(f"{lookup_name}.gd"))
        if candidates:
            return candidates[0]

    return None


# ═══════════════════════════════════════════════════════════════
# Interactable cell parsing
# ═══════════════════════════════════════════════════════════════

def parse_interactable_cell(cell_str: str) -> tuple:
    """Parse a map interactable cell string.

    Handles:
      "artifact_name"           -> ("artifact_name", "")
      "artifact_name:90:-0.5"   -> ("artifact_name", ":90:-0.5")
      "artifact_name#variant"   -> ("artifact_name", "#variant")
      "clipboard#axioms"        -> ("clipboard", "#axioms")

    Returns (artifact_name, config_suffix).
    """
    cell = cell_str.strip()
    if not cell or cell == " ":
        return ("", "")

    # Handle # variant syntax first
    if "#" in cell:
        base, variant = cell.split("#", 1)
        name = base.split(":")[0].strip()
        config = cell[len(name):]
        return (name, config)

    # Handle : config syntax
    parts = cell.split(":")
    name = parts[0].strip()
    config = ":" + ":".join(parts[1:]) if len(parts) > 1 else ""
    return (name, config)


# ═══════════════════════════════════════════════════════════════
# Sequence scanning
# ═══════════════════════════════════════════════════════════════

def scan_all_sequences() -> dict:
    """Read all sequence JSONs. Returns {seq_id: seq_data}."""
    sequences = {}
    if not SEQUENCES_DIR.is_dir():
        return sequences

    for spath in sorted(SEQUENCES_DIR.glob("*.json")):
        data = load_json(spath)
        if not data or "sequences" not in data:
            continue
        seqs = data["sequences"]
        if not isinstance(seqs, dict):
            continue
        for seq_id, seq in seqs.items():
            if not isinstance(seq, dict):
                continue
            sequences[seq_id] = {
                "name": seq.get("name", seq_id),
                "description": seq.get("description", ""),
                "truth": seq.get("truth", ""),
                "difficulty": seq.get("difficulty", ""),
                "maps": seq.get("maps", []),
                "content": seq.get("content", []),
                "artifact_groups": seq.get("artifact_groups", []),
                "status": seq.get("status", ""),
                "_source_file": spath.name,
            }
    return sequences


def build_sequence_index(sequences: dict) -> dict:
    """Build artifact -> sequence placement index.

    Returns {artifact_name: [{seq_id, seq_name, map_name, position}]}.
    """
    index = {}
    for seq_id, seq in sequences.items():
        for group in seq.get("artifact_groups", []):
            if not isinstance(group, dict):
                continue
            map_name = group.get("map", "")
            for art_name in group.get("artifacts", []):
                if isinstance(art_name, dict):
                    art_name = art_name.get("name", art_name.get("artifact", ""))
                if not art_name:
                    continue
                # Strip config
                clean_name = art_name.split(":")[0].split("#")[0].strip()
                if clean_name not in index:
                    index[clean_name] = []
                index[clean_name].append({
                    "seq_id": seq_id,
                    "seq_name": seq["name"],
                    "map_name": map_name,
                })
    return index


# ═══════════════════════════════════════════════════════════════
# Map scanning
# ═══════════════════════════════════════════════════════════════

def build_map_placement_index() -> dict:
    """Scan all map_data.json files for artifact placements.

    Returns {artifact_name: [{map_name, row, col, raw_cell}]}.
    """
    index = {}
    if not MAPS_DIR.is_dir():
        return index

    for map_dir in sorted(MAPS_DIR.iterdir()):
        md_path = map_dir / "map_data.json"
        if not md_path.is_file():
            continue
        data = load_json(md_path)
        if not data:
            continue

        map_name = map_dir.name
        layers = data.get("layers", {})
        interactables = layers.get("interactables", [])

        for row_idx, row in enumerate(interactables):
            for col_idx, cell in enumerate(row):
                if not isinstance(cell, str):
                    continue
                cell = cell.strip()
                if not cell or cell == " ":
                    continue

                art_name, config = parse_interactable_cell(cell)
                if not art_name or len(art_name) <= 1:
                    continue

                if art_name not in index:
                    index[art_name] = []
                index[art_name].append({
                    "map_name": map_name,
                    "row": row_idx,
                    "col": col_idx,
                    "raw_cell": cell,
                    "config": config,
                })

    return index


def parse_map_data(map_dir: Path) -> Optional[dict]:
    """Parse a map_data.json into a structured context dict."""
    md_path = map_dir / "map_data.json"
    data = load_json(md_path)
    if not data:
        return None

    map_info = data.get("map_info", {})
    metadata = map_info.get("metadata", {})
    layers = data.get("layers", {})
    settings = data.get("settings", {})
    lighting = data.get("lighting", {})

    # Parse layers
    structure = layers.get("structure", [])
    utilities = layers.get("utilities", [])
    interactables = layers.get("interactables", [])

    # Extract utility cells
    util_cells = []
    for row_idx, row in enumerate(utilities):
        for col_idx, cell in enumerate(row):
            if isinstance(cell, str):
                cell = cell.strip()
                if cell and cell != " ":
                    util_cells.append({
                        "row": row_idx,
                        "col": col_idx,
                        "value": cell,
                    })

    # Extract artifact cells
    art_cells = []
    for row_idx, row in enumerate(interactables):
        for col_idx, cell in enumerate(row):
            if isinstance(cell, str):
                cell = cell.strip()
                if cell and cell != " ":
                    name, config = parse_interactable_cell(cell)
                    art_cells.append({
                        "row": row_idx,
                        "col": col_idx,
                        "name": name,
                        "config": config,
                        "raw": cell,
                    })

    dims = map_info.get("dimensions", {})

    return {
        "map_name": map_dir.name,
        "display_name": map_info.get("name", map_dir.name),
        "title": map_info.get("title", ""),
        "description": map_info.get("description", ""),
        "dimensions": dims,
        "difficulty": metadata.get("difficulty", ""),
        "estimated_time": metadata.get("estimated_time", ""),
        "learning_objectives": metadata.get("learning_objectives", []),
        "settings": settings,
        "lighting": lighting,
        "utility_definitions": data.get("utility_definitions", {}),
        "structure_rows": len(structure),
        "structure_cols": len(structure[0]) if structure else 0,
        "utility_cells": util_cells,
        "artifact_cells": art_cells,
    }


def find_sequence_for_map(map_name: str, sequences: dict) -> Optional[dict]:
    """Find which sequence contains a map and its position."""
    for seq_id, seq in sequences.items():
        maps_list = seq.get("maps", [])
        for idx, m in enumerate(maps_list):
            m_name = m if isinstance(m, str) else m.get("name", "")
            if m_name == map_name:
                prev_map = None
                next_map = None
                if idx > 0:
                    pm = maps_list[idx - 1]
                    prev_map = pm if isinstance(pm, str) else pm.get("name", "")
                if idx < len(maps_list) - 1:
                    nm = maps_list[idx + 1]
                    next_map = nm if isinstance(nm, str) else nm.get("name", "")
                return {
                    "seq_id": seq_id,
                    "seq_name": seq["name"],
                    "position": idx,
                    "total_maps": len(maps_list),
                    "prev_map": prev_map,
                    "next_map": next_map,
                }
    return None


# ═══════════════════════════════════════════════════════════════
# Build pattern classifier
# ═══════════════════════════════════════════════════════════════

def classify_build_pattern(gd_info: dict, registry_entry: dict) -> str:
    """Classify artifact build pattern from code + registry hints."""
    scene = registry_entry.get("scene", "")
    deps = gd_info.get("dependencies", [])
    methods = [m["name"] for m in gd_info.get("methods", [])]

    # Check scene path hints
    if "infoboards_3d" in scene or "infoboard" in scene:
        return "infoboard"
    if "clipboard" in scene:
        return "clipboard"

    # Check dependencies
    dep_str = " ".join(deps).lower()
    if "rack_templates" in dep_str or "racktemplates" in dep_str:
        return "rack_templates_panel"
    if "shader" in dep_str or any("shader" in m.lower() for m in methods):
        return "shader_demo"
    if "push_button" in dep_str or "slider" in dep_str:
        return "vr_interactable"

    # Check method names
    method_str = " ".join(methods).lower()
    if "create_panel" in method_str:
        return "rack_templates_panel"

    # Check for procedural mesh indicators
    if any(kw in method_str for kw in ["_build_mesh", "surfacetool", "arraymesh", "_generate"]):
        return "procedural_mesh"

    # Default
    return "procedural"


def relative_path(abs_path) -> str:
    """Convert absolute path to repo-relative path string."""
    try:
        return str(Path(abs_path).relative_to(ROOT)).replace("\\", "/")
    except ValueError:
        return str(abs_path)
