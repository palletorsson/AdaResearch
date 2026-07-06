#!/usr/bin/env python3
"""build_recent_changes.py — the colophon feed: what changed last, across
artifacts AND maps.

The key-artifacts gallery tracks .gd mtime; this widens it to the whole project —
every artifact's .gd and every map's map_data.json — and writes a single
recent-changes.json the site-wide Colophon reads, so any page can show "recently
changed, click to navigate". Also emits a curated PAGES index (the book/tooling
routes) for the colophon's navigation row.

Usage: python tools/build_recent_changes.py
"""
from __future__ import annotations

import glob
import json
import os
import re
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.join(os.path.dirname(REPO), "ada_encyclopedia")
REG_DIR = os.path.join(REPO, "commons", "artifacts", "registry")
MAPS_DIR = os.path.join(REPO, "commons", "maps")
OUT = os.path.join(ENC, "public", "recent-changes.json")

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def mtime(p: str) -> float:
    try:
        return os.path.getmtime(p)
    except OSError:
        return 0.0


def artifact_changes(limit: int = 60) -> list:
    """every registered artifact's .gd, by last-modified."""
    rows = []
    seen = set()
    for rp in glob.glob(os.path.join(REG_DIR, "*.json")):
        d = load_json(rp)
        arts = d.get("artifacts", d) if isinstance(d, dict) else {}
        if not isinstance(arts, dict):
            continue
        for k, e in arts.items():
            if not isinstance(e, dict) or not e.get("scene"):
                continue
            name = e.get("lookup_name", k)
            if name in seen:
                continue
            gd = e["scene"].replace("res://", REPO + os.sep).replace("/", os.sep)
            gd = re.sub(r"\.tscn$", ".gd", gd)
            if not os.path.exists(gd):
                alt = os.path.join(os.path.dirname(gd), name + ".gd")
                gd = alt if os.path.exists(alt) else gd
            if not os.path.exists(gd):
                continue
            seen.add(name)
            rows.append({"name": name, "kind": "artifact",
                         "mtime": round(mtime(gd)),
                         "route": f"/artifacts?name={name}"})
    rows.sort(key=lambda r: -r["mtime"])
    return rows[:limit]


def map_changes(limit: int = 60) -> list:
    """every map's map_data.json, by last-modified."""
    rows = []
    for md in glob.glob(os.path.join(MAPS_DIR, "*", "map_data.json")):
        name = os.path.basename(os.path.dirname(md))
        rows.append({"name": name, "kind": "map",
                     "mtime": round(mtime(md)),
                     "route": f"/maps?name={name}"})
    rows.sort(key=lambda r: -r["mtime"])
    return rows[:limit]


# Curated navigation index — the book/tooling pages built for the project.
PAGES = [
    {"label": "Composition", "route": "/composition", "note": "need · potential · actual"},
    {"label": "Key Artifacts", "route": "/key-artifacts", "note": "the book's DNA"},
    {"label": "Station Gallery", "route": "/station-gallery", "note": "the lab benches"},
    {"label": "Wall Gallery", "route": "/wall-gallery", "note": "curated walls"},
    {"label": "Book Log", "route": "/book-log", "note": "the session feed"},
    {"label": "Spine Graph", "route": "/spine-graph", "note": "the central path"},
    {"label": "Map Overview", "route": "/map-overview", "note": "all maps top-down"},
    {"label": "Order of Things", "route": "/order-of-things", "note": "every artifact in spine order"},
    {"label": "Atlas", "route": "/atlas", "note": "artifact distance"},
    {"label": "Final Lap", "route": "/final-lap", "note": "thesis-landing readiness"},
    {"label": "Concept Maps", "route": "/concept-maps", "note": "the ten ladders"},
    {"label": "Book", "route": "/book", "note": "the encyclopedia"},
    {"label": "Maps", "route": "/maps", "note": "map reader"},
    {"label": "Artifacts", "route": "/artifacts", "note": "the registry"},
]


def main() -> int:
    arts = artifact_changes()
    maps = map_changes()
    out = {
        "generated_by": "tools/build_recent_changes.py",
        "artifacts": arts,
        "maps": maps,
        "pages": PAGES,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with open(OUT, "w", encoding="utf-8", newline="\n") as f:
        json.dump(out, f, indent=1, ensure_ascii=False)
    print(f"recent-changes.json: {len(arts)} artifacts + {len(maps)} maps + "
          f"{len(PAGES)} pages -> {OUT}")
    if arts:
        print("  newest artifacts:", ", ".join(a["name"] for a in arts[:5]))
    if maps:
        print("  newest maps:", ", ".join(m["name"] for m in maps[:5]))
    return 0


if __name__ == "__main__":
    sys.exit(main())
