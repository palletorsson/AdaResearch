# -*- coding: utf-8 -*-
"""harvest_segments.py — mine REAL maps into track segments (Palle 2026-07-25:
"what about the grammar and map templates that already exist").

The wizard's first ten segments were invented. The project already holds ~1,990
maps, many hand-composed with more care than any generator; grammar_fit (round
11) ranks them by how inducible their rule is. This tool cuts 13-wide windows
out of the best-organized maps and writes them as segments in the track's role
grammar — the corpus becomes the template library.

Each harvested segment carries TYPED SOCKETS (Minecraft's jigsaw idea): which
edges offer walk, at which columns, so segments can be matched rather than
merely stacked. Sockets are read from the window, never assumed.

  python tools/harvest_segments.py --scan                # candidates only
  python tools/harvest_segments.py --take 8 --write      # harvest into a file
  python tools/harvest_segments.py --write --out commons/data/wizard_track_harvested.json
"""
import json, argparse, pathlib, collections

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAPS = ROOT / "commons/maps"
INDEX = ROOT / "commons/data/grammar_fit_index.json"
OUT_DEFAULT = ROOT / "commons/data/wizard_track_harvested.json"
WIDTH = 13
PRE = ("cluster:", "mc:", "gridagent:", "criticalinfo:")
# a harvested window must not be a generated trial or a wizard product
SKIP_PREFIX = ("Trial_", "Probe_", "Wizard_", "Track_", "MapSim_", "Thread_Gate")


def h_of(S, x, z):
    try:
        return int(float(str(S[z][x]).strip() or 0))
    except Exception:
        return 0


def window_to_rows(md, x0, z0, depth):
    """Cut a 13 x depth window and translate it into the segment role grammar."""
    L = md["layers"]
    S = L.get("structure") or []
    U = L.get("utilities") or []
    I = L.get("interactables") or []
    WL = L.get("walls") or []
    rows, slots, walls = [], [], []
    for dz in range(depth):
        row = []
        for dx in range(WIDTH):
            x, z = x0 + dx, z0 + dz
            hh = h_of(S, x, z)
            util = str(U[z][x]).strip() if z < len(U) and x < len(U[z]) else ""
            inter = str(I[z][x]).strip() if z < len(I) and x < len(I[z]) else ""
            if hh <= 0:
                row.append("")
                continue
            if hh >= 4:
                row.append("4")
            elif hh == 3:
                row.append("3")
            elif hh == 2:
                row.append("2")
            else:
                row.append("1")
            if inter and not inter.startswith(PRE):
                # an artifact stood here in the source map -> this is a SLOT
                slots.append({"cell": [dx, dz], "cap": 16, "harvested_from": inter.split(":")[0]})
                if row[-1] == "1":
                    row[-1] = "1s"
            elif util.startswith("wp"):
                row[-1] = row[-1]          # keep the height; the engine re-derives wedges
        rows.append(row)
        if z < len(WL):
            for dx in range(WIDTH):
                x = x0 + dx
                seg = (WL[z][x] or "") if x < len(WL[z]) else ""
                for ch in seg:
                    walls.append([dx, dz, ch.lower(), ch.isupper()])
    return rows, slots, walls


def align_spine(rows):
    """Shift a window horizontally so its spine centre lands on the track's own
    spine (x=6). Harvested walks usually sit at the map edge; without this they
    could never concatenate with the authored segments (the SEAM law demands
    walk at the shared centre columns). Cells shifted off the edge must be void,
    or the window is rejected."""
    socks = sockets_of(rows)
    if not socks["spine"]:
        return None
    centre = socks["spine"][len(socks["spine"]) // 2]
    shift = 6 - centre
    if shift == 0:
        return rows
    out = []
    for row in rows:
        new = [""] * WIDTH
        for i, c in enumerate(row):
            j = i + shift
            if not c:
                continue
            if not (0 <= j < WIDTH):
                return None                 # would clip real content
            new[j] = c
        out.append(new)
    return out


def sockets_of(rows):
    """Typed sockets: which columns of the first/last row offer walk."""
    def open_cols(row):
        return [i for i, c in enumerate(row) if c in ("1", "1s", "2")]
    north, south = open_cols(rows[0]), open_cols(rows[-1])
    return {"north": north, "south": south,
            "spine": sorted(set(north) & set(south))}


def score_window(rows, slots):
    cells = [c for r in rows for c in r]
    filled = sum(1 for c in cells if c)
    walkish = sum(1 for c in cells if c in ("1", "1s", "2"))
    walled = sum(1 for c in cells if c in ("3", "4"))
    socks = sockets_of(rows)
    if not socks["spine"]:
        return -1, {}
    fill = filled / len(cells)
    slot_score = min(len(slots), 3) / 3.0
    wall_score = min(walled / max(1, filled), 0.35) / 0.35
    return (0.35 * fill + 0.35 * slot_score + 0.30 * wall_score), {
        "fill": round(fill, 2), "slots": len(slots),
        "walled_share": round(walled / max(1, filled), 2),
        "walk_cells": walkish}


def harvest(md, name, depth=7):
    S = md["layers"].get("structure") or []
    if not S: return []
    D, W = len(S), max(len(r) for r in S)
    if W < WIDTH or D < depth: return []
    out = []
    for z0 in range(0, D - depth + 1, max(2, depth // 2)):
        for x0 in range(0, W - WIDTH + 1, 3):
            rows, slots, walls = window_to_rows(md, x0, z0, depth)
            aligned = align_spine(rows)
            if aligned is None: continue
            if aligned is not rows:
                socks0 = sockets_of(rows)
                shift = 6 - socks0["spine"][len(socks0["spine"]) // 2]
                rows = aligned
                slots = [dict(s, cell=[s["cell"][0] + shift, s["cell"][1]]) for s in slots
                         if 0 <= s["cell"][0] + shift < WIDTH]
                walls = [[w[0] + shift, w[1], w[2], w[3]] for w in walls
                         if 0 <= w[0] + shift < WIDTH]
            sc, stats = score_window(rows, slots)
            if sc <= 0: continue
            out.append({"score": round(sc, 3), "src": name, "at": [x0, z0],
                        "rows": rows, "slots": slots, "walls": walls,
                        "sockets": sockets_of(rows), "stats": stats})
    out.sort(key=lambda r: -r["score"])
    return out[:2]                      # at most two windows per source map


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--scan", action="store_true")
    ap.add_argument("--write", action="store_true")
    ap.add_argument("--take", type=int, default=8)
    ap.add_argument("--pool", type=int, default=120)
    ap.add_argument("--out", default=str(OUT_DEFAULT))
    a = ap.parse_args()
    import sys; sys.stdout.reconfigure(encoding="utf-8")

    idx = json.loads(INDEX.read_text(encoding="utf-8"))["maps"]
    # the harvest pool: hand maps in the ALIVE band, best-organized first
    pool = [r for r in idx
            if r["band"] == "alive" and r["artifacts"] >= 2
            and not r["map"].startswith(SKIP_PREFIX)]
    pool.sort(key=lambda r: -r["organization"])
    pool = pool[:a.pool]
    cands = []
    for r in pool:
        p = MAPS / r["map"] / "map_data.json"
        if not p.exists(): continue
        try: md = json.loads(p.read_text(encoding="utf-8"))
        except Exception: continue
        for c in harvest(md, r["map"]):
            c["organization"] = r["organization"]
            c["rule"] = r["rule"]
            cands.append(c)
    cands.sort(key=lambda c: -(c["score"] * 0.7 + c["organization"] * 0.3))
    print(f"pool {len(pool)} maps -> {len(cands)} windows")
    for c in cands[:a.take]:
        print(f"  {c['score']:.3f} org {c['organization']:.2f} {c['src']:32s} at {c['at']} "
              f"slots {c['stats']['slots']} walls {c['stats']['walled_share']} "
              f"spine {c['sockets']['spine'][:4]}")
    if not a.write:
        return
    segs = {}
    used = collections.Counter()
    for c in cands[:a.take]:
        used[c["src"]] += 1
        key = f"h_{c['src'].lower()}_{used[c['src']]}"
        segs[key] = {
            "desc": f"harvested from {c['src']} at {c['at']} (organization {c['organization']}, "
                    f"rule: {' + '.join(c['rule']) or 'none'})",
            "rows": c["rows"], "slots": c["slots"], "walls": c["walls"],
            "sockets": c["sockets"], "harvest": {"src": c["src"], "at": c["at"],
                                                  "score": c["score"]},
        }
    pathlib.Path(a.out).write_text(json.dumps({
        "_readme": "HARVESTED track segments — 13-wide windows cut from the best-organized hand "
                   "maps (grammar_fit index) and translated into the track role grammar. Each "
                   "carries typed sockets (north/south open columns + the shared spine) so "
                   "segments can be MATCHED, not merely stacked (Minecraft's jigsaw idea). "
                   "Generated by tools/harvest_segments.py; merge into wizard_track_templates.json "
                   "or load alongside it.",
        "segments": segs}, indent=1), encoding="utf-8")
    print(f"wrote {len(segs)} segments -> {a.out}")


if __name__ == "__main__":
    main()
