#!/usr/bin/env python3
"""
ada — Fractal Project Navigator for AdaResearch

Zoom in/out through the project's fractal structure:
  project → phase → sequence → map → artifact/doc
"""

import argparse
import json
import os
import sys
from pathlib import Path
from typing import Optional
from dataclasses import dataclass, field, asdict
from collections import defaultdict
import re

# Fix Windows encoding for emoji/unicode
if sys.platform == "win32":
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')

# Find project root (look for project.godot)
def find_project_root() -> Path:
    current = Path.cwd()
    while current != current.parent:
        if (current / "project.godot").exists():
            return current
        current = current.parent
    # Fallback: assume we're in tools/ada
    return Path(__file__).parent.parent.parent

PROJECT_ROOT = find_project_root()
INDEX_PATH = PROJECT_ROOT / ".ada_index.json"

# QFEP Phase colors for terminal output
PHASE_COLORS = {
    "F_order": "\033[94m",      # Blue
    "oscillation": "\033[95m",  # Purple
    "E_entropy": "\033[91m",    # Red
    "lambda_edge": "\033[93m",  # Yellow/Orange
    "integration": "\033[92m",  # Green
    "synthesis": "\033[95m",    # Pink/Magenta
}
RESET = "\033[0m"
BOLD = "\033[1m"
DIM = "\033[2m"


@dataclass
class ProjectIndex:
    """The fractal index of the entire project."""
    spine: list = field(default_factory=list)  # ordered spine sequences
    phases: dict = field(default_factory=dict)  # phase_name -> {sequences, color, ...}
    sequences: dict = field(default_factory=dict)  # seq_name -> {maps, docs, artifacts, phase, is_spine}
    maps: dict = field(default_factory=dict)  # map_name -> {sequence, path, artifacts, layers}
    artifacts: dict = field(default_factory=dict)  # artifact_id -> {path, sequences_used_in}
    docs: dict = field(default_factory=dict)  # doc path -> {sequence, type}
    files: dict = field(default_factory=dict)  # path -> {type, sequence, ...}
    themes: dict = field(default_factory=dict)  # theme index data
    
    def to_dict(self):
        return asdict(self)
    
    @classmethod
    def from_dict(cls, d):
        return cls(**d)


def load_json(path: Path) -> Optional[dict]:
    """Load JSON file, return None if missing/invalid."""
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return None


def build_index() -> ProjectIndex:
    """Build the project index from all sources."""
    idx = ProjectIndex()
    
    # 1. Load curriculum spine
    spine_data = load_json(PROJECT_ROOT / "commons/maps/curriculum_spine.json")
    if spine_data:
        # Extract spine order
        spine_seqs = spine_data.get("spine", {}).get("sequences", [])
        idx.spine = [s.get("name") for s in spine_seqs]
        
        # Extract phases
        idx.phases = spine_data.get("phases", {})
        
        # Extract branch points
        branches = spine_data.get("branches", {}).get("branch_points", {})
        
        # Build sequence entries from spine
        for seq in spine_seqs:
            name = seq.get("name", "")
            idx.sequences[name] = {
                "phase": seq.get("phase", ""),
                "qfep_role": seq.get("qfep_role", ""),
                "is_spine": True,
                "spine_order": seq.get("order", 0),
                "branches": branches.get(name, {}).get("unlocks", []),
                "maps": [],
                "docs": [],
                "artifacts": [],
            }
        
        # Add branch sequences
        for spine_seq, branch_info in branches.items():
            for branch_name in branch_info.get("unlocks", []):
                if branch_name not in idx.sequences:
                    # Inherit phase from parent
                    parent_phase = idx.sequences.get(spine_seq, {}).get("phase", "")
                    idx.sequences[branch_name] = {
                        "phase": parent_phase,
                        "qfep_role": "",
                        "is_spine": False,
                        "parent": spine_seq,
                        "maps": [],
                        "docs": [],
                        "artifacts": [],
                    }
    
    # 2. Load sequence definitions from commons/maps/sequences/*.json
    sequences_dir = PROJECT_ROOT / "commons/maps/sequences"
    if sequences_dir.exists():
        for seq_file in sequences_dir.glob("*.json"):
            seq_data = load_json(seq_file)
            if not seq_data:
                continue
            
            seq_name = seq_file.stem  # filename without .json
            
            # Handle nested format: {sequences: {seq_name: {maps: [...]}}}
            if "sequences" in seq_data and seq_name in seq_data.get("sequences", {}):
                seq_data = seq_data["sequences"][seq_name]
            
            maps = seq_data.get("maps", [])
            
            if seq_name in idx.sequences:
                idx.sequences[seq_name]["maps"] = maps
            else:
                # Sequence not in spine, add it
                idx.sequences[seq_name] = {
                    "phase": "",
                    "is_spine": False,
                    "maps": maps,
                    "docs": [],
                    "artifacts": [],
                    "description": seq_data.get("description", ""),
                }
            
            # Add map entries
            for map_name in maps:
                idx.maps[map_name] = {
                    "sequence": seq_name,
                    "path": f"commons/maps/{map_name}",
                    "artifacts": [],
                    "has_map_data": False,
                }
    
    # 2b. Also check map_progression.json for additional sequences
    map_prog = load_json(PROJECT_ROOT / "commons/maps/map_progression.json")
    if map_prog:
        prog_sequences = map_prog.get("sequences", {})
        for seq_name, seq_info in prog_sequences.items():
            if isinstance(seq_info, dict):
                maps = seq_info.get("maps", [])
                if seq_name not in idx.sequences:
                    idx.sequences[seq_name] = {
                        "phase": "",
                        "is_spine": False,
                        "maps": maps,
                        "docs": [],
                        "artifacts": [],
                        "description": seq_info.get("description", ""),
                    }
                elif not idx.sequences[seq_name].get("maps"):
                    idx.sequences[seq_name]["maps"] = maps
                
                for map_name in maps:
                    if map_name not in idx.maps:
                        idx.maps[map_name] = {
                            "sequence": seq_name,
                            "path": f"commons/maps/{map_name}",
                            "artifacts": [],
                            "has_map_data": False,
                        }
    
    # 3. Scan map directories for map_data.json
    maps_dir = PROJECT_ROOT / "commons/maps"
    if maps_dir.exists():
        for map_dir in maps_dir.iterdir():
            if map_dir.is_dir() and not map_dir.name.startswith(".") and map_dir.name != "sequences":
                map_data_path = map_dir / "map_data.json"
                if map_data_path.exists():
                    map_name = map_dir.name
                    if map_name not in idx.maps:
                        idx.maps[map_name] = {
                            "sequence": "",
                            "path": str(map_dir.relative_to(PROJECT_ROOT)),
                            "artifacts": [],
                        }
                    idx.maps[map_name]["has_map_data"] = True
                    
                    # Parse map_data for artifacts
                    map_data = load_json(map_data_path)
                    if map_data:
                        # Check artifact_definitions for artifacts
                        artifact_defs = map_data.get("artifact_definitions", {})
                        if isinstance(artifact_defs, dict):
                            for artifact_id in artifact_defs.keys():
                                if artifact_id not in idx.maps[map_name]["artifacts"]:
                                    idx.maps[map_name]["artifacts"].append(artifact_id)
    
    # 4. Scan artifacts
    artifacts_dir = PROJECT_ROOT / "commons/artifacts"
    if artifacts_dir.exists():
        for json_file in artifacts_dir.rglob("*.json"):
            rel_path = str(json_file.relative_to(PROJECT_ROOT))
            artifact_data = load_json(json_file)
            if artifact_data:
                # Handle registry files where "artifacts" is a dict
                if "artifacts" in artifact_data:
                    artifacts_obj = artifact_data.get("artifacts", {})
                    if isinstance(artifacts_obj, dict):
                        # Dict format: {artifact_id: {name, description, ...}}
                        for aid, artifact_info in artifacts_obj.items():
                            if isinstance(artifact_info, dict):
                                idx.artifacts[aid] = {
                                    "path": rel_path,
                                    "name": artifact_info.get("name", aid),
                                    "description": artifact_info.get("description", ""),
                                    "scene": artifact_info.get("scene", ""),
                                    "used_in": [],
                                }
                    elif isinstance(artifacts_obj, list):
                        # List format: [{id, name, ...}, ...]
                        for artifact in artifacts_obj:
                            if isinstance(artifact, dict):
                                aid = artifact.get("id", "") or artifact.get("lookup_name", "")
                                if aid:
                                    idx.artifacts[aid] = {
                                        "path": rel_path,
                                        "name": artifact.get("name", aid),
                                        "description": artifact.get("description", ""),
                                        "scene": artifact.get("scene", ""),
                                        "used_in": [],
                                    }
                elif "id" in artifact_data:
                    # Single artifact file
                    aid = artifact_data.get("id", "")
                    idx.artifacts[aid] = {
                        "path": rel_path,
                        "name": artifact_data.get("name", aid),
                        "description": artifact_data.get("description", ""),
                        "scene": artifact_data.get("scene", ""),
                        "used_in": [],
                    }
    
    # 5. Cross-reference: which maps use which artifacts
    for map_name, map_info in idx.maps.items():
        for artifact_id in map_info.get("artifacts", []):
            if artifact_id in idx.artifacts:
                idx.artifacts[artifact_id]["used_in"].append(map_name)
    
    # 6. Scan docs
    doc_dir = PROJECT_ROOT / "doc"
    if doc_dir.exists():
        for md_file in doc_dir.rglob("*.md"):
            rel_path = str(md_file.relative_to(PROJECT_ROOT))
            # Try to associate with sequence based on filename
            stem = md_file.stem.lower()
            associated_seq = ""
            for seq_name in idx.sequences:
                if seq_name.lower() in stem:
                    associated_seq = seq_name
                    break
            
            idx.docs[rel_path] = {
                "sequence": associated_seq,
                "name": md_file.stem,
            }
    
    # 7. Scan for map-specific docs (blurb, summary, technical, critical)
    # These docs belong to maps, but we'll also aggregate them to sequences
    for map_name, map_info in idx.maps.items():
        map_doc_dir = PROJECT_ROOT / "commons/maps" / map_name
        if map_doc_dir.exists():
            for doc_type in ["blurb", "summary", "technical", "critical"]:
                doc_path = map_doc_dir / f"{doc_type}.md"
                if doc_path.exists():
                    rel_path = str(doc_path.relative_to(PROJECT_ROOT))
                    
                    # Add to map's docs list
                    if "docs" not in map_info:
                        map_info["docs"] = []
                    map_info["docs"].append(rel_path)
                    
                    # Add to sequence's docs list
                    seq_name = map_info.get("sequence", "")
                    if seq_name and seq_name in idx.sequences:
                        if rel_path not in idx.sequences[seq_name]["docs"]:
                            idx.sequences[seq_name]["docs"].append(rel_path)
                    
                    # Add to docs index
                    idx.docs[rel_path] = {
                        "map": map_name,
                        "sequence": seq_name,
                        "type": doc_type,
                        "name": f"{map_name}/{doc_type}",
                    }
    
    # 8. Load artifact theme index
    theme_index = load_json(PROJECT_ROOT / "commons/artifacts/artifact_theme_index.json")
    if theme_index:
        idx.themes = theme_index
    
    return idx


def save_index(idx: ProjectIndex):
    """Save index to disk."""
    with open(INDEX_PATH, 'w', encoding='utf-8') as f:
        json.dump(idx.to_dict(), f, indent=2)


def load_index() -> ProjectIndex:
    """Load index from disk, rebuild if missing."""
    if INDEX_PATH.exists():
        data = load_json(INDEX_PATH)
        if data:
            return ProjectIndex.from_dict(data)
    # Rebuild
    idx = build_index()
    save_index(idx)
    return idx


# ============ Commands ============

def cmd_overview(idx: ProjectIndex, args):
    """Show project overview."""
    print(f"{BOLD}AdaResearch Project Overview{RESET}\n")
    
    # Spine progress
    spine_count = len(idx.spine)
    print(f"📍 Spine: {spine_count} sequences")
    
    # Sequences by phase
    phase_counts = defaultdict(int)
    for seq_name, seq_info in idx.sequences.items():
        phase = seq_info.get("phase", "unassigned")
        phase_counts[phase] += 1
    
    print(f"\n{BOLD}QFEP Phases:{RESET}")
    for phase in ["F_order", "oscillation", "E_entropy", "lambda_edge", "integration", "synthesis"]:
        color = PHASE_COLORS.get(phase, "")
        count = phase_counts.get(phase, 0)
        phase_info = idx.phases.get(phase, {})
        name = phase_info.get("name", phase)
        print(f"  {color}●{RESET} {name}: {count} sequences")
    
    # Totals
    total_seqs = len(idx.sequences)
    total_maps = len(idx.maps)
    total_artifacts = len(idx.artifacts)
    total_docs = len(idx.docs)
    
    print(f"\n{BOLD}Totals:{RESET}")
    print(f"  Sequences:  {total_seqs}")
    print(f"  Maps:       {total_maps}")
    print(f"  Artifacts:  {total_artifacts}")
    print(f"  Docs:       {total_docs}")


def cmd_spine(idx: ProjectIndex, args):
    """Show curriculum spine."""
    print(f"{BOLD}Curriculum Spine (Recommended Path){RESET}\n")
    
    current_phase = ""
    for i, seq_name in enumerate(idx.spine, 1):
        seq_info = idx.sequences.get(seq_name, {})
        phase = seq_info.get("phase", "")
        
        # Print phase header when it changes
        if phase != current_phase:
            current_phase = phase
            phase_info = idx.phases.get(phase, {})
            phase_name = phase_info.get("name", phase)
            color = PHASE_COLORS.get(phase, "")
            print(f"\n{color}{BOLD}{phase_name}{RESET}")
        
        # Print sequence
        qfep_role = seq_info.get("qfep_role", "")
        branches = seq_info.get("branches", [])
        
        color = PHASE_COLORS.get(phase, "")
        print(f"  {color}[{i:2}]{RESET} {seq_name}")
        if qfep_role:
            print(f"       {DIM}{qfep_role}{RESET}")
        if branches:
            print(f"       {DIM}→ branches: {', '.join(branches)}{RESET}")


def cmd_phase(idx: ProjectIndex, args):
    """Show sequences in a QFEP phase."""
    phase_name = args.name.lower()
    
    # Match phase
    matched_phase = None
    for p in idx.phases:
        if phase_name in p.lower() or phase_name in idx.phases[p].get("name", "").lower():
            matched_phase = p
            break
    
    if not matched_phase:
        print(f"Unknown phase: {phase_name}")
        print(f"Available: {', '.join(idx.phases.keys())}")
        return
    
    phase_info = idx.phases.get(matched_phase, {})
    color = PHASE_COLORS.get(matched_phase, "")
    
    print(f"{color}{BOLD}{phase_info.get('name', matched_phase)}{RESET}")
    print(f"{DIM}{phase_info.get('description', '')}{RESET}\n")
    
    # Find sequences in this phase
    for seq_name, seq_info in idx.sequences.items():
        if seq_info.get("phase") == matched_phase:
            is_spine = seq_info.get("is_spine", False)
            marker = "●" if is_spine else "○"
            map_count = len(seq_info.get("maps", []))
            print(f"  {color}{marker}{RESET} {seq_name} ({map_count} maps)")


def cmd_seq(idx: ProjectIndex, args):
    """Show details for a sequence."""
    seq_name = args.name.lower()
    
    # Find matching sequence
    matched = None
    for s in idx.sequences:
        if seq_name == s.lower() or seq_name in s.lower():
            matched = s
            break
    
    if not matched:
        print(f"Unknown sequence: {seq_name}")
        return
    
    seq_info = idx.sequences[matched]
    phase = seq_info.get("phase", "")
    color = PHASE_COLORS.get(phase, "")
    
    is_spine = seq_info.get("is_spine", False)
    spine_marker = " [SPINE]" if is_spine else ""
    
    print(f"{color}{BOLD}{matched}{RESET}{spine_marker}")
    if seq_info.get("qfep_role"):
        print(f"{DIM}{seq_info['qfep_role']}{RESET}")
    print()
    
    # Maps
    maps = seq_info.get("maps", [])
    if maps:
        print(f"{BOLD}Maps ({len(maps)}):{RESET}")
        for m in maps:
            map_info = idx.maps.get(m, {})
            has_data = map_info.get("has_map_data", False)
            marker = "✓" if has_data else "○"
            artifact_count = len(map_info.get("artifacts", []))
            extra = f" ({artifact_count} artifacts)" if artifact_count else ""
            print(f"  {marker} {m}{extra}")
    
    # Docs
    docs = seq_info.get("docs", [])
    if docs:
        print(f"\n{BOLD}Docs ({len(docs)}):{RESET}")
        for d in docs:
            print(f"  📄 {d}")
    
    # Branches
    branches = seq_info.get("branches", [])
    if branches:
        print(f"\n{BOLD}Unlocks branches:{RESET}")
        for b in branches:
            print(f"  → {b}")
    
    if args.json:
        print(f"\n{BOLD}JSON:{RESET}")
        print(json.dumps(seq_info, indent=2))


def cmd_map(idx: ProjectIndex, args):
    """Show details for a map."""
    map_name = args.name.lower()
    
    # Find matching map
    matched = None
    for m in idx.maps:
        if map_name == m.lower() or map_name in m.lower():
            matched = m
            break
    
    if not matched:
        print(f"Unknown map: {map_name}")
        return
    
    map_info = idx.maps[matched]
    seq = map_info.get("sequence", "unknown")
    seq_info = idx.sequences.get(seq, {})
    phase = seq_info.get("phase", "")
    color = PHASE_COLORS.get(phase, "")
    
    print(f"{BOLD}{matched}{RESET}")
    print(f"Sequence: {color}{seq}{RESET}")
    print(f"Path: {map_info.get('path', '')}")
    print()
    
    # Artifacts
    artifacts = map_info.get("artifacts", [])
    if artifacts:
        print(f"{BOLD}Artifacts ({len(artifacts)}):{RESET}")
        for a in artifacts:
            artifact_info = idx.artifacts.get(a, {})
            name = artifact_info.get("name", a)
            print(f"  🔮 {a}")
    
    if args.json:
        print(f"\n{BOLD}JSON:{RESET}")
        print(json.dumps(map_info, indent=2))


def cmd_find(idx: ProjectIndex, args):
    """Search everything."""
    query = args.query.lower()
    
    results = {
        "sequences": [],
        "maps": [],
        "artifacts": [],
        "docs": [],
    }
    
    for name in idx.sequences:
        if query in name.lower():
            results["sequences"].append(name)
    
    for name in idx.maps:
        if query in name.lower():
            results["maps"].append(name)
    
    for aid, info in idx.artifacts.items():
        if query in aid.lower() or query in info.get("name", "").lower():
            results["artifacts"].append(aid)
    
    for path in idx.docs:
        if query in path.lower():
            results["docs"].append(path)
    
    # Print results
    total = sum(len(v) for v in results.values())
    print(f"{BOLD}Found {total} matches for '{args.query}':{RESET}\n")
    
    if results["sequences"]:
        print(f"{BOLD}Sequences:{RESET}")
        for s in results["sequences"]:
            print(f"  {s}")
    
    if results["maps"]:
        print(f"\n{BOLD}Maps:{RESET}")
        for m in results["maps"]:
            print(f"  {m}")
    
    if results["artifacts"]:
        print(f"\n{BOLD}Artifacts:{RESET}")
        for a in results["artifacts"]:
            print(f"  {a}")
    
    if results["docs"]:
        print(f"\n{BOLD}Docs:{RESET}")
        for d in results["docs"]:
            print(f"  {d}")
    
    if args.json:
        print(json.dumps(results, indent=2))


def cmd_refs(idx: ProjectIndex, args):
    """Find references to an artifact."""
    artifact_id = args.artifact.lower()
    
    # Find matching artifact
    matched = None
    for aid in idx.artifacts:
        if artifact_id == aid.lower() or artifact_id in aid.lower():
            matched = aid
            break
    
    if not matched:
        print(f"Unknown artifact: {artifact_id}")
        return
    
    artifact_info = idx.artifacts[matched]
    
    print(f"{BOLD}Artifact: {matched}{RESET}")
    print(f"Path: {artifact_info.get('path', '')}")
    print()
    
    used_in = artifact_info.get("used_in", [])
    if used_in:
        print(f"{BOLD}Used in {len(used_in)} maps:{RESET}")
        for m in used_in:
            map_info = idx.maps.get(m, {})
            seq = map_info.get("sequence", "")
            print(f"  {m} ({seq})")
    else:
        print(f"{DIM}Not used in any maps{RESET}")


def cmd_docs(idx: ProjectIndex, args):
    """Show docs for a sequence."""
    seq_name = args.sequence.lower() if args.sequence else None
    
    if seq_name:
        # Find matching sequence
        matched = None
        for s in idx.sequences:
            if seq_name == s.lower() or seq_name in s.lower():
                matched = s
                break
        
        if not matched:
            print(f"Unknown sequence: {seq_name}")
            return
        
        seq_info = idx.sequences[matched]
        docs = seq_info.get("docs", [])
        
        print(f"{BOLD}Docs for {matched}:{RESET}\n")
        for d in docs:
            print(f"  📄 {d}")
        
        if not docs:
            print(f"  {DIM}No docs found{RESET}")
    else:
        # List all docs grouped by type
        print(f"{BOLD}All Documentation:{RESET}\n")
        for path, info in sorted(idx.docs.items()):
            seq = info.get("sequence", "")
            marker = f"[{seq}]" if seq else ""
            print(f"  📄 {path} {DIM}{marker}{RESET}")


def cmd_reindex(idx: ProjectIndex, args):
    """Rebuild the index."""
    print("Rebuilding index...")
    new_idx = build_index()
    save_index(new_idx)
    print(f"Done. Indexed:")
    print(f"  {len(new_idx.sequences)} sequences")
    print(f"  {len(new_idx.maps)} maps")
    print(f"  {len(new_idx.artifacts)} artifacts")
    print(f"  {len(new_idx.docs)} docs")


def cmd_themes(idx: ProjectIndex, args):
    """List all artifact themes."""
    themes = idx.themes.get("by_theme", {})
    complexity = idx.themes.get("by_complexity", {})
    categories = idx.themes.get("by_category", {})
    
    print(f"{BOLD}Artifact Theme Index{RESET}")
    print(f"Total tagged: {idx.themes.get('total_tagged_artifacts', 0)}")
    print(f"Last updated: {idx.themes.get('last_updated', 'unknown')}\n")
    
    print(f"{BOLD}Themes:{RESET}")
    for theme, artifacts in sorted(themes.items()):
        print(f"  {theme}: {len(artifacts)} artifacts")
    
    print(f"\n{BOLD}Complexity:{RESET}")
    for level, artifacts in sorted(complexity.items()):
        print(f"  {level}: {len(artifacts)} artifacts")
    
    print(f"\n{BOLD}Categories:{RESET}")
    for cat, artifacts in sorted(categories.items()):
        print(f"  {cat}: {len(artifacts)} artifacts")


def cmd_theme(idx: ProjectIndex, args):
    """Query artifacts by theme/complexity/category."""
    query = args.query.lower()
    themes = idx.themes.get("by_theme", {})
    complexity = idx.themes.get("by_complexity", {})
    categories = idx.themes.get("by_category", {})
    
    results = []
    source = ""
    
    # Check themes first
    for theme, artifacts in themes.items():
        if query == theme.lower() or query in theme.lower():
            results = artifacts
            source = f"theme:{theme}"
            break
    
    # Check complexity
    if not results:
        for level, artifacts in complexity.items():
            if query == level.lower() or query in level.lower():
                results = artifacts
                source = f"complexity:{level}"
                break
    
    # Check categories
    if not results:
        for cat, artifacts in categories.items():
            if query == cat.lower() or query in cat.lower():
                results = artifacts
                source = f"category:{cat}"
                break
    
    if not results:
        print(f"No theme/complexity/category matching '{query}'")
        print(f"\nAvailable themes: {', '.join(themes.keys())}")
        print(f"Complexity levels: {', '.join(complexity.keys())}")
        return
    
    print(f"{BOLD}Artifacts for {source}:{RESET} ({len(results)})\n")
    for artifact_id in sorted(results):
        # Get artifact info if available
        artifact_info = idx.artifacts.get(artifact_id, {})
        name = artifact_info.get("name", artifact_id)
        desc = artifact_info.get("description", "")
        if desc and len(desc) > 60:
            desc = desc[:57] + "..."
        
        if desc:
            print(f"  🔮 {artifact_id}")
            print(f"     {DIM}{desc}{RESET}")
        else:
            print(f"  🔮 {artifact_id}")
    
    if args.json:
        print(f"\n{json.dumps(results, indent=2)}")


def cmd_play(idx: ProjectIndex, args):
    """Launch the game with a specific map or sequence."""
    import subprocess
    import time
    
    target = args.target.lower()
    map_name = ""
    sequence_name = ""
    
    # Check if it's a sequence or map
    for seq in idx.sequences:
        if target == seq.lower() or target in seq.lower():
            sequence_name = seq
            break
    
    if not sequence_name:
        # Try as a map
        for m in idx.maps:
            if target == m.lower() or target in m.lower():
                map_name = m
                break
    
    if not map_name and not sequence_name:
        print(f"Unknown map or sequence: {target}")
        return
    
    # Find Godot
    godot_paths = [
        Path(os.environ.get("GODOT_PATH", "")) if os.environ.get("GODOT_PATH") else None,
        Path.home() / "Desktop" / "Godot_v4.5.1-stable_win64.exe",
        Path.home() / "Desktop" / "Godot_v4.5-stable_win64.exe",
        Path.home() / "Desktop" / "Godot_v4.4.1-stable_win64.exe",
        Path("C:/Program Files/Godot/Godot.exe"),
    ]
    
    godot_exe = None
    for p in godot_paths:
        if p and p.exists():
            godot_exe = p
            break
    
    if not godot_exe:
        print("Could not find Godot executable.")
        print("Set GODOT_PATH environment variable or place Godot on Desktop.")
        return
    
    # Write launch intent
    # Godot user:// maps to %APPDATA%/Godot/app_userdata/ProjectName/ on Windows
    # But we need to find the actual project name from project.godot
    project_name = "AdaResearch"  # Default
    project_godot = PROJECT_ROOT / "project.godot"
    if project_godot.exists():
        with open(project_godot, 'r') as f:
            for line in f:
                if line.startswith("config/name="):
                    project_name = line.split("=", 1)[1].strip().strip('"')
                    break
    
    user_data_dir = Path(os.environ.get("APPDATA", "")) / "Godot" / "app_userdata" / project_name
    user_data_dir.mkdir(parents=True, exist_ok=True)
    
    launch_file = user_data_dir / "ada_launch.json"
    launch_data = {
        "map": map_name,
        "sequence": sequence_name,
        "timestamp": time.time()
    }
    
    with open(launch_file, 'w') as f:
        json.dump(launch_data, f)
    
    print(f"{BOLD}Launching AdaResearch...{RESET}")
    if sequence_name:
        print(f"  Sequence: {sequence_name}")
    else:
        print(f"  Map: {map_name}")
    
    # Launch Godot
    cmd = [str(godot_exe), "--path", str(PROJECT_ROOT)]
    
    if args.editor:
        cmd.append("-e")  # Open in editor
    
    subprocess.Popen(cmd, cwd=str(PROJECT_ROOT))


def main():
    parser = argparse.ArgumentParser(
        description="ada — Fractal Project Navigator for AdaResearch",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--json", action="store_true", help="Output as JSON")
    
    subparsers = parser.add_subparsers(dest="command", help="Commands")
    
    # overview
    subparsers.add_parser("overview", help="Project overview")
    
    # spine
    subparsers.add_parser("spine", help="Show curriculum spine")
    
    # phase <name>
    p = subparsers.add_parser("phase", help="Show sequences in a QFEP phase")
    p.add_argument("name", help="Phase name (e.g., 'integration', 'F_order')")
    
    # seq <name>
    p = subparsers.add_parser("seq", help="Show sequence details")
    p.add_argument("name", help="Sequence name")
    p.add_argument("--json", action="store_true", help="Include JSON dump")
    
    # map <name>
    p = subparsers.add_parser("map", help="Show map details")
    p.add_argument("name", help="Map name")
    p.add_argument("--json", action="store_true", help="Include JSON dump")
    
    # find <query>
    p = subparsers.add_parser("find", help="Search everything")
    p.add_argument("query", help="Search query")
    p.add_argument("--json", action="store_true", help="Output as JSON")
    
    # refs <artifact>
    p = subparsers.add_parser("refs", help="Find artifact references")
    p.add_argument("artifact", help="Artifact ID")
    
    # docs [sequence]
    p = subparsers.add_parser("docs", help="Show documentation")
    p.add_argument("sequence", nargs="?", help="Sequence name (optional)")
    
    # reindex
    subparsers.add_parser("reindex", help="Rebuild the index")
    
    # play
    p = subparsers.add_parser("play", help="Launch the game with a map or sequence")
    p.add_argument("target", help="Map or sequence name")
    p.add_argument("-e", "--editor", action="store_true", help="Open in Godot editor instead")
    
    # themes
    subparsers.add_parser("themes", help="List all artifact themes")
    
    # theme <query>
    p = subparsers.add_parser("theme", help="Query artifacts by theme/complexity/category")
    p.add_argument("query", help="Theme, complexity level, or category name")
    p.add_argument("--json", action="store_true", help="Output as JSON")
    
    args = parser.parse_args()
    
    # Load index
    idx = load_index()
    
    # Dispatch
    if args.command == "overview" or args.command is None:
        cmd_overview(idx, args)
    elif args.command == "spine":
        cmd_spine(idx, args)
    elif args.command == "phase":
        cmd_phase(idx, args)
    elif args.command == "seq":
        cmd_seq(idx, args)
    elif args.command == "map":
        cmd_map(idx, args)
    elif args.command == "find":
        cmd_find(idx, args)
    elif args.command == "refs":
        cmd_refs(idx, args)
    elif args.command == "docs":
        cmd_docs(idx, args)
    elif args.command == "reindex":
        cmd_reindex(idx, args)
    elif args.command == "play":
        cmd_play(idx, args)
    elif args.command == "themes":
        cmd_themes(idx, args)
    elif args.command == "theme":
        cmd_theme(idx, args)
    else:
        parser.print_help()


if __name__ == "__main__":
    main()
