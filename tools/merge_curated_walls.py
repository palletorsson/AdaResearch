#!/usr/bin/env python3
"""Merge per-map curated walls (commons/data/curated_walls/*.json) into the single
spine_walls.json the editor loads. Each curated file replaces that map's entry;
all other entries are preserved.
"""
import json
import os
import glob

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SPINE = os.path.join(ROOT, "commons", "data", "spine_walls.json")
CURATED = os.path.join(ROOT, "commons", "data", "curated_walls")


def main() -> None:
    with open(SPINE, encoding="utf-8") as f:
        spine = json.load(f)
    before = len(spine)
    merged = []
    for path in sorted(glob.glob(os.path.join(CURATED, "*.json"))):
        name = os.path.splitext(os.path.basename(path))[0]
        with open(path, encoding="utf-8") as f:
            entry = json.load(f)
        if not isinstance(entry, dict) or "pieces" not in entry:
            print(f"  SKIP {name}: not a valid wall entry")
            continue
        spine[name] = entry
        merged.append((name, len(entry.get("pieces", []))))
    with open(SPINE, "w", encoding="utf-8") as f:
        json.dump(spine, f, indent=1)
    print(f"merged {len(merged)} curated walls into spine_walls.json "
          f"({before} -> {len(spine)} entries)")
    for name, count in merged:
        print(f"  {name}: {count} pieces")


if __name__ == "__main__":
    main()
