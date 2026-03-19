#!/usr/bin/env python3
"""
Add titles to maps and rename folders for better overview.
Processes one sequence at a time.

Usage:
    python tools/add_map_titles.py cellularautomata --dry-run
    python tools/add_map_titles.py cellularautomata --apply
    python tools/add_map_titles.py ALL --dry-run
"""

import json
import os
import sys
import shutil
import re
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SEQUENCES_DIR = REPO / "commons" / "maps" / "sequences"
MAPS_DIR = REPO / "commons" / "maps"

# Files that reference map names and need updating
REFERENCE_FILES = [
    REPO / ".ada_index.json",
    REPO / "commons" / "maps" / "catalog" / "map_grades.json",
]


def load_json(path):
    with open(path, "r", encoding="utf-8") as f:
        return json.load(f)


def save_json(path, data):
    with open(path, "w", encoding="utf-8") as f:
        json.dump(data, f, indent=2, ensure_ascii=False)
        f.write("\n")


def extract_title_from_blurb(blurb_path):
    """Extract a short title from blurb.md — first sentence condensed."""
    if not blurb_path.exists():
        return None
    text = blurb_path.read_text(encoding="utf-8").strip()
    # First sentence
    first = re.split(r'[.!?]', text)[0].strip()
    # Remove common filler words for a tighter title
    return first[:80] if first else None


def extract_artifacts(map_data):
    """Get artifact names from interactables layer."""
    arts = set()
    for row in map_data.get("layers", {}).get("interactables", []):
        for cell in row:
            if cell and str(cell).strip() and str(cell) != "0":
                name = str(cell).split(":")[0].strip()
                if name:
                    arts.add(name)
    # Remove generic ones
    arts.discard("dark_sphere")
    arts.discard(" ")
    return sorted(arts)


def make_folder_name(prefix, title):
    """Convert a title to a valid folder name with prefix."""
    # Take key words, PascalCase them
    words = re.sub(r'[^a-zA-Z0-9\s]', '', title).split()
    # Keep max 3 words
    words = words[:3]
    name = "_".join(w.capitalize() for w in words)
    return f"{prefix}_{name}" if prefix else name


def process_sequence(seq_name, dry_run=True, title_overrides=None):
    """Process a single sequence: analyze maps, generate titles, apply changes."""
    seq_path = SEQUENCES_DIR / f"{seq_name}.json"
    if not seq_path.exists():
        print(f"Sequence not found: {seq_path}")
        return

    seq_data = load_json(seq_path)
    seq_info = seq_data.get("sequences", {}).get(seq_name, {})
    maps_list = seq_info.get("maps", [])
    content_list = seq_info.get("content", [])

    if not maps_list:
        print(f"No maps in sequence {seq_name}")
        return

    # Build content descriptions lookup
    content_desc = {}
    for entry in content_list:
        if ":" in entry:
            key, desc = entry.split(":", 1)
            content_desc[key.strip()] = desc.strip()

    print(f"\n{'='*60}")
    print(f"Sequence: {seq_name} ({len(maps_list)} maps)")
    print(f"{'='*60}")

    rename_plan = []  # (old_name, new_name, title)

    for i, map_name in enumerate(maps_list):
        map_dir = MAPS_DIR / map_name
        if not map_dir.exists():
            print(f"  MISSING: {map_name}")
            continue

        map_data_path = map_dir / "map_data.json"
        blurb_path = map_dir / "blurb.md"

        map_data = load_json(map_data_path) if map_data_path.exists() else {}
        map_info = map_data.get("map_info", {})

        # Gather info for title generation
        description = map_info.get("description", "")
        blurb = blurb_path.read_text(encoding="utf-8").strip() if blurb_path.exists() else ""
        content_hint = content_desc.get(map_name, "")
        artifacts = extract_artifacts(map_data)

        # Use override if provided, otherwise use content hint or blurb
        if title_overrides and map_name in title_overrides:
            title = title_overrides[map_name]
        elif content_hint:
            # Content hints are like "Introduction to cellular automata concepts"
            # Condense to max 6 words
            words = content_hint.split()
            # Remove filler
            filler = {'to', 'the', 'a', 'an', 'of', 'in', 'and', 'with', 'for', 'from', 'at'}
            key_words = [w for w in words if w.lower() not in filler]
            title = " ".join(key_words[:6]).rstrip("—-–")
        else:
            # Fall back to first sentence of blurb
            first = re.split(r'[.!?—]', blurb)[0].strip() if blurb else map_name
            words = first.split()
            title = " ".join(words[:6])

        # Clean up title
        title = title.strip().rstrip("—-–:,").strip()

        print(f"\n  [{i+1}] {map_name}")
        print(f"      Content: {content_hint[:60]}")
        print(f"      Blurb:   {blurb[:60]}...")
        print(f"      Arts:    {', '.join(artifacts[:5])}")
        print(f"      => Title: \"{title}\"")

        rename_plan.append((map_name, title))

    if dry_run:
        print(f"\n{'='*60}")
        print("DRY RUN — no changes made. Use --apply to execute.")
        print(f"{'='*60}")
        return rename_plan

    # Apply changes
    print(f"\nApplying changes...")

    new_maps_list = []
    new_content_list = []

    for old_name, title in rename_plan:
        map_dir = MAPS_DIR / old_name
        map_data_path = map_dir / "map_data.json"

        if not map_data_path.exists():
            new_maps_list.append(old_name)
            continue

        # 1. Add title to map_data.json
        map_data = load_json(map_data_path)
        map_data["map_info"]["title"] = title
        save_json(map_data_path, map_data)
        print(f"  Updated map_data.json: {old_name} → title: \"{title}\"")

        new_maps_list.append(old_name)
        new_content_list.append(f"{old_name}: {title}")

    # 2. Update sequence JSON
    seq_info["maps"] = new_maps_list
    seq_info["content"] = new_content_list
    save_json(seq_path, seq_data)
    print(f"  Updated sequence: {seq_name}.json")

    return rename_plan


# Manual title overrides for sequences where auto-extraction isn't great
TITLE_OVERRIDES = {
    "cellularautomata": {
        "CA_1": "Local Rules, Global Patterns",
        "CA_2": "Game of Life",
        "CA_3": "Wolfram Elementary Rules",
        "CA_4": "Totalistic Rules",
        "CA_5": "Multi-State Automata",
        "CA_6": "Extended Neighborhoods",
        "CA_7": "Stochastic Automata",
        "CA_8": "Continuous Automata",
        "CA_9": "Three-Dimensional CA",
        "CA_10": "Langton's Ant",
        "CA_11": "Wireworld Circuits",
        "CA_12": "Edge of Chaos",
    }
}


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python add_map_titles.py <sequence_name|ALL> [--dry-run|--apply]")
        sys.exit(1)

    seq_name = sys.argv[1]
    mode = sys.argv[2] if len(sys.argv) > 2 else "--dry-run"
    dry_run = mode != "--apply"

    if seq_name == "ALL":
        for f in sorted(SEQUENCES_DIR.glob("*.json")):
            name = f.stem
            if name == "sequence_index":
                continue
            overrides = TITLE_OVERRIDES.get(name)
            process_sequence(name, dry_run=dry_run, title_overrides=overrides)
    else:
        overrides = TITLE_OVERRIDES.get(seq_name)
        process_sequence(seq_name, dry_run=dry_run, title_overrides=overrides)
