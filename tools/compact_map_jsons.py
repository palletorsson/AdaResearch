#!/usr/bin/env python
"""
compact_map_jsons.py -- reformat every map JSON for human readability.

For each file matching commons/maps/*/map_data.json and
commons/maps/*/map_data.corridor.json, rewrite so that:
  - layers.structure / utilities / interactables rows go on single lines
  - all other keys use standard 2-space indent
  - trailing commas are removed

The transformation is lossless (parses -> rewrites). If parsing fails, the
file is reported and left untouched.

Usage:
    python tools/compact_map_jsons.py                 # all maps
    python tools/compact_map_jsons.py --dry-run
    python tools/compact_map_jsons.py --only primitives
    python tools/compact_map_jsons.py --map Point_One
    python tools/compact_map_jsons.py --corridor-only  # skip base map_data.json
    python tools/compact_map_jsons.py --base-only      # skip corridor variants
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
MAPS_DIR = REPO / "commons" / "maps"
SEQ_DIR = REPO / "commons" / "maps" / "sequences"


def loose_loads(text: str):
    cleaned = re.sub(r",\s*([\]}])", r"\1", text)
    return json.loads(cleaned)


def format_compact(data: dict) -> str:
    """Same format as spine_corridor_generate.format_corridor_json()."""
    lines: list[str] = ["{"]
    top_keys = list(data.keys())
    for ki, key in enumerate(top_keys):
        val = data[key]
        suffix = "," if ki < len(top_keys) - 1 else ""
        if key == "layers" and isinstance(val, dict):
            lines.append(f'  "layers": {{')
            layer_keys = list(val.keys())
            for li, lk in enumerate(layer_keys):
                rows = val[lk]
                lsuf = "," if li < len(layer_keys) - 1 else ""
                lines.append(f'    "{lk}": [')
                if isinstance(rows, list):
                    for ri, row in enumerate(rows):
                        row_json = json.dumps(row, separators=(",", ""))
                        rsuf = "," if ri < len(rows) - 1 else ""
                        lines.append(f'      {row_json}{rsuf}')
                lines.append(f'    ]{lsuf}')
            lines.append(f'  }}{suffix}')
        else:
            rendered = json.dumps(val, indent=2, ensure_ascii=False)
            rendered_lines = rendered.split("\n")
            if len(rendered_lines) > 1:
                out_lines = [f'  "{key}": {rendered_lines[0]}']
                for ln in rendered_lines[1:]:
                    out_lines.append("  " + ln)
                lines.append("\n".join(out_lines) + suffix)
            else:
                lines.append(f'  "{key}": {rendered}{suffix}')
    lines.append("}")
    return "\n".join(lines) + "\n"


def maps_in_sequence(seq: str) -> set[str]:
    sp = SEQ_DIR / f"{seq}.json"
    if not sp.exists():
        return set()
    data = loose_loads(sp.read_text(encoding="utf-8"))
    entry = data.get("sequences", {}).get(seq, {})
    out: set[str] = set()
    for m in entry.get("maps", []):
        if isinstance(m, str):
            out.add(m)
        elif isinstance(m, dict) and "name" in m:
            out.add(str(m["name"]))
    return out


def process(path: Path, dry_run: bool) -> tuple[str, str]:
    """Return (status, detail)."""
    try:
        raw = path.read_text(encoding="utf-8")
    except Exception as e:
        return ("READ_FAIL", str(e))
    try:
        data = loose_loads(raw)
    except Exception as e:
        return ("PARSE_FAIL", str(e))
    if not isinstance(data, dict):
        return ("NOT_OBJECT", f"root is {type(data).__name__}")
    new_text = format_compact(data)
    if new_text == raw:
        return ("UNCHANGED", "")
    old_bytes = len(raw.encode("utf-8"))
    new_bytes = len(new_text.encode("utf-8"))
    if not dry_run:
        try:
            path.write_text(new_text, encoding="utf-8")
        except OSError as e:
            return ("WRITE_FAIL", f"{type(e).__name__}: {e}")
    pct = (new_bytes / max(old_bytes, 1)) * 100.0
    return ("REWROTE", f"{old_bytes:>7d} -> {new_bytes:>7d} ({pct:5.1f}%)")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry-run", action="store_true")
    ap.add_argument("--only", help="restrict to one sequence")
    ap.add_argument("--map", help="restrict to one map folder name")
    ap.add_argument("--corridor-only", action="store_true")
    ap.add_argument("--base-only", action="store_true")
    args = ap.parse_args()

    filter_set: set[str] | None = None
    if args.only:
        filter_set = maps_in_sequence(args.only)
        if not filter_set:
            print(f"no maps found for sequence '{args.only}'", file=sys.stderr)
            return 1
    if args.map:
        filter_set = {args.map}

    targets: list[Path] = []
    for d in MAPS_DIR.iterdir():
        if not d.is_dir() or d.name in ("catalog", "sequences"):
            continue
        if filter_set is not None and d.name not in filter_set:
            continue
        if d.name == "Lab":
            # Lab has many siblings; handle recursively
            for p in d.rglob("*.json"):
                if p.name in ("map_data.json", "map_data.corridor.json"):
                    if args.base_only and p.name != "map_data.json": continue
                    if args.corridor_only and p.name != "map_data.corridor.json": continue
                    targets.append(p)
            continue
        base = d / "map_data.json"
        corr = d / "map_data.corridor.json"
        if base.exists() and not args.corridor_only:
            targets.append(base)
        if corr.exists() and not args.base_only:
            targets.append(corr)

    counts = {"REWROTE": 0, "UNCHANGED": 0, "PARSE_FAIL": 0, "READ_FAIL": 0, "NOT_OBJECT": 0, "WRITE_FAIL": 0}
    fails: list[tuple[Path, str, str]] = []

    for p in targets:
        status, detail = process(p, args.dry_run)
        counts[status] = counts.get(status, 0) + 1
        rel = p.relative_to(REPO).as_posix()
        if status == "REWROTE":
            print(f"  [{'DRY' if args.dry_run else ' OK'}] {rel}  {detail}")
        elif status == "UNCHANGED":
            pass  # quiet
        else:
            print(f"  [FAIL:{status}] {rel}  {detail}")
            fails.append((p, status, detail))

    print()
    print("-" * 60)
    print(f"Scanned: {len(targets)} files")
    print(f"  rewrote:   {counts['REWROTE']}{' (dry)' if args.dry_run else ''}")
    print(f"  unchanged: {counts['UNCHANGED']}")
    print(f"  failed:    {counts['PARSE_FAIL'] + counts['READ_FAIL'] + counts['NOT_OBJECT']}")
    if fails:
        return 2
    return 0


if __name__ == "__main__":
    sys.exit(main())
