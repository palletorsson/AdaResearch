#!/usr/bin/env python3
"""
validate_map.py — AdaResearch map_data.json validator.

Checks structure (voxel grammar), utilities (syntax), and interactables (directionality).
See doc/MAP_QUALITY_SYSTEM.md for the full reference.
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"
REGISTRY_DIR = REPO / "commons" / "artifacts" / "registry"
# Legacy registry deprecated — all entries now in REGISTRY_DIR
GRAMMAR_FILE = REPO / "grammar" / "grammar_structue.json"
SEQUENCES_DIR = MAPS_DIR / "sequences"

# Maps where interactables/utilities intentionally exceed structure dimensions
# (e.g. artifacts bigger than the grid)
DIMENSION_EXCEPTIONS = {"Noise_Voxel", "Random_Definition"}

# Team policy (default):
# - Spawn safety is map-design specific and should not fail validation.
# - Artifacts on void are allowed for floating/staged compositions.
# These can still be enforced ad hoc via CLI flags.
ENFORCE_SPAWN_SAFE = False
ENFORCE_NO_ARTIFACTS_ON_VOID = False

# ---------------------------------------------------------------------------
# Registry loader
# ---------------------------------------------------------------------------

_artifact_keys: set | None = None


def load_artifact_keys() -> set:
    global _artifact_keys
    if _artifact_keys is not None:
        return _artifact_keys

    keys = set()

    # New registry files (commons/artifacts/registry/*.json)
    if REGISTRY_DIR.is_dir():
        for f in REGISTRY_DIR.glob("*.json"):
            try:
                data = json.loads(f.read_text(encoding="utf-8"))
                if isinstance(data, dict):
                    artifacts = data.get("artifacts", {})
                    if isinstance(artifacts, dict):
                        # Format: {"artifacts": {"name": {...}}}
                        keys.update(artifacts.keys())
                    elif isinstance(artifacts, list):
                        # Format: {"artifacts": [{"key_id": "name"}]}
                        for art in artifacts:
                            if isinstance(art, dict) and "key_id" in art:
                                keys.add(art["key_id"])
            except Exception:
                pass

    _artifact_keys = keys
    return keys


# ---------------------------------------------------------------------------
# Grammar loader
# ---------------------------------------------------------------------------

_grammar_composites: list | None = None


def load_grammar_composites() -> list:
    """Load composite patterns from grammar_structue.json."""
    global _grammar_composites
    if _grammar_composites is not None:
        return _grammar_composites

    composites = []
    if GRAMMAR_FILE.is_file():
        try:
            data = json.loads(GRAMMAR_FILE.read_text(encoding="utf-8"))
            for elem in data.get("elements", []):
                sample = elem.get("sample", {})
                pattern = sample.get("pattern")
                if pattern and isinstance(pattern, list):
                    composites.append({
                        "id": elem.get("id", ""),
                        "name": elem.get("name", ""),
                        "category": elem.get("category", ""),
                        "pattern": pattern,
                    })
        except Exception:
            pass

    _grammar_composites = composites
    return composites


# ---------------------------------------------------------------------------
# Parsing helpers
# ---------------------------------------------------------------------------

def parse_artifact_cell(cell: str) -> dict | None:
    """Parse 'name:rot:y:scale' or 'name#config...:rot:y:scale'."""
    cell = cell.strip()
    if not cell or cell == " ":
        return None

    # Split off #config part
    config = ""
    if "#" in cell:
        base, config = cell.split("#", 1)
        # config might contain more colons; re-join if needed
        # Actually the format is name#config:rot:y:scale
        # We need to be careful — config can have colons too
        # Strategy: split from the RIGHT for up to 3 numeric params
        parts = config.rsplit(":", 3)
        # Check how many trailing parts are numeric
        numeric_tail = []
        non_numeric = parts[:]
        while non_numeric and _is_numeric(non_numeric[-1]):
            numeric_tail.insert(0, non_numeric.pop())
        config = ":".join(non_numeric)
        cell = base + ":" + ":".join(numeric_tail) if numeric_tail else base
    
    parts = cell.split(":")
    name = parts[0]
    rotation = float(parts[1]) if len(parts) > 1 and _is_numeric(parts[1]) else 0.0
    y_offset = float(parts[2]) if len(parts) > 2 and _is_numeric(parts[2]) else 0.0
    scale = float(parts[3]) if len(parts) > 3 and _is_numeric(parts[3]) else 1.0

    return {
        "name": name,
        "rotation": rotation,
        "y_offset": y_offset,
        "scale": scale,
        "config": config,
    }


def _is_numeric(s: str) -> bool:
    try:
        float(s)
        return True
    except (ValueError, TypeError):
        return False


def cell_height(val) -> int:
    """Convert structure cell to integer height."""
    try:
        return int(val)
    except (ValueError, TypeError):
        return 0


# ---------------------------------------------------------------------------
# Footprint classification
# ---------------------------------------------------------------------------

# Keywords that suggest directionality
CONE_KEYWORDS = {"shader_", "mandelbrot_dive", "julia_set_explorer", "cctv",
                 "graphics_monitor", "graphics_slideshow_2d", "rorschach_monitor",
                 "perlin_terrain_sculptor"}
HALF_CIRCLE_KEYWORDS = {"display", "monitor", "clipboard", "info_display",
                        "code_display", "infokiosk", "plaque", "gallery",
                        "ca_rule_explorer", "bias_visualizer", "game_of_life_petri",
                        "turing_pattern_generator", "lsystem_editor", "algorithm_overview",
                        "monitorsystem", "godel_statement_plaque"}
CORRIDOR_KEYWORDS = {"bifurcation_walkway", "boolean_tunnel", "hallway_scene",
                     "maze_generation", "maze_generator", "lsystem_dungeon",
                     "mondrian_run", "rhizome_cave_system", "knowledge_terrain_space"}
AMBIENT_KEYWORDS = {"dark_sphere", "env_one", "light_sphere", "tesla_sparks",
                    "rainbow", "disco_floor", "standalone_disco"}
FULL_CIRCLE_KEYWORDS = {"grab_", "pick_up_", "pickup_", "jelly_", "vector_",
                        "Pendulum", "platonic", "cube", "sphere", "torus",
                        "pyramid", "octahedron", "dodecahedron", "icosahedron",
                        "tetrahedron", "snap_"}


def classify_footprint(name: str) -> str:
    """Classify artifact footprint: full_circle, half_circle, cone, corridor, ambient."""
    low = name.lower()

    for kw in AMBIENT_KEYWORDS:
        if kw in low:
            return "ambient"
    for kw in CORRIDOR_KEYWORDS:
        if kw in low:
            return "corridor"
    for kw in CONE_KEYWORDS:
        if kw in low:
            return "cone"
    for kw in HALF_CIRCLE_KEYWORDS:
        if kw in low:
            return "half_circle"
    for kw in FULL_CIRCLE_KEYWORDS:
        if kw in low:
            return "full_circle"

    # Default: half_circle for observe-type, full_circle otherwise
    return "full_circle"


# ---------------------------------------------------------------------------
# Directional helpers
# ---------------------------------------------------------------------------

def rotation_to_facing(rot: float) -> tuple[int, int]:
    """Return (drow, dcol) for the direction the artifact faces."""
    r = int(rot) % 360
    if r < 45 or r >= 315:
        return (1, 0)    # faces South (+row)
    elif r < 135:
        return (0, -1)   # faces West (-col)
    elif r < 225:
        return (-1, 0)   # faces North (-row)
    else:
        return (0, 1)    # faces East (+col)


# ---------------------------------------------------------------------------
# Validation
# ---------------------------------------------------------------------------

def validate_map(path: Path) -> dict:
    """Validate a single map_data.json. Returns scorecard dict."""
    result = {
        "map": path.parent.name,
        "path": str(path.relative_to(REPO)),
        "checks": {},
        "grammar": {},
        "directionality": {"artifact_count": 0, "warnings": [], "errors": []},
        "score": {},
    }
    checks = result["checks"]

    # 1. JSON valid
    try:
        raw = path.read_text(encoding="utf-8")
        data = json.loads(raw)
        checks["json_valid"] = True
    except Exception as e:
        checks["json_valid"] = False
        checks["json_error"] = str(e)
        result["score"] = {"mechanical": 0, "total_warnings": 0, "total_errors": 1, "grade": "F"}
        return result

    # 2. Required fields
    has_map_info = "map_info" in data
    has_layers = "layers" in data
    has_structure = has_layers and "structure" in data.get("layers", {})
    has_utilities = has_layers and "utilities" in data.get("layers", {})
    checks["has_required_fields"] = has_map_info and has_structure and has_utilities
    if not has_structure:
        result["score"] = {"mechanical": 1, "total_warnings": 0, "total_errors": 1, "grade": "F"}
        return result

    layers = data["layers"]
    structure = layers["structure"]
    utilities = layers.get("utilities", [])
    interactables = layers.get("interactables", [])

    # 3. Dimensions consistent
    struct_rows = len(structure)
    struct_cols = [len(r) for r in structure] if structure else [0]
    util_rows = len(utilities)
    inter_rows = len(interactables)

    dims_ok = True
    dim_issues = []
    map_name = path.parent.name

    if map_name not in DIMENSION_EXCEPTIONS:
        if utilities and util_rows != struct_rows:
            dims_ok = False
            dim_issues.append(f"structure has {struct_rows} rows, utilities has {util_rows}")
        if interactables and inter_rows != struct_rows:
            dims_ok = False
            dim_issues.append(f"structure has {struct_rows} rows, interactables has {inter_rows}")

    checks["dimensions_consistent"] = {"pass": dims_ok, "issues": dim_issues}

    # 4. Spawn safety
    spawn_safe = True
    has_spawn_override = False

    # Check for s: or m: utility that overrides spawn
    for row in utilities:
        for cell in row:
            c = str(cell).strip()
            if c.startswith("s:") or c == "s" or c.startswith("m:") or c == "m":
                has_spawn_override = True

    if not has_spawn_override:
        # Check 2x2 at [0,0]
        for r in range(min(2, struct_rows)):
            row = structure[r]
            for c in range(min(2, len(row))):
                if cell_height(row[c]) != 1:
                    spawn_safe = False
    
    spawn_safe_pass = spawn_safe or has_spawn_override
    checks["spawn_safe"] = spawn_safe_pass if ENFORCE_SPAWN_SAFE else True

    # 5. Has teleporter
    has_teleporter = False
    for row in utilities:
        for cell in row:
            c = str(cell).strip()
            if c == "t" or c.startswith("t:"):
                has_teleporter = True
                break

    checks["has_teleporter"] = has_teleporter

    # 6. No lifts
    has_lift = False
    for row in utilities:
        for cell in row:
            c = str(cell).strip()
            if c == "l" or c.startswith("l:"):
                has_lift = True

    checks["no_lifts"] = not has_lift

    # 7. Artifacts in registry
    registry = load_artifact_keys()
    missing_artifacts = []
    artifact_cells = []

    for z, row in enumerate(interactables):
        for x, cell in enumerate(row):
            c = str(cell).strip()
            if not c or c == " ":
                continue
            parsed = parse_artifact_cell(c)
            if parsed:
                artifact_cells.append((x, z, parsed))
                if parsed["name"] not in registry:
                    missing_artifacts.append(parsed["name"])

    checks["artifacts_in_registry"] = {
        "pass": len(missing_artifacts) == 0,
        "missing": list(set(missing_artifacts)),
    }

    # 8. No artifacts on void
    void_violations = []
    for x, z, parsed in artifact_cells:
        if z < len(structure) and x < len(structure[z]):
            h = cell_height(structure[z][x])
            if h == 0:
                void_violations.append(f"{parsed['name']} at ({x},{z}) on void")

    checks["no_artifacts_on_void"] = {
        "pass": len(void_violations) == 0 if ENFORCE_NO_ARTIFACTS_ON_VOID else True,
        "violations": void_violations,
    }

    # --- Grammar analysis ---
    cell_counts = {"void": 0, "floor": 0, "platform": 0, "wall": 0, "high": 0}
    all_heights = []
    total_cells = 0

    for row in structure:
        for cell in row:
            h = cell_height(cell)
            all_heights.append(h)
            total_cells += 1
            if h == 0:
                cell_counts["void"] += 1
            elif h == 1:
                cell_counts["floor"] += 1
            elif h == 2:
                cell_counts["platform"] += 1
            elif h == 3:
                cell_counts["wall"] += 1
            elif h >= 4:
                cell_counts["high"] += 1

    height_range = [min(all_heights), max(all_heights)] if all_heights else [0, 0]

    # Temperature estimation
    temp = 0.0
    if total_cells > 0:
        non_floor_ratio = 1 - (cell_counts["floor"] / total_cells)
        height_spread = height_range[1] - height_range[0]
        void_ratio = cell_counts["void"] / total_cells

        temp = min(1.0, (
            non_floor_ratio * 0.4 +
            min(height_spread / 5.0, 1.0) * 0.3 +
            void_ratio * 0.3
        ))

    # Size class
    if total_cells <= 25:
        size_class = "intimate"
    elif total_cells <= 80:
        size_class = "gallery"
    else:
        size_class = "immersive"

    result["grammar"] = {
        "cell_counts": cell_counts,
        "height_range": height_range,
        "temperature": round(temp, 2),
        "size_class": size_class,
        "total_cells": total_cells,
    }

    # --- Directionality checks ---
    dir_warnings = []
    dir_errors = []

    for x, z, parsed in artifact_cells:
        footprint = classify_footprint(parsed["name"])
        
        if footprint == "ambient":
            continue

        # Check surrounding cells
        if z < len(structure) and x < len(structure[z]):
            neighbors = {}
            for label, dx, dz in [("N", 0, -1), ("S", 0, 1), ("W", -1, 0), ("E", 1, 0)]:
                nz, nx = z + dz, x + dx
                if 0 <= nz < len(structure) and 0 <= nx < len(structure[nz]):
                    neighbors[label] = cell_height(structure[nz][nx])
                else:
                    neighbors[label] = -1  # out of bounds

            if footprint == "full_circle":
                walls = [d for d, h in neighbors.items() if h >= 3]
                if walls:
                    dir_warnings.append(
                        f"{parsed['name']} at ({x},{z}): full-circle artifact has wall neighbors {walls}"
                    )

            elif footprint == "half_circle":
                dr, dc = rotation_to_facing(parsed["rotation"])
                # Front should be clear
                front_z, front_x = z + dr, x + dc
                if 0 <= front_z < len(structure) and 0 <= front_x < len(structure[front_z]):
                    front_h = cell_height(structure[front_z][front_x])
                    if front_h >= 3:
                        dir_warnings.append(
                            f"{parsed['name']} at ({x},{z}): half-circle faces wall (rot:{parsed['rotation']})"
                        )

            elif footprint == "cone":
                dr, dc = rotation_to_facing(parsed["rotation"])
                # Check 2 cells in viewing direction
                for dist in range(1, 3):
                    check_z, check_x = z + dr * dist, x + dc * dist
                    if 0 <= check_z < len(structure) and 0 <= check_x < len(structure[check_z]):
                        h = cell_height(structure[check_z][check_x])
                        if h >= 3:
                            dir_warnings.append(
                                f"{parsed['name']} at ({x},{z}): cone viewing blocked at distance {dist}"
                            )
                            break

    result["directionality"] = {
        "artifact_count": len(artifact_cells),
        "warnings": dir_warnings,
        "errors": dir_errors,
    }

    # --- Score ---
    mechanical_checks = [
        checks.get("json_valid", False),
        checks.get("has_required_fields", False),
        checks.get("dimensions_consistent", {}).get("pass", False) if isinstance(checks.get("dimensions_consistent"), dict) else checks.get("dimensions_consistent", False),
        checks.get("spawn_safe", False),
        checks.get("has_teleporter", False),
        checks.get("no_lifts", True),
        checks.get("artifacts_in_registry", {}).get("pass", False) if isinstance(checks.get("artifacts_in_registry"), dict) else True,
        checks.get("no_artifacts_on_void", {}).get("pass", False) if isinstance(checks.get("no_artifacts_on_void"), dict) else True,
    ]
    mechanical_pass = sum(1 for c in mechanical_checks if c)
    total_errors = sum(1 for c in mechanical_checks if not c)
    total_warnings = len(dir_warnings)

    if total_errors == 0:
        grade = "A" if total_warnings == 0 else "B"
    elif total_errors <= 2:
        grade = "C"
    else:
        grade = "F"

    result["score"] = {
        "mechanical": mechanical_pass,
        "mechanical_total": len(mechanical_checks),
        "total_warnings": total_warnings,
        "total_errors": total_errors,
        "grade": grade,
    }

    return result


# ---------------------------------------------------------------------------
# Map discovery
# ---------------------------------------------------------------------------

def find_all_maps() -> list[Path]:
    """Find all map_data.json files."""
    maps = []
    if MAPS_DIR.is_dir():
        for md in sorted(MAPS_DIR.rglob("map_data.json")):
            # Skip post_* lab progression maps and sequence files
            if "sequences" in md.parts:
                continue
            maps.append(md)
    return maps


def find_sequence_maps(sequence_name: str) -> list[Path]:
    """Find maps belonging to a sequence."""
    seq_file = SEQUENCES_DIR / f"{sequence_name}.json"
    if not seq_file.is_file():
        print(f"Sequence file not found: {seq_file}", file=sys.stderr)
        return []

    try:
        data = json.loads(seq_file.read_text(encoding="utf-8"))
    except Exception as e:
        print(f"Error reading sequence: {e}", file=sys.stderr)
        return []

    maps = []
    # Sequence format: {"sequences": {"id": {"maps": [...]}}}
    seqs = data.get("sequences", {})
    if isinstance(seqs, dict) and sequence_name in seqs:
        map_list = seqs[sequence_name].get("maps", [])
    else:
        map_list = data.get("maps", data.get("sequence", []))
    if isinstance(map_list, list):
        for entry in map_list:
            name = entry if isinstance(entry, str) else entry.get("map", entry.get("name", ""))
            if name:
                md = MAPS_DIR / name / "map_data.json"
                if md.is_file():
                    maps.append(md)

    return maps


# ---------------------------------------------------------------------------
# Output
# ---------------------------------------------------------------------------

def safe_print(text: str):
    """Print with fallback for Windows cp1252."""
    try:
        print(text)
    except UnicodeEncodeError:
        print(text.encode("ascii", "replace").decode("ascii"))


def print_result(result: dict, verbose: bool = True):
    """Print human-readable result."""
    grade = result["score"].get("grade", "?")
    name = result["map"]
    mech = result["score"].get("mechanical", 0)
    mech_total = result["score"].get("mechanical_total", 8)
    warns = result["score"].get("total_warnings", 0)
    errs = result["score"].get("total_errors", 0)

    grade_icon = {"A": "OK", "B": "!!", "C": "XX", "F": "##"}.get(grade, "??")
    safe_print(f"{grade_icon} [{grade}] {name}  ({mech}/{mech_total} checks, {warns} warnings, {errs} errors)")

    if not verbose:
        return

    checks = result.get("checks", {})
    for key, val in checks.items():
        if isinstance(val, dict):
            ok = val.get("pass", True)
            if not ok:
                detail = val.get("missing", val.get("violations", val.get("issues", [])))
                safe_print(f"    FAIL {key}: {detail}")
        elif val is False:
            safe_print(f"    FAIL {key}")

    for w in result.get("directionality", {}).get("warnings", []):
        safe_print(f"    WARN {w}")

    gram = result.get("grammar", {})
    if gram:
        safe_print(f"    Grammar: temp={gram.get('temperature', '?')} size={gram.get('size_class', '?')} "
                   f"cells={gram.get('total_cells', '?')} heights={gram.get('height_range', '?')}")


def print_summary(results: list[dict]):
    """Print summary across all results."""
    total = len(results)
    by_grade = {"A": 0, "B": 0, "C": 0, "F": 0}
    issue_counts = {}

    for r in results:
        grade = r["score"].get("grade", "F")
        by_grade[grade] = by_grade.get(grade, 0) + 1

        checks = r.get("checks", {})
        for key, val in checks.items():
            if isinstance(val, dict) and not val.get("pass", True):
                issue_counts[key] = issue_counts.get(key, 0) + 1
            elif val is False:
                issue_counts[key] = issue_counts.get(key, 0) + 1

    safe_print(f"\n{'='*50}")
    safe_print(f"MAP VALIDATION SUMMARY")
    safe_print(f"{'='*50}")
    safe_print(f"Total maps: {total}")
    safe_print(f"  [A] Grade A (no issues):     {by_grade.get('A', 0)}")
    safe_print(f"  [B] Grade B (warnings only): {by_grade.get('B', 0)}")
    safe_print(f"  [C] Grade C (1-2 errors):    {by_grade.get('C', 0)}")
    safe_print(f"  [F] Grade F (3+ errors):     {by_grade.get('F', 0)}")

    if issue_counts:
        safe_print(f"\nTop issues:")
        for issue, count in sorted(issue_counts.items(), key=lambda x: -x[1]):
            safe_print(f"  {issue}: {count} maps")


# ---------------------------------------------------------------------------
# CLI
# ---------------------------------------------------------------------------

def main():
    parser = argparse.ArgumentParser(description="Validate AdaResearch map_data.json files")
    parser.add_argument("path", nargs="?", help="Path to a single map_data.json")
    parser.add_argument("--all", action="store_true", help="Validate all maps")
    parser.add_argument("--sequence", help="Validate maps in a sequence")
    parser.add_argument("--summary", action="store_true", help="Show only summary")
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    parser.add_argument("--verbose", "-v", action="store_true", help="Show all details")
    parser.add_argument("--grade", help="Filter by grade (A/B/C/F)")
    parser.add_argument(
        "--enforce-spawn-safe",
        action="store_true",
        help="Treat spawn safety as a failing check (disabled by default)",
    )
    parser.add_argument(
        "--enforce-no-artifacts-on-void",
        action="store_true",
        help="Treat artifacts on void cells as a failing check (disabled by default)",
    )

    args = parser.parse_args()

    if not args.path and not args.all and not args.sequence:
        parser.print_help()
        return 1

    global ENFORCE_SPAWN_SAFE, ENFORCE_NO_ARTIFACTS_ON_VOID
    ENFORCE_SPAWN_SAFE = args.enforce_spawn_safe
    ENFORCE_NO_ARTIFACTS_ON_VOID = args.enforce_no_artifacts_on_void

    # Collect maps
    if args.all:
        maps = find_all_maps()
    elif args.sequence:
        maps = find_sequence_maps(args.sequence)
    else:
        p = Path(args.path)
        if not p.is_absolute():
            p = REPO / p
        if not p.is_file():
            print(f"File not found: {p}", file=sys.stderr)
            return 1
        maps = [p]

    if not maps:
        print("No maps found.", file=sys.stderr)
        return 1

    # Validate
    results = [validate_map(m) for m in maps]

    # Filter by grade
    if args.grade:
        results = [r for r in results if r["score"].get("grade") == args.grade.upper()]

    # Output
    if args.json:
        print(json.dumps(results, indent=2))
    elif args.summary:
        print_summary(results)
    else:
        for r in results:
            print_result(r, verbose=args.verbose or len(maps) == 1)
        if len(results) > 1:
            print_summary(results)

    return 0


if __name__ == "__main__":
    sys.exit(main())
