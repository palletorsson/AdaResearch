#!/usr/bin/env python3
"""Minimal kernel map generator.

Policy: DEFAULT 9 wide, DEFAULT flat. The artifact is the only source of exceptions.
  - width stays 9 unless an artifact's footprint won't fit (then widen + keep a lane)
  - floor stays flat (height 1) unless an artifact's `platform` demands relief:
        pedestal / table -> raised plinth (2),   sunken -> pit (0)

The whole grammar, four rules:
  1. FOOTPRINTS  - each artifact occupies its measured AABB (cells), from the registry.
  2. PACK from (0,0) with separation `s` (the walking gap).
  3. SIZE        - width = 9 by default; depth follows from the pack. (Artifact may widen.)
  4. PATHFIND    - guarantee a walkable route start->end past every footprint.

Seed = { artifacts[], s }.  Width and relief are 9/flat unless an artifact says otherwise.

Usage:
  python tools/kernel_map.py --map Point_One
  python tools/kernel_map.py --map Trans_Rotation --s 1 --out commons/maps/.../map_data.kernel.json
"""
import json, re, glob, math, argparse, os
from collections import deque

PLAT_H = {"pedestal": 2, "table": 2, "sunken": 0, "floor": 1, "wall": 1, "none": 1}


def loose(t):
    return json.loads(re.sub(r",\s*([\]}])", r"\1", t))


def build_footprints(root="."):
    """token -> (w, d, platform)."""
    FP = {}
    def rec(o, pk=None):
        if isinstance(o, dict):
            sn, ms = o.get("spatial_needs"), o.get("measurements")
            if sn or ms:
                tok = o.get("id") or o.get("token") or o.get("lookup_name") or o.get("name") or pk
                w = d = None
                if ms and isinstance(ms.get("aabb_size"), list) and len(ms["aabb_size"]) == 3:
                    w = math.ceil(ms["aabb_size"][0]); d = math.ceil(ms["aabb_size"][2])
                if (not w or not d) and sn and sn.get("footprint_cells"):
                    side = max(1, round(math.sqrt(sn["footprint_cells"])))
                    w = w or side; d = d or side
                sn2 = sn or {}
                plat = sn2.get("platform", "none")
                wall = bool(sn2.get("wall_backing"))
                iso = int(sn2.get("isolation", 0) or 0)
                if tok and w and d:
                    FP.setdefault(str(tok), (max(1, int(w)), max(1, int(d)), str(plat), wall, iso))
            for k, v in o.items():
                rec(v, k)
        elif isinstance(o, list):
            for v in o:
                rec(v, pk)
    for f in glob.glob(os.path.join(root, "commons/artifacts/registry/*.json")):
        try:
            rec(loose(open(f, encoding="utf-8").read()))
        except Exception:
            pass
    return FP


def bag_from_map(name, root="."):
    d = loose(open(os.path.join(root, f"commons/maps/{name}/map_data.json"), encoding="utf-8").read())
    I = d["layers"]["interactables"]
    return [str(c).split("#")[0].split(":")[0].strip()
            for row in I for c in row if str(c).strip() and not str(c).startswith("#")]


def pack(bag, FP, s=1, width=9):
    """Rules 1-3: footprints, pack from origin, width=9 unless an artifact demands more."""
    items = []
    for t in bag:
        w, d, plat, wall, iso = FP.get(t, (1, 1, "none", False, 0))
        iso = min(int(iso), 3)
        if w > d and w > width:                  # too wide to fit: lay long side along depth
            w, d = d, w
        items.append([t, w, d, plat, wall, iso])
    maxw = max(it[1] for it in items)
    W = max(width, maxw + 1 + s)                  # default 9; widen only to keep a lane past a wide item
    order = sorted(items, key=lambda it: -it[2])  # deepest first
    placed, cx, cy, shelf_d = [], 0, 0, 0
    for t, w, d, plat, wall, iso in order:
        if cx + w > W and cx > 0:
            cy += shelf_d + s; cx = 0; shelf_d = 0
        placed.append((t, cy, cx, w, d, plat, wall))
        cx += w + s + iso                          # isolation = extra walking gap after the item
        shelf_d = max(shelf_d, d + iso)
    return placed, W, cy + shelf_d


def build(placed, W, D):
    """Rule 4: pathfind. Flat (1) floor; per-artifact relief from platform."""
    height = [[1] * W for _ in range(D)]          # default flat
    occ = [[0] * W for _ in range(D)]
    inter = [[""] * W for _ in range(D)]
    util = [[""] * W for _ in range(D)]
    for t, r, c, w, d, plat, wall in placed:
        h = PLAT_H.get(plat, 1)                    # exception: pedestal/table=2, sunken=0
        for rr in range(r, r + d):
            for cc in range(c, c + w):
                if 0 <= rr < D and 0 <= cc < W:
                    occ[rr][cc] = 1; height[rr][cc] = h
        inter[r][c] = t
        if wall:                                   # wall_backing: raised backing panel behind (deeper side)
            wr = r + d
            if wr < D:
                for cc in range(c, c + w):
                    if not occ[wr][cc]:
                        occ[wr][cc] = 1; height[wr][cc] = 3
    free = [(r, c) for r in range(D) for c in range(W) if not occ[r][c]]
    start = min(free, key=lambda p: p[0] + p[1])
    end = max(free, key=lambda p: p[0] + p[1])
    util[start[0]][start[1]] = "sp"; util[end[0]][end[1]] = "t"
    seen = {start}; q = deque([start])
    while q:
        r, c = q.popleft()
        for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
            nr, nc = r + dr, c + dc
            if 0 <= nr < D and 0 <= nc < W and not occ[nr][nc] and (nr, nc) not in seen:
                seen.add((nr, nc)); q.append((nr, nc))
    unreached = [t for t, r, c, w, d, _, _ in placed
                 if not any((r + dr, c + dc) in seen
                            for dr in range(-1, d + 1) for dc in range(-1, w + 1))]
    return height, inter, util, occ, start, end, (end in seen), len(seen), unreached


def grid_rows(height, inter, util, occ, W, D):
    rows = []
    for r in range(D):
        cell = ""
        for c in range(W):
            h = height[r][c]
            if inter[r][c]: t = "a"
            elif util[r][c] == "sp": t = "s"
            elif util[r][c] == "t": t = "t"
            elif occ[r][c]: t = "o"
            else: t = "f"
            cell += str(h) + t
        rows.append(cell)
    return rows


def to_map_data(height, inter, util, W, D, name, n_art):
    struct = [[str(height[r][c]) for c in range(W)] for r in range(D)]
    util_out = [[("#sp" if util[r][c] == "sp" else "t" if util[r][c] == "t" else " ")
                 for c in range(W)] for r in range(D)]
    inter_out = [[(inter[r][c] if inter[r][c] else " ") for c in range(W)] for r in range(D)]
    # teleport convention: exit cell is void (h0) with a catch-floor row beyond it
    for r in range(D):
        for c in range(W):
            if util_out[r][c] == "t":
                struct[r][c] = "0"
                struct.append(["0"] * W); struct[-1][c] = "1"      # catch row
                util_out.append([" "] * W); inter_out.append([" "] * W)
                D += 1
    maxh = max((int(v) for row in struct for v in row), default=1)
    return {
        "map_info": {
            "dimensions": {"depth": D, "max_height": max(5, maxh), "width": W},
            "format": "json", "lookup_name": name,
            "metadata": {"n_artifacts": n_art, "source": "kernel_map"},
            "name": name, "version": "1.0",
        },
        "layers": {"structure": struct, "utilities": util_out, "interactables": inter_out},
        "settings": {
            "background": {"color": [0.08, 0.1, 0.18], "type": "sky"},
            "cube_size": 1, "gutter": 0, "show_grid": True,
            "grid_animation": {"enabled": False},
            "initial_tile_visibility": "hidden_except_corners",
            "disable_biome": False, "ground_only": True,
        },
        "utility_definitions": {"sp": {"type": "spawn"}, "t": {"type": "teleport"}},
    }


def write_compact(path, d):
    """Write map_data.json with each grid row on one line (canonical compact-rows)."""
    L = d["layers"]
    out = ["{", '  "map_info": ' + json.dumps(d["map_info"], ensure_ascii=False) + ",", '  "layers": {']
    names = list(L.keys())
    for li, nm in enumerate(names):
        out.append(f'    "{nm}": [')
        rows = L[nm]
        for ri, row in enumerate(rows):
            out.append("      " + json.dumps(row, ensure_ascii=False) + ("," if ri < len(rows) - 1 else ""))
        out.append("    ]" + ("," if li < len(names) - 1 else ""))
    out.append("  },")
    out.append('  "settings": ' + json.dumps(d["settings"], ensure_ascii=False) + ",")
    out.append('  "utility_definitions": ' + json.dumps(d["utility_definitions"], ensure_ascii=False))
    out.append("}")
    open(path, "w", encoding="utf-8").write("\n".join(out))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", default=None, help="source map to borrow the artifact bag from")
    ap.add_argument("--bag", default=None, help="comma-separated artifact tokens (instead of --map)")
    ap.add_argument("--s", type=int, default=1, help="separation / walking gap")
    ap.add_argument("--width", type=int, default=9, help="default map width (artifact may widen it)")
    ap.add_argument("--out", default=None, help="optional map_data.json output path")
    ap.add_argument("--name", default=None, help="lookup_name for the emitted map")
    a = ap.parse_args()
    FP = build_footprints()
    bag = [t.strip() for t in a.bag.split(",")] if a.bag else bag_from_map(a.map)
    placed, W, D = pack(bag, FP, a.s, a.width)
    height, inter, util, occ, start, end, ok, nfree, unreached = build(placed, W, D)
    relief = sorted({p[5] for p in placed if PLAT_H.get(p[5], 1) != 1})
    walls = sum(1 for p in placed if p[6])
    src = a.map or "bag"
    print(f"KERNEL {src} {W}x{D} (default w={a.width}) s={a.s} artifacts={len(bag)} "
          f"path_ok={ok} free={nfree} relief={relief or 'flat'} walls={walls} unreached={unreached}")
    print("<<ROWS")
    for r in grid_rows(height, inter, util, occ, W, D):
        print(r)
    print("ROWS>>")
    if a.out:
        name = a.name or os.path.splitext(os.path.basename(os.path.dirname(a.out)))[0] or "Kernel_Demo"
        os.makedirs(os.path.dirname(a.out), exist_ok=True)
        write_compact(a.out, to_map_data(height, inter, util, W, D, name, len(bag)))
        print("wrote", a.out, "as", name)


if __name__ == "__main__":
    main()
