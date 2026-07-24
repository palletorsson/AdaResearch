# -*- coding: utf-8 -*-
"""wizard_compose.py — THE COMPOSER behind /map-wizard (and research rounds).

Runs the canon order of operations (commons/data/composition_grammar.json)
stage by stage and emits a JSON snapshot AFTER EVERY STAGE, so the wizard can
show the map developing: order (a 1D strip), typology (three frames), rooms
grown around artifacts, walls+doors (+ hangar cluster dressing), the yard,
elevation (a SECTION along the walk), paths, final grid + metrics.

Not to be confused with tools/compose_map.py (2026-05, narrative-grammar
composer) — this one is the canon-driven staged engine the wizard drives.

Spec (JSON via --spec-file or --spec):
{
  "cast": ["line", ...],            # measured artifact lookup names
  "hero": "laser_measure",          # gets rot 270 (aim along walk)
  "anti": "mold_network",           # quarantine yard occupant ("" disables)
  "order": {"strategy": "narrative"} | {"strategy":"manual","list":[...]},
  "typology": "courtyard",          # gallery_spine | courtyard | hall_wings
  "grower": "sdf_disc",             # rect | sdf_disc | sdf_blob
  "walls": {"dressing": {"<artifact>": "<cluster_name>"}},   # hangar wall system
  "yard": {"enabled": true},
  "elevation": "procession",        # flat | procession
  "trim_approach": false            # round-4 lever: cut hall to room extent
}

CLI:
  python tools/wizard_compose.py                          # default spec, stdout
  python tools/wizard_compose.py --spec-file s.json --out stages.json
  python tools/wizard_compose.py --save MyMap --pathfind  # writes commons/maps/MyMap
                                                          # + wizard_recipes/MyMap.json
"""
import json, math, subprocess, sys, argparse, pathlib, datetime

ROOT = pathlib.Path(__file__).resolve().parents[1]
elems = json.loads((ROOT / "commons/data/artifact_elements.json").read_text(encoding="utf-8"))["artifacts"]
GRAMMAR = json.loads((ROOT / "commons/data/composition_grammar.json").read_text(encoding="utf-8"))
MW = GRAMMAR["metric_weights"]
BAND = GRAMMAR["room_band"]
COMPACT_T = GRAMMAR.get("compact_target", 0.5)
TISSUE_FREE = GRAMMAR.get("tissue_free_run", 8)

DEFAULT_SPEC = {
    "cast": ["line", "laser_measure", "helicoid", "crystal_cluster",
             "csg_difference_demo", "geodesic_dome", "branching_growth_algorithm"],
    "hero": "laser_measure",
    "anti": "mold_network",
    "order": {"strategy": "narrative"},
    "typology": "hall_wings",
    "grower": "rect",
    "walls": {"dressing": {}},
    "yard": {"enabled": True},
    "elevation": "procession",
    "trim_approach": False,
    # round 5 — arrival as story: compression threshold, prologue artifact, overview parapet
    "arrival": {"threshold": "none", "prologue": False, "overview": "none"},
    # the TRACK (Palle 2026-07-24): 13-wide, as-long-as-needed-in-z concatenation of
    # authored 13x7 template segments; order poured into slots; kin-fill extra slots
    "track": {"enabled": False, "plan": "auto", "kin_fill": True},
}

# ---------- measured floor ----------
def union(k):
    s = (elems.get(k, {}).get("union_aabb") or {}).get("size") or [1.0, 1.0, 1.0]
    return (max(0.2, s[0]), max(0.2, s[2]), max(0.2, s[1]))  # w, d, h (raw probe truth)

REACH_ASPECT = 4.0
def body(k):
    # THE REACH LAW (canon): a high-aspect envelope is reach, not body.
    # Rooms are sized by the body; the reach is aimed along the walk.
    w, d, h = union(k)
    if max(w, d) / min(w, d) > REACH_ASPECT:
        m = min(w, d)
        return (m, m, h, True)
    return (w, d, h, False)
def fp(k):
    w, d, _, _ = body(k); return max(w, d)
def afp_cells(k):
    w, d, _, _ = body(k); return max(1, math.ceil(w) * math.ceil(d))

# ---------- stage 1: order ----------
def order_crescendo(c): return sorted(c, key=fp)
def order_narrative(c, hero):
    lead = [k for k in ("line",) if k in c]
    front = lead + ([hero] if hero in c and hero not in lead else [])
    rest = sorted([k for k in c if k not in front], key=fp)
    return front + rest
def order_rhythm(c):
    s = sorted(c, key=fp); out = []
    while s:
        out.append(s.pop(0))
        if s: out.append(s.pop(-1))
    return out

def resolve_order(spec):
    cast, hero = spec["cast"], spec.get("hero", "")
    st = spec["order"].get("strategy", "narrative")
    if st == "manual":
        want = [k for k in spec["order"].get("list", []) if k in cast]
        return want + [k for k in cast if k not in want]
    if st == "crescendo": return order_crescendo(cast)
    if st == "rhythm": return order_rhythm(cast)
    return order_narrative(cast, hero)

# ---------- stage 3: room growers ----------
def sdf_box(px, pz, cx, cz, hw, hd):
    dx, dz = abs(px - cx) - hw, abs(pz - cz) - hd
    return math.hypot(max(dx, 0), max(dz, 0)) + min(max(dx, dz), 0.0)

def grow_rect(cx, cz, k, clr):
    hw, hd = body(k)[0] / 2, body(k)[1] / 2
    return {(x, z) for x in range(math.floor(cx - hw - clr), math.ceil(cx + hw + clr) + 1)
                    for z in range(math.floor(cz - hd - clr), math.ceil(cz + hd + clr) + 1)}
def grow_sdf_disc(cx, cz, k, clr):
    hw, hd = body(k)[0] / 2, body(k)[1] / 2
    return {(x, z) for z in range(int(cz - hd - clr - 1), int(cz + hd + clr + 2))
                    for x in range(int(cx - hw - clr - 1), int(cx + hw + clr + 2))
            if sdf_box(x + 0.5, z + 0.5, cx, cz, hw, hd) <= clr}
def grow_sdf_blob(cx, cz, k, clr, ddir=(0, 1)):
    hw, hd = body(k)[0] / 2, body(k)[1] / 2
    vx, vz = cx + ddir[0] * (hw + clr * 0.9), cz + ddir[1] * (hd + clr * 0.9)
    vr, kk = max(1.2, clr * 0.8), 1.6
    out = set()
    for z in range(int(min(cz - hd, vz) - clr - 2), int(max(cz + hd, vz) + clr + 2)):
        for x in range(int(min(cx - hw, vx) - clr - 2), int(max(cx + hw, vx) + clr + 2)):
            d1 = sdf_box(x + 0.5, z + 0.5, cx, cz, hw, hd) - clr
            d2 = math.hypot(x + 0.5 - vx, z + 0.5 - vz) - vr
            h = max(kk - abs(d1 - d2), 0) / kk
            if min(d1, d2) - h * h * kk * 0.25 <= 0: out.add((x, z))
    return out
GROWERS = {"rect": grow_rect, "sdf_disc": grow_sdf_disc, "sdf_blob": grow_sdf_blob}

def grow_banded(gname, cx, cz, k, ddir):
    lo = BAND['lo_x_artifact_cells'] * afp_cells(k) + 3
    clr, cells = 1.2, set()
    for _ in range(6):
        cells = (grow_sdf_blob(cx, cz, k, clr, ddir) if gname == "sdf_blob"
                 else GROWERS[gname](cx, cz, k, clr))
        if len(cells) >= lo: break
        clr += 0.5
    return cells

# ---------- stage 2.5: typologies (yard integrated as a slot) ----------
YARD_R = 4
def typo_gallery_spine(order):
    zc = 10
    slots, x = [], 5.0
    for i, k in enumerate(order):
        side = -1 if i % 2 == 0 else 1
        hw, hd, _, _ = body(k); hw /= 2; hd /= 2
        cz = zc + side * (hd + 1.8 + 1.2)
        cx = x + hw + 1.2
        slots.append((cx, cz, (0, -side)))
        x = cx + hw + 1.8
    hall = {(xx, zz) for xx in range(3, math.ceil(x) + 1) for zz in (zc - 1, zc, zc + 1)}
    yard_c = (math.ceil(x) + YARD_R + 1, zc)
    return hall, slots, (3, zc), yard_c
def typo_courtyard(order):
    ccx, ccz, R = 13.0, 12.0, 4.0
    hall = {(x, z) for x in range(int(ccx - R - 1), int(ccx + R + 2))
                    for z in range(int(ccz - R - 1), int(ccz + R + 2))
            if math.hypot(x + 0.5 - ccx, z + 0.5 - ccz) <= R}
    slots = []
    n = len(order) + 1                      # +1: the yard takes a ring slot
    for i, k in enumerate(order):
        ang = -math.pi / 2 + i * (2 * math.pi / n)
        hw, hd, _, _ = body(k); hw /= 2; hd /= 2
        rr = R + 1.6 + max(hw, hd) + 1.0
        slots.append((ccx + rr * math.cos(ang), ccz + rr * math.sin(ang),
                      (-math.cos(ang), -math.sin(ang))))
    ang = -math.pi / 2 + len(order) * (2 * math.pi / n)
    rr = R + 1.6 + YARD_R + 0.5
    yard_c = (int(ccx + rr * math.cos(ang)), int(ccz + rr * math.sin(ang)))
    return hall, slots, (int(ccx - R), int(ccz)), yard_c
def typo_hall_wings(order):
    hz0, hz1 = 9, 12
    slots, x = [], 5.0
    for i, k in enumerate(order):
        hw, hd, _, _ = body(k); hw /= 2; hd /= 2
        side = -1 if i % 2 == 0 else 1
        cx = x + hw + 1.2
        cz = (hz0 - (hd + 1.6)) if side < 0 else (hz1 + (hd + 1.6))
        slots.append((cx, cz, (0, 1 if side < 0 else -1)))
        x = cx + hw + 1.6
    hall = {(xx, zz) for xx in range(3, math.ceil(x) + 1) for zz in range(hz0, hz1 + 1)}
    yard_c = (math.ceil(x) + YARD_R + 1, (hz0 + hz1) // 2)
    return hall, slots, (3, (hz0 + hz1) // 2), yard_c
TYPOLOGIES = {"gallery_spine": typo_gallery_spine, "courtyard": typo_courtyard, "hall_wings": typo_hall_wings}

DIRS = {(-1, 0): "w", (1, 0): "e", (0, -1): "n", (0, 1): "s"}
# cluster Y-rot so the dressing faces the artifact: local +z (front) → door dir
ROT_FOR_DIR = {(0, 1): 0, (1, 0): 90, (0, -1): 180, (-1, 0): 270}

def carve_passage(a, b):
    cells = set()
    x, z = a
    path = [(x, z)]
    while (x, z) != b:
        if x != b[0]: x += 1 if b[0] > x else -1
        elif z != b[1]: z += 1 if b[1] > z else -1
        path.append((x, z))
    mid = len(path) // 2
    for i, (px, pz) in enumerate(path):
        w = 3 if abs(i - mid) <= 1 else 2
        horiz = (i + 1 < len(path) and path[i + 1][0] != px) or (i > 0 and path[i - 1][0] != px)
        for off in range(-(w // 2), w - (w // 2)):
            cells.add((px, pz + off) if horiz else (px + off, pz))
    return cells, path

def cl(cells):  # cell set → sorted [[x,z],...] for JSON
    return sorted([list(c) for c in cells])

# ---------- the staged composition ----------
def compose(spec):
    if (spec.get("track") or {}).get("enabled"):
        return compose_track(spec)
    stages = []
    cast, hero, anti = spec["cast"], spec.get("hero", ""), spec.get("anti", "")
    gname, tname, ename = spec["grower"], spec["typology"], spec["elevation"]
    yard_on = bool(spec.get("yard", {}).get("enabled", True)) and anti != ""

    # 1 ORDER — the 1D array made visible
    order = resolve_order(spec)
    strip = []
    for k in order:
        w, d, h = union(k)
        _, _, _, reach = body(k)
        strip.append({"name": k, "w": round(w, 2), "d": round(d, 2), "h": round(h, 2),
                      "cells": afp_cells(k), "reach": reach, "measured": k in elems})
    stages.append({"op": "order", "chosen": spec["order"].get("strategy", "narrative"),
                   "strip": strip,
                   "previews": {s: (order_crescendo(cast) if s == "crescendo" else
                                    order_rhythm(cast) if s == "rhythm" else
                                    order_narrative(cast, hero))
                                for s in ("crescendo", "narrative", "rhythm")}})

    # 8 ARRIVAL (resolved early — it shapes the frame): compression threshold,
    # prologue artifact standing IN the threshold, overview parapet at the yard
    arrv = spec.get("arrival") or {}
    thr_mode = arrv.get("threshold", "none")
    prologue_on = bool(arrv.get("prologue")) and thr_mode == "compression"
    over_mode = arrv.get("overview", "none")
    room_order = order[1:] if (prologue_on and len(order) > 1) else order

    # 2 FOOTPRINT lives inside the strip (probe truth) — no geometry yet
    # 2.5 TYPOLOGY — compute ALL THREE frames so options are visible, then choose
    typo_prev = {}
    for tn, fn in TYPOLOGIES.items():
        h, sl, sp, yc = fn(room_order)
        typo_prev[tn] = {"hall": cl(h), "slots": [[round(a, 1), round(b, 1)] for a, b, _ in sl],
                         "spawn": list(sp), "yard": list(yc)}
    hall, slots, spawn_a, yard_c = TYPOLOGIES[tname](room_order)
    stages.append({"op": "typology", "chosen": tname, "options": typo_prev})

    threshold = set(); prologue_cell = None; mouth_door = None

    # 3 ROOM grown around each artifact
    rooms = []
    for k, (cx, cz, dd) in zip(room_order, slots):
        dn = (1 if dd[0] > 0 else -1, 0) if abs(dd[0]) >= abs(dd[1]) else (0, 1 if dd[1] > 0 else -1)
        cells = grow_banded(gname, cx, cz, k, dn) - hall
        rooms.append([k, cells, (round(cx), round(cz)), dn])
    stages.append({"op": "room", "chosen": gname, "hall": cl(hall),
                   "rooms": [{"name": k, "cells": cl(c), "anchor": list(a)} for k, c, a, _ in rooms]})

    # threshold: a two-wide walled corridor CARVED AFTER the rooms, west of all
    # floor in its rows — compression before the release (v3's entry, composable).
    # If it mouths into a room rather than the hall, that edge becomes a DOOR.
    if thr_mode == "compression":
        sz = spawn_a[1]
        floorish = set(hall)
        for _, cells, _, _ in rooms: floorish |= cells
        rows = (sz, sz + 1)
        in_rows = [x for (x, z) in floorish if z in rows]
        if in_rows:
            wx = min(in_rows)
            L = 5
            threshold = {(x, z) for x in range(wx - L, wx) for z in rows}
            spawn_a = (wx - L, sz)
            if prologue_on:
                prologue_cell = (wx - 3, sz)
            for z in rows:
                if (wx, z) in floorish:
                    mouth_door = ((wx, z), "w", (wx - 1, z))   # room/hall cell, its west edge
                    break

    # 5-pre YARD geometry (needed before normalisation)
    yard_cells = set()
    passage = set()
    if yard_on:
        yard_cells = {(x, z) for x in range(yard_c[0] - YARD_R, yard_c[0] + YARD_R + 1)
                              for z in range(yard_c[1] - YARD_R, yard_c[1] + YARD_R + 1)}
        hn = min(hall, key=lambda h: math.dist(h, yard_c))
        ye = (yard_c[0] - YARD_R - 1, yard_c[1])
        passage, _ = carve_passage(hn, ye)
        passage -= yard_cells

    # TRIM (round-4 lever): cut the hall approach to the composed extent
    # (skipped under compression — the threshold hangs off the untrimmed spawn)
    trimmed = 0
    if spec.get("trim_approach") and thr_mode == "none" and tname in ("gallery_spine", "hall_wings"):
        roomx = [c[0] for _, cells, _, _ in rooms for c in cells]
        if roomx:
            keep_from = min(roomx) - 2
            drop = {c for c in hall if c[0] < keep_from}
            if drop and spawn_a in drop:
                spawn_a = min(hall - drop, key=lambda c: (c[0], abs(c[1] - spawn_a[1])))
            trimmed = len(drop)
            hall -= drop

    floor = set(hall) | passage | threshold
    for _, cells, _, _ in rooms: floor |= cells
    allc = floor | yard_cells
    xs = [c[0] for c in allc]; zs = [c[1] for c in allc]
    offx, offz = 2 - min(xs), 2 - min(zs)
    N = lambda c: (c[0] + offx, c[1] + offz)
    hall = {N(c) for c in hall}; passage = {N(c) for c in passage}
    floor = {N(c) for c in floor}; threshold = {N(c) for c in threshold}
    rooms = [[k, {N(c) for c in cells}, N(a), d] for k, cells, a, d in rooms]
    spawn_a = N(spawn_a); yard_c = N(yard_c)
    if prologue_cell: prologue_cell = N(prologue_cell)
    if mouth_door: mouth_door = (N(mouth_door[0]), mouth_door[1], N(mouth_door[2]))
    yard_cells = {N(c) for c in yard_cells}
    W = max(c[0] for c in allc) + offx + 4; D = max(c[1] for c in allc) + offz + 4

    # 6 ELEVATION — heights along the walk (procession: second half rises)
    hmap = {}
    if ename == "procession":
        for i, (k, cells, a, d) in enumerate(rooms):
            if i >= len(rooms) // 2:
                for c in cells: hmap[c] = 2
    profile = [{"i": i, "name": k, "h": (2 if (ename == "procession" and i >= len(rooms) // 2) else 1),
                "art_h": round(union(k)[2], 2)} for i, (k, _, _, _) in enumerate(rooms)]

    S = [["0"] * W for _ in range(D)]
    U = [[" "] * W for _ in range(D)]
    I = [[" "] * W for _ in range(D)]
    WL = [[""] * W for _ in range(D)]

    if yard_on:
        for x in range(yard_c[0] - YARD_R, yard_c[0] + YARD_R + 1):
            for z in range(yard_c[1] - YARD_R, yard_c[1] + YARD_R + 1):
                if 0 <= x < W and 0 <= z < D:
                    edge = (abs(x - yard_c[0]) == YARD_R or abs(z - yard_c[1]) == YARD_R)
                    S[z][x] = "4" if edge else "1"
        mx, mz = yard_c
        for x in range(yard_c[0] - YARD_R + 1, yard_c[0] + YARD_R):
            for z in range(yard_c[1] - YARD_R + 1, yard_c[1] + YARD_R):
                if 2.2 < math.dist((x, z), (mx, mz)) <= 3.2: S[z][x] = "0"
        I[mz][mx] = anti
        S[mz][yard_c[0] - YARD_R] = "1"

    for (x, z) in floor:
        if 0 <= x < W and 0 <= z < D: S[z][x] = str(hmap.get((x, z), 1))

    # 4 WALLS: room boundaries with one door to the hall (+ wp on height change)
    door_info = []
    for k, cells, (ax, az), dd in rooms:
        boundary = []
        for (x, z) in cells:
            for (dx, dz), code in DIRS.items():
                nb = (x + dx, z + dz)
                if nb not in cells: boundary.append(((x, z), code, nb))
        cands = [b for b in boundary if b[2] in hall] or \
                sorted(boundary, key=lambda b: min((math.dist(b[2], h) for h in hall), default=99))[:1]
        (bx, bz), code, nb = min(cands, key=lambda b: math.dist(b[0], (ax, az)))
        if nb not in floor and 0 <= nb[0] < W and 0 <= nb[1] < D and S[nb[1]][nb[0]] == "0":
            S[nb[1]][nb[0]] = "1"; floor.add(nb)
        for (cx_, cz_), cd, nb_ in boundary:
            if not (0 <= cx_ < W and 0 <= cz_ < D): continue
            if ((cx_, cz_), cd) == ((bx, bz), code): WL[cz_][cx_] += cd.upper()
            elif mouth_door and ((cx_, cz_), cd) == (mouth_door[0], mouth_door[1]):
                WL[cz_][cx_] += cd.upper()      # the threshold mouths into this room: a door
                if hmap.get((cx_, cz_), 1) != hmap.get(mouth_door[2], 1):
                    U[cz_][cx_] = "wp"
                    mx2, mz2 = mouth_door[2]
                    if 0 <= mx2 < W and 0 <= mz2 < D: U[mz2][mx2] = "wp"
            elif nb_ in floor: WL[cz_][cx_] += cd
        if hmap.get((bx, bz), 1) != hmap.get(nb, 1):
            U[bz][bx] = "wp"
            if 0 <= nb[0] < W and 0 <= nb[1] < D: U[nb[1]][nb[0]] = "wp"
        door_info.append(((bx, bz), nb, k))

    # 4b DRESSING — the hangar wall system enters the composition
    dressing_spec = (spec.get("walls") or {}).get("dressing") or {}
    dressed = []
    for k, cells, (ax, az), dn in rooms:
        cname = dressing_spec.get(k)
        if not cname: continue
        back = (-dn[0], -dn[1])            # away from the door
        cand = [c for c in cells if (c[0] + dn[0], c[1] + dn[1]) in cells
                and (c[0] + back[0], c[1] + back[1]) not in cells]
        if not cand: continue
        cx_, cz_ = min(cand, key=lambda c: math.dist(c, (ax, az)))
        if I[cz_][cx_] == " ":
            rot = ROT_FOR_DIR[dn]
            I[cz_][cx_] = f"cluster:{cname}:{rot}"
            dressed.append({"room": k, "cluster": cname, "cell": [cx_, cz_], "rot": rot})

    # threshold flanks: walls both long sides — the compression is the walls
    if threshold:
        thrz0 = min(z for (_, z) in threshold)
        for (x, z) in threshold:
            WL[z][x] += ("n" if z == thrz0 else "s")

    segs = []
    for z in range(D):
        for x in range(W):
            for ch in WL[z][x]:
                segs.append({"x": x, "z": z, "d": ch.lower(), "door": ch.isupper()})
    stages.append({"op": "walls", "segments": segs, "dressing": dressed,
                   "floor": cl(floor), "hall": cl(hall),
                   "rooms": [{"name": k, "cells": cl(c)} for k, c, _, _ in rooms],
                   "doors": [{"room": k, "cell": list(b), "to": list(nb)} for b, nb, k in door_info]})

    # 5 TEMPLATES_FIXED — the yard as a composition slot
    stages.append({"op": "templates_fixed", "enabled": yard_on,
                   "yard": {"center": list(yard_c), "r": YARD_R, "cells": cl(yard_cells)} if yard_on else None})

    stages.append({"op": "elevation", "chosen": ename, "profile": profile})

    # artifacts + spawn + teleporter
    for k, cells, (ax, az), _ in rooms:
        tok = f"{k}:270" if k == hero else k
        if 0 <= ax < W and 0 <= az < D: I[az][ax] = tok
    if prologue_cell:
        k0 = order[0]
        px0, pz0 = prologue_cell
        if 0 <= px0 < W and 0 <= pz0 < D and I[pz0][px0] == " ":
            I[pz0][px0] = f"{k0}:270" if k0 == hero else k0
    U[spawn_a[1]][spawn_a[0]] = "s"
    tp = None
    parapet = set(); parapet_side = None
    if yard_on:
        tx, tz = yard_c[0] + YARD_R + 2, yard_c[1]
        if tx >= W: tx = W - 1
        S[tz][tx] = "0"; U[tz][tx] = "t"; tp = (tx, tz)
        for x in range(yard_c[0] + YARD_R + 1, tx):
            if S[tz][x] == "0": S[tz][x] = "1"
        for x in range(yard_c[0] - YARD_R - 1, yard_c[0] + YARD_R + 2):
            z = yard_c[1] + YARD_R + 1
            if 0 <= x < W and 0 <= z < D and S[z][x] == "0": S[z][x] = "1"
        for z in range(min(yard_c[1], yard_c[1] + YARD_R + 1), max(yard_c[1], yard_c[1] + YARD_R + 1) + 1):
            x = yard_c[0] - YARD_R - 1
            if 0 <= x < W and 0 <= z < D and S[z][x] == "0": S[z][x] = "1"
        # overview parapet, GUARANTEED (r6): search sides s→w→n for a legal
        # 3-cell landing (east is the teleporter's). All-or-nothing per side:
        # landing only on void/plain floor (never rooms), wall lowered 4→3
        # behind it, approach ONLY from existing connected floor, wp pairs on
        # the climb. From h2 (eye ~3.7m) you look over the h3 wall; the yard
        # stays sealed.
        if over_mode == "parapet":
            roomcells = set()
            for _, cells_, _, _ in rooms: roomcells |= cells_
            yx, yz = yard_c
            SIDES = [
                ("s", [(yx - 1, yz + YARD_R + 1), (yx, yz + YARD_R + 1), (yx + 1, yz + YARD_R + 1)],
                       [(yx - 1, yz + YARD_R), (yx, yz + YARD_R), (yx + 1, yz + YARD_R)],
                       [(yx - 2, yz + YARD_R + 1), (yx + 2, yz + YARD_R + 1)]),
                ("w", [(yx - YARD_R - 1, yz - 1), (yx - YARD_R - 1, yz), (yx - YARD_R - 1, yz + 1)],
                       [(yx - YARD_R, yz - 1), (yx - YARD_R, yz), (yx - YARD_R, yz + 1)],
                       [(yx - YARD_R - 1, yz - 2), (yx - YARD_R - 1, yz + 2)]),
                ("n", [(yx - 1, yz - YARD_R - 1), (yx, yz - YARD_R - 1), (yx + 1, yz - YARD_R - 1)],
                       [(yx - 1, yz - YARD_R), (yx, yz - YARD_R), (yx + 1, yz - YARD_R)],
                       [(yx - 2, yz - YARD_R - 1), (yx + 2, yz - YARD_R - 1)]),
            ]
            for side, land, wallc, approach in SIDES:
                if not all(0 <= x < W and 0 <= z < D for (x, z) in land + wallc): continue
                if not all(S[z][x] in ("0", "1") and (x, z) not in roomcells for (x, z) in land): continue
                ap = [(x, z) for (x, z) in approach
                      if 0 <= x < W and 0 <= z < D and S[z][x] == "1" and (x, z) not in roomcells]
                if not ap: continue
                for (x, z) in land: S[z][x] = "2"
                for (x, z) in wallc:
                    if S[z][x] == "4": S[z][x] = "3"
                parapet = set(land)
                parapet_side = side
                for (ax2, az2) in ap[:2]:
                    end = min(land, key=lambda c: abs(c[0] - ax2) + abs(c[1] - az2))
                    if U[az2][ax2] == " " and U[end[1]][end[0]] == " ":
                        U[az2][ax2] = "wp"; U[end[1]][end[0]] = "wp"
                break
    else:
        lastr = rooms[-1]
        bx = max(c[0] for c in lastr[1]) + 2
        bz = lastr[2][1]
        if bx >= W: bx = W - 1
        U[bz][bx] = "t"; tp = (bx, bz)
        for x in range(max(c[0] for c in lastr[1]) + 1, bx):
            if S[bz][x] == "0": S[bz][x] = "1"

    # 7 PATHS — connective tissue, cared for
    stages.append({"op": "paths", "passage": cl(passage), "spawn": list(spawn_a),
                   "teleporter": list(tp) if tp else None, "trimmed_cells": trimmed,
                   "floor": cl(floor), "yard": cl(yard_cells)})

    # 8 ARRIVAL — the entry as story: pinch, release, prologue, overlook
    story = {"pinch": 1.0 if len(threshold) >= 8 else 0.0,
             "release": 0.0,
             "prologue": 1.0 if prologue_cell else 0.0,
             "overlook": 1.0 if parapet else 0.0}
    if threshold:
        ex, ez = mouth_door[0] if mouth_door else (max(x for (x, _) in threshold) + 1,
                                                   min(z for (_, z) in threshold))
        open9 = sum(1 for dx in (-1, 0, 1) for dz in (-1, 0, 1) if (ex + dx, ez + dz) in floor)
        story["release"] = min(open9 / 6.0, 1.0)
    story_score = sum(story.values()) / 4.0
    stages.append({"op": "arrival",
                   "chosen": {"threshold": thr_mode, "prologue": prologue_on, "overview": over_mode},
                   "threshold": cl(threshold), "parapet": cl(parapet), "parapet_side": parapet_side,
                   "prologue": ({"artifact": order[0], "cell": list(prologue_cell)} if prologue_cell else None),
                   "story": {k: round(v, 2) for k, v in story.items()}})

    data = {"map_info": {"name": "X", "lookup_name": "X", "title": "X",
        "description": "wizard: " + "/".join([spec["order"].get("strategy", "?"), gname, tname, ename]),
        "dimensions": {"width": W, "depth": D, "max_height": 4},
        "version": "wizard-v1",
        "design": {"order": spec["order"], "grower": gname, "typology": tname,
                   "elevation": ename, "dressing": dressing_spec,
                   "trim_approach": bool(spec.get("trim_approach")), "yard": yard_on}},
        "settings": {"cube_size": 1.0, "gutter": 0.0, "show_grid": True, "enable_physics": True, "enter_type": "I",
                     "wall_segments": {"height": 2.2, "thickness": 0.12}},
        "utility_definitions": {"t": {"type": "teleporter", "name": "Gate passed", "description": "",
                                      "properties": {"action": "next_in_sequence"}}},
        "layers": {"structure": S, "utilities": U, "walls": WL, "interactables": I}}

    m = metrics(data, rooms, hall, passage, floor, door_info, story_score)
    stages.append({"op": "final", "W": W, "D": D, "metrics": m["parts"], "score_soft": m["soft"],
                   "weights": MW})
    return data, stages

def metrics(data, rooms, hall, passage, floor, door_info, story_score=0.0):
    S = data["layers"]["structure"]; WL = data["layers"]["walls"]
    W = len(S[0]); D = len(S)
    fset = floor
    rb = 0.0
    for k, cells, _, _ in rooms:
        a = afp_cells(k); n = len(cells)
        lo, hi = BAND['lo_x_artifact_cells'] * a, BAND['hi_x_artifact_cells'] * a + BAND['hi_pad']
        rb += 1.0 if lo <= n <= hi else max(0.0, 1.0 - ((lo - n) / max(1, lo) if n < lo else (n - hi) / max(1, hi)))
    rb /= max(1, len(rooms))
    held = 0
    for (x, z) in fset:
        we = 0
        for (dx, dz), code in DIRS.items():
            nb = (x + dx, z + dz)
            if code in (WL[z][x] or "").lower() or nb not in fset: we += 1
        if we >= 2: held += 1
    enc = held / max(1, len(fset))
    roomcells = set()
    for _, cells, _, _ in rooms: roomcells |= cells
    hf = len(hall - roomcells) / max(1, len(fset))
    hs = 1.0 if 0.2 <= hf <= 0.5 else max(0.0, 1 - abs(hf - 0.35) / 0.35)
    arr = 0.0
    for (bxz, nb, k) in door_info:
        room = next(c for kk, c, _, _ in rooms if kk == k)
        mouth = sum(1 for h in hall if max(abs(h[0] - nb[0]), abs(h[1] - nb[1])) <= 2)
        arr += min(len(room) / max(1, mouth) / 4.0, 1.0)
    arr /= max(1, len(door_info))
    heights = {int(float(S[z][x])) for (x, z) in fset}
    elev = min((len(heights) - 1) / 2.0, 1.0)
    all_mass = [(x, z) for z in range(D) for x in range(W) if S[z][x] != "0"]
    if all_mass:
        bx0 = min(c[0] for c in all_mass); bx1 = max(c[0] for c in all_mass)
        bz0 = min(c[1] for c in all_mass); bz1 = max(c[1] for c in all_mass)
        compact = len(all_mass) / max(1, (bx1 - bx0 + 1) * (bz1 - bz0 + 1))
    else: compact = 0
    longest = 0
    for (x, z) in passage:
        for dx, dz in ((1, 0), (0, 1)):
            if (x - dx, z - dz) in passage: continue
            L, cx_, cz_ = 0, x, z
            while (cx_, cz_) in passage: L += 1; cx_ += dx; cz_ += dz
            longest = max(longest, L)
    tissue = max(0.0, 1.0 - max(0, longest - TISSUE_FREE) / 16.0)
    # AURA (r8, observed at weight 0 unless the canon weights it): the gaze
    # law — viewing distance scales with size. standoff = longest free-floor
    # run from the anchor; required = 0.8 x max dimension.
    aura = 0.0
    if rooms:
        _EDGE = {(1, 0): ("e", "w"), (-1, 0): ("w", "e"), (0, 1): ("s", "n"), (0, -1): ("n", "s")}
        def _sight_blocked(x, z, dx, dz):
            # a lowercase wall segment blocks sight; a door (uppercase) is an opening
            a, b = _EDGE[(dx, dz)]
            if a in WL[z][x]: return True
            nx, nz = x + dx, z + dz
            if 0 <= nx < W and 0 <= nz < D and b in WL[nz][nx]: return True
            return False
        tot = 0.0
        for k, cells, (ax, az), _ in rooms:
            w_, d_, h_ = union(k)
            req = max(1.0, 0.8 * max(w_, d_, h_))
            best = 0
            for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                run, x, z = 0, ax, az
                while True:
                    if _sight_blocked(x, z, dx, dz): break
                    nx, nz = x + dx, z + dz
                    if not (0 <= nx < W and 0 <= nz < D and S[nz][nx] in "12"): break
                    run += 1; x, z = nx, nz
                best = max(best, run)
            tot += min(1.0, best / req)
        aura = tot / len(rooms)
    parts = {"room_band": round(rb, 2), "enclosure": round(enc, 2), "hall": round(hs, 2),
             "arrival": round(arr, 2), "elevation": round(elev, 2),
             "compact": round(compact, 2), "tissue": round(tissue, 2),
             "story": round(story_score, 2), "aura": round(aura, 2)}
    soft = (MW['room_band'] * rb + MW['enclosure'] * enc + MW['hall'] * hs + MW['arrival'] * arr
            + MW['elevation'] * elev + MW['compact'] * min(compact / COMPACT_T, 1) + MW['tissue'] * tissue
            + MW.get('story', 0) * story_score + MW.get('aura', 0) * aura)
    return {"parts": parts, "soft": round(soft, 3)}

def pathfind(name):
    r = subprocess.run([sys.executable, str(ROOT / "tools/map_pathfinder.py"), "check", name, "--verbose"],
                       cwd=str(ROOT), capture_output=True, text=True, timeout=120)
    out = r.stdout
    reach = 0.0
    for line in out.splitlines():
        if "reachable," in line:
            try:
                a, b = line.split("(")[1].split(" ")[0].split("/")
                reach = int(a) / max(1, int(b))
            except Exception: pass
    return {"ok": "0 FAIL" in out, "reach": round(reach, 2),
            "tail": "\n".join(out.strip().splitlines()[-12:])}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--spec"); ap.add_argument("--spec-file")
    ap.add_argument("--out"); ap.add_argument("--save")
    ap.add_argument("--pathfind", action="store_true")
    a = ap.parse_args()
    spec = dict(DEFAULT_SPEC)
    if a.spec_file:
        spec.update(json.loads(pathlib.Path(a.spec_file).read_text(encoding="utf-8")))
    elif a.spec:
        spec.update(json.loads(a.spec))
    data, stages = compose(spec)
    result = {"spec": spec, "stages": stages}
    if a.save:
        name = a.save
        p = ROOT / "commons/maps" / name
        p.mkdir(exist_ok=True)
        for kk in ("name", "lookup_name", "title"): data["map_info"][kk] = name
        (p / "map_data.json").write_text(json.dumps(data), encoding="utf-8")
        result["saved"] = name
        if a.pathfind:
            result["pathfinder"] = pathfind(name)
        rec = ROOT / "commons/data/wizard_recipes"
        rec.mkdir(exist_ok=True)
        (rec / f"{name}.json").write_text(json.dumps({
            "name": name, "date": datetime.date.today().isoformat(), "spec": spec,
            "score_soft": stages[-1]["score_soft"], "metrics": stages[-1]["metrics"],
            "pathfinder": result.get("pathfinder")}, indent=1), encoding="utf-8")
    else:
        result["map_data"] = data
    txt = json.dumps(result)
    if a.out:
        pathlib.Path(a.out).write_text(txt, encoding="utf-8")
    else:
        sys.stdout.reconfigure(encoding="utf-8")
        print(txt)



# ---------- TRACK MODE (Palle 2026-07-24) ----------
# x fixed at 13, z as long as needed: concatenate authored 13x7 template
# segments (commons/data/wizard_track_templates.json, role grammar shared with
# template_patterns.json), pour the order into the slots walk-order (FIT law at
# slot: artifact fits room, the inverse direction of the grower), kin-fill
# leftover slots with registry-category relatives.
TRACKS_PATH = ROOT / "commons/data/wizard_track_templates.json"

# ROLE ROUTING (round 8): staging posture -> preferred segments. Past a size,
# an artifact stops being furniture and becomes architecture: floor IS the
# ground (terrain_field), monument IS the room (hall_grand), wall IS the wall
# (tableau_face). Postures arrive via spec.track.postures (runner-computed
# from tools/classify_postures.classify — the composer stays dependency-free).
POSTURE_ROUTE = {
    "pedestal": ["gallery_pair", "spine_niches"],
    "table": ["spine_niches", "gallery_pair"],
    "platform": ["court_open"],
    "floor": ["terrain_field"],
    "monument": ["hall_grand"],
    "wall": ["tableau_face"],
    "float": ["court_open"],
    "pit": ["court_open"],
}

def _registry_categories():
    cats = {}
    for f in sorted((ROOT / "commons/artifacts/registry").glob("*.json")):
        if ".bak" in f.name:
            continue
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        if isinstance(d, dict):
            for k in d:
                if isinstance(k, str) and not k.startswith("_"):
                    cats.setdefault(k, f.stem)
    return cats

def compose_track(spec):
    T = json.loads(TRACKS_PATH.read_text(encoding="utf-8"))
    SEG = T["segments"]; CYCLE = T["content_cycle"]
    stages = []
    cast, hero, anti = spec["cast"], spec.get("hero", ""), spec.get("anti", "")
    ename = spec["elevation"]
    trk = spec.get("track") or {}
    kin_fill = bool(trk.get("kin_fill", True))
    order = resolve_order(spec)

    plan = trk.get("plan", "auto")
    if plan == "auto":
        # ORDER-DRIVEN plan: segments are chosen to fit each artifact as it
        # comes, so the order survives exactly (no misfits by construction)
        plan = ["gate_in"]
        open_caps = [sl.get("cap", 4) for sl in SEG["gate_in"]["slots"] if not sl.get("anti")]
        used_count = {n: 0 for n in CYCLE}
        postures = trk.get("postures") or {}
        routing = trk.get("routing", "size")
        for k in order:
            need = afp_cells(k)
            i = next((j for j, c in enumerate(open_caps) if c >= need), None)
            if i is None:
                cands = []
                if routing == "type" and postures.get(k) in POSTURE_ROUTE:
                    cands = [n for n in POSTURE_ROUTE[postures[k]] if n in SEG
                             and any(sl.get("cap", 4) >= need for sl in SEG[n]["slots"] if not sl.get("anti"))]
                if not cands:
                    cands = [n for n in CYCLE
                             if any(sl.get("cap", 4) >= need for sl in SEG[n]["slots"] if not sl.get("anti"))]
                if not cands:
                    cands = [n for n in SEG if n not in ("gate_in", "gate_out", "yard_seg")
                             and any(sl.get("cap", 4) >= need for sl in SEG[n]["slots"] if not sl.get("anti"))]
                if not cands:
                    continue                     # FIT: nothing holds it — recorded as misfit downstream
                seg = min(cands, key=lambda n: (used_count.get(n, 0),
                                                CYCLE.index(n) if n in CYCLE else 99))
                used_count[seg] = used_count.get(seg, 0) + 1
                plan.append(seg)
                open_caps += [sl.get("cap", 4) for sl in SEG[seg]["slots"] if not sl.get("anti")]
                i = next(j for j, c in enumerate(open_caps) if c >= need)
            open_caps.pop(i)
        if anti: plan.append("yard_seg")
        plan.append("gate_out")
    plan = [s for s in plan if s in SEG]

    W = 13
    depths = [len(SEG[n]["rows"]) for n in plan]
    bases = []
    _b = 0
    for dd in depths: bases.append(_b); _b += dd
    D = _b
    S = [["0"] * W for _ in range(D)]
    U = [[" "] * W for _ in range(D)]
    I = [[" "] * W for _ in range(D)]
    WL = [[""] * W for _ in range(D)]
    slots, walls_auth = [], []
    threshold, parapet = set(), set()
    hallc, yardc = set(), set()
    seg_rooms = []          # (si, set of room cells)
    spawn, tp = None, None
    for si, name in enumerate(plan):
        sg = SEG[name]; z0 = bases[si]
        rcells = set()
        for z in range(len(sg["rows"])):
            for x in range(W):
                c = sg["rows"][z][x]
                gz = z0 + z
                if c == "": continue
                if c in ("1", "1s"): S[gz][x] = "1"; hallc.add((x, gz))
                elif c == "s": S[gz][x] = "1"; U[gz][x] = "s"; spawn = (x, gz); hallc.add((x, gz))
                elif c in ("r", "rs"): S[gz][x] = "1"; rcells.add((x, gz))
                elif c in ("y", "ys"): S[gz][x] = "1"; yardc.add((x, gz))
                elif c == "2": S[gz][x] = "2"
                elif c == "p": S[gz][x] = "2"; parapet.add((x, gz))
                elif c == "3": S[gz][x] = "3"
                elif c == "4": S[gz][x] = "4"
                elif c == "m": S[gz][x] = "0"
                elif c == "t": S[gz][x] = "0"; U[gz][x] = "t"; tp = (x, gz)
        seg_rooms.append((si, rcells))
        for sl in sg.get("slots", []):
            slots.append({"cell": (sl["cell"][0], z0 + sl["cell"][1]), "cap": sl.get("cap", 4),
                          "prologue": sl.get("prologue", False), "anti": sl.get("anti", False),
                          "seg": si, "segname": name})
        for (x, z) in sg.get("threshold", []): threshold.add((x, z0 + z))
        for w in sg.get("walls", []): walls_auth.append((w[0], z0 + w[1], w[2], bool(w[3]), si))

    # elevation BEFORE walls/wp: procession lifts the later half of content segments
    content_idx = [i for i, n in enumerate(plan) if n in CYCLE]
    lifted = set()
    if ename == "procession" and content_idx:
        for si in content_idx[len(content_idx) // 2:]:
            lifted.add(si)
            for (x, z) in seg_rooms[si][1]:
                S[z][x] = "2"

    # slot assignment: FIT at slot, walk order; then kin-fill
    content_slots = sorted([s for s in slots if not s["anti"]],
                           key=lambda s: (s["cell"][1], s["cell"][0]))
    remaining = list(order)
    placed = []
    for sl in content_slots:
        pick = next((k for k in remaining if afp_cells(k) <= sl["cap"]), None)
        if pick is not None: remaining.remove(pick)
        placed.append([pick, sl, False])
    misfit = list(remaining)
    kin_added = []
    if kin_fill and any(a is None for a, _, _ in placed):
        cats = _registry_categories()
        cast_cats = []
        for k in order:
            c = cats.get(k)
            if c and c not in cast_cats: cast_cats.append(c)
        pool = [k for k in elems if k not in order and cats.get(k) in cast_cats]
        pool.sort(key=lambda k: (cast_cats.index(cats.get(k)), fp(k)))
        for rec in placed:
            if rec[0] is None:
                pick = next((k for k in pool if afp_cells(k) <= rec[1]["cap"]), None)
                if pick is not None:
                    pool.remove(pick); rec[0] = pick; rec[2] = True; kin_added.append(pick)

    prologue_cell = None
    for a, sl, iskin in placed:
        if a is None: continue
        x, z = sl["cell"]
        I[z][x] = (a + ":0") if a == hero else a     # hero beam aims along the track (+z)
        if sl["prologue"]: prologue_cell = (x, z)
    if anti:
        ys = next((s for s in slots if s["anti"]), None)
        if ys: I[ys["cell"][1]][ys["cell"][0]] = anti

    # walls + doors (+wp on height difference), parapet wp at both ends
    NB = {"n": (0, -1), "s": (0, 1), "e": (1, 0), "w": (-1, 0)}
    raw_doors = []
    for (x, z, d, door, si) in walls_auth:
        WL[z][x] += d.upper() if door else d
        if door:
            dx, dz = NB[d]; nb = (x + dx, z + dz)
            if 0 <= nb[1] < D and 0 <= nb[0] < W:
                raw_doors.append(((x, z), nb))
                if S[z][x] != S[nb[1]][nb[0]] and S[z][x] in "12" and S[nb[1]][nb[0]] in "12":
                    U[z][x] = "wp"; U[nb[1]][nb[0]] = "wp"
    for (x, z) in parapet:
        for nx in (x - 1, x + 1):
            if 0 <= nx < W and (nx, z) not in parapet and S[z][nx] == "1":
                if U[z][nx] == " " and U[z][x] == " ":
                    U[z][nx] = "wp"; U[z][x] = "wp"
    # LIFT LAW: no lift without a step — a procession-lifted room with no door
    # gets a wp pair at its mouth, or its artifact strands at h2 (r7 bug: spine
    # niches lifted doorless -> unreach 2 across every +4 plan)
    for si in lifted:
        if any(w[4] == si and w[3] for w in walls_auth):
            continue
        rc = seg_rooms[si][1]
        seen_comp = set()
        for (x, z) in sorted(rc):
            if (x, z) in seen_comp: continue
            comp, stack = set(), [(x, z)]
            while stack:
                c = stack.pop()
                if c in comp or c not in rc: continue
                comp.add(c)
                stack += [(c[0]+1, c[1]), (c[0]-1, c[1]), (c[0], c[1]+1), (c[0], c[1]-1)]
            seen_comp |= comp
            pair = next((((cx, cz), (cx+dx, cz+dz)) for (cx, cz) in sorted(comp)
                         for dx, dz in ((1, 0), (-1, 0), (0, 1), (0, -1))
                         if (cx+dx, cz+dz) in hallc), None)
            if pair:
                (rx, rz), (hx, hz) = pair
                if U[rz][rx] == " " and U[hz][hx] == " ":
                    U[rz][rx] = "wp"; U[hz][hx] = "wp"

    # metrics geometry: rooms = slot regions; open slots get a 3x3 region
    rooms = []
    for a, sl, iskin in placed:
        if a is None: continue
        si = sl["seg"]; rc = seg_rooms[si][1]
        ax, az = sl["cell"]
        if rc:
            start = min(rc, key=lambda c: abs(c[0] - ax) + abs(c[1] - az))
            comp, stack = set(), [start]
            while stack:
                c = stack.pop()
                if c in comp or c not in rc: continue
                comp.add(c)
                stack += [(c[0] + 1, c[1]), (c[0] - 1, c[1]), (c[0], c[1] + 1), (c[0], c[1] - 1)]
            cells = comp if (ax, az) in comp else {(xx, zz) for xx in range(ax - 1, ax + 2)
                                                  for zz in range(az - 1, az + 2)}
        else:
            cells = {(xx, zz) for xx in range(ax - 1, ax + 2) for zz in range(az - 1, az + 2)
                     if (xx, zz) in hallc}
        rooms.append([a, cells, (ax, az), (0, 1)])
    floor = set(hallc)
    for _, cells, _, _ in rooms: floor |= cells
    passage = set()
    # doors mapped to the artifact whose room they open (metrics contract)
    door_info = []
    for cell, nb in raw_doors:
        art = next((k for k, cells, _, _ in rooms if cell in cells or nb in cells), None)
        if art is not None:
            door_info.append((cell, nb, art))

    # ---- stages, canonical op order ----
    strip = []
    for a, sl, iskin in placed:
        if a is None: continue
        w, d_, h = union(a); _, _, _, reach = body(a)
        strip.append({"name": a, "w": round(w, 2), "d": round(d_, 2), "h": round(h, 2),
                      "cells": afp_cells(a), "reach": reach, "measured": a in elems, "kin": iskin})
    stages.append({"op": "order", "chosen": spec["order"].get("strategy", "narrative"),
                   "strip": strip, "kin_added": kin_added, "misfit": misfit,
                   "previews": {s: (order_crescendo(cast) if s == "crescendo" else
                                    order_rhythm(cast) if s == "rhythm" else
                                    order_narrative(cast, hero)) for s in ("crescendo", "narrative", "rhythm")}})
    stages.append({"op": "typology", "chosen": "track_13",
                   "plan": [{"seg": n, "desc": SEG[n].get("desc", "")} for n in plan],
                   "options": {}})
    stages.append({"op": "room", "chosen": "template", "hall": cl(hallc),
                   "rooms": [{"name": k, "cells": cl(c), "anchor": list(a)} for k, c, a, _ in rooms]})
    segs = []
    for z in range(D):
        for x in range(W):
            for ch in WL[z][x]:
                segs.append({"x": x, "z": z, "d": ch.lower(), "door": ch.isupper()})
    stages.append({"op": "walls", "segments": segs, "dressing": [], "floor": cl(floor),
                   "hall": cl(hallc), "rooms": [{"name": k, "cells": cl(c)} for k, c, _, _ in rooms],
                   "doors": [{"room": k, "cell": list(b), "to": list(nb)} for b, nb, k in door_info]})
    stages.append({"op": "templates_fixed", "enabled": bool(anti and yardc),
                   "yard": {"center": None, "r": 0, "cells": cl(yardc)} if yardc else None})
    profile = [{"i": i, "name": a, "h": (2 if sl["seg"] in lifted else 1), "art_h": round(union(a)[2], 2)}
               for i, (a, sl, _) in enumerate(placed) if a is not None]
    stages.append({"op": "elevation", "chosen": ename, "profile": profile})
    stages.append({"op": "paths", "passage": [], "spawn": list(spawn) if spawn else None,
                   "teleporter": list(tp) if tp else None, "trimmed_cells": 0,
                   "floor": cl(floor), "yard": cl(yardc)})
    story = {"pinch": 1.0 if len(threshold) >= 8 else 0.0, "release": 0.0,
             "prologue": 1.0 if prologue_cell else 0.0, "overlook": 1.0 if parapet else 0.0}
    if threshold:
        ez = max(z for (_, z) in threshold) + 1
        open9 = sum(1 for dx in (-1, 0, 1) for dz in (-1, 0, 1) if (6 + dx, ez + dz) in floor)
        story["release"] = min(open9 / 6.0, 1.0)
    story_score = sum(story.values()) / 4.0
    first_placed = next((a for a, _, _ in placed if a is not None), None)
    stages.append({"op": "arrival", "chosen": {"threshold": "template", "prologue": bool(prologue_cell),
                                               "overview": "template" if parapet else "none"},
                   "threshold": cl(threshold), "parapet": cl(parapet),
                   "parapet_side": "s" if parapet else None,
                   "prologue": ({"artifact": first_placed, "cell": list(prologue_cell)} if prologue_cell else None),
                   "story": {k: round(v, 2) for k, v in story.items()}})

    data = {"map_info": {"name": "X", "lookup_name": "X", "title": "X",
        "description": "wizard track: " + "+".join(plan),
        "dimensions": {"width": W, "depth": D, "max_height": 4},
        "version": "wizard-track-v1",
        "design": {"mode": "track_13", "plan": plan, "order": spec["order"], "elevation": ename,
                   "kin": kin_added, "misfit": misfit, "yard": bool(anti)}},
        "settings": {"cube_size": 1.0, "gutter": 0.0, "show_grid": True, "enable_physics": True, "enter_type": "I",
                     "wall_segments": {"height": 2.2, "thickness": 0.12}},
        "utility_definitions": {"t": {"type": "teleporter", "name": "Track passed", "description": "",
                                      "properties": {"action": "next_in_sequence"}}},
        "layers": {"structure": S, "utilities": U, "walls": WL, "interactables": I}}
    m = metrics(data, rooms, hallc, passage, floor, door_info, story_score)
    stages.append({"op": "final", "W": W, "D": D, "metrics": m["parts"], "score_soft": m["soft"],
                   "weights": MW})
    return data, stages

if __name__ == "__main__":
    main()
