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


def _ser(o, ind: int) -> str:
    """Canonical compact-rows serialiser: dicts indent=2, scalar-only lists (the grid
    rows, tags, etc.) on one line, lists-with-nesting multi-line. Matches the format the
    live maps + the voxel-editor use (e.g. ForcesArena)."""
    pad = "  " * ind
    cpad = "  " * (ind + 1)
    if isinstance(o, dict):
        if not o:
            return "{}"
        return "{\n" + ",\n".join('%s"%s": %s' % (cpad, k, _ser(v, ind + 1)) for k, v in o.items()) + "\n" + pad + "}"
    if isinstance(o, list):
        if not o:
            return "[]"
        if all(not isinstance(e, (dict, list)) for e in o):
            return json.dumps(o, separators=(",", ":"), ensure_ascii=False)
        return "[\n" + ",\n".join(cpad + _ser(e, ind + 1) for e in o) + "\n" + pad + "]"
    return json.dumps(o, ensure_ascii=False)


def compact_map(path: Path) -> str:
    """Reformat a map_data.json to readable compact-rows format (lossless)."""
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    return _ser(data, 0) + "\n"


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
