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
    6. VR Testing    — desktop_feedback.md NAMES one of this sequence's maps
    7. Polish        — captures exist for maps
"""

import json
import os
import re
import sys
from collections import Counter
import subprocess
from pathlib import Path

ROOT = Path(__file__).parent.parent
MAPS_DIR = ROOT / "commons" / "maps"
SEQ_DIR = MAPS_DIR / "sequences"
SPINE_FILE = MAPS_DIR / "curriculum_spine.json"
REGISTRY_DIR = ROOT / "commons" / "artifacts" / "registry"
FEEDBACK_FILE = ROOT / "ada_run" / "desktop_feedback.md"
APPDATA = Path(os.environ.get("APPDATA", ""))
# Godot writes user:// to %APPDATA%/Godot/app_userdata on Windows (Roaming, not Local).
CAPTURES_DIR = APPDATA / "Godot" / "app_userdata" / "Ada Research Zero One" / "multi_shots"


# --- stage 6 evidence -------------------------------------------------------
# The desktop bridge names a map in exactly three forms. DERIVED from the writer
# (commons/maps/catalog/DesktopMapSwitcherOverlay.gd), not transcribed from the file:
#   "## <timestamp> | <map>"  entry title    _append_comment / _append_request
#   "- Map: `<map>`"          structured field, both writers
#   "[map:<map>]"             inline token    _on_insert_map_pressed
_FB_TITLE = re.compile(r"^##[^|\n]*\|\s*(.+?)\s*$", re.M)
_FB_FIELD = re.compile(r"^-\s*Map:\s*`([^`]+)`", re.M)
_FB_TOKEN = re.compile(r"\[map:([^\]]+)\]")
# the writer's placeholder when the user commented with no map loaded
_FB_NON_MAPS = {"(no map selected)"}


def walked_maps_from_feedback(text):
    """Return the set of map names the feedback file actually NAMES, lowercased.

    Exact names only. A substring test is not a laxer version of this check, it is a
    different check: it passes a sequence on some OTHER sequence's feedback whenever
    one map name is a substring of another. Measured 2026-08-26 across all 22 spine
    sequences -- exactly one diverged, and it was wrong: `Array` (color) passed on a
    2026-02-18 entry about `Array_Basics` (array_tutorial) whose content asks for that
    map to be removed from its sequence. See _self_test below; it runs on every scoring
    run, because a blind detector must not be able to print a verdict.
    """
    names = set()
    for rx in (_FB_TITLE, _FB_FIELD, _FB_TOKEN):
        for raw in rx.findall(text):
            name = raw.strip().lower()
            if name and name not in _FB_NON_MAPS:
                names.add(name)
    return names


def _self_test():
    """Prove the stage-6 detector both BITES and does not over-reject.

    Returns a list of failure strings; empty means the detector works.
    """
    failures = []
    # 1. the three real forms are each found (no over-rejection)
    for label, sample in (
        ("title", "## 2026-02-13T11:49:19 | Random_Rotate_Random_XYZ\n"),
        ("field", "- Map: `Random_Rotate_Random_XYZ`\n"),
        ("token", "walked it [map:Random_Rotate_Random_XYZ] fine\n"),
    ):
        if "random_rotate_random_xyz" not in walked_maps_from_feedback(sample):
            failures.append("stage6 detector misses the %s form" % label)
    # 2. THE NEGATIVE TEST: the real regression, reproduced. A map whose name is a
    #    substring of a DIFFERENT sequence's map must not pass on that entry.
    bystander = "## 2026-02-18T08:50:54 | Array_Basics\n- Sequence: `array_tutorial`\n- Map: `Array_Basics`\n"
    if "array" in bystander.lower() and "array" in walked_maps_from_feedback(bystander):
        failures.append("stage6 detector passes `Array` on an `Array_Basics` entry")
    # 3. the writer's no-map placeholder is not a map
    if walked_maps_from_feedback("## 2026-01-01T00:00:00 | (no map selected)\n"):
        failures.append("stage6 detector counts the (no map selected) placeholder")
    return failures


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
    """Build a map of artifact lookup_name -> scene path.

    Two passes, so delegate_to artifacts resolve to their target's scene.
    An entry may carry no `scene` of its own but instead `delegate_to`
    another registered artifact (the /dna-promoted + pattern-loader
    convention: dna_*, loom_*, mill_*, the vector *_xl walk-inside
    exhibits...). At runtime GridInteractablesComponent.gd looks the target
    up by registry key and renders the TARGET's scene. The scorer must honor
    the same convention or it undercounts every delegate-based artifact as a
    missing scene (breath 2026-06-11 — was depressing forces stage 3 to 97%
    and color stage 3 to 72% even though every delegate target resolves to a
    scene that exists on disk).
    """
    scenes = {}      # lookup_name -> scene path (direct)
    by_token = {}    # key AND lookup_name -> art dict (for delegate lookup)
    for f in REGISTRY_DIR.glob("*.json"):
        try:
            with open(f, encoding="utf-8") as fh:
                data = json.load(fh)
        except Exception:
            continue
        for key, art in data.get("artifacts", {}).items():
            lookup = art.get("lookup_name", key)
            by_token[key] = art
            by_token[lookup] = art
            scene = art.get("scene", "")
            if scene:
                scenes[lookup] = scene
    # Pass 2: resolve delegate_to chains for entries lacking a direct scene.
    for token, art in by_token.items():
        lookup = art.get("lookup_name", token)
        if scenes.get(lookup):
            continue
        cur = art
        seen = set()
        while cur is not None and not cur.get("scene"):
            tgt = str(cur.get("delegate_to", "")).strip()
            if not tgt or tgt in seen:
                cur = None
                break
            seen.add(tgt)
            cur = by_token.get(tgt)
        if cur is not None and cur.get("scene"):
            scenes[lookup] = cur["scene"]
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
        # Empty sequence: populate all stages with zero so display loop and
        # JSON consumers see the expected schema. HEAD stays at structure.
        for key in (
            "2_documentation", "3_artifacts", "4_maps",
            "5_validation", "6_vr_testing", "7_polish",
        ):
            result["stages"][key] = {"done": 0, "total": 0, "pct": 0}
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
                    if c and c != " " and not c.startswith("#"):
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
            walked = walked_maps_from_feedback(FEEDBACK_FILE.read_text(encoding="utf-8"))
            # Exact names only -- see walked_maps_from_feedback. A substring test here
            # passed `color` for six months on another sequence's feedback.
            for m in maps:
                if m.lower() in walked:
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
        if arg not in ("--json", "--self-test"):
            single = arg

    # A detector that cannot see must not be allowed to print a verdict. Pure string
    # work, microseconds, so it runs on every scoring run rather than on a flag nobody
    # remembers to pass.
    failures = _self_test()
    if failures:
        for f in failures:
            print("SELF-TEST FAIL: %s" % f, file=sys.stderr)
        print("stage 6 detector is broken -- refusing to score", file=sys.stderr)
        sys.exit(2)
    if "--self-test" in sys.argv:
        print("stage 6 detector self-test: PASS (4 cases, 1 negative)")
        if not single:
            return

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

    # The aggregate. Until now this table was the tool's entire output, so every
    # caller wanting one number had to invent it: doc/reports/breath_log.json
    # carries baseline_avg 0.0 / delta 0.0 for five consecutive breaths because
    # nothing here was parseable as an average, and the 6.083 in the entries
    # before those was carried forward rather than measured. The definition
    # below is chosen to reproduce that 6.083 exactly on the corpus that
    # produced it (23 sequences at head 6 + 1 complete at head 8), so the
    # history stays comparable instead of being orphaned by a new metric.
    if results:
        heads = [r["head"] for r in results]
        avg_head = sum(heads) / len(heads)
        complete = sum(1 for h in heads if h >= 8)
        dist = Counter(heads)
        spread = "  ".join(
            f"stage {h}: {dist[h]}" for h in sorted(dist)
        )
        print("-" * 100)
        noun = "sequence" if len(heads) == 1 else "sequences"
        print(f"global_avg {avg_head:.3f}   ({len(heads)} {noun} scored, "
              f"{complete} complete)   {spread}")


if __name__ == "__main__":
    main()
