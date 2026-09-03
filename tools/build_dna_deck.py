#!/usr/bin/env python3
"""build_dna_deck.py — the DNA variants, as cards the map curator can place.

2026-09-03, Palle: "there are also the dna artifact (/dna, /dna-galleries, for
each category /concept-galleries) add them to map-curator".

The curator's deck comes from `/{chapter}-concepts/manifest.json`, and every one
of those entries carries an EMPTY dna field, so the curator can only ever place
an artifact at its shipped default. Measured today: 849 artifacts declare
dna.axes, 1219 axes between them, 5164 possible variant cards — and exactly one
map in the whole corpus places any artifact at a non-default value. The families
exist on the bench and the museum has never met a variant.

This writes the same DeckEntry shape the curator already consumes, one file per
chapter plus an `unplaced` deck, with `prop` set to the PLACEMENT TOKEN INCLUDING
THE CONFIG — `noise_quarry#grain:coarse` — so clicking a card places the variant
rather than the default.

    python tools/build_dna_deck.py            write the decks
    python tools/build_dna_deck.py --dry      count only

Images: a card takes the first sweep PNG under the encyclopedia's public/ whose
filename carries both the token and the value; failing that the scene-catalog
shot of the artifact itself; failing that nothing, and the card says BLIND.
"""
from __future__ import annotations

import argparse
import collections
import glob
import json
import os
import re
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
ENC = os.path.join(os.path.dirname(ROOT), "ada_encyclopedia")
PUB = os.path.join(ENC, "public")
OUT = os.path.join(PUB, "dna-deck")


def registry() -> dict:
    reg = {}
    for f in sorted(glob.glob(os.path.join(ROOT, "commons", "artifacts", "registry", "*.json"))):
        try:
            for k, v in json.load(open(f, encoding="utf-8")).get("artifacts", {}).items():
                reg[k] = v
        except Exception:
            continue
    return reg


def chapters() -> dict[str, set[str]]:
    """chapter -> the set of its live map names"""
    authored = json.load(open(os.path.join(ROOT, "commons", "data", "map_authored.json"), encoding="utf-8"))
    out = {}
    for sid in authored:
        p = os.path.join(ROOT, "commons", "maps", "sequences", sid + ".json")
        if not os.path.exists(p):
            continue
        try:
            d = json.load(open(p, encoding="utf-8"))
        except Exception:
            continue
        s = d["sequences"].get(sid) if isinstance(d.get("sequences"), dict) else d
        if isinstance(s, dict):
            out[sid] = set(s.get("maps", []))
    return out


def index_images() -> dict[str, list[str]]:
    """lower-cased png basename -> web paths, for matching a token and a value"""
    idx = collections.defaultdict(list)
    for p in glob.glob(os.path.join(PUB, "**", "*.png"), recursive=True):
        rel = "/" + os.path.relpath(p, PUB).replace("\\", "/")
        idx[os.path.splitext(os.path.basename(p))[0].lower()].append(rel)
    return idx


def pick_image(images: dict, token: str, value: str) -> str:
    t, v = token.lower(), str(value).lower()
    for name, paths in images.items():
        if t in name and v in name:
            return paths[0]
    cat = images.get(t)
    if cat:
        return cat[0]
    return ""


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--dry", action="store_true")
    args = ap.parse_args()

    reg = registry()
    chap = chapters()
    images = index_images()

    # which chapter does an artifact belong to? the one whose live maps hold it.
    owner: dict[str, str] = {}
    for sid, maps in chap.items():
        for m in maps:
            p = os.path.join(ROOT, "commons", "maps", m, "map_data.json")
            if not os.path.exists(p):
                continue
            try:
                layers = json.load(open(p, encoding="utf-8"))["layers"]
            except Exception:
                continue
            for row in layers.get("interactables", []):
                for c in row:
                    c = str(c).strip()
                    if c and c != "-":
                        owner.setdefault(c.split(":")[0].split("#")[0], sid)

    decks: dict[str, list] = collections.defaultdict(list)
    blind = 0
    for token, entry in sorted(reg.items()):
        axes = ((entry.get("dna") or {}).get("axes") or {})
        if not axes:
            continue
        where = owner.get(token, "unplaced")
        desc = str(entry.get("description", ""))
        for axis, values in axes.items():
            for i, value in enumerate(values):
                img = pick_image(images, token, str(value))
                if not img:
                    blind += 1
                decks[where].append({
                    "id": f"{token}::{axis}::{value}",
                    "prop": f"{token}#{axis}:{value}",
                    "index": len(decks[where]),
                    "label": f"{token} · {value}",
                    "subtitle": f"{axis} = {value}" + ("" if img else "  (BLIND)"),
                    "notes": (f"DNA variant. Axis {axis!r} of {token}, value {i + 1} of "
                              f"{len(values)}: {', '.join(str(x) for x in values)}. {desc}"[:600]),
                    "image": img,
                    "dna": {axis: value},
                })

    total = sum(len(v) for v in decks.values())
    print(f"DNA deck: {total} variant cards across {len(decks)} deck(s); {blind} have no image")
    for k in sorted(decks, key=lambda k: -len(decks[k])):
        print(f"   {len(decks[k]):5d}  {k}")
    if args.dry:
        return 0

    os.makedirs(OUT, exist_ok=True)
    for name, entries in decks.items():
        doc = {
            "version": 1,
            "description": (f"DNA variant cards for {name}. Generated by "
                            "tools/build_dna_deck.py from the artifact registry's declared "
                            "dna.axes. `prop` is the placement token WITH its config, so "
                            "placing a card places the variant, not the default."),
            "capture_size": None,
            "partial_axes": {},
            "entries": entries,
        }
        with open(os.path.join(OUT, f"{name}.json"), "w", encoding="utf-8") as fh:
            json.dump(doc, fh, indent=1, ensure_ascii=False)
    with open(os.path.join(OUT, "index.json"), "w", encoding="utf-8") as fh:
        json.dump({"decks": {k: len(v) for k, v in sorted(decks.items())}}, fh, indent=1)
    print(f"wrote {len(decks) + 1} files to {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
