#!/usr/bin/env python3
"""Measure the Endless Museum's WALLS, the way a white cube would be judged.

A python mirror of the three GDScript modules that decide what stands on a wall:

    commons/scenes/em/em_budget.gd   the rate  (wall_features_max, fill_walls)
    commons/scenes/em/em_detail.gd   the hang  (_dressed_faces, _add_wall_showings,
                                                _add_labels)
    commons/scenes/em/em_props.gd    the cap   (service furniture per segment)

Nothing here is invented. Every constant is quoted from the file that owns it and
the function names are kept so a drift is greppable. The mirror exists because
the question -- "how long is an unbroken wall, and how much of it is bare?" -- is
a property of the STAMP, not of the render, and answering it for all 30 museums
by capturing 30 PNGs would take an hour and tell you less.

    python tools/em_white_cube_measure.py                # all 30, table + means
    python tools/em_white_cube_measure.py --key=<key>     # one museum, verbose
    python tools/em_white_cube_measure.py --json=<path>   # machine readable
    python tools/em_white_cube_measure.py --after         # with the gate ON

THE THREE NUMBERS
  run_mean_m       mean length of one unbroken wall stretch (same plane, same
                   outward normal, contiguous) in metres. 1 dressed face = 1 m.
  features_per_m   everything stuck on a wall -- hung showings + wall cards +
                   wall-mounted service props -- per linear metre of wall run.
  bare_pct         share of the readable wall BAND (skirting head 0.13 to cornice
                   soffit 2.72 = 2.59 m tall) with nothing on it.
  longest_bare_m   the longest contiguous stretch carrying no feature at all.
"""
from __future__ import annotations

import argparse
import json
import math
import os
import sys
from collections import defaultdict

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATTERNS = os.path.join(ROOT, "commons", "data", "template_patterns.json")

# ── em_detail.gd / endless_museum.gd geometry contract ───────────────────────
VESTIBULE_H = 4
LOBBY_W = 17
WALL_H = 3.0
SKIRT_H = 0.13
CORNICE_BOTTOM = 2.72
BAND_H = CORNICE_BOTTOM - SKIRT_H          # 2.59 m of readable wall
HANG_PITCH_FACES = 2
HANG_FRAME_W = 0.075
HANG_FORMATS = [(0.72, 0.98), (1.32, 0.86), (0.58, 0.58)]
HANG_HARD_MAX = 80
LABEL_EVERY = 11
LABEL_W, LABEL_H = 0.30, 0.42

# ── em_budget.gd ─────────────────────────────────────────────────────────────
HARD_MAX_OBJECTS = 24
MAX_LEADS = 12
MAX_MULTIPLES = 16
MAX_WALL_FEATURES = 80
HANG_PITCH_M = 6.0
DEFAULT_WALK_FRACTION = 0.62
CORPUS_RATE = 4.8
CORPUS_WALL_FEATURES = 2.2

# ── em_props.gd ──────────────────────────────────────────────────────────────
PROP_SHARE = 0.40
RATE_SILENT = 0.6
RATE_STATUTORY_ONLY = 1.5
MAX_PROPS_PER_SEGMENT = 16
# em_props.Q — family -> [share of cap, floor, ceiling]
Q = {"statutory": (0.25, 1, 4), "feature": (0.25, 0, 4), "gate": (0.13, 0, 2),
     "ceiling": (0.13, 0, 2), "run": (0.07, 0, 1), "edge": (0.07, 0, 1),
     "backing": (0.07, 0, 1), "pocket": (0.19, 0, 3)}


def gd_round(v: float) -> int:
    """GDScript round(): half away from zero. Python's round() is banker's and
    differs on exactly the values a small cap lands on (round(0.5) = 0 vs 1)."""
    return int(math.floor(v + 0.5)) if v >= 0 else -int(math.floor(-v + 0.5))


def props_placed(cap: int) -> int:
    """How many props em_props can actually stamp at this cap. The quota table
    is spent per family, so a small cap does NOT place `cap` props."""
    if cap <= 0:
        return 0
    total = 0
    for share, lo, hi in Q.values():
        total += max(min(lo, cap), min(gd_round(cap * share), hi))
    return min(cap, total)
# frontal area of the wall-mounted props em_props actually stamps, m^2, read off
# the catalogue's own back/front and the scripts' exports. Used only for the
# bare-surface sum; the counts are exact.
PROP_FACE_AREA = 0.16

# The wall-furniture rate table, transcribed from em_budget.gd TEMPLATES.
# key -> (rate, lead, rel, mult, walls, wf)
BUDGET_ROWS = {
    "uffizi-spine-enfilade": (5.0, 8, 1, 2, True, 2.5),
    "grande-galerie-axial": (4.8, 9, 1, 2, True, 3.0),
    "altes-rotunda-hub": (4.0, 6, 1, 4, True, 2.5),
    "castelvecchio-endstopped-enfilade": (3.0, 6, 0, 1, True, 3.0),
    "louisiana-pavilion-chain": (4.9, 4, 2, 2, True, 1.5),
    "soane-cabinet-vista": (12.0, 12, 1, 2, True, 4.5),
    "kanazawa-room-matrix": (3.8, 6, 1, 3, True, 3.0),
    "neue-nationalgalerie-free-plan": (3.0, 8, 0, 2, True, 1.0),
    "pompidou-plateau-libre": (4.3, 7, 1, 2, True, 5.0),
    "dia-beacon-field": (5.2, 4, 3, 5, True, 2.0),
    "mezquita-hypostyle": (3.7, 4, 2, 3, False, 1.5),
    "bilbao-atrium-radial": (5.4, 5, 2, 2, True, 2.5),
    "guggenheim-serpentine": (4.5, 8, 1, 2, True, 2.0),
    "chichu-buried-cells": (3.3, 3, 0, 1, False, 0.8),
    "teshima-droplet": (0.45, 1, 0, 1, False, 0.3),
    "libeskind-void-axis": (6.7, 6, 1, 1, False, 1.0),
    "sainsbury-false-perspective-enfilade": (4.5, 7, 1, 2, True, 2.5),
    "capuchin-crypt-corridor": (23.7, 5, 2, 6, True, 4.0),
    "caracalla-thermal-axis": (5.2, 7, 1, 2, True, 3.0),
    "katsura-miegakure-circuit": (4.6, 5, 0, 1, False, 0.8),
    "labrouste-stack-hall": (10.0, 4, 1, 6, True, 4.5),
    "mengoni-glazed-thoroughfare": (11.8, 4, 1, 8, True, 4.0),
    "mesdag-panorama-drum": (9.1, 2, 1, 2, False, 0.8),
    "sando-threshold-run": (20.8, 3, 0, 16, False, 0.5),
    "thoronet-circumambulation-void": (7.7, 6, 1, 2, False, 0.6),
}
DERIVED_ROW = (CORPUS_RATE, 6, 1, 2, True, CORPUS_WALL_FEATURES)

# ── THE GATE. Mirrors the white_cube branch in em_budget.gd. ─────────────────
WC_WALL_FEATURES_PER_10M = 0.55   # showings: one per ~18 m of run
WC_PROPS_PER_SEGMENT = 2.0        # props per ROOM, not per wall
WC_LABEL_EVERY = 44               # em_detail LABEL_EVERY under the gate
WC_MIN_WALL_M = 6                 # no showing on a wall shorter than this


def budget_row(key: str):
    if key in BUDGET_ROWS:
        return BUDGET_ROWS[key]
    lineage = key.split("-")[0] if key else ""
    if len(lineage) >= 4:
        for k, v in BUDGET_ROWS.items():
            if k.startswith(lineage + "-"):
                return v
    return DERIVED_ROW


# ═════════════════════════════════════════════════════════════════════════════
# em_detail.gd occupancy, verbatim
# ═════════════════════════════════════════════════════════════════════════════
def map_vestibule(walls, floors, w, prev_w):
    for zr in range(VESTIBULE_H):
        for x in range(LOBBY_W):
            floors.add((x, zr))
        walls.add((0, zr))
        walls.add((LOBBY_W - 1, zr))
    for x1 in range(max(w - 1, 0), LOBBY_W):
        walls.add((x1, VESTIBULE_H - 1))
    if prev_w > 0:
        for x2 in range(max(prev_w - 1, 0), LOBBY_W):
            walls.add((x2, 0))


def map_tile(walls, floors, tile, w):
    for y, row in enumerate(tile):
        z = y + VESTIBULE_H
        walls.add((-1, z))
        walls.add((w, z))
        for x, c in enumerate(row):
            if c == "4":
                walls.add((x, z))
            elif c in ("1", "1s"):
                floors.add((x, z))


def dressed_faces(walls, floors):
    out = []
    dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)]
    for cell in sorted(walls, key=lambda c: (c[1], c[0])):
        for dx, dz in dirs:
            nb = (cell[0] + dx, cell[1] + dz)
            if nb in walls or nb not in floors:
                continue
            out.append({
                "x": cell[0] + 0.5 + dx * 0.5,
                "z": cell[1] + 0.5 + dz * 0.5,
                "along_x": dz != 0,
                "nx": float(dx), "nz": float(dz),
            })
    return out


def stretches_of(faces):
    """em_detail._add_wall_showings' run/stretch grouping, in metres."""
    runs = defaultdict(list)
    for f in faces:
        fixed = f["z"] if f["along_x"] else f["x"]
        vary = f["x"] if f["along_x"] else f["z"]
        key = "%s|%.2f|%.0f|%.0f" % ("x" if f["along_x"] else "z", fixed,
                                     f["nx"], f["nz"])
        runs[key].append(vary)
    out = []
    for key in sorted(runs):
        vs = sorted(runs[key])
        cur = []
        for v in vs:
            if cur and abs(v - cur[-1]) > 1.01:
                out.append((key, cur))
                cur = []
            cur.append(v)
        if cur:
            out.append((key, cur))
    return out


def hang_candidates(faces, min_stretch=HANG_PITCH_FACES):
    """Every position a showing could take, grouped per run, in deal order."""
    per_run = []
    runs = defaultdict(list)
    for f in faces:
        fixed = f["z"] if f["along_x"] else f["x"]
        vary = f["x"] if f["along_x"] else f["z"]
        key = "%s|%.2f|%.0f|%.0f" % ("x" if f["along_x"] else "z", fixed,
                                     f["nx"], f["nz"])
        runs[key].append(vary)
    for key in sorted(runs):
        vs = sorted(runs[key])
        here = []
        stretch = []
        i = 0
        while i <= len(vs):
            broke = i == len(vs)
            if not broke and stretch:
                broke = abs(vs[i] - stretch[-1]) > 1.01
            if broke:
                _stretch_candidates(stretch, key, here, min_stretch)
                stretch = []
                if i == len(vs):
                    break
            stretch.append(vs[i])
            i += 1
        if here:
            per_run.append(here)
    return per_run


def hang_candidates_guarded(faces, min_stretch):
    """em_detail._add_wall_showings' STUBBY-BUILDING GUARD, mirrored.

    A floor stated in metres is a fact about the corpus, and four buildings are
    not in it: soane-cabinet-vista, sainsbury-false-perspective-enfilade,
    pompidou-plateau-libre and mengoni-glazed-thoroughfare have 0.0% of their
    wall run in stretches of 6 m or more, so a flat 6 m floor rejects every
    candidate and they hang nothing at all. If the requested floor silences a
    building completely, drop to that building's OWN longest wall -- not to the
    shipped 2 m floor, which would put the pictures back on the 1 m stubs.

    Returns (per_run, effective_floor_in_metres).
    """
    per_run = hang_candidates(faces, min_stretch)
    if not per_run and min_stretch > HANG_PITCH_FACES:
        longest = max([len(s[1]) for s in stretches_of(faces)] or [0])
        if longest >= HANG_PITCH_FACES:
            return hang_candidates(faces, longest), longest
    return per_run, min_stretch


def _stretch_candidates(stretch, key, out, min_stretch=HANG_PITCH_FACES):
    if len(stretch) < max(min_stretch, HANG_PITCH_FACES):
        return
    fixed = float(key.split("|")[1])
    g = 0
    while g + HANG_PITCH_FACES <= len(stretch):
        centre = sum(stretch[g:g + HANG_PITCH_FACES]) / float(HANG_PITCH_FACES)
        idx = abs(int(round(centre * 2.0)) + int(round(fixed * 2.0)))
        out.append({"key": key, "centre": centre,
                    "fmt": HANG_FORMATS[idx % len(HANG_FORMATS)]})
        g += HANG_PITCH_FACES


def deal_showings(per_run, cap):
    """The round-robin in em_detail._add_wall_showings."""
    hung = []
    round_i = 0
    guard = 0
    while len(hung) < cap and guard < 4096:
        guard += 1
        dealt = 0
        for lane in per_run:
            if round_i >= len(lane):
                continue
            if len(hung) >= cap:
                break
            hung.append(lane[round_i])
            dealt += 1
        if dealt == 0:
            break
        round_i += 1
    return hung


# ═════════════════════════════════════════════════════════════════════════════
# em_budget.gd, verbatim
# ═════════════════════════════════════════════════════════════════════════════
def is_walk(tile, x, y):
    if y < 0 or y >= len(tile):
        return False
    row = tile[y]
    if x < 0 or x >= len(row):
        return False
    return row[x] in ("1", "1s")


def walkable_of(tile):
    return sum(1 for y in range(len(tile)) for x in range(len(tile[y]))
               if is_walk(tile, x, y))


def perimeter_of(tile):
    m = 0.0
    for y in range(len(tile)):
        for x in range(len(tile[y])):
            if not is_walk(tile, x, y):
                continue
            for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                if not is_walk(tile, x + dx, y + dy):
                    m += 1.0
    return m


def for_segment(w, h, tile, key, white_cube=False):
    rate, lead, rel, mult, walls_ok, wf = budget_row(key)
    heroes = sum(r.count("3s") for r in tile)
    podiums = sum(r.count("2s") for r in tile)
    floors_s = sum(r.count("1s") for r in tile)
    slot_capacity = heroes + podiums + floors_s
    walkable = walkable_of(tile) or int(round(w * h * DEFAULT_WALK_FRACTION))
    wall_run = perimeter_of(tile) or float(2 * (w + h))

    wall_hang = int(math.floor(wall_run / HANG_PITCH_M)) if walls_ok else 0
    capacity = slot_capacity + wall_hang
    wanted = gd_round(walkable * rate * 0.01)
    max_objects = min(max(min(wanted, HARD_MAX_OBJECTS), 0), capacity)
    if capacity > 0:
        max_objects = max(max_objects, 1)

    props_per_10m = None
    if white_cube:
        # THE GATE. Two knobs that already exist, moved; nothing new downstream.
        wf = min(wf, WC_WALL_FEATURES_PER_10M) if wf > 0 else wf
        props_per_10m = (WC_PROPS_PER_SEGMENT * 10.0 / wall_run) if wall_run > 0 else 0.0

    wf_max = gd_round(wall_run * 0.1 * wf)
    wf_max = max(0, min(wf_max, MAX_WALL_FEATURES))
    return {
        "template": key, "max_objects": max_objects, "fill_walls": walls_ok,
        "wall_features_per_10m": wf, "wall_features_max": wf_max,
        "wall_run_m": wall_run, "walkable_cells": walkable,
        "slot_capacity": slot_capacity, "props_per_10m": props_per_10m,
    }


def props_cap(budget, artworks, white_cube=False):
    """em_props.dress' cap arithmetic. Returns (cap, statutory_only)."""
    run_m = budget["wall_run_m"]
    wf_rate = budget["wall_features_per_10m"]
    ppm = budget.get("props_per_10m")
    rate = ppm if ppm is not None else wf_rate * PROP_SHARE
    if wf_rate < RATE_SILENT and not white_cube:
        return 0, False
    if wf_rate < RATE_STATUTORY_ONLY and not white_cube:
        return 1, True
    if white_cube and budget["wall_features_per_10m"] <= 0.0:
        return 0, False
    cap = gd_round(run_m * 0.1 * rate)
    cap = max(0, min(cap, MAX_PROPS_PER_SEGMENT))
    cap = min(cap, artworks) if artworks > 0 else cap
    return cap, False


# ═════════════════════════════════════════════════════════════════════════════
# THE MEASUREMENT
# ═════════════════════════════════════════════════════════════════════════════
def measure(key, spec, white_cube=False, prev_w=-1):
    tile = spec["tile"]
    w, h = int(spec["w"]), int(spec["h"])
    walls, floors = set(), set()
    map_vestibule(walls, floors, w, prev_w)
    map_tile(walls, floors, tile, w)
    faces = dressed_faces(walls, floors)

    strs = stretches_of(faces)
    lens = [len(s[1]) for s in strs]
    run_total = float(sum(lens))
    run_mean = run_total / len(lens) if lens else 0.0
    # what a walker meets: each metre of wall weighted by the stretch it is in
    run_wmean = (sum(l * l for l in lens) / run_total) if run_total else 0.0

    budget = for_segment(w, h, tile, key, white_cube)
    cap = budget["wall_features_max"]
    hang_on = budget["fill_walls"]
    if cap < 0:
        cap = max(0, min(int(math.floor(len(faces) / 6.0)), HANG_HARD_MAX))
    cap = max(0, min(cap, HANG_HARD_MAX))
    min_stretch = WC_MIN_WALL_M if white_cube else HANG_PITCH_FACES
    cands, min_stretch_used = hang_candidates_guarded(faces, min_stretch)
    showings = deal_showings(cands, cap) if hang_on and cap else []

    label_every = WC_LABEL_EVERY if white_cube else LABEL_EVERY
    n_labels = len(faces) // label_every

    artworks = budget["max_objects"]
    n_props, statutory = props_cap(budget, artworks, white_cube)
    # em_props.Q spends the cap by family quota, so a small cap does not place
    # `cap` props: quota[fam] = clamp(round(cap * share), min(floor, cap), ceil).
    n_props = props_placed(n_props)

    # ── area ────────────────────────────────────────────────────────────────
    band_area = len(faces) * BAND_H
    show_area = sum((f["fmt"][0] + 2 * HANG_FRAME_W) * (f["fmt"][1] + 2 * HANG_FRAME_W)
                    for f in showings)
    label_area = n_labels * LABEL_W * LABEL_H
    wall_props = n_props
    prop_area = wall_props * PROP_FACE_AREA
    covered = show_area + label_area + prop_area
    bare_pct = 100.0 * (1.0 - covered / band_area) if band_area else 100.0

    n_features = len(showings) + n_labels + wall_props
    per_m = n_features / run_total if run_total else 0.0

    # ── longest bare run, and how much wall LENGTH is bare ──────────────────
    # a stretch carries a feature at each dealt showing centre. A showing plus
    # the wall it needs either side occupies HALO m of run; everything else is
    # bare wall you could stand a body or an artifact in front of.
    HALO = 0.75
    occupied = defaultdict(list)
    for s in showings:
        occupied[s["key"]].append(s["centre"])
    longest_bare = 0.0
    bare_len = 0.0
    for key_s, cells in strs:
        marks = sorted(c for c in occupied.get(key_s, [])
                       if cells[0] - 0.6 <= c <= cells[-1] + 0.6)
        lo, hi = cells[0] - 0.5, cells[-1] + 0.5
        cursor = lo
        for m in marks:
            gap = max(0.0, m - HALO - cursor)
            longest_bare = max(longest_bare, gap)
            bare_len += gap
            cursor = max(cursor, m + HALO)
        gap = max(0.0, hi - cursor)
        longest_bare = max(longest_bare, gap)
        bare_len += gap
    long_walls = [l for l in lens if l >= 6]
    long_share = 100.0 * sum(long_walls) / run_total if run_total else 0.0

    return {
        "key": key, "museum": spec.get("museum", ""), "w": w, "h": h,
        "faces_m": len(faces), "stretches": len(lens),
        "run_mean_m": run_mean, "run_wmean_m": run_wmean,
        "run_max_m": max(lens) if lens else 0,
        "showings": len(showings), "labels": n_labels, "props": n_props,
        "wall_props": wall_props, "features": n_features,
        "features_per_m": per_m,
        "band_area_m2": band_area, "covered_m2": covered, "bare_pct": bare_pct,
        "longest_bare_m": longest_bare, "bare_len_m": bare_len,
        "bare_len_pct": 100.0 * bare_len / run_total if run_total else 0.0,
        "long_walls": len(long_walls), "long_share_pct": long_share,
        "wf_per_10m": budget["wall_features_per_10m"],
        "min_stretch_m": min_stretch, "min_stretch_used_m": min_stretch_used,
        "guard_fired": min_stretch_used != min_stretch,
        "wall_features_max": budget["wall_features_max"],
        "fill_walls": hang_on, "artworks": artworks,
        "interior_wall_cells": sum(r.count("4") for r in tile),
        "walk_cells": budget["walkable_cells"],
        "cells": w * h,
    }


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--key", default="")
    ap.add_argument("--after", action="store_true", help="measure with the gate ON")
    ap.add_argument("--json", default="")
    args = ap.parse_args()

    pats = json.load(open(PATTERNS, encoding="utf-8"))["patterns"]
    keys = [k for k, v in pats.items() if isinstance(v, dict) and v.get("museum")]
    keys.sort()
    if args.key:
        keys = [k for k in keys if k == args.key or k.startswith(args.key)]
        if not keys:
            print("no museum template matches %r" % args.key)
            return 1

    rows = [measure(k, pats[k], white_cube=args.after) for k in keys]
    cols = [("template", "%-38s", "key"), ("wall", "%5d", "faces_m"),
            ("runs", "%6d", "stretches"), ("mean", "%6.1f", "run_mean_m"),
            ("wmean", "%6.1f", "run_wmean_m"), ("max", "%5d", "run_max_m"),
            (">=6m%", "%6.1f", "long_share_pct"),
            ("show", "%5d", "showings"), ("lbl", "%5d", "labels"),
            ("prop", "%5d", "props"), ("feat/m", "%7.3f", "features_per_m"),
            ("bareA%", "%7.1f", "bare_pct"), ("bareL%", "%7.1f", "bare_len_pct"),
            ("bare_m", "%7.1f", "longest_bare_m")]
    hdr = " ".join(("%-38s" if c[1].startswith("%-") else
                    "%" + c[1][1:c[1].index(".") if "." in c[1] else -1] + "s") % c[0]
                   for c in cols)
    print(hdr)
    print("-" * len(hdr))
    for r in rows:
        print(" ".join(c[1] % (r[c[2]][:38] if c[2] == "key" else r[c[2]]) for c in cols))
    n = len(rows)
    print("-" * len(hdr))
    print(" ".join(("%-38s" % ("MEAN of %d" % n)) if c[2] == "key"
                   else (c[1].replace("d", ".1f") % (sum(r[c[2]] for r in rows) / n))
                   for c in cols))
    tot_feat = sum(r["features"] for r in rows)
    tot_run = sum(r["faces_m"] for r in rows)
    print("corpus features/metre (pooled): %.3f   (%d features over %d m)"
          % (tot_feat / tot_run, tot_feat, tot_run))
    print("corpus bare%% (pooled AREA): %.1f    bare%% (pooled LENGTH): %.1f" % (
        100.0 * (1.0 - sum(r["covered_m2"] for r in rows)
                 / sum(r["band_area_m2"] for r in rows)),
        100.0 * sum(r["bare_len_m"] for r in rows) / tot_run))
    print("props per ROOM (segment), mean: %.1f    wall stretches per room: %.0f"
          % (sum(r["props"] for r in rows) / n, sum(r["stretches"] for r in rows) / n))
    allen = []
    for k in keys:
        _w, _h, _t = int(pats[k]["w"]), int(pats[k]["h"]), pats[k]["tile"]
        ww, ff = set(), set()
        map_vestibule(ww, ff, _w, -1)
        map_tile(ww, ff, _t, _w)
        allen += [len(s[1]) for s in stretches_of(dressed_faces(ww, ff))]
    allen.sort()
    buckets = [(1, 1), (2, 2), (3, 5), (6, 9), (10, 999)]
    print("stretch-length histogram over all %d walls in the corpus:" % len(allen))
    for lo, hi in buckets:
        c = sum(1 for l in allen if lo <= l <= hi)
        m = sum(l for l in allen if lo <= l <= hi)
        print("   %-8s %5d walls  %6d m  (%4.1f%% of all wall run)" % (
            ("%d m" % lo) if lo == hi else ("%d-%d m" % (lo, hi) if hi < 999 else ">=%d m" % lo),
            c, m, 100.0 * m / sum(allen)))
    if args.json:
        json.dump(rows, open(args.json, "w", encoding="utf-8"), indent=1)
        print("wrote %s" % args.json)
    return 0


if __name__ == "__main__":
    sys.exit(main())
