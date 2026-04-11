"""Compact map_data.json files for readability.

Format: expanded metadata (readable), compact layers (one row per line).
Usage:
    python tools/compact_map_json.py commons/maps/Point_One/map_data.json
    python tools/compact_map_json.py --sequence primitives
    python tools/compact_map_json.py --all
"""

import json
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent


def compact_map(path: Path) -> str:
    """Reformat a map_data.json to readable-compact format."""
    with open(path, encoding="utf-8") as f:
        data = json.load(f)

    # Build output with controlled formatting
    lines = ["{"]

    # map_info — expanded
    if "map_info" in data:
        lines.append('  "map_info": ' + json.dumps(data["map_info"], indent=4, ensure_ascii=False).replace("\n", "\n  ") + ",")

    # All other top-level keys except layers — expanded
    for key in data:
        if key in ("map_info", "layers"):
            continue
        val = json.dumps(data[key], indent=4, ensure_ascii=False)
        lines.append(f'  "{key}": ' + val.replace("\n", "\n  ") + ",")

    # layers — compact: one row per line
    if "layers" in data:
        lines.append('  "layers": {')
        layer_names = list(data["layers"].keys())
        for li, layer_name in enumerate(layer_names):
            grid = data["layers"][layer_name]
            lines.append(f'    "{layer_name}": [')
            for ri, row in enumerate(grid):
                row_str = json.dumps(row, ensure_ascii=False)
                comma = "," if ri < len(grid) - 1 else ""
                lines.append(f"      {row_str}{comma}")
            comma = "," if li < len(layer_names) - 1 else ""
            lines.append(f"    ]{comma}")
        lines.append("  }")

    # Close
    # Remove trailing comma from last non-layers entry if layers is last
    result = "\n".join(lines)
    if result.endswith(","):
        result = result[:-1]
    result += "\n}\n"

    # Fix double trailing commas before "layers"
    result = result.replace(",\n  \"layers\"", ",\n  \"layers\"")

    return result


def process_file(path: Path):
    """Compact a single map_data.json file."""
    try:
        output = compact_map(path)
        with open(path, "w", encoding="utf-8", newline="\n") as f:
            f.write(output)
        lines = output.count("\n")
        print(f"  {path.parent.name}: {lines} lines")
    except Exception as e:
        print(f"  ERROR {path.parent.name}: {e}")


def main():
    if "--all" in sys.argv:
        maps_dir = ROOT / "commons" / "maps"
        for path in sorted(maps_dir.glob("*/map_data.json")):
            process_file(path)
        return

    if "--sequence" in sys.argv:
        idx = sys.argv.index("--sequence") + 1
        if idx >= len(sys.argv):
            print("Usage: --sequence <seq_id>")
            return
        seq_id = sys.argv[idx]
        # Load sequence maps
        seq_dir = ROOT / "commons" / "maps" / "sequences"
        for f in seq_dir.glob("*.json"):
            try:
                with open(f, encoding="utf-8") as fh:
                    sdata = json.load(fh)
                if "sequences" in sdata and seq_id in sdata["sequences"]:
                    maps = sdata["sequences"][seq_id].get("maps", [])
                    for m in maps:
                        path = ROOT / "commons" / "maps" / m / "map_data.json"
                        if path.exists():
                            process_file(path)
                    return
            except Exception:
                continue
        print(f"Sequence not found: {seq_id}")
        return

    # Single file
    for arg in sys.argv[1:]:
        path = Path(arg)
        if path.exists():
            process_file(path)
        else:
            print(f"Not found: {arg}")


if __name__ == "__main__":
    main()
