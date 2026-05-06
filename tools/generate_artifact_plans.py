#!/usr/bin/env python3
"""
Generate structured design plan documents for Ada Research artifacts.

Reads artifact registries, GDScript source, sequence definitions, and map
placements to produce a rich markdown plan per artifact. Output goes to
doc/plans/artifacts/<lookup_name>.md.

Usage:
  python tools/generate_artifact_plans.py                          # all
  python tools/generate_artifact_plans.py --sequence randomness    # one sequence
  python tools/generate_artifact_plans.py --artifact coin_toss     # single
  python tools/generate_artifact_plans.py --force                  # overwrite
  python tools/generate_artifact_plans.py --dry-run                # preview
"""

import argparse
import os
import sys
from datetime import date
from pathlib import Path

# Add tools/ to path so lib can be imported
sys.path.insert(0, str(Path(__file__).resolve().parent))

from lib.plan_utils import (
    ROOT,
    load_all_registries,
    parse_gdscript,
    find_gd_file,
    scan_all_sequences,
    build_sequence_index,
    build_map_placement_index,
    classify_build_pattern,
    relative_path,
)

OUTPUT_DIR = ROOT / "doc" / "plans" / "artifacts"


def collect_artifacts_for_sequence(seq_id: str, sequences: dict, registry: dict) -> list:
    """Collect all artifact lookup_names used in a sequence."""
    seq = sequences.get(seq_id)
    if not seq:
        # Try case-insensitive match
        for sid, sdata in sequences.items():
            if sid.lower() == seq_id.lower():
                seq = sdata
                seq_id = sid
                break
    if not seq:
        print(f"Sequence '{seq_id}' not found.")
        return []

    names = set()
    for group in seq.get("artifact_groups", []):
        if not isinstance(group, dict):
            continue
        for art in group.get("artifacts", []):
            if isinstance(art, str):
                clean = art.split(":")[0].split("#")[0].strip()
                if clean:
                    names.add(clean)
            elif isinstance(art, dict):
                n = art.get("name", art.get("artifact", ""))
                clean = n.split(":")[0].split("#")[0].strip()
                if clean:
                    names.add(clean)

    # Also scan maps in this sequence for placed artifacts
    from lib.plan_utils import MAPS_DIR, load_json, parse_interactable_cell
    for map_name in seq.get("maps", []):
        if isinstance(map_name, dict):
            map_name = map_name.get("name", "")
        md = load_json(MAPS_DIR / map_name / "map_data.json")
        if md:
            for row in md.get("layers", {}).get("interactables", []):
                for cell in row:
                    if isinstance(cell, str) and cell.strip() and cell.strip() != " ":
                        art_name, _ = parse_interactable_cell(cell)
                        if art_name and len(art_name) > 1:
                            names.add(art_name)

    return sorted(names)


def generate_artifact_plan(lookup_name: str, registry: dict, sequences: dict,
                           seq_index: dict, map_index: dict) -> str:
    """Generate markdown plan content for a single artifact."""
    reg = registry.get(lookup_name, {})
    name = reg.get("name", lookup_name)
    description = reg.get("description", "")
    category = reg.get("category", "unknown")
    complexity = reg.get("complexity", "")
    tags = reg.get("tags", [])
    dev_themes = reg.get("dev_themes", [])
    scene_path = reg.get("scene", "")
    registry_file = reg.get("_registry_file", "")
    geometry_spec = reg.get("geometry_spec", {})
    parameters = reg.get("parameters", {})
    map_sequences = reg.get("map_sequences", [])

    # Find and parse GDScript
    gd_path = find_gd_file(lookup_name, scene_path)
    gd_info = parse_gdscript(gd_path) if gd_path else {}

    # Classify build pattern
    build_pattern = classify_build_pattern(gd_info, reg) if gd_info else "unknown"

    # Identity
    identity = gd_info.get("identity", {})
    essence = identity.get("essence", description)

    # Sequence placements
    seq_placements = seq_index.get(lookup_name, [])

    # Map placements
    map_placements = map_index.get(lookup_name, [])

    # Build markdown
    lines = []
    lines.append(f"# Artifact: {name}")
    lines.append("")
    if essence:
        lines.append(f"> {essence}")
        lines.append("")

    # Context
    lines.append("## Context")
    lines.append("")
    meta_parts = []
    if category:
        meta_parts.append(f"**Category:** {category}")
    if complexity:
        meta_parts.append(f"**Complexity:** {complexity}")
    if meta_parts:
        lines.append(" | ".join(meta_parts))

    tag_parts = []
    if tags:
        tag_parts.append(f"**Tags:** {', '.join(tags)}")
    if dev_themes:
        tag_parts.append(f"**Themes:** {', '.join(dev_themes)}")
    if tag_parts:
        lines.append(" | ".join(tag_parts))

    if meta_parts or tag_parts:
        lines.append("")

    if description:
        lines.append(description)
        lines.append("")

    truth = identity.get("truth", "")
    if truth:
        lines.append(f"*{truth}*")
        lines.append("")

    # Design
    lines.append("## Design")
    lines.append("")

    # Visual from geometry_spec
    construction = geometry_spec.get("construction", {})
    material = geometry_spec.get("material", {})
    visual_parts = []
    if construction.get("mesh_type"):
        visual_parts.append(f"mesh: {construction['mesh_type']}")
    if construction.get("topology"):
        visual_parts.append(f"topology: {construction['topology']}")
    if material.get("type"):
        visual_parts.append(f"material: {material['type']}")
    animation = geometry_spec.get("animation", {})
    if animation.get("type") and animation["type"] != "none":
        visual_parts.append(f"animation: {animation['type']}")
    if visual_parts:
        lines.append(f"- **Visual:** {', '.join(visual_parts)}")

    footprint = parameters.get("footprint", "")
    size_group = parameters.get("size_group", "")
    if footprint or size_group:
        lines.append(f"- **Scale:** {footprint} ({size_group})" if size_group else f"- **Scale:** {footprint}")

    desire = identity.get("desire", "")
    if desire:
        lines.append(f"- **Interaction:** {desire}")

    crit = identity.get("critical_parameter", "")
    if crit:
        lines.append(f"- **Critical Parameter:** {crit}")

    emerges = identity.get("emerges", "")
    if emerges:
        lines.append(f"- **What Emerges:** {emerges}")

    triggers = identity.get("triggers", "")
    if triggers:
        lines.append(f"- **Triggers:** {triggers}")

    lines.append("")

    # Architecture
    lines.append("## Architecture")
    lines.append("")
    lines.append("| | |")
    lines.append("|---|---|")
    if gd_path:
        lines.append(f"| **File** | `{relative_path(gd_path)}` ({gd_info.get('line_count', '?')} lines) |")
    elif not reg:
        lines.append("| **File** | [MISSING - not in registry] |")
    else:
        lines.append("| **File** | [No dedicated GDScript found] |")

    if scene_path:
        lines.append(f"| **Scene** | `{scene_path}` |")
    if registry_file:
        lines.append(f"| **Registry** | `{registry_file}` |")
    if gd_info.get("class_name"):
        lines.append(f"| **Class** | `{gd_info['class_name']}` extends `{gd_info.get('extends', 'Node3D')}` |")
    lines.append(f"| **Pattern** | {build_pattern} |")
    lines.append("")

    # Exports
    exports = gd_info.get("exports", [])
    if exports:
        lines.append("### Exports")
        lines.append("")
        lines.append("| Name | Type | Default |")
        lines.append("|------|------|---------|")
        for exp in exports:
            lines.append(f"| `{exp['name']}` | {exp['type'] or '-'} | {exp['default'] or '-'} |")
        lines.append("")

    # Dependencies
    deps = gd_info.get("dependencies", [])
    if deps:
        lines.append("### Dependencies")
        lines.append("")
        for dep in deps:
            lines.append(f"- `{dep}`")
        lines.append("")

    # Key Methods
    methods = gd_info.get("methods", [])
    if methods:
        lines.append("### Key Methods")
        lines.append("")
        for m in methods[:15]:  # cap at 15
            doc_str = f" -- {m['doc']}" if m['doc'] else ""
            lines.append(f"- `{m['name']}({m['args']})`{doc_str}")
        lines.append("")

    # Signals
    signals = gd_info.get("signals", [])
    if signals:
        lines.append("### Signals")
        lines.append("")
        for sig in signals:
            lines.append(f"- `{sig}`")
        lines.append("")

    # Grid Config
    if gd_info.get("has_apply_grid_config"):
        params = gd_info.get("grid_config_params", [])
        lines.append("### Grid Config")
        lines.append("")
        if params and params != ["(stub)"]:
            lines.append(f"Accepts: `{'`, `'.join(params)}`")
        elif params == ["(stub)"]:
            lines.append("Stub only (`pass`)")
        lines.append("")

    # Curriculum Position
    lines.append("## Curriculum Position")
    lines.append("")

    if seq_placements:
        lines.append("### Sequences")
        lines.append("")
        for sp in seq_placements:
            lines.append(f"- **{sp['seq_name']}** ({sp['seq_id']}) -- map: {sp['map_name']}")
        lines.append("")
    elif map_sequences:
        lines.append("### Sequences")
        lines.append("")
        for ms in map_sequences:
            lines.append(f"- {ms}")
        lines.append("")

    if map_placements:
        lines.append("### Map Placements")
        lines.append("")
        lines.append("| Map | Cell | Config |")
        lines.append("|-----|------|--------|")
        for mp in map_placements[:20]:  # cap display
            lines.append(f"| {mp['map_name']} | [{mp['row']},{mp['col']}] | `{mp['config'] or '-'}` |")
        if len(map_placements) > 20:
            lines.append(f"| ... | ... | +{len(map_placements) - 20} more |")
        lines.append("")

    # Relationships from identity
    rels = identity.get("relationships", "")
    needs = identity.get("needs", "")
    if rels or needs:
        lines.append("### Relationships")
        lines.append("")
        if rels:
            lines.append(f"- {rels}")
        if needs:
            lines.append(f"- Needs: {needs}")
        lines.append("")

    # Verification
    lines.append("## Verification")
    lines.append("")
    lines.append("- [ ] Run scene directly")
    lines.append("- [ ] Place in map, check interaction")
    lines.append("- [ ] Capture screenshot")
    lines.append("")
    lines.append("---")
    lines.append(f"*Generated by generate_artifact_plans.py on {date.today().isoformat()}*")
    lines.append("")

    return "\n".join(lines)


def main():
    parser = argparse.ArgumentParser(description="Generate artifact plan documents")
    parser.add_argument("--artifact", help="Generate for a single artifact")
    parser.add_argument("--sequence", help="Generate for all artifacts in a sequence")
    parser.add_argument("--force", action="store_true", help="Overwrite existing plans")
    parser.add_argument("--dry-run", action="store_true", help="Show what would be generated")
    args = parser.parse_args()

    print("Loading registries...")
    registry = load_all_registries()
    print(f"  {len(registry)} artifacts in registry")

    print("Scanning sequences...")
    sequences = scan_all_sequences()
    print(f"  {len(sequences)} sequences found")

    print("Building sequence index...")
    seq_index = build_sequence_index(sequences)
    print(f"  {len(seq_index)} artifacts indexed from sequences")

    print("Building map placement index...")
    map_index = build_map_placement_index()
    print(f"  {len(map_index)} artifacts found in maps")

    # Determine which artifacts to generate
    if args.artifact:
        targets = [args.artifact]
    elif args.sequence:
        targets = collect_artifacts_for_sequence(args.sequence, sequences, registry)
        print(f"  {len(targets)} artifacts in sequence '{args.sequence}'")
    else:
        targets = sorted(registry.keys())
        print(f"  Generating plans for all {len(targets)} registered artifacts")

    if not targets:
        print("No artifacts to process.")
        return

    # Ensure output dir
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    generated = 0
    skipped = 0
    errors = 0

    for lookup_name in targets:
        out_path = OUTPUT_DIR / f"{lookup_name}.md"

        if out_path.exists() and not args.force:
            skipped += 1
            continue

        if args.dry_run:
            print(f"  [dry-run] Would generate: {out_path.name}")
            generated += 1
            continue

        try:
            content = generate_artifact_plan(
                lookup_name, registry, sequences, seq_index, map_index
            )
            out_path.write_text(content, encoding="utf-8")
            generated += 1
            if generated <= 5 or generated % 50 == 0:
                print(f"  [{generated}] {lookup_name}.md")
        except Exception as e:
            errors += 1
            print(f"  [ERROR] {lookup_name}: {e}", file=sys.stderr)

    print(f"\nDone. Generated: {generated}, Skipped: {skipped}, Errors: {errors}")
    print(f"Output: {OUTPUT_DIR}")


if __name__ == "__main__":
    main()
