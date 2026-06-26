#!/usr/bin/env python3
"""Extract the canonical PROP set for the wall-hangar editor from the props-dna-gallery
manifest — the lab/staging props the gallery showcases, EXCLUDING the algorithm
*_workbench artifacts (which are content, not props).

Reads the sibling encyclopedia's manifest; writes commons/data/dna_props.json.
"""
import json
import os

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)
MANIFEST = os.path.join(ROOT, "..", "ada_encyclopedia", "public", "props-dna-gallery", "manifest.json")
OUT = os.path.join(ROOT, "commons", "data", "dna_props.json")


def main() -> None:
    with open(MANIFEST, encoding="utf-8") as f:
        manifest = json.load(f)
    props: list[str] = []
    seen: set[str] = set()
    for entry in manifest.get("entries", []):
        p = str(entry.get("prop", "")).strip()
        if not p or p in seen:
            continue
        if p.endswith("_workbench"):
            continue  # algorithm benches are content, not props
        seen.add(p)
        props.append(p)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8") as f:
        json.dump({"props": props}, f, indent=1)
    print(f"gen_dna_props: wrote {len(props)} props to {OUT}")
    print("sample:", ", ".join(props[:8]))


if __name__ == "__main__":
    main()
