#!/usr/bin/env python3
"""gen_wanghall.py — THE BREATHING HALL: one continuous corridor whose WIDTH
VARIES along its length.

Palle: "Can we use wang tiles halls that are just one hall with different widths
and like 7 footprint artifacts?"

ONE hall runs along +x as a chain of SEGMENTS — one per teaching beat, plus a
short entry and exit. Each segment is a rectangle of floor centred on a common
axis (y_mid); the segment WIDTH breathes: narrow passages open into wide
chambers and pinch shut again. The heroes (each beat's cast) stand in their own
segment, sized by their honest measured footprint.

THE WANG EDGE CONTRACT, generalised. wall_kit made 8x8 blocks whose edges match
by construction; here the same idea drops the block grid: every segment is
floor, and the whole silhouette is sealed by ONE rule —

    a cell gets a wall on a side  iff  the neighbour on that side is void.

Walls live only on the floor/void boundary, so no seam can leak and no door is
needed: because all segments share the centre axis, consecutive segments overlap
by the full width of the narrower one, and their floors are continuous. The step
where the width changes becomes an exposed vertical wall stub — the breath made
visible. Guaranteed walkable by construction (the pathfinder confirms).

Voltage pieces (the critical charge) are inserted as their own NARROW segments
(width 8) — the chapel-pressure move: critical charge = compression. The
silhouette becomes wide - narrow - wide.

The strategy only invents the FLOOR IDEA; map_principal.finish() turns it into a
complete Ada map (dimensions, palettes, proximity_lod, spawn/exit, wall runs,
wall props). mission_graph supplies the mission (beats + voltage), the size
oracle (resolve_cast), the integration wrapper, and the supporting-cast staffer.

Usage:
  python tools/gen_wanghall.py --seq=randomness [--name=MissionWang_Randomness]
"""
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import mission_graph as mg          # reuse: mission, size oracle, staffing
import staging_beds as sb           # reuse: the bed a hero stands on
import map_principal as mp          # the finisher contract


# ── segment geometry ─────────────────────────────────────────────────────────
# the breath bands. Voltage pinches to 8; non-voltage segments alternate between
# a WIDE chamber [18,22] and a NARROW passage [12,14]. The gap between the bands
# (and between narrow and the voltage pinch) is >= 4 BY CONSTRUCTION, so the
# "consecutive widths differ by >= 4, alternating" contract always holds — and
# narrow (>=12) always clears the voltage pinch (8) by >= 4, so a voltage never
# sits too close in width to its neighbour.
VOLT_WIDTH = 8      # the chapel pinch: critical charge = compression
VOLT_LEN = 6
ENTRY_LEN = 4
EXIT_LEN = 4
ENTRY_BASE = 12     # nominal base width for the roomless entry/exit segments


def _clamp(v, lo, hi):
    return max(lo, min(hi, v))


def _hero_cells(name):
    """max measured grid-cell footprint of a cast (2 when unmeasured)."""
    s = mg._sizes().get(name, {})
    gc = s.get("grid_cells")
    if not gc:
        return 2
    return max(1, int(round(max(float(gc[0]), float(gc[1])))))


def _seg_len(cells):
    """segment LENGTH 8..14 by footprint — bigger hero, longer segment.
    (Palle: keep the maps a bit tighter around the artifacts.)"""
    return _clamp(6 + cells * 2, 8, 14)


def _base_width(cells):
    return _clamp(cells * 2 + 6, 8, 18)


def _band_width(base, parity):
    """FORCE variety: wide chamber vs narrow passage (>= 4 apart); tight —
    the chamber hugs its hero, the walk still breathes."""
    if parity == 0:
        return _clamp(max(14, base), 14, 18)     # wide chamber
    return 10                                    # narrow passage


# ── the build ────────────────────────────────────────────────────────────────

def build(seq, name):
    beats, volt = mg.load_mission(seq)
    if not beats:
        print(f"no beats in baseline for {seq}")
        return 1
    n = len(beats)

    # 1. the mission: which beat each voltage piece attaches to. build_halls'
    # spreading rule (voltage k -> spread-out beat), nudged to a DISTINCT beat
    # so two pinches never abut (which would break the width contract).
    volt_after, used = {}, set()
    for k, piece in enumerate(volt):
        t = round(k * (n - 1) / max(1, len(volt) - 1)) if len(volt) > 1 else n // 2
        if t in used:
            for d in range(1, n):
                nxt = [c for c in (t + d, t - d) if 0 <= c < n and c not in used]
                if nxt:
                    t = nxt[0]
                    break
        used.add(t)
        volt_after.setdefault(t, []).append(piece)

    # 2. the ordered segment chain: entry, beats (voltage inserted after its
    # target beat), exit.
    segments = [{"kind": "entry", "cast": "", "alts": [], "len": ENTRY_LEN,
                 "base": ENTRY_BASE}]
    for i, b in enumerate(beats):
        cells = _hero_cells(b["cast"])
        segments.append({"kind": "beat", "i": i, "cast": b["cast"],
                         "alts": b.get("alts", []), "len": _seg_len(cells),
                         "base": _base_width(cells)})
        for piece in volt_after.get(i, []):
            segments.append({"kind": "voltage", "cast": piece, "alts": [],
                             "len": VOLT_LEN, "base": VOLT_WIDTH})
    segments.append({"kind": "exit", "cast": "", "alts": [], "len": EXIT_LEN,
                     "base": ENTRY_BASE})

    # 3. widths: voltage pinned; non-voltage alternate wide/narrow. x tiles +x.
    parity = 0
    for s in segments:
        if s["kind"] == "voltage":
            s["width"] = VOLT_WIDTH
        else:
            s["width"] = _band_width(s["base"], parity)
            parity ^= 1
    x = 0
    for s in segments:
        s["x0"] = x
        x += s["len"]
    W = x

    # 4. vertical centring on a common axis — the wang edge contract: because
    # every segment is centred on y_mid, the narrower one's floor is fully inside
    # the wider one's span, so consecutive floors are continuous (no door needed).
    max_w = max(s["width"] for s in segments)
    H = max_w + 4                                  # a void margin all round
    y_mid = H // 2
    for s in segments:
        s["y0"] = y_mid - s["width"] // 2
        s["y1"] = s["y0"] + s["width"] - 1

    layers = mp.blank_layers(W, H)
    for s in segments:                             # fill every segment with SEA
        for r in range(s["y0"], s["y1"] + 1):
            for c in range(s["x0"], s["x0"] + s["len"]):
                layers["structure"][r][c] = mg.SEA

    # 5. THE WALL PASS — walls live on the floor/void boundary, nowhere else.
    # This one rule draws the whole hull AND the vertical step stubs where the
    # width breathes. No seam can leak; no door is needed.
    def is_floor(r, c):
        return 0 <= r < H and 0 <= c < W and layers["structure"][r][c] != "0"
    for r in range(H):
        for c in range(W):
            if not is_floor(r, c):
                continue
            if not is_floor(r - 1, c):
                mp.wall(layers, r, c, "n")
            if not is_floor(r + 1, c):
                mp.wall(layers, r, c, "s")
            if not is_floor(r, c - 1):
                mp.wall(layers, r, c, "w")
            if not is_floor(r, c + 1):
                mp.wall(layers, r, c, "e")

    # 6. heroes + supporting-cast slots. Register thirds run over the BEAT
    # segments: first third arrival, last third depth, middle work.
    beat_idxs = [j for j, s in enumerate(segments) if s["kind"] == "beat"]
    nb = len(beat_idxs)
    beat_pos = {j: p for p, j in enumerate(beat_idxs)}

    def third_of(p):
        if p < nb / 3:
            return 0
        if p >= 2 * nb / 3:
            return 2
        return 1

    swaps, slots, seg_meta = [], [], []
    for j, s in enumerate(segments):
        if s["kind"] in ("entry", "exit"):
            seg_meta.append({"cast": None, "x0": s["x0"], "len": s["len"],
                             "width": s["width"], "kind": s["kind"]})
            continue
        cx = s["x0"] + s["len"] // 2
        # size-govern by the segment the hero must live in
        chosen, swapped = mg.resolve_cast(s["cast"], s["alts"],
                                          float(s["width"] - 6), 3.4)
        if swapped:
            swaps.append(f"{swapped}->{chosen}")
        s["cast"] = chosen

        # INTEGRATION (the common wrapper, reused from mission_graph): self/field
        # stand bare; cube/wrap/plinth/frame get housing; else a staging bed.
        cr, cc = y_mid, cx
        integ, cfam = mg._integration().get(chosen, (None, None))
        if integ in ("self", "field"):
            layers["interactables"][cr][cc] = chosen
        elif integ in ("cube", "wrap", "plinth", "frame"):
            fam = cfam if integ in ("cube", "wrap") else integ
            layers["interactables"][cr][cc] = f"sim_cube#family:{fam}#mount:{chosen}"
        else:
            bed = sb.select_bed(chosen)
            if bed["is_wall"]:
                cr, cc = s["y0"] + 1, cx          # hang the graphic on the wall
                layers["interactables"][cr][cc] = f"{bed['bed']}:180#mount:{chosen}"
            else:
                layers["interactables"][cr][cc] = f"{bed['bed']}#mount:{chosen}"

        if s["kind"] == "beat":
            F = min(s["len"], s["width"]) - 2
            slots.append({"act": third_of(beat_pos[j]), "kind": "beat",
                          "cast": chosen, "oy": s["y0"] + 1, "ox": s["x0"] + 1,
                          "F": F})
        seg_meta.append({"cast": chosen, "x0": s["x0"], "len": s["len"],
                         "width": s["width"], "kind": s["kind"]})

    # 7. the supporting cast staffs the beat segments (same-domain benches).
    # Runs before finish() writes spawn/exit, but the slots only ever touch beat
    # columns — disjoint from the entry/exit segments — so occupancy is safe.
    def register_of(act):
        return {0: "arrival", 1: "work", 2: "depth"}[act]
    staffed = mg.staff_supporting_cast(layers, slots, mg._bench_library(seq),
                                       register_of)

    # 8. palette bands: three rects splitting the hall along x, full height.
    t1, t2 = W // 3, 2 * W // 3
    bands = [{"rect": [0, 0, t1 - 1, H - 1], "register": "arrival"},
             {"rect": [t1, 0, t2 - 1, H - 1], "register": "work"},
             {"rect": [t2, 0, W - 1, H - 1], "register": "depth"}]

    # 9. mission metadata + the finisher contract (spawn/exit written by finish).
    mission = {"beats": n, "segments": seg_meta, "swaps": swaps,
               "supporting_cast": staffed}
    mp.finish(name, seq, "breathing-wanghall", layers, mission, bands,
              spawn=(y_mid, 2), exit_cell=(y_mid, W - 3))

    # 10. the report — the width sequence is the proof the hall breathes.
    widths = [s["width"] for s in segments]
    tag = {"entry": "IN", "exit": "OUT", "voltage": "V", "beat": "*"}
    print(f"{name}: {n} beats + {len(volt)} voltage -> {len(segments)} segments "
          f"({W}x{H} cells), y_mid={y_mid}")
    print("  width sequence: " + " ".join(f"{tag[s['kind']]}{s['width']}"
                                          for s in segments))
    print("  widths only:    " + " ".join(str(w) for w in widths))
    for s in segments:
        cast = s["cast"] or "-"
        print(f"    {s['kind']:8s} x0={s['x0']:3d} L={s['len']:2d} "
              f"w={s['width']:2d}  {cast}")
    if swaps:
        print("  size-governed swaps: " + ", ".join(swaps))
    if staffed:
        print("  supporting cast: " + ", ".join(
            f"{s['name']} (beside {s['beside']}, {s['register']})" for s in staffed))
    print(f"view: /map-viewer?map={name}")
    return 0


def main():
    arg = lambda k, d: next((a.split("=", 1)[1] for a in sys.argv
                             if a.startswith(f"--{k}=")), d)
    seq = arg("seq", None)
    if not seq:
        print(__doc__)
        return 1
    name = arg("name", f"MissionWang_{seq.title().replace('_', '')}")
    return build(seq, name)


if __name__ == "__main__":
    sys.exit(main())
