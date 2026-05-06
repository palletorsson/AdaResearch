#!/usr/bin/env python3
"""
format_map_json.py — Format map_data.json with compact rows.

Rows in structure/utilities/interactables stay on one line:
  [1, 1, 2, 0, 1, 1]
The outer structure uses tabs for readability.

Usage:
    python scripts/format_map_json.py                   # Format all maps
    python scripts/format_map_json.py path/to/file      # Format one file
    python scripts/format_map_json.py --dry-run          # Preview
    python scripts/format_map_json.py --check            # Just check which need formatting
"""

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"


def compact_json(data: dict) -> str:
    """Serialize map JSON with compact rows but readable structure."""
    # First, do a normal pretty-print with tabs
    raw = json.dumps(data, indent="\t", ensure_ascii=False)
    
    # Now collapse inner arrays (rows) onto single lines.
    # Strategy: find array-of-arrays patterns and compact the inner arrays.
    # 
    # A row looks like:
    #   \t\t\t[
    #   \t\t\t\t"1",
    #   \t\t\t\t"1",
    #   \t\t\t\t...
    #   \t\t\t]
    #
    # We want:  \t\t\t["1", "1", ...]
    
    lines = raw.split("\n")
    result = []
    i = 0
    
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        
        # Detect start of an inner array: line is just "[" and we're inside a layer array
        if stripped == "[" and i + 1 < len(lines):
            # Look ahead to see if this is a row (array of simple values)
            # Collect until we find the matching ]
            depth = line.count("\t") - line.replace("\t", "").count("\t")  # nah, simpler:
            indent = line[:len(line) - len(line.lstrip())]
            
            # Check if next lines are simple values (strings, numbers) until ]
            j = i + 1
            row_items = []
            is_simple_row = True
            
            while j < len(lines):
                inner = lines[j].strip()
                
                # End of array
                if inner == "]" or inner == "],":
                    break
                
                # Check if it's a simple value (not a nested object/array)
                if inner.startswith("{") or inner.startswith("["):
                    is_simple_row = False
                    break
                
                # Strip trailing comma
                item = inner.rstrip(",").strip()
                row_items.append(item)
                j += 1
            
            if is_simple_row and row_items and j < len(lines):
                # Compact this row
                closing = lines[j].strip()  # ] or ],
                compact_row = indent + "[" + ", ".join(row_items) + "]"
                if closing.endswith(","):
                    compact_row += ","
                result.append(compact_row)
                i = j + 1
                continue
        
        result.append(line)
        i += 1
    
    return "\n".join(result)


def needs_formatting(path: Path) -> bool:
    """Check if a file has exploded rows."""
    try:
        text = path.read_text(encoding="utf-8")
    except Exception:
        return False
    
    # Quick heuristic: if we see a pattern like \n\t\t\t\t"1",\n 
    # that means rows are exploded
    if re.search(r'\n\t{3,}"[^"]*",?\n\t{3,}"', text):
        return True
    return False


def format_file(path: Path, dry_run: bool = False) -> bool:
    """Format a single file. Returns True if changed."""
    try:
        raw = path.read_text(encoding="utf-8")
        data = json.loads(raw)
    except Exception:
        return False
    
    formatted = compact_json(data)
    
    if formatted == raw:
        return False
    
    if not dry_run:
        path.write_text(formatted, encoding="utf-8")
    
    return True


def find_all_maps() -> list[Path]:
    maps = []
    for md in sorted(MAPS_DIR.rglob("map_data*.json")):
        if "sequences" in str(md) or "Structure_Examples" in str(md):
            continue
        maps.append(md)
    return maps


def main():
    parser = argparse.ArgumentParser(description="Format map JSON with compact rows")
    parser.add_argument("path", nargs="?", help="Single file to format")
    parser.add_argument("--dry-run", action="store_true", help="Preview only")
    parser.add_argument("--check", action="store_true", help="Just check which need formatting")
    parser.add_argument("--all", action="store_true", help="Format ALL maps (not just exploded ones)")
    args = parser.parse_args()

    if args.path:
        targets = [Path(args.path)]
    else:
        targets = find_all_maps()

    changed = 0
    checked = 0

    for p in targets:
        if not p.is_file():
            continue
        
        if args.check:
            if needs_formatting(p):
                rel = p.relative_to(REPO)
                print(f"  NEEDS FORMAT: {rel}")
                changed += 1
            checked += 1
            continue

        if format_file(p, dry_run=args.dry_run):
            rel = p.relative_to(REPO)
            label = "WOULD FORMAT" if args.dry_run else "FORMATTED"
            print(f"  [{label}] {rel}")
            changed += 1
        checked += 1

    action = "Need formatting" if args.check else ("Would format" if args.dry_run else "Formatted")
    print(f"\n{action}: {changed} / {checked} files")


if __name__ == "__main__":
    sys.exit(main())
