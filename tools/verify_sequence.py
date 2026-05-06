#!/usr/bin/env python3
import sys
sys.stdout.reconfigure(encoding="utf-8", errors="replace")
"""
Verify a processed sequence for common issues.
Run after another AI (or human) audits a sequence.

Usage:
    python tools/verify_sequence.py forces
    python tools/verify_sequence.py ALL
"""

import json
import sys
import os
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SEQUENCES_DIR = REPO / "commons" / "maps" / "sequences"
MAPS_DIR = REPO / "commons" / "maps"

PASS = "  PASS"
WARN = "  WARN"
FAIL = "  FAIL"


def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def get_artifacts(map_data):
    """Extract non-utility artifact names from interactables layer."""
    arts = []
    skip = {" ", "0", "dark_sphere", "catalyst_target", "proximity_spawner"}
    for row in map_data.get("layers", {}).get("interactables", []):
        for cell in row:
            if cell and str(cell).strip():
                name = str(cell).split(":")[0].strip()
                if name and name not in skip:
                    arts.append(name)
    return arts


def verify_sequence(seq_name):
    seq_path = SEQUENCES_DIR / f"{seq_name}.json"
    if not seq_path.exists():
        print(f"Sequence not found: {seq_path}")
        return False

    seq_data = load_json(seq_path)
    seq_info = seq_data.get("sequences", {}).get(seq_name, {})
    maps_list = seq_info.get("maps", [])
    content_list = seq_info.get("content", [])

    if not maps_list:
        print(f"No maps in sequence {seq_name}")
        return True

    errors = 0
    warnings = 0

    print(f"\n{'='*60}")
    print(f"Verifying: {seq_name} ({len(maps_list)} maps)")
    print(f"{'='*60}")

    # --Check 1: All map folders exist --
    print("\n1. Map folders exist:")
    for m in maps_list:
        map_dir = MAPS_DIR / m
        if not map_dir.exists():
            print(f"{FAIL} {m} --folder missing!")
            errors += 1
        elif not (map_dir / "map_data.json").exists():
            print(f"{FAIL} {m} --no map_data.json!")
            errors += 1
        else:
            print(f"{PASS} {m}")

    # --Check 2: Every map has a title --
    print("\n2. Titles present:")
    for m in maps_list:
        try:
            md = load_json(MAPS_DIR / m / "map_data.json")
            title = md.get("map_info", {}).get("title", "")
            if not title:
                print(f"{FAIL} {m} --no title field!")
                errors += 1
            else:
                print(f"{PASS} {m} --\"{title}\"")
        except Exception as e:
            print(f"{FAIL} {m} --JSON error: {e}")
            errors += 1

    # --Check 3: lookup_name matches folder name --
    print("\n3. lookup_name matches folder:")
    for m in maps_list:
        try:
            md = load_json(MAPS_DIR / m / "map_data.json")
            lookup = md.get("map_info", {}).get("lookup_name", "")
            if lookup != m:
                print(f"{FAIL} {m} --lookup_name is \"{lookup}\", should be \"{m}\"")
                errors += 1
            else:
                print(f"{PASS} {m}")
        except:
            pass

    # --Check 4: Content array matches maps array --
    print("\n4. Content array matches maps:")
    content_map_names = []
    for entry in content_list:
        if ":" in entry:
            content_map_names.append(entry.split(":")[0].strip())
        else:
            content_map_names.append(entry.strip())

    if len(content_list) != len(maps_list):
        print(f"{FAIL} content has {len(content_list)} entries, maps has {len(maps_list)}")
        errors += 1
    else:
        for i, (m, c) in enumerate(zip(maps_list, content_map_names)):
            if m != c:
                print(f"{FAIL} maps[{i}]={m} but content[{i}] starts with \"{c}\"")
                errors += 1
        if not any(m != c for m, c in zip(maps_list, content_map_names)):
            print(f"{PASS} all {len(maps_list)} entries match")

    # --Check 5: Blurb exists and isn't empty/placeholder --
    print("\n5. Blurbs valid:")
    for m in maps_list:
        blurb_path = MAPS_DIR / m / "blurb.md"
        if not blurb_path.exists():
            print(f"{FAIL} {m} --no blurb.md!")
            errors += 1
            continue
        text = blurb_path.read_text(encoding="utf-8").strip()
        if len(text) < 20:
            print(f"{FAIL} {m} --blurb too short ({len(text)} chars)")
            errors += 1
        elif text.lower().startswith("written") or text.lower().startswith("todo") or text.lower().startswith("placeholder"):
            print(f"{WARN} {m} --blurb looks like a placeholder: \"{text[:50]}\"")
            warnings += 1
        else:
            first_line = text.split("\n")[0][:60]
            print(f"{PASS} {m} -- \"{first_line}...\"")

    # --Check 6: Artifacts exist in at least one registry --
    print("\n6. Artifacts registered:")
    all_registry_keys = set()
    for reg_file in (REPO / "commons" / "artifacts" / "registry").glob("*.json"):
        try:
            rd = load_json(reg_file)
            if isinstance(rd, dict):
                arts = rd.get("artifacts", rd)
                if isinstance(arts, dict):
                    all_registry_keys.update(arts.keys())
        except:
            pass

    for m in maps_list:
        try:
            md = load_json(MAPS_DIR / m / "map_data.json")
            arts = get_artifacts(md)
            for a in arts:
                base = a.split("#")[0]
                if base not in all_registry_keys:
                    print(f"{WARN} {m} --artifact \"{a}\" not found in any registry")
                    warnings += 1
        except:
            pass
    if warnings == 0 and errors == 0:
        print(f"{PASS} all artifacts found in registries")

    # --Check 7: No obviously wrong artifacts (CA in physics, etc.) --
    print("\n7. Artifact-topic alignment spot check:")
    for m in maps_list:
        try:
            md = load_json(MAPS_DIR / m / "map_data.json")
            title = md.get("map_info", {}).get("title", "").lower()
            arts = get_artifacts(md)
            for a in arts:
                al = a.lower()
                # Flag obvious mismatches
                if "cellular_automata" in al and "automata" not in seq_name and "ca" not in title:
                    print(f"{WARN} {m} [{title}] has CA artifact \"{a}\" --wrong sequence?")
                    warnings += 1
                if "evolutionary" in al and "evolution" not in title and "cross" not in title:
                    print(f"{WARN} {m} [{title}] has evolutionary artifact \"{a}\" --wrong sequence?")
                    warnings += 1
        except:
            pass

    # --Check 8: Blurb first sentence vs title alignment --
    print("\n8. Blurb-title alignment:")
    for m in maps_list:
        try:
            md = load_json(MAPS_DIR / m / "map_data.json")
            title = md.get("map_info", {}).get("title", "")
            blurb_path = MAPS_DIR / m / "blurb.md"
            if blurb_path.exists():
                text = blurb_path.read_text(encoding="utf-8").strip()
                first_sentence = text.split(".")[0][:80] if text else ""
                print(f"  {m}: title=\"{title}\" | blurb=\"{first_sentence}\"")
        except:
            pass

    # --Summary --
    print(f"\n{'='*60}")
    if errors == 0 and warnings == 0:
        print(f"ALL CHECKS PASSED for {seq_name}")
    else:
        print(f"Results for {seq_name}: {errors} errors, {warnings} warnings")
    print(f"{'='*60}")

    return errors == 0


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python verify_sequence.py <sequence_name|ALL>")
        sys.exit(1)

    name = sys.argv[1]
    if name == "ALL":
        skip = ["sequence_index", "testmaps", "unused", "devexamples",
                "proceduralgeneration_all", "templats"]
        all_pass = True
        for f in sorted(SEQUENCES_DIR.glob("*.json")):
            if f.stem in skip:
                continue
            if not verify_sequence(f.stem):
                all_pass = False
        sys.exit(0 if all_pass else 1)
    else:
        ok = verify_sequence(name)
        sys.exit(0 if ok else 1)
