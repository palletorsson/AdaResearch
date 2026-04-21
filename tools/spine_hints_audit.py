#!/usr/bin/env python
"""
spine_hints_audit.py — report which artifacts declare spine_hints() and which don't.

Walks every .gd file under commons/ and algorithms/ that contains a scene
(either `class_name` or a matching .tscn sibling). Counts the ones that
implement `func spine_hints()` and the ones that don't. Produces a
coverage report so we know where to add hints next.

Usage:
    python tools/spine_hints_audit.py              # summary + missing list
    python tools/spine_hints_audit.py --json       # machine-readable
    python tools/spine_hints_audit.py --sequence primitives  # only artifacts used by this sequence
"""
from __future__ import annotations

import argparse
import json
import re
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SCAN_DIRS = [REPO / "commons", REPO / "algorithms"]
SEQ_DIR = REPO / "commons" / "maps" / "sequences"
MAPS_DIR = REPO / "commons" / "maps"
SPINE_JSON = REPO / "commons" / "maps" / "curriculum_spine.json"

HINT_RE = re.compile(r"^\s*func\s+spine_hints\s*\(\s*\)", re.MULTILINE)
CLASS_NAME_RE = re.compile(r"^\s*class_name\s+(\w+)", re.MULTILINE)


def scan_gd_files() -> list[Path]:
    out: list[Path] = []
    for root in SCAN_DIRS:
        if not root.exists():
            continue
        for p in root.rglob("*.gd"):
            if "android" in p.parts or "_staging" in p.parts:
                continue
            out.append(p)
    return out


def file_has_hints(path: Path) -> bool:
    try:
        txt = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return False
    return bool(HINT_RE.search(txt))


def extract_class_name(path: Path) -> str | None:
    try:
        txt = path.read_text(encoding="utf-8", errors="ignore")
    except Exception:
        return None
    m = CLASS_NAME_RE.search(txt)
    return m.group(1) if m else None


def has_scene_sibling(path: Path) -> bool:
    return path.with_suffix(".tscn").exists()


def collect_tokens_in_sequence(seq_name: str) -> set[str]:
    """Return set of artifact tokens used by any map in the given sequence."""
    sp = SEQ_DIR / f"{seq_name}.json"
    if not sp.exists():
        return set()
    data = json.loads(sp.read_text(encoding="utf-8"))
    entry = data.get("sequences", {}).get(seq_name, {})
    tokens: set[str] = set()
    for map_name in entry.get("maps", []):
        mp = MAPS_DIR / map_name / "map_data.json"
        if not mp.exists():
            continue
        try:
            mdata = json.loads(mp.read_text(encoding="utf-8"))
        except Exception:
            continue
        interactables = mdata.get("layers", {}).get("interactables", [])
        for row in interactables:
            if not isinstance(row, list):
                continue
            for cell in row:
                s = str(cell).strip()
                if not s:
                    continue
                # Token format: "name:rot:yoff" or "name:rot:yoff:extra" or "name:rot"
                token = s.split(":", 1)[0].split("#", 1)[0].strip()
                if token:
                    tokens.add(token)
    return tokens


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--json", action="store_true")
    ap.add_argument("--sequence", help="filter artifacts to those used by this sequence")
    ap.add_argument("--only-missing", action="store_true")
    args = ap.parse_args()

    # Filter by sequence token list if requested
    filter_tokens: set[str] | None = None
    if args.sequence:
        filter_tokens = collect_tokens_in_sequence(args.sequence)
        if not filter_tokens:
            print(f"no artifacts found for sequence '{args.sequence}'", file=sys.stderr)
            return 1

    gd_files = scan_gd_files()
    results: list[dict] = []
    for gd in gd_files:
        if not has_scene_sibling(gd):
            continue
        token = gd.stem
        if filter_tokens is not None and token not in filter_tokens:
            continue
        cls = extract_class_name(gd)
        has = file_has_hints(gd)
        results.append({
            "token": token,
            "class_name": cls,
            "path": str(gd.relative_to(REPO)).replace("\\", "/"),
            "has_hints": has,
        })

    results.sort(key=lambda r: (not r["has_hints"], r["token"]))

    if args.json:
        print(json.dumps({"results": results, "filter_sequence": args.sequence}, indent=2))
        return 0

    # Text output
    with_hints = [r for r in results if r["has_hints"]]
    without = [r for r in results if not r["has_hints"]]
    total = len(results)
    cov_pct = (100.0 * len(with_hints) / total) if total else 0.0

    header = "Spine hints audit"
    if args.sequence:
        header += f" -- sequence '{args.sequence}'"
    print(header)
    print("-" * 72)
    print(f"Total scannable artifacts: {total}")
    print(f"  with spine_hints():     {len(with_hints)}")
    print(f"  missing:                {len(without)}")
    print(f"  coverage:               {cov_pct:.1f}%")
    print("-" * 72)

    if not args.only_missing and with_hints:
        print("\n[+] artifacts declaring spine_hints():")
        for r in with_hints[:200]:
            print(f"  OK  {r['token']:<42s}  {r['path']}")

    if without:
        print("\n[-] artifacts missing spine_hints() (generator uses defaults):")
        for r in without[:200]:
            print(f"  --  {r['token']:<42s}  {r['path']}")
        if len(without) > 200:
            print(f"  ... and {len(without) - 200} more")

    return 0


if __name__ == "__main__":
    sys.exit(main())
