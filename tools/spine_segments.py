# -*- coding: utf-8 -*-
"""spine_segments.py — the spine cut into corridor segments.

Palle: a template should be a SMALLER SEGMENT that combines into maps, the way
endless_museum.gd concatenates museum plans along z. Not one plan per map — a
stock of pieces. And at the corridor's own scale: x 13-17, z 6-20.

Measured against the 269 spine maps, that box is a poor fit and the misfit is
itself worth knowing: the curriculum's rooms are 10-12 wide (132 of 269), NARROWER
than the corridor's 13-17. The corridor's width came from the body — two promise
radii, 16 m — so the spine's rooms sit below the distance at which a thing is
supposed to call to you. 41 maps fit the box exactly; 166 fit it relaxed to 10-17.

So the bank is cut at 10-17 x 6-20, which is where the material actually is, and
the corridor already knows how to join mismatched widths: it opens each segment
with a vestibule the width of the widest plan.

  - a map inside the box IS a segment (most of the spine already is one)
  - a map deeper than 20 is SLICED along z at its own seams (rows of void or wall)
  - a map outside the width band is recorded and skipped, not cropped: cropping
    invents a plan nobody drew

    python tools/spine_segments.py build
    python tools/spine_segments.py sheet --top 30
"""
import json, hashlib, argparse, pathlib, sys
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "commons/data/spine_segments.json"
sys.path.insert(0, str(ROOT / "tools"))
import walk_polish as wp                       # noqa: E402
import spine_typologies as sty                 # noqa: E402
import spine_rebuild_set as rb                 # noqa: E402

W_MIN, W_MAX = 10, 17          # the corridor box, relaxed to where the spine lives
D_MIN, D_MAX = 6, 20
TINT = {"solo": "#946b3d", "aisle": "#3d7a94", "wallside": "#8a4b6b", "cluster": "#5c7a3d",
        "axis": "#7a5c3d", "ring": "#4b6b8a", "grid": "#6b4b8a", "scatter": "#5a5a66",
        "empty": "#33343c"}


def height(c):
    """A structure cell is usually a height, and sometimes a scene token —
    `7_1_elementary_ca_vr` sits in one spine map's structure layer. An
    unparseable cell is SOMETHING standing on the ground, so it reads as floor;
    the original token stays in the tile so nothing is invented or lost."""
    s = str(c).strip().rstrip("s")
    if not s:
        return 0
    try:
        return int(float(s))
    except Exception:
        return 1


def tile_rows(S, I, z0, z1):
    """Structure rows z0..z1 with artifact cells marked as slots — the museum
    schema's notation, so a segment is readable by the same consumers."""
    out = []
    for z in range(z0, z1):
        row = []
        for x in range(len(S[z])):
            h = str(S[z][x]).strip() or "0"
            occ = (z < len(I) and x < len(I[z]) and str(I[z][x]).strip()
                   and not str(I[z][x]).strip().startswith(wp.PRE)
                   and not str(I[z][x]).strip().startswith("hangar_"))
            row.append(h + "s" if occ else h)
        out.append(row)
    return out


def seams(S):
    """Rows the map itself treats as a break: entirely void, or entirely wall.
    A segment boundary the author already drew beats one cut every N rows."""
    out = []
    for z, row in enumerate(S):
        vals = [wp.h_at(S, x, z) for x in range(len(row))]
        if not vals:
            continue
        if all(v <= 0 for v in vals) or all(v >= 4 for v in vals):
            out.append(z)
    return out


def cut(S, I):
    """(z0, z1) spans of depth D_MIN..D_MAX. A map already inside the box is one
    segment; a deeper map is cut at its seams, and only falls back to an even
    division when it has none."""
    D = len(S)
    if D <= D_MAX:
        return [(0, D)] if D >= D_MIN else []
    br = [0] + [z for z in seams(S) if 0 < z < D] + [D]
    spans, a = [], 0
    for b in br[1:]:
        if b - a >= D_MIN:
            if b - a <= D_MAX:
                spans.append((a, b)); a = b
            else:
                n = max(1, round((b - a) / float(D_MAX)))
                step = (b - a) // n
                for i in range(n):
                    z0 = a + i * step
                    z1 = b if i == n - 1 else a + (i + 1) * step
                    if D_MIN <= z1 - z0 <= D_MAX:
                        spans.append((z0, z1))
                a = b
    return spans


def build():
    segs, skipped = {}, Counter()
    shapes = Counter()
    for seq, nm in sty.spine_maps():
        md = wp.load(nm)
        if not md:
            continue
        S, U, I, WL = wp.grids(md)
        W = max((len(r) for r in S), default=0)
        if not (W_MIN <= W <= W_MAX):
            skipped["narrow" if W < W_MIN else "wide"] += 1
            continue
        spans = cut(S, I)
        if not spans:
            skipped["shallow"] += 1
            continue
        for i, (z0, z1) in enumerate(spans):
            tile = tile_rows(S, I, z0, z1)
            floor = sum(1 for r in tile for c in r if 0 < height(c) <= 3)
            if floor < 12:                       # a slice with no room in it
                skipped["thin"] += 1
                continue
            h = hashlib.md5(json.dumps(tile).encode()).hexdigest()[:10]
            shapes[h] += 1
            if h in segs:
                segs[h]["from"].append("%s#%d" % (nm, i))
                continue
            sub = {"layers": {"structure": [[c.rstrip("s") for c in r] for r in tile],
                              "utilities": [], "interactables": [], "walls": []}}
            for z, r in enumerate(tile):
                sub["layers"]["interactables"].append(
                    ["x" if str(c).endswith("s") else " " for c in r])
            segs[h] = {
                "key": "seg_%s" % h, "label": "%s %s" % (nm[:22], "" if len(spans) == 1 else "[%d]" % i),
                "w": W, "h": z1 - z0, "mode": "stamp", "source": "spine-segment",
                "sequence": seq, "from": ["%s#%d" % (nm, i)],
                "slots": sum(1 for r in tile for c in r if str(c).endswith("s")),
                "contract": rb.placement(sub), "whole_map": len(spans) == 1,
                "tile": tile,
            }
    for h, s in segs.items():
        s["reuse"] = shapes[h]
        s["color"] = TINT.get(s["contract"], "#888")
    ranked = dict(sorted(segs.items(), key=lambda kv: (-kv[1]["reuse"], -kv[1]["slots"])))
    OUT.write_text(json.dumps({
        "_readme": ("The spine cut into corridor segments (x %d-%d, z %d-%d) — a stock of pieces to "
                    "combine, the way endless_museum concatenates museum plans. Most spine maps are "
                    "one segment already; deeper maps are cut at their own seams. Maps outside the "
                    "width band are SKIPPED, not cropped: cropping invents a plan nobody drew."
                    % (W_MIN, W_MAX, D_MIN, D_MAX)),
        "box": {"w": [W_MIN, W_MAX], "d": [D_MIN, D_MAX]},
        "counts": {"segments": len(segs), "skipped": dict(skipped),
                   "whole_map": sum(1 for s in segs.values() if s["whole_map"]),
                   "sliced": sum(1 for s in segs.values() if not s["whole_map"])},
        "patterns": ranked}, indent=1), encoding="utf-8")
    print("%d segments from the spine (box x %d-%d, z %d-%d)" % (len(segs), W_MIN, W_MAX, D_MIN, D_MAX))
    print("  whole maps: %d   sliced from deeper maps: %d"
          % (sum(1 for s in segs.values() if s["whole_map"]),
             sum(1 for s in segs.values() if not s["whole_map"])))
    print("  skipped: %s" % dict(skipped))
    print("  contracts:", dict(Counter(s["contract"] for s in segs.values())))
    print("-> %s" % OUT)


def sheet(top=30, cols=8):
    d = json.loads(OUT.read_text(encoding="utf-8"))
    pats = list(d["patterns"].values())[:top]
    CELL, PAD = 6, 24
    colw = max(p["w"] for p in pats) * CELL + 18
    rowh = max(p["h"] for p in pats) * CELL + 40
    rows = (len(pats) + cols - 1) // cols
    W = PAD * 2 + cols * colw
    H = PAD + 60 + rows * rowh
    c = d["counts"]
    sv = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">' % (W, H, W, H),
          '<rect width="100%" height="100%" fill="#12141a"/>',
          '<text x="%d" y="30" fill="#e8e4dc" font-family="Georgia,serif" font-size="19">'
          'The spine as corridor segments</text>' % PAD,
          '<text x="%d" y="48" fill="#8a8f9a" font-family="Georgia,serif" font-size="11.5">'
          '%d segments at x 10-17 / z 6-20 \\u00b7 %d whole maps, %d sliced \\u00b7 slot dots '
          'coloured by placement contract \\u00b7 showing %d</text>'
          % (PAD, c["segments"], c["whole_map"], c["sliced"], len(pats))]
    for i, p in enumerate(pats):
        ox = PAD + (i % cols) * colw
        oy = 66 + (i // cols) * rowh
        sv.append('<text x="%d" y="%d" fill="%s" font-family="Georgia,serif" font-size="9">%s</text>'
                  % (ox, oy, p["color"], p["label"][:22]))
        sv.append('<text x="%d" y="%d" fill="#6f7480" font-family="Georgia,serif" font-size="8">'
                  '%dx%d \\u00b7 %s \\u00b7 %d slots</text>' % (ox, oy + 10, p["w"], p["h"],
                                                         p["contract"], p["slots"]))
        for z, row in enumerate(p["tile"]):
            for x, cc in enumerate(row):
                s = str(cc); slot = s.endswith("s")
                hv = height(cc)
                fill = ("#191c24" if hv <= 0 else "#3a3f4c" if hv >= 4
                        else ["#c9c4b8", "#b3ada0", "#9d9789"][min(hv - 1, 2)])
                sv.append('<rect x="%.1f" y="%.1f" width="%d" height="%d" fill="%s"/>'
                          % (ox + x * CELL, oy + 16 + z * CELL, CELL, CELL, fill))
                if slot:
                    sv.append('<circle cx="%.1f" cy="%.1f" r="1.9" fill="%s"/>'
                              % (ox + x * CELL + CELL / 2.0, oy + 16 + z * CELL + CELL / 2.0, p["color"]))
    sv.append('</svg>')
    out = ROOT / "commons/data/spine_segments.svg"
    out.write_text("\n".join(sv), encoding="utf-8")
    print("sheet (%d of %d) -> %s" % (len(pats), c["segments"], out))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stage", choices=["build", "sheet"])
    ap.add_argument("--top", type=int, default=30)
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    build() if a.stage == "build" else sheet(a.top)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
