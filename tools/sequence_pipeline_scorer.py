"""Score every spine sequence through the 7-stage completion pipeline.

Usage:
    python tools/sequence_pipeline_scorer.py              # all spine sequences
    python tools/sequence_pipeline_scorer.py qfeplaboratory  # single sequence
    python tools/sequence_pipeline_scorer.py --json       # machine-readable output

Stages:
    1. Structure     — maps defined in sequence JSON
    2. Documentation — blurb.md + intent.md per map
    3. Artifacts     — every interactable reference has a scene file on disk
    4. Maps          — map_data.json exists with 3 layers
    5. Validation    — pathfinder passes (if available)
    6. VR Testing    — desktop_feedback.md mentions this sequence
    7. Polish        — captures exist for maps
"""

import json
import os
import sys
import subprocess
from pathlib import Path

ROOT = Path(__file__).parent.parent
MAPS_DIR = ROOT / "commons" / "maps"
SEQ_DIR = MAPS_DIR / "sequences"
SPINE_FILE = MAPS_DIR / "curriculum_spine.json"
REGISTRY_DIR = ROOT / "commons" / "artifacts" / "registry"
FEEDBACK_FILE = ROOT / "ada_run" / "desktop_feedback.md"
APPDATA = Path(os.environ.get("APPDATA", ""))
CAPTURES_DIR = APPDATA.parent / "Local" / "Godot" / "app_userdata" / "Ada Research Zero One" / "multi_shots"


def load_spine():
    """Load spine sequence IDs with order and phase."""
    with open(SPINE_FILE, encoding="utf-8") as f:
        data = json.load(f)
    return data.get("spine", {}).get("sequences", [])


def load_sequence_maps(seq_id):
    """Load map list for a sequence from sequence JSON files."""
    for f in SEQ_DIR.glob("*.json"):
        try:
            with open(f, encoding="utf-8") as fh:
                data = json.load(fh)
            if "sequences" in data and isinstance(data["sequences"], dict):
                if seq_id in data["sequences"]:
                    return data["sequences"][seq_id].get("maps", [])
        except Exception:
            continue
    return []


def load_all_registry_scenes():
    """Build a set of all registered artifact scene paths."""
    scenes = {}
    for f in REGISTRY_DIR.glob("*.json"):
        try:
            with open(f, encoding="utf-8") as fh:
                data = json.load(fh)
            for key, art in data.get("artifacts", {}).items():
                scene = art.get("scene", "")
                if scene:
                    scenes[art.get("lookup_name", key)] = scene
        except Exception:
            continue
    return scenes


def score_sequence(seq_id, maps, registry_scenes):
    """Score a sequence through all 7 stages."""
    result = {
        "id": seq_id,
        "map_count": len(maps),
        "stages": {},
        "head": 0,
        "head_label": "",
    }

    # Stage 1: Structure
    s1_done = len(maps)
    s1_total = max(1, len(maps))  # at least 1 map expected
    result["stages"]["1_structure"] = {
        "done": s1_done, "total": s1_total,
        "pct": round(100 * s1_done / s1_total) if s1_total else 0,
        "detail": f"{s1_done} maps defined",
    }

    if not maps:
        result["head"] = 1
        result["head_label"] = "structure"
        return result

    # Stage 2: Documentation
    s2_done = 0
    s2_total = len(maps)
    for m in maps:
        blurb = MAPS_DIR / m / "blurb.md"
        intent = MAPS_DIR / m / "intent.md"
        if blurb.exists() or intent.exists():
            s2_done += 1
    result["stages"]["2_documentation"] = {
        "done": s2_done, "total": s2_total,
        "pct": round(100 * s2_done / s2_total) if s2_total else 0,
    }

    # Stage 3: Artifacts
    s3_total = 0
    s3_done = 0
    for m in maps:
        map_file = MAPS_DIR / m / "map_data.json"
        if not map_file.exists():
            continue
        try:
            with open(map_file, encoding="utf-8") as fh:
                mdata = json.load(fh)
            interactables = mdata.get("layers", {}).get("interactables", [])
            for row in interactables:
                for cell in row:
                    c = (cell or "").strip()
                    if c and c != " ":
                        token = c.split(":")[0].split("#")[0]
                        if token in ("dark_sphere", "ds"):
                            s3_done += 1
                            s3_total += 1
                            continue
                        s3_total += 1
                        # Check if scene exists on disk
                        scene_path = registry_scenes.get(token, "")
                        if scene_path:
                            disk_path = ROOT / scene_path.replace("res://", "")
                            if disk_path.exists():
                                s3_done += 1
        except Exception:
            pass
    result["stages"]["3_artifacts"] = {
        "done": s3_done, "total": s3_total,
        "pct": round(100 * s3_done / s3_total) if s3_total else 0,
    }

    # Stage 4: Maps (map_data.json with all 3 layers)
    s4_done = 0
    s4_total = len(maps)
    for m in maps:
        map_file = MAPS_DIR / m / "map_data.json"
        if map_file.exists():
            try:
                with open(map_file, encoding="utf-8") as fh:
                    mdata = json.load(fh)
                layers = mdata.get("layers", {})
                if "structure" in layers and "utilities" in layers and "interactables" in layers:
                    s4_done += 1
            except Exception:
                pass
    result["stages"]["4_maps"] = {
        "done": s4_done, "total": s4_total,
        "pct": round(100 * s4_done / s4_total) if s4_total else 0,
    }

    # Stage 5: Validation (run pathfinder if available)
    s5_done = 0
    s5_total = len(maps)
    pathfinder = ROOT / "tools" / "map_pathfinder.py"
    if pathfinder.exists():
        for m in maps:
            try:
                result_text = subprocess.run(
                    [sys.executable, str(pathfinder), "check", m],
                    capture_output=True, text=True, timeout=10,
                    cwd=str(ROOT)
                ).stdout
                if " 0 FAIL" in result_text:
                    s5_done += 1
            except Exception:
                pass
    result["stages"]["5_validation"] = {
        "done": s5_done, "total": s5_total,
        "pct": round(100 * s5_done / s5_total) if s5_total else 0,
    }

    # Stage 6: VR Testing
    s6_done = 0
    s6_total = 1  # binary: has any VR feedback or not
    if FEEDBACK_FILE.exists():
        try:
            feedback = FEEDBACK_FILE.read_text(encoding="utf-8").lower()
            # Check if any map name from this sequence appears in feedback
            for m in maps:
                if m.lower() in feedback:
                    s6_done = 1
                    break
        except Exception:
            pass
    result["stages"]["6_vr_testing"] = {
        "done": s6_done, "total": s6_total,
        "pct": 100 if s6_done else 0,
    }

    # Stage 7: Polish (captures exist)
    s7_done = 0
    s7_total = len(maps)
    for m in maps:
        capture_dir = CAPTURES_DIR / m
        if capture_dir.exists() and any(capture_dir.glob("*.png")):
            s7_done += 1
    result["stages"]["7_polish"] = {
        "done": s7_done, "total": s7_total,
        "pct": round(100 * s7_done / s7_total) if s7_total else 0,
    }

    # Find the head (lowest incomplete stage)
    stage_labels = ["structure", "documentation", "artifacts", "maps", "validation", "vr_testing", "polish"]
    for i, (key, stage) in enumerate(result["stages"].items()):
        if stage["pct"] < 100:
            result["head"] = i + 1
            result["head_label"] = stage_labels[i]
            break
    else:
        result["head"] = 8
        result["head_label"] = "complete"

    return result


def main():
    single = None
    as_json = "--json" in sys.argv

    for arg in sys.argv[1:]:
        if arg != "--json":
            single = arg

    spine = load_spine()
    registry_scenes = load_all_registry_scenes()

    results = []
    for entry in spine:
        seq_id = entry["name"]
        if single and seq_id != single:
            continue
        maps = load_sequence_maps(seq_id)
        score = score_sequence(seq_id, maps, registry_scenes)
        score["phase"] = entry.get("phase", "")
        score["order"] = entry.get("order", 99)
        results.append(score)

    if as_json:
        print(json.dumps(results, indent=2))
        return

    # Sort by head position (most complete first)
    results.sort(key=lambda r: (-r["head"], r["order"]))

    # Print table
    print(f"{'Seq':<30s} {'Maps':>4s} {'Str':>4s} {'Doc':>4s} {'Art':>4s} {'Map':>4s} {'Val':>4s} {'VR':>4s} {'Pol':>4s}  HEAD")
    print("-" * 100)

    for r in results:
        stages = r["stages"]
        bar = lambda s: f"{s['pct']:3d}%" if s['pct'] < 100 else " OK "

        head_marker = f"<- stage {r['head']}: {r['head_label']}" if r["head"] < 8 else "COMPLETE"

        print(
            f"{r['id']:<30s} {r['map_count']:>4d} "
            f"{bar(stages['1_structure']):>4s} "
            f"{bar(stages['2_documentation']):>4s} "
            f"{bar(stages['3_artifacts']):>4s} "
            f"{bar(stages['4_maps']):>4s} "
            f"{bar(stages['5_validation']):>4s} "
            f"{bar(stages['6_vr_testing']):>4s} "
            f"{bar(stages['7_polish']):>4s}  "
            f"{head_marker}"
        )


if __name__ == "__main__":
    main()
