#!/usr/bin/env python3
"""Extract audit data for all spine sequences."""
import json, os, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "commons" / "maps"
SEQ_DIR = MAPS_DIR / "sequences"

# Get spine sequences from curriculum_spine.json
spine = json.load(open(MAPS_DIR / "curriculum_spine.json"))
spine_seqs = spine["spine"]["sequences"]

# Also load each sequence file for map lists
results = {}

for seq_entry in spine_seqs:
    seq_name = seq_entry["name"]
    seq_file = SEQ_DIR / f"{seq_name}.json"
    
    if not seq_file.exists():
        results[seq_name] = {"error": f"Sequence file not found: {seq_file}"}
        continue
    
    seq_data = json.load(open(seq_file))
    seq_info = seq_data["sequences"][seq_name]
    
    map_names = seq_info.get("maps", [])
    
    seq_result = {
        "title": seq_info.get("name", ""),
        "description": seq_info.get("description", ""),
        "difficulty": seq_info.get("difficulty", ""),
        "estimated_time": seq_info.get("estimated_time", ""),
        "qfep_term": seq_info.get("qfep_term", ""),
        "map_count": len(map_names),
        "maps": []
    }
    
    for map_name in map_names:
        map_dir = MAPS_DIR / map_name
        map_json = map_dir / "map_data.json"
        
        map_result = {"name": map_name}
        
        if not map_json.exists():
            map_result["error"] = "map_data.json NOT FOUND"
            seq_result["maps"].append(map_result)
            continue
        
        try:
            md = json.load(open(map_json, encoding="utf-8"))
        except Exception as e:
            map_result["error"] = f"JSON parse error: {e}"
            seq_result["maps"].append(map_result)
            continue
        
        # Basic metadata
        map_result["internal_name"] = md.get("name", "")
        map_result["map_description"] = md.get("description", "")[:100] if md.get("description") else ""
        
        # Dimensions
        w = md.get("width", 0)
        d = md.get("depth", 0)
        map_result["dimensions"] = f"{w}x{d}"
        
        # Interactables
        layers = md.get("layers", {})
        interactables_layer = layers.get("interactables", [])
        found_interactables = set()
        for row in interactables_layer:
            if isinstance(row, list):
                for cell in row:
                    if isinstance(cell, str) and cell.strip() and cell.strip() != " ":
                        found_interactables.add(cell.strip())
            elif isinstance(row, str) and row.strip() and row.strip() != " ":
                found_interactables.add(row.strip())
        map_result["interactables"] = sorted(found_interactables)
        
        # Check for docs
        docs_found = []
        for doc_name in ["blurb.md", "critical.md", "technical.md", "summary.md"]:
            if (map_dir / doc_name).exists():
                docs_found.append(doc_name.replace(".md", ""))
        map_result["docs"] = docs_found
        
        # Classify doc status
        if "critical" in docs_found and "technical" in docs_found:
            map_result["doc_status"] = "full dual-lens"
        elif "blurb" in docs_found:
            map_result["doc_status"] = "blurb-only"
        elif docs_found:
            map_result["doc_status"] = "partial: " + ", ".join(docs_found)
        else:
            map_result["doc_status"] = "NO DOCS"
        
        # Metadata issues
        issues = []
        if not md.get("name"):
            issues.append("missing name")
        if not md.get("description"):
            issues.append("missing description")
        if w == 0 or d == 0:
            issues.append("zero dimensions")
        if md.get("name") and md.get("name") != map_name:
            # Name mismatch might be intentional (display name vs folder name)
            pass
        map_result["metadata_issues"] = issues
        
        seq_result["maps"].append(map_result)
    
    results[seq_name] = seq_result

# Output as JSON
print(json.dumps(results, indent=2, ensure_ascii=False))
