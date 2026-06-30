#!/usr/bin/env python
"""auto_walls_manifest.py — emit the /wall-gallery review entries for the
auto-curated concept walls.

The walls the generator writes (lay_necklace --concepts → clusters/*.json,
marked "auto by lay_necklace") are *seeds*: correctness guaranteed (cap-fit,
wall-clearance, size-gate), composition not. They deserve a review surface
next to the hand-curated walls, so this reads the clusters and writes a
compact manifest the encyclopedia's /wall-gallery renders as its own
"Auto-curated seeds" section.

  Out: ada_encyclopedia/public/auto-walls.json

Run after generating walls:  python tools/auto_walls_manifest.py
"""
from __future__ import annotations

import json
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
CLUSTERS = REPO / "commons" / "data" / "curated_walls" / "clusters"
ENC = REPO.parent / "ada_encyclopedia"
OUT = ENC / "public" / "auto-walls.json"

# Pieces that frame the wall rather than sit on it.
STRUCTURE_TOKENS = {"station_wall", "station_panel", "station_plinth"}

# The panel header is the concept slug uppercased ("CANTORSET") — readable display
# names for the concepts the generator currently walls. Falls back to header.title().
PRETTY = {
    "recursion": "Recursion",
    "cantorset": "Cantor set",
    "kochsierpinski": "Koch–Sierpinski",
    "mandelbrotset": "Mandelbrot set",
    "juliaset": "Julia set",
    "recursivetrees": "Recursive trees",
    "crosssequence": "Cross-sequence",
    "synthesis": "Synthesis",
}


def entry_for(path: Path) -> dict | None:
    """One gallery entry per auto-curated cluster (None if not auto-curated)."""
    data = json.loads(path.read_text(encoding="utf-8"))
    if "auto by lay_necklace" not in str(data.get("source", "")):
        return None  # only the generator's own seeds belong in this section
    pieces = data.get("pieces", [])
    header = ""
    artifacts: list[str] = []
    for p in pieces:
        tok = str(p.get("token", ""))
        if tok == "station_panel":
            header = str(p.get("config", {}).get("header", "")).strip()
        elif tok not in STRUCTURE_TOKENS:
            artifacts.append(tok)
    name = str(data.get("name", path.stem))
    slug = name.replace("nk_fractals_", "").replace("nk_", "")
    title = PRETTY.get(slug) or (header.title() if header else slug.replace("_", " ").title())
    return {
        "map": name,
        "title": title,
        "pieces": len(pieces),
        "held": len(artifacts),
        "artifacts": artifacts,
    }


def main() -> None:
    entries: list[dict] = []
    for p in sorted(CLUSTERS.glob("*.json")):
        e = entry_for(p)
        if e:
            entries.append(e)
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(entries, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"wrote {OUT}  ({len(entries)} auto-walls)")
    for e in entries:
        print(f"  {e['map']:32s} {e['title']:18s} held={e['held']:2d}  {', '.join(e['artifacts'])}")


if __name__ == "__main__":
    main()
