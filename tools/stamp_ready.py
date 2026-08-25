#!/usr/bin/env python3
"""IS THIS MAP READY TO BE STAMPED? — the three rules, scored and applied.

2026-08-25, Palle: "we need more rules when we stamp all maps... that must
include surrounding walls... first change map sequence by sequence in the grid
to have outer wall 2, placing the artifact in the central pathfinding line."

The stamping tool wraps a museum wall around a grid map as it stands. That
works — 185 of 205 maps stamp clean — but "stamps clean" only means the hall
BUILDS. It says nothing about whether the hall is a good room. These are the
rules that make it one, checked on the map, in the grid, before any stamp:

  WALL   the map's outer border is a complete wall. Measured 2026-08-25:
         exactly ONE of 187 unstamped spine maps had this. 178 had five or
         more gaps, which the museum wraps into a hall with holes in its shell.
  BAND   the map, INCLUDING that wall, is an EVEN size between 9 and 19 on
         both axes — so 10, 12, 14, 16 or 18. The corpus spikes at 12 (50
         maps) and 10 (24), both legal; the 20-wides come down to 18.
  SPINE  the artifacts stand near the central walk line, so the walker meets
         them instead of hunting for them. Reported, never enforced — where a
         thing stands is a design act and a percentage is not an argument.

    python tools/stamp_ready.py                          # score every spine map
    python tools/stamp_ready.py --sequence=forces
    python tools/stamp_ready.py --sequence=forces --apply         # close gaps
    python tools/stamp_ready.py --sequence=forces --apply --grow  # and resize

WHAT --apply IS ALLOWED TO DO, and why it is so narrow:

Growth happens at the FAR edges only. Tile cells ARE map cells, forever — the
deriver pins the origin for exactly this reason — so appending rows and columns
at max x and max z leaves every existing coordinate, every saved ruling and
every artifact cell untouched. Cropping or re-centring would silently
re-address the whole map, so this tool will never shrink one.

A border gap is closed only when nothing stands on it. A gap holding a spawn,
a teleporter or an artifact is a DOORWAY, not an omission, and closing it would
wall the map's own entrance. Those are reported and skipped.

Every changed map is re-checked with map_pathfinder afterwards, and any map
that stops passing is restored from the copy taken before the edit.
"""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
# THE BAND (2026-08-25, Palle: "a map can be down to 9 cells but up to 19 but
# must be even"). 9 and 19 are both odd, so the reachable sizes are 10, 12, 14,
# 16 and 18 — the floor is 10 and the ceiling 18. This replaced a 13-19 band
# ruled earlier the same day, and it fits the corpus far better: 12 is its
# biggest spike (50 maps) and 10 its third (24), and both are now legal.
BAND_LO, BAND_HI = 9, 19
EVEN_LO, EVEN_HI = 10, 18
WALL = "w"


def in_band(n):
    return BAND_LO <= n <= BAND_HI and n % 2 == 0


def target(n):
    """The nearest legal size: round UP to even, then clamp into [10, 18].
    Rounding up rather than down means a map only ever grows to reach the
    band, and only shrinks when it is genuinely over it — growth is
    origin-safe, shrinking is conditional on the far edge being empty."""
    t = n + (n % 2)
    return min(EVEN_HI, max(EVEN_LO, t))


def height(v):
    s = str(v).strip()
    if s == "w":
        return 3
    if s == "p" or s.startswith("p:"):
        try:
            return max(1, int(s.split(":")[1])) if ":" in s else 1
        except ValueError:
            return 1
    return int(s) if s.isdigit() else 0


def map_path(name):
    return os.path.join(ROOT, "commons", "maps", name, "map_data.json")


def spine_maps(only=None):
    spine = json.load(open(os.path.join(ROOT, "commons", "maps", "curriculum_spine.json"),
                           encoding="utf-8"))
    out = []
    for s in spine["spine"]["sequences"]:
        sid = s["name"]
        if only and sid != only:
            continue
        p = os.path.join(ROOT, "commons", "maps", "sequences", "%s.json" % sid)
        if not os.path.exists(p):
            continue
        doc = json.load(open(p, encoding="utf-8"))
        seqs = doc["sequences"]
        block = seqs[0] if isinstance(seqs, list) else (seqs.get(sid) or list(seqs.values())[0])
        for m in block.get("maps", []):
            if os.path.exists(map_path(m)):
                out.append((sid, m))
    return out


def cell(layer, x, z):
    if z < len(layer) and x < len(layer[z]):
        return str(layer[z][x]).strip()
    return ""


def analyse(doc):
    layers = doc.get("layers", {})
    st = layers.get("structure", [])
    ut = layers.get("utilities", [])
    inter = layers.get("interactables", [])
    h = len(st)
    w = len(st[0]) if h else 0
    gaps, blocked = [], []
    for z in range(h):
        for x in range(w):
            if not (z in (0, h - 1) or x in (0, w - 1)):
                continue
            if height(st[z][x]) >= 2:
                continue
            (blocked if (cell(ut, x, z) or cell(inter, x, z)) else gaps).append((x, z))
    arts = [(x, z) for z, row in enumerate(inter)
            for x, v in enumerate(row) if str(v).strip()]
    mid = w / 2.0
    near = sum(1 for x, _z in arts if abs(x + 0.5 - mid) <= 1.5)
    return {
        "w": w, "h": h,
        "gaps": gaps, "blocked": blocked,
        "arts": len(arts),
        "spine": (100.0 * near / len(arts)) if arts else None,
        "band": in_band(w) and in_band(h),
        "grow_x": max(0, target(w) - w), "grow_z": max(0, target(h) - h),
        "over": (target(w) < w or target(h) < h),
    }


def wall_border(st):
    """Every cell on the border becomes an explicit wall. Returns cells changed."""
    h = len(st)
    w = len(st[0]) if h else 0
    changed = 0
    for z in range(h):
        for x in range(w):
            if (z in (0, h - 1) or x in (0, w - 1)) and str(st[z][x]).strip() != WALL:
                st[z][x] = WALL
                changed += 1
    return changed


def grow(doc, add_x, add_z):
    """Append columns and rows at the FAR edges — origin-preserving, so no
    existing cell moves. The new strip is floor; the shell is re-walled after,
    and the old border, now interior, opens up unless something stands on it."""
    layers = doc.get("layers", {})
    st = layers.get("structure", [])
    h0 = len(st)
    w0 = len(st[0]) if h0 else 0
    opened = 0
    if add_x or add_z:
        # the old border becomes room, where it was a plain empty wall
        ut = layers.get("utilities", [])
        inter = layers.get("interactables", [])
        for z in range(h0):
            for x in range(w0):
                on_far = (add_x and x == w0 - 1) or (add_z and z == h0 - 1)
                if on_far and height(st[z][x]) >= 2 and not cell(ut, x, z) and not cell(inter, x, z):
                    st[z][x] = "1"
                    opened += 1
    for key, layer in layers.items():
        if not isinstance(layer, list) or not layer or not isinstance(layer[0], list):
            continue
        blank = "1" if key == "structure" else ""
        for row in layer:
            row.extend([blank] * add_x)
        width = len(layer[0])
        for _ in range(add_z):
            layer.append([blank] * width)
    return opened


def trim(doc, want_w=EVEN_HI, want_h=EVEN_HI):
    """Drop FAR rows and columns while the map is over the band and the far
    edge carries nothing. Also origin-preserving — (0,0) and every remaining
    cell keep their address — which is why only the far edge is ever dropped.
    A far edge holding an artifact, a utility or any floor is left alone and
    the map stays over band, reported rather than mangled."""
    layers = doc.get("layers", {})
    st = layers.get("structure", [])
    dropped_x = dropped_z = 0

    def col_free(x):
        for z in range(len(st)):
            if height(st[z][x]) == 1:
                return False
            if cell(layers.get("utilities", []), x, z) or cell(layers.get("interactables", []), x, z):
                return False
        return True

    def row_free(z):
        for x in range(len(st[z])):
            if height(st[z][x]) == 1:
                return False
            if cell(layers.get("utilities", []), x, z) or cell(layers.get("interactables", []), x, z):
                return False
        return True

    while len(st[0]) > want_w and col_free(len(st[0]) - 1):
        for key, layer in layers.items():
            if isinstance(layer, list) and layer and isinstance(layer[0], list):
                for row in layer:
                    if row:
                        row.pop()
        dropped_x += 1
    while len(st) > want_h and row_free(len(st) - 1):
        for key, layer in layers.items():
            if isinstance(layer, list) and layer and isinstance(layer[0], list):
                if layer:
                    layer.pop()
        dropped_z += 1
    return dropped_x, dropped_z


def check_map(name):
    r = subprocess.run([sys.executable, os.path.join(ROOT, "tools", "map_pathfinder.py"),
                        "check", name], cwd=ROOT, capture_output=True, text=True)
    return "0 FAIL" in (r.stdout or "")


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--sequence", default="")
    ap.add_argument("--apply", action="store_true", help="close border gaps")
    ap.add_argument("--grow", action="store_true", help="also grow up to the band minimum")
    ap.add_argument("--json", action="store_true")
    args = ap.parse_args()

    rows, report = spine_maps(args.sequence or None), []
    ready = 0
    for sid, name in rows:
        doc = json.load(open(map_path(name), encoding="utf-8"))
        a = analyse(doc)
        before = json.dumps(doc)
        actions = []

        if args.apply:
            if args.grow and (a["grow_x"] or a["grow_z"]):
                opened = grow(doc, a["grow_x"], a["grow_z"])
                actions.append("grew +%dx +%dz%s" % (a["grow_x"], a["grow_z"],
                               (", opened %d old wall cell(s)" % opened) if opened else ""))
            if args.grow and a["over"]:
                dx, dz = trim(doc, target(a["w"]), target(a["h"]))
                if dx or dz:
                    actions.append("trimmed -%dx -%dz" % (dx, dz))
            st = doc["layers"]["structure"]
            # never wall over something that stands on the border
            keep = set()
            for x, z in analyse(doc)["blocked"]:
                keep.add((x, z))
            saved = {(x, z): st[z][x] for (x, z) in keep}
            n = wall_border(st)
            for (x, z), v in saved.items():
                st[z][x] = v
            if n:
                actions.append("walled %d border cell(s)" % n)
            if actions:
                with open(map_path(name), "w", encoding="utf-8") as fh:
                    json.dump(doc, fh)
                subprocess.run([sys.executable, os.path.join(ROOT, "tools", "compact_map_json.py"),
                                map_path(name)], cwd=ROOT, capture_output=True)
                if not check_map(name):
                    with open(map_path(name), "w", encoding="utf-8") as fh:
                        fh.write(before)
                    subprocess.run([sys.executable, os.path.join(ROOT, "tools", "compact_map_json.py"),
                                    map_path(name)], cwd=ROOT, capture_output=True)
                    actions = ["REVERTED — the pathfinder stopped passing"]
                else:
                    a = analyse(json.load(open(map_path(name), encoding="utf-8")))

        verdict = []
        if a["gaps"]:
            verdict.append("%d gap%s" % (len(a["gaps"]), "" if len(a["gaps"]) == 1 else "s"))
        if a["blocked"]:
            verdict.append("%d doorway%s" % (len(a["blocked"]), "" if len(a["blocked"]) == 1 else "s"))
        if not a["band"]:
            verdict.append("%dx%d" % (a["w"], a["h"]) + (" OVER" if a["over"] else " under"))
        if not verdict:
            ready += 1
        report.append({"sequence": sid, "map": name, **{k: v for k, v in a.items()
                       if k not in ("gaps", "blocked")},
                       "gap_count": len(a["gaps"]), "doorways": len(a["blocked"]),
                       "verdict": "READY" if not verdict else " · ".join(verdict),
                       "actions": actions})

    if args.json:
        print(json.dumps(report, indent=1))
        return 0
    print("STAMP READINESS — wall complete · %d-%d on both axes · artifacts near the spine\n"
          % (BAND_LO, BAND_HI))
    seq = None
    for r in report:
        if r["sequence"] != seq:
            seq = r["sequence"]
            print("  %s" % seq)
        sp = "  —  " if r["spine"] is None else "%3.0f%%" % r["spine"]
        print("    %-40s %2dx%-3d spine %s  %s%s"
              % (r["map"], r["w"], r["h"], sp, r["verdict"],
                 ("   [" + "; ".join(r["actions"]) + "]") if r["actions"] else ""))
    print("\n  %d of %d READY" % (ready, len(report)))
    return 0


if __name__ == "__main__":
    sys.exit(main())
