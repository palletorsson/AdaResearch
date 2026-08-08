# -*- coding: utf-8 -*-
"""spine_rebuild_set.py — the templates that would rebuild the spine.

A spine map is three things, and I measured them one at a time before putting
them together: the ROOM (its floor plan), the PLACEMENT CONTRACT (how the cast
sits in it — /template-maps' own definition of a template: "each template
decides where artifacts MAY stand"), and the CAST with its position in the
269-chapter order. The first two repeat. The third is the lesson and is nearly
unique per map.

So the rebuild set is the recurring (room x contract) pairs. Each is lifted from
a real spine map — the class's most-repeated exact floor plan where one exists,
its medoid otherwise — with the artifact cells marked as slots, which is the
contract made concrete.

    python tools/spine_rebuild_set.py derive
    python tools/spine_rebuild_set.py sheet --cover 90
"""
import json, math, hashlib, argparse, pathlib, sys
from collections import Counter, defaultdict

ROOT = pathlib.Path(__file__).resolve().parents[1]
OUT = ROOT / "commons/data/spine_rebuild_set.json"
sys.path.insert(0, str(ROOT / "tools"))
import walk_polish as wp                      # noqa: E402
import spine_typologies as sty                # noqa: E402

CONTRACT_TINT = {
    "solo": "#946b3d", "aisle": "#3d7a94", "wallside": "#8a4b6b", "cluster": "#5c7a3d",
    "axis": "#7a5c3d", "ring": "#4b6b8a", "grid": "#6b4b8a", "scatter": "#5a5a66",
    "empty": "#33343c",
}


def placement(md):
    """How the cast sits in the room. `scatter` is deliberately the residual —
    it is not a pattern, it is the absence of one, and naming it honestly is the
    whole point: 43% of the curriculum lands there."""
    S, U, I, WL = wp.grids(md)
    D = len(S); W = max((len(r) for r in S), default=0)
    pts = [(x, z) for z, row in enumerate(I) for x, c in enumerate(row)
           if str(c).strip() and not str(c).strip().startswith(wp.PRE)
           and not str(c).strip().startswith("hangar_")]
    n = len(pts)
    if n == 0: return "empty"
    if n == 1: return "solo"
    xs = [p[0] for p in pts]; zs = [p[1] for p in pts]
    if len(set(zs)) == 1 or len(set(xs)) == 1: return "axis"
    cx = sum(xs) / n; cz = sum(zs) / n
    rad = [math.hypot(x - cx, z - cz) for x, z in pts]
    mr = sum(rad) / n
    if n >= 4 and mr > 1.2 and (max(rad) - min(rad)) <= max(1.2, mr * 0.35): return "ring"
    if max(rad) <= 1.9: return "cluster"

    def edge(p):
        x, z = p
        return (x <= 1 or z <= 1 or x >= W - 2 or z >= D - 2 or
                any(wp.h_at(S, x + dx, z + dz) >= 4 for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1))))
    if all(edge(p) for p in pts): return "wallside"
    ux = sorted(set(xs)); uz = sorted(set(zs))
    even = lambda v: len(v) >= 3 and len({v[i + 1] - v[i] for i in range(len(v) - 1)}) == 1
    if even(ux) and even(uz): return "grid"
    if len(set(zs)) == 2 or len(set(xs)) == 2: return "aisle"
    return "scatter"


def derive(cover=90):
    maps = sty.spine_maps()
    by = defaultdict(list)
    for seq, nm in maps:
        md = wp.load(nm)
        if not md: continue
        s = sty.signature(md)
        if not s: continue
        by[(s, placement(md))].append((seq, nm, md))
    total = sum(len(v) for v in by.values())
    ranked = sorted(by.items(), key=lambda kv: -len(kv[1]))
    pats, run, needed = {}, 0, 0
    for i, ((sig, contract), members) in enumerate(ranked):
        run += len(members)
        hashes = Counter(sty.plan_hash(m[2]) for m in members)
        h, rep = hashes.most_common(1)[0]
        src = (next(m for m in members if sty.plan_hash(m[2]) == h) if rep > 1
               else sorted(members, key=lambda m: len(m[2]["layers"]["structure"]))[len(members) // 2])
        seq, nm, md = src
        room = sty.NAMES.get(sig, ("·".join(sig), ""))[0]
        key = "%s__%s" % (room.lower().replace("the ", "").replace(" ", "-"), contract)
        tile = sty.tile_of(md)
        pats[key] = {
            "label": "%s / %s" % (room, contract), "room": room, "contract": contract,
            "color": CONTRACT_TINT.get(contract, "#888"),
            "signature": list(sig), "maps": len(members),
            "share": round(100.0 * len(members) / total, 1),
            "cum": round(100.0 * run / total, 1),
            "sequences": sorted({s for s, _, _ in members}),
            "derived_from": nm, "w": max(len(r) for r in tile), "h": len(tile),
            "mode": "stamp", "tile": tile,
            "basis": ("%d of %d share this exact plan" % (rep, len(members))) if rep > 1
                     else "medoid; no two share a plan",
        }
        if not needed and run / total >= cover / 100.0:
            needed = i + 1
    OUT.write_text(json.dumps({
        "_readme": ("The recurring (room x placement contract) pairs of the 269 spine maps — the "
                    "templates that would rebuild them. A map is room x contract x cast; the first "
                    "two repeat, the cast is the lesson and is nearly unique. `scatter` is the "
                    "residual, not a pattern: it marks a map whose arrangement carries no contract."),
        "total_maps": total, "distinct_templates": len(pats),
        "needed_for_%d" % cover: needed,
        "patterns": pats}, indent=1), encoding="utf-8")
    print("%d spine maps -> %d distinct (room x contract) templates" % (total, len(pats)))
    print("%d templates cover %d%%\n" % (needed, cover))
    print("%-34s %5s %6s %7s  %s" % ("template", "maps", "share", "cum", "seqs"))
    for k, p in list(pats.items())[:16]:
        print("%-34s %5d %5.1f%% %6.1f%%  %d" % (p["label"][:34], p["maps"], p["share"],
                                                 p["cum"], len(p["sequences"])))
    return needed


def sheet(cover=90, cols=6, top=0):
    d = json.loads(OUT.read_text(encoding="utf-8"))
    pats = list(d["patterns"].items())
    need = top or d.get("needed_for_%d" % cover) or len(pats)
    pats = pats[:need]
    shown = sum(p["maps"] for _, p in pats)
    CELL, PAD = 8, 24
    colw = max(p["w"] for _, p in pats) * CELL + 22
    rowh = max(p["h"] for _, p in pats) * CELL + 46
    rows = (len(pats) + cols - 1) // cols
    W = PAD * 2 + cols * colw
    H = PAD + 62 + rows * rowh
    sv = ['<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">' % (W, H, W, H),
          '<rect width="100%" height="100%" fill="#12141a"/>',
          '<text x="%d" y="30" fill="#e8e4dc" font-family="Georgia,serif" font-size="19">'
          'The %d templates that rebuild %d%% of the spine</text>'
          % (PAD, len(pats), round(100.0 * shown / d["total_maps"])),
          '<text x="%d" y="48" fill="#8a8f9a" font-family="Georgia,serif" font-size="11.5">'
          'room \\u00d7 placement contract, lifted from real maps \\u00b7 floor light, void dark, '
          'slots marked \\u00b7 %d spine maps, %d distinct templates in all</text>'
          % (PAD, d["total_maps"], d["distinct_templates"])]
    for i, (k, p) in enumerate(pats):
        ox = PAD + (i % cols) * colw
        oy = 68 + (i // cols) * rowh
        sv.append('<text x="%d" y="%d" fill="%s" font-family="Georgia,serif" font-size="11">%s</text>'
                  % (ox, oy, p["color"], p["label"][:30]))
        sv.append('<text x="%d" y="%d" fill="#6f7480" font-family="Georgia,serif" font-size="9">'
                  '%d maps \\u00b7 %.1f%% \\u00b7 cum %.0f%%</text>' % (ox, oy + 12, p["maps"], p["share"], p["cum"]))
        for z, row in enumerate(p["tile"]):
            for x, c in enumerate(row):
                s = str(c); slot = s.endswith("s")
                hh = s.rstrip("s") or "0"
                try: hv = int(float(hh))
                except Exception: hv = 0
                fill = ("#191c24" if hv <= 0 else "#3a3f4c" if hv >= 4
                        else ["#c9c4b8", "#b3ada0", "#9d9789"][min(hv - 1, 2)])
                sv.append('<rect x="%.1f" y="%.1f" width="%d" height="%d" fill="%s"/>'
                          % (ox + x * CELL, oy + 18 + z * CELL, CELL, CELL, fill))
                if slot:
                    sv.append('<circle cx="%.1f" cy="%.1f" r="2.4" fill="%s"/>'
                              % (ox + x * CELL + CELL / 2.0, oy + 18 + z * CELL + CELL / 2.0, p["color"]))
    sv.append('</svg>')
    out = ROOT / "commons/data/spine_rebuild_set.svg"
    out.write_text("\n".join(sv), encoding="utf-8")
    print("sheet (%d templates) -> %s" % (len(pats), out))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("stage", choices=["derive", "sheet"])
    ap.add_argument("--cover", type=int, default=90)
    ap.add_argument("--top", type=int, default=0)
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    derive(a.cover) if a.stage == "derive" else sheet(a.cover, top=a.top)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
