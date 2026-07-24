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
    parapet = set()
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
        # overview parapet: three walkway cells rise to h2 behind a wall lowered
        # 4→3 — from up there (eye ~3.7m) you look over into the quarantine.
        # wp pairs at both ends make the climb legal; the yard stays sealed.
        if over_mode == "parapet":
            pz = yard_c[1] + YARD_R + 1
            wz = yard_c[1] + YARD_R
            for px in (yard_c[0] - 1, yard_c[0], yard_c[0] + 1):
                if 0 <= px < W and 0 <= pz < D and S[pz][px] == "1":
                    S[pz][px] = "2"; parapet.add((px, pz))
                if 0 <= px < W and 0 <= wz < D and S[wz][px] == "4":
                    S[wz][px] = "3"
            if parapet:
                for ax2, first in ((yard_c[0] - 2, yard_c[0] - 1), (yard_c[0] + 2, yard_c[0] + 1)):
                    if (0 <= ax2 < W and S[pz][ax2] == "1" and U[pz][ax2] == " "
                            and (first, pz) in parapet and U[pz][first] == " "):
                        U[pz][ax2] = "wp"; U[pz][first] = "wp"
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
                   "threshold": cl(threshold), "parapet": cl(parapet),
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
    parts = {"room_band": round(rb, 2), "enclosure": round(enc, 2), "hall": round(hs, 2),
             "arrival": round(arr, 2), "elevation": round(elev, 2),
             "compact": round(compact, 2), "tissue": round(tissue, 2),
             "story": round(story_score, 2)}
    soft = (MW['room_band'] * rb + MW['enclosure'] * enc + MW['hall'] * hs + MW['arrival'] * arr
            + MW['elevation'] * elev + MW['compact'] * min(compact / COMPACT_T, 1) + MW['tissue'] * tissue
            + MW.get('story', 0) * story_score)
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

if __name__ == "__main__":
    main()
