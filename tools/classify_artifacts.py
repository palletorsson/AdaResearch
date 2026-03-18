#!/usr/bin/env python3
"""
Artifact Spatial Classifier for Ada Research.

Reads AABB measurements (from Godot), registry metadata, and GDScript source
to classify every artifact by spatial footprint category.

Usage:
    python tools/classify_artifacts.py
    python tools/classify_artifacts.py --verbose
    python tools/classify_artifacts.py --validate
    python tools/classify_artifacts.py --measurements path/to/artifact_measurements.json
"""

import argparse
import json
import os
import re
import sys
from pathlib import Path

# ══════════════════════════════════════════════════════════════════
# CONSTANTS
# ══════════════════════════════════════════════════════════════════

REPO_ROOT = Path(__file__).resolve().parent.parent
REGISTRY_DIR = REPO_ROOT / "commons" / "artifacts" / "registry"
# Legacy registry deprecated — all entries now in REGISTRY_DIR
DEFAULT_MEASUREMENTS = REPO_ROOT / "ada_run" / "artifact_measurements.json"
OUTPUT_PATH = REPO_ROOT / "commons" / "artifacts" / "artifact_spatial_classification.json"

# Utility artifact names (always 1x1, not exhibits)
UTILITY_NAMES = {
    "dark_sphere", "info_board", "annotation", "code_display", "score_display",
    "coordinate_system", "coordinate_system_3m", "label_3d", "info_label",
    "map_info_label", "progress_tracker", "checkpoint_marker",
}

# Patterns in GDScript that indicate interaction types
INTERACTIVE_CONTROL_PATTERNS = [
    r'preload\(["\'].*slider_horizontal\.tscn',
    r'preload\(["\'].*push_button\.tscn',
    r'InteractableAreaButton',
    r'slider_moved\.connect',
    r'button_pressed\.connect',
    r'\.slider_moved\.',
    r'\.button_pressed\.',
]

INTERACTIVE_GRAB_PATTERNS = [
    r'preload\(["\'].*grab_sphere',
    r'preload\(["\'].*grab_cube',
    r'picked_up\.connect',
    r'dropped\.connect',
    r'XRToolsGrabPointHand',
    r'"picked_up"',
    r'"dropped"',
]

LARGE_PATTERNS = [
    r'MultiMesh',
    r'MultiMeshInstance3D',
    r'instance_count\s*=',
]

SHOWCASE_PATTERNS = [
    r'QuadMesh',
    r'PlaneMesh\.new',
]

# Names that suggest a showcase/display artifact
SHOWCASE_NAME_HINTS = [
    "painting", "gallery", "relief", "display", "plaque", "poster",
    "shader_", "screen", "canvas", "mural", "panel_bridge",
]


# ══════════════════════════════════════════════════════════════════
# REGISTRY LOADING
# ══════════════════════════════════════════════════════════════════

def load_all_registries():
    """Load all artifact entries from registry/*.json."""
    artifacts = {}

    # Load registries
    if REGISTRY_DIR.exists():
        for f in sorted(REGISTRY_DIR.glob("*.json")):
            data = _load_json(f)
            if "artifacts" not in data:
                continue
            arts = data["artifacts"]
            if isinstance(arts, dict):
                for key, entry in arts.items():
                    if not isinstance(entry, dict):
                        continue  # skip _comment keys
                    lname = entry.get("lookup_name", key)
                    entry["_registry_source"] = f.name
                    artifacts[lname] = entry
            elif isinstance(arts, list):
                for entry in arts:
                    if isinstance(entry, dict):
                        lname = entry.get("lookup_name", "")
                        if lname:
                            entry["_registry_source"] = f.name
                            artifacts[lname] = entry

    return artifacts


def _load_json(path):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (json.JSONDecodeError, UnicodeDecodeError, FileNotFoundError):
        return {}


# ══════════════════════════════════════════════════════════════════
# SCRIPT RESOLUTION & READING
# ══════════════════════════════════════════════════════════════════

def resolve_script_path(scene_path_res):
    """Convert res:// scene path to GDScript path by parsing .tscn."""
    if not scene_path_res:
        return None

    # Convert res:// to filesystem
    rel = scene_path_res.replace("res://", "")
    tscn_path = REPO_ROOT / rel

    if not tscn_path.exists():
        return None

    try:
        content = tscn_path.read_text(encoding="utf-8", errors="replace")
    except OSError:
        return None

    # Look for ext_resource script reference
    match = re.search(r'type="Script".*?path="(res://[^"]+\.gd)"', content)
    if match:
        return match.group(1)

    # Check for inline GDScript
    if "GDScript" in content and "script/source" in content:
        return "__inline__:" + scene_path_res

    return None


def read_script_content(script_path_res):
    """Read GDScript content from res:// path or inline."""
    if not script_path_res:
        return ""

    if script_path_res.startswith("__inline__:"):
        # Inline script in .tscn — read the .tscn and extract
        tscn_res = script_path_res.split(":", 1)[1]
        rel = tscn_res.replace("res://", "")
        tscn_path = REPO_ROOT / rel
        try:
            content = tscn_path.read_text(encoding="utf-8", errors="replace")
            # Extract between script/source markers
            match = re.search(r'script/source\s*=\s*"(.*?)"', content, re.DOTALL)
            if match:
                return match.group(1)
        except OSError:
            pass
        return ""

    rel = script_path_res.replace("res://", "")
    gd_path = REPO_ROOT / rel
    try:
        return gd_path.read_text(encoding="utf-8", errors="replace")
    except (OSError, FileNotFoundError):
        return ""


# ══════════════════════════════════════════════════════════════════
# CLASSIFICATION
# ══════════════════════════════════════════════════════════════════

def classify_artifact(lookup_name, entry, script_content, aabb_data):
    """Classify a single artifact. Returns classification dict."""
    signals = []
    interaction = entry.get("interaction", "")
    tags = entry.get("tags", [])
    category = entry.get("category", "")

    # Get AABB data if available
    aabb_size = None
    max_dim = 0.0
    if aabb_data:
        aabb_size = aabb_data.get("aabb_size", None)
        max_dim = aabb_data.get("max_dimension_m", 0.0)

    # ── Rule 1: Utility ──
    if lookup_name in UTILITY_NAMES or any(n in lookup_name for n in ["info_board", "annotation", "code_display", "score_display"]):
        signals.append("utility_name_match")
        return _make_result("utility", "none", [1, 1], ["no_special"], "high", signals)

    if "utility" in tags or "marker" in tags:
        signals.append("utility_tag")
        return _make_result("utility", "none", [1, 1], ["no_special"], "high", signals)

    # ── Rule 2: Interactive (controls) ──
    if script_content:
        for pattern in INTERACTIVE_CONTROL_PATTERNS:
            if re.search(pattern, script_content):
                signals.append("interactive_control:" + pattern.split("\\")[-1][:20])
                fw, fd = _interactive_footprint(script_content, aabb_size)
                return _make_result("interactive", "controls", [fw, fd],
                                    ["needs_player_facing", "walkable_front"], "high", signals)

    if interaction in ("slider", "button", "full_control", "configurable"):
        signals.append("registry_interaction:" + interaction)
        return _make_result("interactive", "controls", [2, 2],
                            ["needs_player_facing", "walkable_front"], "medium", signals)

    # ── Rule 3: Interactive (grab) ──
    if script_content:
        for pattern in INTERACTIVE_GRAB_PATTERNS:
            if re.search(pattern, script_content):
                signals.append("interactive_grab:" + pattern.split("\\")[-1][:20])
                return _make_result("interactive", "grab", [2, 2],
                                    ["needs_player_facing", "walkable_front"], "high", signals)

    if interaction in ("grab", "grab_slide", "touch", "touch_to_activate"):
        signals.append("registry_interaction:" + interaction)
        return _make_result("interactive", "grab", [2, 2],
                            ["needs_player_facing", "walkable_front"], "medium", signals)

    # ── Rule 4: Puzzle ──
    if "_puzzle" in lookup_name or "_assembly" in lookup_name:
        signals.append("puzzle_name")
        return _make_result("interactive", "puzzle", [3, 2],
                            ["needs_player_facing", "walkable_front", "needs_circulation"], "high", signals)

    if "puzzle" in tags:
        signals.append("puzzle_tag")
        return _make_result("interactive", "puzzle", [3, 2],
                            ["needs_player_facing", "walkable_front"], "medium", signals)

    # ── Rule 5: Large (AABB-based) ──
    if max_dim > 2.0:
        signals.append("aabb_large:%.1fm" % max_dim)
        grid_w = max(2, min(5, int(max_dim + 0.5)))
        grid_d = grid_w
        if aabb_size:
            grid_w = max(2, min(5, int(aabb_size[0] + 0.5)))
            grid_d = max(2, min(5, int(aabb_size[2] + 0.5)))
        itype = "observe"
        if interaction == "walk_through":
            itype = "walk_through"
            signals.append("walk_through")
        return _make_result("large", itype, [grid_w, grid_d],
                            ["needs_circulation"], "high", signals)

    # ── Rule 5b: Large (code-based, no AABB) ──
    if script_content:
        for pattern in LARGE_PATTERNS:
            if re.search(pattern, script_content):
                signals.append("large_code:" + pattern[:15])
                # Check instance count
                count_match = re.search(r'instance_count\s*=\s*(\d+)', script_content)
                if count_match and int(count_match.group(1)) > 10:
                    signals.append("instances:" + count_match.group(1))
                return _make_result("large", "observe", [3, 3],
                                    ["needs_circulation"], "medium" if not aabb_data else "high", signals)

    if interaction == "walk_through" or interaction == "immersive":
        signals.append("registry_walk_through")
        return _make_result("large", interaction, [3, 3],
                            ["needs_circulation"], "medium", signals)

    # ── Rule 6: Showcase (flat display) ──
    is_showcase_name = any(n in lookup_name for n in SHOWCASE_NAME_HINTS)

    if script_content:
        has_flat_mesh = any(re.search(p, script_content) for p in SHOWCASE_PATTERNS)
        if has_flat_mesh and is_showcase_name:
            # Flat display with showcase name — high confidence
            signals.append("showcase_mesh_and_name")
            fw, fd = 2, 1
            if aabb_size:
                fw = max(1, min(3, int(aabb_size[0] + 0.5)))
                fd = max(1, min(2, int(aabb_size[2] + 0.5)))
            return _make_result("showcase", "observe", [fw, fd],
                                ["wall_behind", "open_front"], "high", signals)
        elif has_flat_mesh and not any(re.search(p, script_content) for p in INTERACTIVE_CONTROL_PATTERNS + LARGE_PATTERNS):
            # Flat mesh, no interaction, no large patterns — medium confidence
            signals.append("showcase_flat_mesh")
            fw, fd = 2, 1
            if aabb_size:
                fw = max(1, min(3, int(aabb_size[0] + 0.5)))
                fd = max(1, min(2, int(aabb_size[2] + 0.5)))
            return _make_result("showcase", "observe", [fw, fd],
                                ["wall_behind", "open_front"], "medium", signals)

    if is_showcase_name:
        signals.append("showcase_name")
        return _make_result("showcase", "observe", [2, 1],
                            ["wall_behind", "open_front"], "medium", signals)

    # ── Rule 7: Pedestal (default) ──
    confidence = "medium"
    if not script_content and not aabb_data:
        confidence = "low"
    elif aabb_data and max_dim <= 1.0:
        confidence = "high"
        signals.append("aabb_small:%.1fm" % max_dim)

    if aabb_data and not script_content:
        signals.append("no_script")

    fw, fd = 1, 1
    if aabb_size:
        fw = max(1, min(2, int(aabb_size[0] + 0.5)))
        fd = max(1, min(2, int(aabb_size[2] + 0.5)))
    elif max_dim > 0.8:
        fw, fd = 2, 2

    return _make_result("pedestal", interaction or "observe", [fw, fd],
                        ["can_elevate"], confidence, signals)


def _interactive_footprint(script_content, aabb_size):
    """Estimate footprint for interactive artifacts."""
    # Count sliders/buttons — more controls = wider artifact
    slider_count = len(re.findall(r'slider_horizontal|push_button', script_content))
    w = 2
    d = 2
    if slider_count > 3:
        w = 3
    if aabb_size:
        w = max(w, min(4, int(aabb_size[0] + 1)))
        d = max(d, min(3, int(aabb_size[2] + 1)))
    return w, d


def _make_result(spatial_cat, interaction_type, footprint, placement_rules, confidence, signals):
    return {
        "spatial_category": spatial_cat,
        "interaction_type": interaction_type,
        "footprint": {"width": footprint[0], "depth": footprint[1]},
        "placement_rules": placement_rules,
        "confidence": confidence,
        "classification_signals": signals,
    }


# ══════════════════════════════════════════════════════════════════
# VALIDATION
# ══════════════════════════════════════════════════════════════════

EXPECTED = {
    "dark_sphere": "utility",
    "code_display": "utility",
    "barnsley_fern": "showcase",  # renders onto QuadMesh — flat display
}

# These depend on code analysis, validated after classification
EXPECTED_WITH_CODE = {
    "boids_aquarium": "interactive",  # has sliders + large, interactive wins
    "flocking_controls": "interactive",
}


def validate(results_by_name, verbose=False):
    """Validate classification against known artifacts."""
    passed = 0
    failed = 0

    all_expected = {**EXPECTED, **EXPECTED_WITH_CODE}
    for name, expected_cat in sorted(all_expected.items()):
        if name not in results_by_name:
            if verbose:
                print("  SKIP %s — not in registries" % name)
            continue
        actual = results_by_name[name]["spatial_category"]
        if actual == expected_cat:
            passed += 1
            if verbose:
                print("  PASS %s → %s" % (name, actual))
        else:
            failed += 1
            print("  FAIL %s: expected %s, got %s (signals: %s)" % (
                name, expected_cat, actual,
                results_by_name[name].get("classification_signals", [])))

    print("Validation: %d passed, %d failed" % (passed, failed))
    return failed == 0


# ══════════════════════════════════════════════════════════════════
# MAIN
# ══════════════════════════════════════════════════════════════════

def main():
    parser = argparse.ArgumentParser(description="Classify Ada Research artifacts by spatial footprint")
    parser.add_argument("--measurements", type=str, default=str(DEFAULT_MEASUREMENTS),
                        help="Path to artifact_measurements.json from Godot")
    parser.add_argument("--output", type=str, default=str(OUTPUT_PATH),
                        help="Output classification JSON path")
    parser.add_argument("--verbose", action="store_true", help="Print each classification")
    parser.add_argument("--dry-run", action="store_true", help="Don't write output file")
    parser.add_argument("--validate", action="store_true", help="Run validation checks only")
    args = parser.parse_args()

    print("Artifact Spatial Classifier")
    print("=" * 50)

    # 1. Load registries
    artifacts = load_all_registries()
    print("Loaded %d unique artifacts from registries" % len(artifacts))

    # 2. Load AABB measurements (if available)
    measurements = {}
    measurements_path = Path(args.measurements)
    if measurements_path.exists():
        data = _load_json(measurements_path)
        for entry in data.get("artifacts", []):
            lname = entry.get("lookup_name", "")
            if lname:
                measurements[lname] = entry
        print("Loaded %d AABB measurements" % len(measurements))
    else:
        print("WARNING: No AABB measurements found at %s" % args.measurements)
        print("  Run measure_artifacts.gd in Godot first for best results.")
        print("  Continuing with code-only classification...")

    # 3. Classify each artifact
    results = {}
    category_counts = {}

    for lookup_name in sorted(artifacts.keys()):
        entry = artifacts[lookup_name]
        scene_path = entry.get("scene", "")

        # Resolve and read GDScript
        script_path = resolve_script_path(scene_path)
        script_content = read_script_content(script_path)

        # Get AABB data
        aabb_data = measurements.get(lookup_name, None)

        # Classify
        result = classify_artifact(lookup_name, entry, script_content, aabb_data)
        result["lookup_name"] = lookup_name
        result["scene"] = scene_path
        result["registry"] = entry.get("_registry_source", "")
        if aabb_data and "aabb_size" in aabb_data:
            result["aabb_meters"] = {
                "x": aabb_data["aabb_size"][0],
                "y": aabb_data["aabb_size"][1],
                "z": aabb_data["aabb_size"][2],
            }

        results[lookup_name] = result

        cat = result["spatial_category"]
        category_counts[cat] = category_counts.get(cat, 0) + 1

        if args.verbose:
            sig = ", ".join(result["classification_signals"][:3])
            print("  %-40s → %-12s [%s] (%s)" % (
                lookup_name[:40], cat, result["confidence"], sig))

    # 4. Print summary
    print("")
    print("Classification Summary")
    print("-" * 40)
    for cat in ["utility", "interactive", "puzzle", "showcase", "pedestal", "large"]:
        count = category_counts.get(cat, 0)
        pct = (count / len(results) * 100) if results else 0
        print("  %-14s %4d  (%4.1f%%)" % (cat, count, pct))
    print("  %-14s %4d" % ("TOTAL", len(results)))

    # Confidence breakdown
    conf_counts = {}
    for r in results.values():
        c = r["confidence"]
        conf_counts[c] = conf_counts.get(c, 0) + 1
    print("")
    print("Confidence:")
    for c in ["high", "medium", "low"]:
        print("  %-8s %4d" % (c, conf_counts.get(c, 0)))

    # Low-confidence list
    low_conf = [r for r in results.values() if r["confidence"] == "low"]
    if low_conf:
        print("")
        print("Low-confidence artifacts (%d):" % len(low_conf))
        for r in low_conf[:20]:
            print("  %s -> %s" % (r["lookup_name"], r["spatial_category"]))
        if len(low_conf) > 20:
            print("  ... and %d more" % (len(low_conf) - 20))

    # 5. Validation
    if args.validate:
        print("")
        print("Running validation...")
        validate(results, verbose=True)
        return

    # 6. Write output
    if not args.dry_run:
        output_data = {
            "version": "1.0",
            "generated": _timestamp(),
            "total_artifacts": len(results),
            "categories": category_counts,
            "artifacts": [results[k] for k in sorted(results.keys())],
        }

        output_path = Path(args.output)
        output_path.parent.mkdir(parents=True, exist_ok=True)
        with open(output_path, "w", encoding="utf-8") as f:
            json.dump(output_data, f, indent=2, ensure_ascii=False)
        print("")
        print("Output written to: %s" % output_path)
    else:
        print("")
        print("(dry run — no output written)")

    # Always validate at end
    print("")
    validate(results)


def _timestamp():
    from datetime import datetime, timezone
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%S")


if __name__ == "__main__":
    main()
