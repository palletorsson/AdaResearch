#!/usr/bin/env python3
"""wall_runs.py — MARRIAGE 2: promote wall runs from render-time trick to DATA.

The viewer's wall fixer computed runs (deduped edges grouped into contiguous
colinear walls) in JavaScript at render time — invisible to Godot, to props,
to anything. This compiler does that computation ONCE, per map, and writes it
into the map itself as `settings.wall_runs`:

  runs:    [{axis, x, z, len, baseY, modules: [{v: variant, door: bool}]}]
  corners: [{x, z, y}]

Every renderer then OBEYS the data instead of re-deriving it, and wall PROPS
get an addressable surface: "run 7, module 2" is a real place. MAP-LEVEL by
design — works on any map with a layers.walls, hand-authored or generated;
the mission/wall-kit generators call annotate() at build time.

Composition rules (ported from the viewer's fixer, now canonical here):
  - one BASE variant per run (seeded by run key, weighted by the palette
    zone of each module's cell — register changes mid-run are intended)
  - one rhythmic ACCENT every 4th module on runs >= 5
  - doors become `doorframe`
  - corner records where perpendicular runs meet

Usage:
  python tools/wall_runs.py --map=<Name>       annotate one map in place
  python tools/wall_runs.py --all-generated    annotate WallKit*/Mission* maps
"""
import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT.parent / "ada_encyclopedia" / "public" / "wall-gltf" / "manifest.json"
sys.stdout.reconfigure(encoding="utf-8", errors="replace")


def fnv(s: str) -> int:
    """FNV-1a 32-bit — the same hash the viewer used, now canonical."""
    h = 2166136261
    for ch in s:
        h ^= ord(ch)
        h = (h * 16777619) & 0xFFFFFFFF
    return h


def _global_picks():
    try:
        man = json.loads(MANIFEST.read_text(encoding="utf-8"))
        picks = []
        for v in man.get("variants", []):
            picks += [v["name"]] * int(v.get("weight", 0))
        return picks or ["plain"]
    except OSError:
        return ["plain"]


def _parse_h(cell) -> int:
    s = str(cell).strip()
    if not s or s == "0":
        return 0
    try:
        return int(s.split(":")[0])
    except ValueError:
        return 1


def compile_runs(data: dict, map_name: str) -> dict:
    layers = data.get("layers", {})
    wl = layers.get("walls", [])
    st = layers.get("structure", [])
    if not wl:
        return {"runs": [], "corners": []}
    # palette zones -> per-zone weighted pools
    palettes = (data.get("settings", {}).get("wall_segments", {})
                .get("palettes", []))
    zone_pools = []
    for p in palettes:
        pool = []
        for n, w in p.get("weights", {}).items():
            pool += [n] * int(w)
        if pool:
            zone_pools.append((p["rect"], pool))
    gpicks = _global_picks()

    def pool_for(cx, cz):
        for rect, pool in zone_pools:
            c0, r0, c1, r1 = rect
            if c0 <= cx <= c1 and r0 <= cz <= r1:
                return pool
        return gpicks

    # pass 1: dedupe edges (n->(h,x,z) s->(h,x,z+1) w->(v,x,z) e->(v,x+1,z))
    edges = {}
    for z, row in enumerate(wl):
        for x, cell in enumerate(row):
            code = str(cell).strip()
            if not code:
                continue
            base_y = _parse_h(st[z][x]) if z < len(st) and x < len(st[z]) else 1
            for ch in code:
                lo = ch.lower()
                if lo not in "nesw":
                    continue
                axis = "h" if lo in "ns" else "v"
                ex = x + 1 if lo == "e" else x
                ez = z + 1 if lo == "s" else z
                key = (axis, ex, ez)
                door = ch != lo
                if key in edges:
                    edges[key]["door"] = edges[key]["door"] or door
                    edges[key]["baseY"] = min(edges[key]["baseY"], base_y)
                else:
                    edges[key] = {"axis": axis, "ex": ex, "ez": ez, "door": door,
                                  "baseY": base_y, "cx": x, "cz": z}
    # pass 2: group into contiguous colinear runs
    by_line = {}
    for e in edges.values():
        lk = ("h", e["ez"]) if e["axis"] == "h" else ("v", e["ex"])
        by_line.setdefault(lk, []).append(e)
    runs = []
    for (axis, _), lst in by_line.items():
        lst.sort(key=lambda e: e["ex"] if axis == "h" else e["ez"])
        cur = []
        for e in lst:
            coord = e["ex"] if axis == "h" else e["ez"]
            prev = (cur[-1]["ex"] if axis == "h" else cur[-1]["ez"]) if cur else None
            if cur and coord != prev + 1:
                runs.append(cur)
                cur = []
            cur.append(e)
        if cur:
            runs.append(cur)
    # pass 3: compose
    out_runs = []
    for run in runs:
        head = run[0]
        rk = f"{map_name}:{head['axis']}:{head['ex']}:{head['ez']}"
        modules = []
        for i, e in enumerate(run):
            if e["door"]:
                modules.append({"v": "doorframe", "door": True})
                continue
            pool = pool_for(e["cx"], e["cz"])
            base = pool[fnv(rk) % len(pool)]
            accent = pool[fnv(rk + ":accent") % len(pool)]
            v = accent if (len(run) >= 5 and i % 4 == 2 and accent != base) else base
            modules.append({"v": v, "door": False})
        out_runs.append({"axis": head["axis"], "x": head["ex"], "z": head["ez"],
                         "len": len(run), "baseY": head["baseY"],
                         "modules": modules})
    # corners: where perpendicular edges share an endpoint
    pts = {}
    for e in edges.values():
        if e["axis"] == "h":
            ends = ((e["ex"] - 0.5, e["ez"] - 0.5), (e["ex"] + 0.5, e["ez"] - 0.5))
        else:
            ends = ((e["ex"] - 0.5, e["ez"] - 0.5), (e["ex"] - 0.5, e["ez"] + 0.5))
        for p in ends:
            rec = pts.setdefault(p, {"axes": set(), "y": e["baseY"]})
            rec["axes"].add(e["axis"])
            rec["y"] = min(rec["y"], e["baseY"])
    corners = [{"x": p[0], "z": p[1], "y": rec["y"]}
               for p, rec in pts.items() if len(rec["axes"]) > 1]
    return {"runs": out_runs, "corners": corners}


def annotate(data: dict, map_name: str) -> dict:
    """compute + attach wall_runs; call from generators before writing."""
    data.setdefault("settings", {})["wall_runs"] = compile_runs(data, map_name)
    return data


def annotate_file(path: Path) -> tuple:
    data = json.loads(path.read_text(encoding="utf-8"))
    name = data.get("map_info", {}).get("lookup_name", path.parent.name)
    annotate(data, name)
    with open(path, "w", encoding="utf-8", newline="\n") as f:
        json.dump(data, f, indent=1)
    wr = data["settings"]["wall_runs"]
    return len(wr["runs"]), len(wr["corners"])


def main() -> int:
    arg = lambda k: next((a.split("=", 1)[1] for a in sys.argv
                          if a.startswith(f"--{k}=")), None)
    if arg("map"):
        p = ROOT / "commons" / "maps" / arg("map") / "map_data.json"
        n, c = annotate_file(p)
        print(f"{arg('map')}: {n} runs, {c} corners")
        return 0
    if "--all-generated" in sys.argv:
        import glob
        for p in sorted(glob.glob(str(ROOT / "commons" / "maps" / "*" / "map_data.json"))):
            name = Path(p).parent.name
            if not (name.startswith("WallKit") or name.startswith("Mission")):
                continue
            n, c = annotate_file(Path(p))
            print(f"{name}: {n} runs, {c} corners")
        return 0
    print(__doc__)
    return 1


if __name__ == "__main__":
    sys.exit(main())
