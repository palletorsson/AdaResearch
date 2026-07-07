#!/usr/bin/env python3
"""chapter_maps.py — prune each sequence to its LOAD-BEARING maps (R-028).

Palle: "there are many unneeded maps in the sequences; no more than 10 per
sequence, only the load-bearing ones in tutorial order. Key map + a sequence
synthesis." This applies the baseline's load-bearing logic UP a level — from
"which artifacts" to "which maps." A map is load-bearing if it hosts a beat's
cast artifact (or an alt) or a voltage piece; a map that hosts none is a
tutorial passenger and drops to depth (kept in the game, not in the book).

For each sequence: maps in tutorial order, each scored by how many baseline
beats/voltage it hosts; the load-bearing ones (cap 10) become the chapter's
pages; the rest are recorded as at-depth. Writes doc/book/chapter_maps.json —
the chapter structure the writing process (walked.md pages + synthesis) follows.

Usage: python tools/chapter_maps.py [--seq=<name>]
"""
from __future__ import annotations

import json
import os
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SEQ_DIR = os.path.join(REPO, "commons", "maps", "sequences")
MAPS_DIR = os.path.join(REPO, "commons", "maps")
BASE_DIR = os.path.join(REPO, "doc", "book", "baselines")
OUT = os.path.join(REPO, "doc", "book", "chapter_maps.json")
CAP = 10

SPINE = ["primitives", "transformation", "symmetry", "array_tutorial", "color", "change",
         "isosurfaces", "boolean_surfaces", "forces", "formfinding", "wavefunctions", "randomness",
         "noise", "cellularautomata", "fractals", "lsystems", "proceduralgeneration",
         "swarmintelligence", "softbodies", "machinelearning", "graphtheory",
         "foundationscrisis", "qfeplaboratory", "postfoundationscrisis"]

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass


def load_json(p):
    with open(p, encoding="utf-8") as f:
        return json.load(f)


def seq_maps(seq: str) -> list:
    p = os.path.join(SEQ_DIR, f"{seq}.json")
    if not os.path.exists(p):
        return []
    d = load_json(p)
    out = []
    for v in (d.get("sequences") or {}).values():
        for m in v.get("maps", []):
            n = m if isinstance(m, str) else m.get("name", "")
            if n and n not in out:
                out.append(n)
    return out


def map_artifacts(mapname: str) -> set:
    p = os.path.join(MAPS_DIR, mapname, "map_data.json")
    if not os.path.exists(p):
        return set()
    d = load_json(p)
    out = set()
    for row in d.get("layers", {}).get("interactables", []):
        for cell in row:
            tk = str(cell).strip()
            if not tk or tk == " ":
                continue
            tk = tk.split(":")[0].split("#")[0].strip()
            if tk and tk != "cluster":
                out.add(tk)
    return out


def baseline_load(seq: str):
    """(beat_casts+alts set, voltage set) for the sequence."""
    p = os.path.join(BASE_DIR, f"{seq}.json")
    if not os.path.exists(p):
        return set(), set()
    d = load_json(p)
    beats, volt = set(), set()
    for b in d.get("beats", []):
        if not b.get("missing"):
            beats.add(b.get("cast", ""))
            beats.update(b.get("alts", []))
    for v in d.get("voltage", []):
        volt.add(v.get("piece", ""))
    return beats, volt


def select(seq: str) -> dict:
    maps = seq_maps(seq)
    beats, volt = baseline_load(seq)
    scored = []
    for m in maps:
        arts = map_artifacts(m)
        b = len(arts & beats)
        v = len(arts & volt)
        scored.append({"map": m, "beats": b, "voltage": v, "score": b * 2 + v,
                       "load_bearing": (b + v) > 0})
    # keep: load-bearing maps in TUTORIAL order, capped. If more than CAP are
    # load-bearing, keep the highest-scoring CAP (still reported in tutorial order).
    lb = [s for s in scored if s["load_bearing"]]
    if len(lb) > CAP:
        keep_names = {s["map"] for s in sorted(lb, key=lambda s: -s["score"])[:CAP]}
        keep = [s for s in scored if s["map"] in keep_names]
    else:
        keep = lb
    keep_names = {s["map"] for s in keep}
    drop = [s["map"] for s in scored if s["map"] not in keep_names]
    return {"seq": seq, "total_maps": len(maps),
            "keep": [s["map"] for s in keep],
            "keep_detail": keep,
            "drop": drop}


def main() -> int:
    one = next((a.split("=", 1)[1] for a in sys.argv[1:] if a.startswith("--seq=")), None)
    seqs = [one] if one else SPINE
    result = {"generated_by": "tools/chapter_maps.py", "cap": CAP, "chapters": {}}
    tot_keep = tot_total = 0
    print(f"{'sequence':22s} total  keep  drop   (pages = keep + 1 synthesis)")
    for s in seqs:
        r = select(s)
        result["chapters"][s] = {"keep": r["keep"], "drop": r["drop"],
                                 "total_maps": r["total_maps"]}
        tot_keep += len(r["keep"]); tot_total += r["total_maps"]
        flag = "" if len(r["keep"]) <= CAP else " ⚠over cap"
        print(f"{s:22s} {r['total_maps']:4d}  {len(r['keep']):4d}  {len(r['drop']):4d}{flag}")
    if not one:
        with open(OUT, "w", encoding="utf-8", newline="\n") as f:
            json.dump(result, f, indent=1, ensure_ascii=False)
        pages = tot_keep + len(seqs)
        print(f"\nTOTAL: {tot_total} maps -> {tot_keep} load-bearing kept "
              f"({tot_total-tot_keep} to depth) + {len(seqs)} syntheses = {pages} pages")
        print(f"wrote {OUT}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
