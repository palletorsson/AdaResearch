#!/usr/bin/env python3
"""Generate full curriculum audit report markdown."""
import json, os, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "commons" / "maps"
SEQ_DIR = MAPS_DIR / "sequences"

# Get spine sequences from curriculum_spine.json
spine = json.load(open(MAPS_DIR / "curriculum_spine.json"))
spine_seqs = spine["spine"]["sequences"]

lines = []
lines.append("# AdaResearch Curriculum Audit Report")
lines.append("")
lines.append(f"**Generated from:** `curriculum_spine.json` ({len(spine_seqs)} spine sequences)")
lines.append("")
lines.append("---")
lines.append("")

total_maps = 0
total_with_docs = 0
total_no_docs = 0
total_blurb_only = 0
total_full_docs = 0

for seq_entry in spine_seqs:
    seq_name = seq_entry["name"]
    seq_file = SEQ_DIR / f"{seq_name}.json"
    
    if not seq_file.exists():
        lines.append(f"### {seq_name} — SEQUENCE FILE NOT FOUND")
        lines.append("")
        continue
    
    seq_data = json.load(open(seq_file, encoding="utf-8"))
    seq_info = seq_data["sequences"][seq_name]
    
    map_names = seq_info.get("maps", [])
    title = seq_info.get("name", seq_name)
    
    lines.append(f"### {seq_name} — \"{title}\" ({len(map_names)} maps)")
    lines.append("")
    
    # Map inventory header
    lines.append("**Map inventory:**")
    lines.append("")
    
    map_details = []
    has_interactables_count = 0
    no_interactables_count = 0
    doc_statuses = {"full dual-lens": 0, "blurb-only": 0, "NO DOCS": 0, "partial": 0}
    all_interactable_types = set()
    
    for map_name in map_names:
        total_maps += 1
        map_dir = MAPS_DIR / map_name
        map_json = map_dir / "map_data.json"
        
        if not map_json.exists():
            lines.append(f"- `{map_name}` | **MAP DATA NOT FOUND** |  |  |  |")
            continue
        
        try:
            md = json.load(open(map_json, encoding="utf-8"))
        except Exception as e:
            lines.append(f"- `{map_name}` | **JSON ERROR: {e}** |  |  |  |")
            continue
        
        internal_name = md.get("name", "") or "(none)"
        w = md.get("width", 0)
        d = md.get("depth", 0)
        dims = f"{w}x{d}"
        
        # Interactables
        layers = md.get("layers", {})
        interactables_layer = layers.get("interactables", [])
        found = set()
        for row in interactables_layer:
            if isinstance(row, list):
                for cell in row:
                    if isinstance(cell, str) and cell.strip() and cell.strip() != " ":
                        # Extract base name (before colon params)
                        base = cell.strip().split(":")[0].split("#")[0]
                        found.add(cell.strip())
                        all_interactable_types.add(base)
            elif isinstance(row, str) and row.strip() and row.strip() != " ":
                base = row.strip().split(":")[0].split("#")[0]
                found.add(row.strip())
                all_interactable_types.add(base)
        
        if found:
            has_interactables_count += 1
            # Summarize: show base names
            base_names = set()
            for f_item in found:
                base = f_item.split(":")[0].split("#")[0]
                base_names.add(base)
            interactables_str = ", ".join(sorted(base_names))
        else:
            no_interactables_count += 1
            interactables_str = "*(none)*"
        
        # Docs
        docs_found = []
        for doc_name in ["blurb.md", "critical.md", "technical.md", "summary.md"]:
            if (map_dir / doc_name).exists():
                docs_found.append(doc_name.replace(".md", ""))
        
        if "critical" in docs_found and "technical" in docs_found:
            doc_status = "full dual-lens"
            total_full_docs += 1
            doc_statuses["full dual-lens"] += 1
        elif "blurb" in docs_found and len(docs_found) == 1:
            doc_status = "blurb-only"
            total_blurb_only += 1
            doc_statuses["blurb-only"] += 1
        elif docs_found:
            doc_status = "partial: " + "+".join(docs_found)
            doc_statuses["partial"] += 1
        else:
            doc_status = "NO DOCS"
            total_no_docs += 1
            doc_statuses["NO DOCS"] += 1
        
        # Metadata issues
        issues = []
        if not md.get("name"):
            issues.append("no name")
        if not md.get("description"):
            issues.append("no desc")
        if w == 0 and d == 0:
            issues.append("0x0")
        issues_str = ", ".join(issues) if issues else "✓"
        
        lines.append(f"- `{map_name}` | {internal_name} | {dims} | {interactables_str} | {doc_status} | {issues_str}")
    
    lines.append("")
    
    # Curriculum assessment
    lines.append("**Curriculum assessment:**")
    lines.append("")
    
    # EXIST
    if has_interactables_count == len(map_names):
        exist_status = f"YES — all {len(map_names)} maps have interactables"
    elif has_interactables_count > 0:
        exist_status = f"PARTIAL — {has_interactables_count}/{len(map_names)} maps have interactables, {no_interactables_count} empty"
    else:
        exist_status = "NO — no maps have interactables"
    lines.append(f"- **EXIST:** {exist_status}")
    
    # CONTRACT
    lines.append(f"- **CONTRACT:** *(needs manual review — {len(map_names)} maps)*")
    
    # EXPAND
    lines.append(f"- **EXPAND:** *(needs manual review)*")
    
    # REORDER
    lines.append(f"- **REORDER:** *(needs manual review)*")
    
    # RELOCATE
    lines.append(f"- **RELOCATE:** *(needs manual review)*")
    
    # REPURPOSE
    lines.append(f"- **REPURPOSE:** *(needs manual review)*")
    
    # METADATA
    all_have_metadata_issues = all(
        not (MAPS_DIR / mn / "map_data.json").exists() or 
        not json.load(open(MAPS_DIR / mn / "map_data.json", encoding="utf-8")).get("name")
        for mn in map_names
    )
    doc_summary = f"Docs: {doc_statuses['full dual-lens']} full, {doc_statuses['blurb-only']} blurb-only, {doc_statuses.get('partial',0)} partial, {doc_statuses['NO DOCS']} none"
    if all_have_metadata_issues:
        lines.append(f"- **METADATA:** ALL maps missing name/desc in map_data.json. {doc_summary}")
    else:
        lines.append(f"- **METADATA:** {doc_summary}")
    
    lines.append("")
    lines.append("---")
    lines.append("")

# Summary
lines.append("## Summary Statistics")
lines.append("")
lines.append(f"- **Total spine sequences:** {len(spine_seqs)}")
lines.append(f"- **Total maps:** {total_maps}")
lines.append(f"- **Full dual-lens docs:** {total_full_docs}")
lines.append(f"- **Blurb-only docs:** {total_blurb_only}")
lines.append(f"- **No docs:** {total_no_docs}")

report = "\n".join(lines)
output_path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path("curriculum-audit-report.md")
output_path.write_text(report, encoding="utf-8")
print(f"Report written to {output_path} ({len(lines)} lines)")
