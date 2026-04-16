#!/usr/bin/env python3
"""
Generate structured design plan documents for Ada Research maps.

Reads map_data.json, sequence definitions, and artifact registries to
produce a rich markdown plan per map. Output goes to
doc/plans/maps/<MapName>.md.

Usage:
  python tools/generate_map_plans.py                            # all
  python tools/generate_map_plans.py --sequence randomness      # one sequence
  python tools/generate_map_plans.py --map Random_Definition    # single
  python tools/generate_map_plans.py --force                    # overwrite
  python tools/generate_map_plans.py --dry-run                  # preview
"""

import argparse
import os
import sys
from datetime import date
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from lib.plan_utils import (
    ROOT,
    MAPS_DIR,
    load_all_registries,
    parse_map_data,
    scan_all_sequences,
    find_sequence_for_map,
    load_json,
)

OUTPUT_DIR = ROOT / "doc" / "plans" / "maps"


def collect_maps_for_sequence(seq_id: str, sequences: dict) -> list:
    """Collect all map names in a sequence."""
    seq = sequences.get(seq_id)
    if not seq:
        for sid, sdata in sequences.items():
            if sid.lower() == seq_id.lower():
                seq = sdata
                break
    if not seq:
        print(f"Sequence '{seq_id}' not found.")
        return []

    maps = []
    for m in seq.get("maps", []):
        name = m if isinstance(m, str) else m.get("name", "")
        if name:
            maps.append(name)
    return maps


def check_text_files(map_dir: Path) -> dict:
    """Check which documentation text files exist for a map."""
    files = {}
    for fname in ["blurb.md", "technical.md", "critical.md", "summary.md", "intent.md"]:
        fpath = map_dir / fname
        files[fname.replace(".md", "")] = fpath.is_file() and fpath.stat().st_size > 10
    return files


def generate_map_plan(map_name: str, sequences: dict, registry: dict) -> str:
    """Generate markdown plan content for a single map."""
    map_dir = MAPS_DIR / map_name
    map_data = parse_map_data(map_dir)

    if not map_data:
        return f"# Map: {map_name}\n\n> [ERROR] Could not read map_data.json\n"

    # Sequence context
    seq_ctx = find_sequence_for_map(map_name, sequences)

    # Text coverage
    text_files = check_text_files(map_dir)

    # Build markdown
    lines = []
    display = map_data["display_name"] or map_name
    title = map_data.get("title", "")
    lines.append(f"# Map: {display}")
    lines.append("")
    if title:
        lines.append(f"> {title}")
        lines.append("")

    # Overview
    lines.append("## Overview")
    lines.append("")

    if seq_ctx:
        lines.append(
            f"**Sequence:** {seq_ctx['seq_name']} "
            f"(map {seq_ctx['position'] + 1} of {seq_ctx['total_maps']})"
        )

    dims = map_data.get("dimensions", {})
    if dims:
        lines.append(
            f"**Dimensions:** {dims.get('width', '?')} x {dims.get('depth', '?')} "
            f"(max height: {dims.get('max_height', '?')})"
        )

    meta_parts = []
    if map_data.get("difficulty"):
        meta_parts.append(f"**Difficulty:** {map_data['difficulty']}")
    if map_data.get("estimated_time"):
        meta_parts.append(f"**Time:** {map_data['estimated_time']}")
    if meta_parts:
        lines.append(" | ".join(meta_parts))

    if seq_ctx:
        prev_str = seq_ctx["prev_map"] or "--"
        next_str = seq_ctx["next_map"] or "--"
        lines.append(f"**Previous:** {prev_str} | **Next:** {next_str}")

    lines.append("")

    desc = map_data.get("description", "")
    if desc:
        lines.append(desc)
        lines.append("")

    # Learning Objectives
    objectives = map_data.get("learning_objectives", [])
    if objectives:
        lines.append("## Learning Objectives")
        lines.append("")
        for obj in objectives:
            lines.append(f"- {obj}")
        lines.append("")

    # Layout
    lines.append("## Layout")
    lines.append("")
    lines.append(
        f"**Grid:** {map_data['structure_rows']} rows x {map_data['structure_cols']} columns"
    )
    settings = map_data.get("settings", {})
    cube_size = settings.get("cube_size", 1.0)
    gutter = settings.get("gutter", 0.0)
    lines.append(f"**Cube Size:** {cube_size} | **Gutter:** {gutter}")
    bg = settings.get("background", {})
    if bg:
        lines.append(f"**Background:** {bg.get('type', 'default')}")
    lines.append("")

    # Artifacts table
    art_cells = map_data.get("artifact_cells", [])
    if art_cells:
        lines.append("### Artifacts")
        lines.append("")
        lines.append("| Cell | Artifact | Category | Config |")
        lines.append("|------|----------|----------|--------|")
        for ac in art_cells:
            name = ac["name"]
            cat = ""
            reg_entry = registry.get(name, {})
            if reg_entry:
                cat = reg_entry.get("category", "")
            config = ac.get("config", "")
            lines.append(f"| [{ac['row']},{ac['col']}] | {name} | {cat} | `{config or '-'}` |")
        lines.append("")

    # Utilities table
    util_cells = map_data.get("utility_cells", [])
    if util_cells:
        lines.append("### Utilities")
        lines.append("")
        lines.append("| Cell | Value |")
        lines.append("|------|-------|")
        for uc in util_cells:
            lines.append(f"| [{uc['row']},{uc['col']}] | `{uc['value']}` |")
        lines.append("")

    # Utility definitions
    util_defs = map_data.get("utility_definitions", {})
    if util_defs:
        lines.append("### Utility Definitions")
        lines.append("")
        for key, defn in util_defs.items():
            if isinstance(defn, dict):
                utype = defn.get("type", "")
                uname = defn.get("name", "")
                lines.append(f"- `{key}`: {utype} -- {uname}")
            else:
                lines.append(f"- `{key}`: {defn}")
        lines.append("")

    # Lighting
    lighting = map_data.get("lighting", {})
    if lighting:
        lines.append("## Lighting")
        lines.append("")
        ambient_color = lighting.get("ambient_color", [])
        ambient_energy = lighting.get("ambient_energy", "")
        if ambient_color:
            lines.append(f"- **Ambient:** rgb({ambient_color}) energy {ambient_energy}")
        dl = lighting.get("directional_light", {})
        if dl and dl.get("enabled"):
            lines.append(
                f"- **Directional:** dir={dl.get('direction', [])}, "
                f"color={dl.get('color', [])}, energy={dl.get('energy', '')}"
            )
        lines.append("")

    # Sequence Context detail
    if seq_ctx:
        lines.append("## Sequence Context")
        lines.append("")
        lines.append(f"**Sequence:** {seq_ctx['seq_name']} (`{seq_ctx['seq_id']}`)")
        lines.append(f"**Position:** {seq_ctx['position'] + 1} of {seq_ctx['total_maps']}")
        lines.append("")

        # Try to find artifact_group info for this map
        seq_data = sequences.get(seq_ctx["seq_id"], {})
        for group in seq_data.get("artifact_groups", []):
            if isinstance(group, dict) and group.get("map") == map_name:
                rationale = group.get("rationale", "")
                size_budget = group.get("size_budget", "")
                position_desc = group.get("position", "")
                if position_desc:
                    lines.append(f"**Position Role:** {position_desc}")
                if rationale:
                    lines.append(f"**Rationale:** {rationale}")
                if size_budget:
                    lines.append(f"**Size Budget:** {size_budget}")
                lines.append("")
                break

    # Text coverage
    lines.append("## Text Coverage")
    lines.append("")
    lines.append("| blurb | technical | critical | intent | summary |")
    lines.append("|-------|-----------|----------|--------|---------|")
    row = []
    for key in ["blurb", "technical", "critical", "intent", "summary"]:
        row.append("yes" if text_files.get(key) else "**no**")
    lines.append(f"| {' | '.join(row)} |")
    lines.append("")

    # Verification
    lines.append("## Verification")
    lines.append("")
    lines.append("- [ ] Load in Godot")
    lines.append("- [ ] Walk through all artifacts")
    lines.append("- [ ] Test teleporters")
    lines.append("- [ ] Check atmosphere and lighting")
    lines.append("- [ ] Verify text files written")
    lines.append("")
    lines.append("---")
    lines.append(f"*Generated by generate_map_plans.py on {date.today().isoformat()}*")
    lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate map plan documents")
    parser.add_argument("--map", help="Generate for a single map")
    parser.add_argument("--sequence", help="Generate for all maps in a sequence")
    parser.add_argument("--force", action="store_true", help="Overwrite existing plans")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be generated")
    args = parser.parse_args()

    print("Loading registries...")
    registry = load_all_registries()
    print(f"  {len(registry)} artifacts in registry")

    print("Scanning sequences...")
    sequences = scan_all_sequences()
    print(f"  {len(sequences)} sequences found")

    # Determine which maps to generate
    if args.map:
        targets = [args.map]
    elif args.sequence:
        targets = collect_maps_for_sequence(args.sequence, sequences)
        print(f"  {len(targets)} maps in sequence '{args.sequence}'")
    else:
        # All maps that have map_data.json
        targets = sorted([
            d.name for d in MAPS_DIR.iterdir()
            if d.is_dir() and (d / "map_data.json").is_file()
        ])
        print(f"  Generating plans for all {len(targets)} maps")

    if not targets:
        print("No maps to process.")
        return

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    generated = 0
    skipped = 0
    errors = 0

    for map_name in targets:
        out_path = OUTPUT_DIR / f"{map_name}.md"

        if out_path.exists() and not args.force:
            skipped += 1
            continue

        if args.dry_run:
            print(f"  [dry-run] Would generate: {out_path.name}")
            generated += 1
            continue

        try:
            content = generate_map_plan(map_name, sequences, registry)
            out_path.write_text(content, encoding="utf-8")
            generated += 1
            if generated <= 5 or generated % 50 == 0:
                print(f"  [{generated}] {map_name}.md")
        except Exception as e:
            errors += 1
            print(f"  [ERROR] {map_name}: {e}", file=sys.stderr)

    print(f"\nDone. Generated: {generated}, Skipped: {skipped}, Errors: {errors}")
    print(f"Output: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
