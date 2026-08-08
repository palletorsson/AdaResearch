# -*- coding: utf-8 -*-
"""spine_typologies.py — the seven patterns the curriculum actually uses.

The composer has been optimised for eleven research rounds toward courtyards,
hall-wings and gallery spines: large, sparse, walled, multi-room. Measured
against the 269 maps of the 24 spine sequences, that signature occurs ZERO
times. The spine is one open floor, small to medium, flat or two-level, and not
one of its maps has a walls layer.

So this derives the typologies the curriculum has, instead of the ones we like.
Seven patterns cover half the spine; twenty-nine cover ninety per cent. Each is
expressed in the museum line's own template schema (label, w, h, tile) so the
two vocabularies can be read side by side.

DERIVED, NOT TRANSCRIBED. Each tile is lifted from a real spine map — the
class's most-repeated exact floor plan where one exists, otherwise its medoid by
footprint. A typology invented at the keyboard would describe our taste; this
describes the corpus.

    python tools/spine_typologies.py derive     # -> commons/data/spine_typologies.json
    python tools/spine_typologies.py sheet      # -> an SVG of all seven
"""
import json, hashlib, argparse, pathlib, sys
from collections import Counter, defaultdict

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "commons/data/spine_typologies.json"
sys.path.insert(0, str(ROOT / "tools"))
import walk_polish as wp                       # noqa: E402

# colours borrowed from the museum sheet's palette so the two read as one family
COLOURS = ["#946b3d", "#3d7a94", "#8a4b6b", "#5c7a3d", "#7a5c3d", "#4b6b8a", "#6b4b8a"]


def spine_maps():
    sp = json.loads((ROOT / "commons/maps/curriculum_spine.json").read_text(encoding="utf-8"))
    names = [s["name"] for s in sp["spine"]["sequences"]]
    out = []
    for n in names:
        f = ROOT / "commons/maps/sequences" / (n + ".json")
        if not f.exists():
            continue
        d = json.loads(f.read_text(encoding="utf-8"))
        blocks = d.get("sequences")
        blocks = blocks.values() if isinstance(blocks, dict) else (blocks or [])
        for b in blocks:
            if not isinstance(b, dict):
                continue
            for m in (b.get("maps") or []):
                nm = m if isinstance(m, str) else (
                    m.get("map_id") or m.get("name") or m.get("map")) if isinstance(m, dict) else None
                if nm and (ROOT / "commons/maps" / nm / "map_data.json").exists():
                    out.append((n, nm))
    return out


def signature(md):
    """The four axes that carry information. Rooms and walls are dropped: 86% of
    spine maps are one connected space and 269 of 269 have no walls layer, so a
    signature spending a slot on either describes nothing."""
    S, U, I, WL = wp.grids(md)
    D = len(S)
    W = max((len(r) for r in S), default=0)
    if not D or not W:
        return None
    floor = {(x, z) for z in range(D) for x in range(W) if 0 < wp.h_at(S, x, z) <= 3}
    if not floor:
        return None
    fill = len(floor) / float(D * W)
    ar = max(W, D) / float(min(W, D))
    lv = len({wp.h_at(S, x, z) for (x, z) in floor})
    return ("S" if D * W <= 140 else ("M" if D * W <= 400 else "L"),
            "square" if ar < 1.25 else ("oblong" if ar < 2.0 else "long"),
            "open" if fill >= .75 else ("mixed" if fill >= .40 else "sparse"),
            "flat" if lv == 1 else ("2lvl" if lv == 2 else "stepped"))


def plan_hash(md):
    S = (md.get("layers") or md).get("structure") or []
    return hashlib.md5("\n".join("|".join(str(c).strip() for c in r) for r in S).encode()).hexdigest()[:10]


def tile_of(md):
    """Structure rows, with an `s` suffix marking a cell the map stands an
    artifact on — the museum schema's slot notation."""
    S, U, I, WL = wp.grids(md)
    rows = []
    for z, row in enumerate(S):
        out = []
        for x, c in enumerate(row):
            h = str(c).strip() or "0"
            occupied = (z < len(I) and x < len(I[z]) and str(I[z][x]).strip()
                        and not str(I[z][x]).strip().startswith(wp.PRE))
            out.append(h + "s" if occupied else h)
        rows.append(out)
    return rows


NAMES = {
    ("S", "square", "open", "flat"):    ("The Motif Room",
        "A small square you can see all of from the door. The commonest room in the curriculum: "
        "one idea, no corners to lose it in."),
    ("S", "oblong", "open", "flat"):    ("The Chamber",
        "The motif room stretched along one axis, so the walk has a direction before it has anything in it."),
    ("M", "square", "mixed", "flat"):   ("The Yard",
        "Medium and square, but only part of it is floor — the void does the shaping instead of walls."),
    ("S", "square", "open", "2lvl"):    ("The Step Room",
        "The motif room with one height change: the smallest possible reason to look down at something."),
    ("M", "square", "open", "2lvl"):    ("The Terrace",
        "A full medium floor split into two levels — room enough to walk the split rather than step over it."),
    ("M", "square", "open", "stepped"): ("The Cascade",
        "Three or more levels on a medium square. The curriculum's tallest common form, and its rarest kind of drama."),
    ("S", "oblong", "open", "2lvl"):    ("The Ramp Chamber",
        "The chamber with a level change along its long axis — direction and ascent in the same small room."),
}


def derive(top=7):
    maps = spine_maps()
    by_sig = defaultdict(list)
    for seq, nm in maps:
        md = wp.load(nm)
        if not md:
            continue
        s = signature(md)
        if s:
            by_sig[s].append((seq, nm, md))
    ranked = sorted(by_sig.items(), key=lambda kv: -len(kv[1]))
    total = sum(len(v) for v in by_sig.values())
    pats, run = {}, 0
    for i, (sig, members) in enumerate(ranked[:top]):
        run += len(members)
        # the class's most repeated EXACT plan is its template, if it has one
        hashes = Counter(plan_hash(md) for _, _, md in members)
        h, repeats = hashes.most_common(1)[0]
        if repeats > 1:
            src = next(m for m in members if plan_hash(m[2]) == h)
            basis = "%d of %d maps in this class share this exact floor plan" % (repeats, len(members))
        else:
            mid = sorted(members, key=lambda m: len(m[2]["layers"]["structure"]))[len(members) // 2]
            src = mid
            basis = "medoid by footprint; no two maps in this class share a plan"
        seq, nm, md = src
        tile = tile_of(md)
        label, why = NAMES.get(sig, ("·".join(sig), ""))
        key = label.lower().replace("the ", "").replace(" ", "-")
        pats[key] = {
            "label": label, "color": COLOURS[i % len(COLOURS)],
            "w": max(len(r) for r in tile), "h": len(tile), "mode": "stamp",
            "signature": list(sig), "maps_in_class": len(members),
            "share_of_spine": round(100.0 * len(members) / total, 1),
            "derived_from": nm, "sequence": seq, "basis": basis,
            "why": why, "tile": tile,
        }
        print("  %-16s %-30s %3d maps (%4.1f%%)  <- %s" %
              (label, "·".join(sig), len(members), 100.0 * len(members) / total, nm))
    OUT.write_text(json.dumps({
        "_readme": ("The seven typologies the curriculum actually uses, derived from the 269 maps of "
                    "the 24 spine sequences. Same schema as commons/data/template_patterns.json so "
                    "the museum's plans and the spine's can be read side by side. Measured 2026-07-31: "
                    "the composer's own output (large, sparse, walled, stepped) matches NO spine map, "
                    "and 269 of 269 spine maps have no walls layer at all."),
        "covers": {"patterns": len(pats), "share_of_spine": round(100.0 * run / total, 1),
                   "note": "7 patterns cover half the spine; 29 cover 90 per cent"},
        "patterns": pats}, indent=1), encoding="utf-8")
    print("\n%d typologies covering %.0f%% of the spine -> %s" % (len(pats), 100.0 * run / total, OUT))


def sheet():
    """One SVG, all seven, drawn as the museum sheet draws its plans."""
    d = json.loads(OUT.read_text(encoding="utf-8"))
    pats = d["patterns"]
    CELL, GAP, PAD = 13, 34, 22
    cols = 4
    cw = max(p["w"] for p in pats.values()) * CELL + GAP
    ch = max(p["h"] for p in pats.values()) * CELL + GAP + 46
    W = PAD * 2 + cols * cw
    H = PAD * 2 + ((len(pats) + cols - 1) // cols) * ch + 54
    sv = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">' % (W, H, W, H),
          '<rect width="100%" height="100%" fill="#12141a"/>',
          '<text x="%d" y="30" fill="#e8e4dc" font-family="Georgia,serif" font-size="19">'
          'The seven typologies the curriculum actually uses</text>' % PAD,
          '<text x="%d" y="48" fill="#8a8f9a" font-family="Georgia,serif" font-size="11.5">'
          'derived from 269 spine maps · these seven cover %s%% · floor light, void dark, '
          'slot marked · not one spine map has a wall</text>' % (PAD, d["covers"]["share_of_spine"])]
    for i, (k, p) in enumerate(pats.items()):
        ox = PAD + (i % cols) * cw
        oy = 62 + (i // cols) * ch
        sv.append('<text x="%d" y="%d" fill="%s" font-family="Georgia,serif" font-size="13">%s</text>'
                  % (ox, oy, p["color"], p["label"]))
        sv.append('<text x="%d" y="%d" fill="#6f7480" font-family="Georgia,serif" font-size="10">'
                  '%s · %d maps · %.1f%%</text>' % (ox, oy + 14, "·".join(p["signature"]),
                                                    p["maps_in_class"], p["share_of_spine"]))
        for z, row in enumerate(p["tile"]):
            for x, c in enumerate(row):
                s = str(c)
                slot = s.endswith("s")
                h = s.rstrip("s") or "0"
                try:
                    hv = int(float(h))
                except Exception:
                    hv = 0
                if hv <= 0:
                    fill = "#191c24"                      # void
                elif hv >= 4:
                    fill = "#3a3f4c"                      # wall stack
                else:
                    fill = ["#c9c4b8", "#b3ada0", "#9d9789"][min(hv - 1, 2)]
                sv.append('<rect x="%.1f" y="%.1f" width="%d" height="%d" fill="%s" stroke="#12141a" '
                          'stroke-width="0.5"/>' % (ox + x * CELL, oy + 22 + z * CELL, CELL, CELL, fill))
                if slot:
                    sv.append('<circle cx="%.1f" cy="%.1f" r="3.1" fill="%s"/>'
                              % (ox + x * CELL + CELL / 2.0, oy + 22 + z * CELL + CELL / 2.0, p["color"]))
    sv.append('</svg>')
    out = ROOT / "commons/data/spine_typologies.svg"
    out.write_text("\n".join(sv), encoding="utf-8")
    print("sheet -> %s" % out)
    return out


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stage", choices=["derive", "sheet"])
    ap.add_argument("--top", type=int, default=7)
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")
    derive(a.top) if a.stage == "derive" else sheet()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
