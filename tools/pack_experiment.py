"""tools/pack_experiment.py — does 'smallest walkable footprint' beat 'fill the grid'?

Takes a map's artifact set and packs it the way a warehouse or lab actually packs: a
corridor spine with artifacts in bays on both sides, each bay deep enough for the artifact's
body + its front clearance (the spine IS the approach). Everything touches the spine, so the
layout is walkable by construction — and the bounding box shrinks to exactly what the artifacts
and their clearances demand. Spatial economy as the forcing function.

Writes the packed layout as a real map (validatable by map_pathfinder), renders both the
baseline fill and the packed version as Scrabble boards, and prints the area/score comparison.

    python tools/pack_experiment.py --map=Zone_WarehouseLab
"""
from __future__ import annotations
import argparse, json, math, subprocess, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MAPS = ROOT / "commons" / "maps"
sys.path.insert(0, str(ROOT / "tools"))
from compact_map_json import _ser
import scrabble_board as SB           # reuse tile_value + the board renderer
import glob


def load_needs() -> dict:
    out = {}
    for f in glob.glob(str(ROOT / "commons/artifacts/registry/*.json")):
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        for n, a in (d.get("artifacts", d) or {}).items():
            if isinstance(a, dict):
                out.setdefault(n, a)
    return out


def body_dims(meta: dict) -> tuple[int, int]:
    """footprint_cells (a count or [w,d]) -> a near-square (w, d) body."""
    sn = meta.get("spatial_needs", {}) or {}
    fp = sn.get("footprint_cells", sn.get("measured_footprint_cells", 1)) or 1
    if isinstance(fp, (list, tuple)):
        xs = [int(x) for x in fp if x] or [1]
        return max(xs[0], 1), max(xs[-1], 1)
    n = max(int(fp), 1)
    w = int(math.ceil(math.sqrt(n)))
    d = int(math.ceil(n / w))
    return w, d


def front_clear(meta: dict) -> int:
    sn = meta.get("spatial_needs", {}) or {}
    cl = sn.get("clearance", {}) or {}
    return max(1, int(cl.get("front", 1) or 1))


def floor_count(structure) -> int:
    return sum(1 for row in structure for cell in row if str(cell) not in ("0", " ", ""))


def pack(names: list[str], needs: dict) -> dict:
    """Aisle-pack: a 1-wide spine, artifacts in bays N/S, bay depth = (front_clear-1)+body_d."""
    arts = []
    for n in names:
        m = needs.get(n, {})
        w, d = body_dims(m)
        f = front_clear(m)
        arts.append({"name": n, "w": w, "d": d, "f": f, "bay_d": (f - 1) + d})
    # widest bodies first, then alternate sides to balance the two rows
    arts.sort(key=lambda a: -(a["w"] * a["bay_d"]))
    north, south = [], []
    nw = sw = 0
    for a in arts:
        if nw <= sw:
            north.append(a); nw += a["w"]
        else:
            south.append(a); sw += a["w"]

    north_d = max([a["bay_d"] for a in north], default=0)
    south_d = max([a["bay_d"] for a in south], default=0)
    length = max(nw, sw) + 2                       # +2 for spawn / teleporter end caps
    spine_r = north_d
    rows = north_d + 1 + south_d
    cols = length

    S = [["0"] * cols for _ in range(rows)]
    U = [[" "] * cols for _ in range(rows)]
    I = [[" "] * cols for _ in range(rows)]
    Z = [["."] * cols for _ in range(rows)]

    # the spine
    for c in range(cols):
        S[spine_r][c] = "1"; Z[spine_r][c] = " "
    U[spine_r][0] = "sp"; Z[spine_r][0] = "E"
    U[spine_r][cols - 1] = "t"; Z[spine_r][cols - 1] = "Z"

    def lay(side_arts, sign):
        c = 1
        for a in side_arts:
            for dc in range(a["w"]):
                cc = c + dc
                if cc >= cols - 1:
                    continue
                # approach cells (front clearance) + body cells, all floor
                for k in range(1, a["bay_d"] + 1):
                    rr = spine_r + sign * k
                    if 0 <= rr < rows:
                        S[rr][cc] = "1"; Z[rr][cc] = "X"
            # artifact token at the body's front-centre (the cell you read from)
            anchor_r = spine_r + sign * a["f"]
            anchor_c = min(c + a["w"] // 2, cols - 2)
            if 0 <= anchor_r < rows:
                I[anchor_r][anchor_c] = f"{a['name']}:180:0.0"
                Z[anchor_r][anchor_c] = "T" if a["f"] > 1 else "X"
            c += a["w"]

    lay(north, -1)
    lay(south, +1)
    return {"structure": S, "utilities": U, "interactables": I, "zone": Z,
            "rows": rows, "cols": cols, "placed": [a["name"] for a in arts]}


def write_packed(src_map: str, packed: dict) -> str:
    lookup = f"{src_map}_Packed"
    out_dir = MAPS / lookup
    out_dir.mkdir(exist_ok=True)
    md = {
        "map_info": {
            "name": f"{src_map} — packed",
            "lookup_name": lookup,
            "title": "Packed",
            "description": "The same artifact set as " + src_map + ", packed into the smallest "
                           "walkable footprint: a corridor spine with bays sized to each "
                           "artifact's body + front clearance. Spatial economy as the objective.",
            "version": "pack-experiment-0.1",
            "format": "json",
            "created_from": "tools/pack_experiment.py",
            "dimensions": {"width": packed["cols"], "depth": packed["rows"], "max_height": 3},
            "metadata": {
                "category": "lab", "difficulty": "intermediate",
                "archetype": "packed_spine", "artifacts_placed": packed["placed"],
                "zone_legend": {"E": "entry", "T": "teaching", "X": "exploration",
                                "Z": "exit", ".": "void", " ": "floor"},
                "zone_grid": ["".join(r) for r in packed["zone"]],
            },
        },
        "utility_definitions": {
            "sp": {"name": "Spawn", "type": "spawn"},
            "t": {"name": "Exit Portal", "type": "teleporter",
                  "properties": {"action": "next_in_sequence"}},
        },
        "lighting": {"ambient_color": [0.30, 0.32, 0.40], "ambient_energy": 0.85,
                     "directional_light": {"enabled": True, "direction": [-0.3, -1.0, -0.2], "energy": 0.8}},
        "settings": {"cube_size": 1.0, "gutter": 0.0, "show_grid": True},
        "layers": {"structure": packed["structure"], "utilities": packed["utilities"],
                   "interactables": packed["interactables"]},
    }
    (out_dir / "map_data.json").write_text(_ser(md, 0) + "\n", encoding="utf-8", newline="\n")
    return lookup


def stats_for(map_name: str) -> dict:
    md = json.load(open(MAPS / map_name / "map_data.json", encoding="utf-8"))
    S = md["layers"]["structure"]
    rows, cols = len(S), len(S[0])
    fc = floor_count(S)
    return {"rows": rows, "cols": cols, "bbox": rows * cols, "floor": fc}


def pathfinder(map_name: str) -> str:
    try:
        out = subprocess.run([sys.executable, str(ROOT / "tools/map_pathfinder.py"), "check", map_name],
                             capture_output=True, text=True, cwd=str(ROOT), timeout=120)
        tail = (out.stdout or "").strip().splitlines()
        return tail[-1] if tail else "(no output)"
    except Exception as e:
        return f"(pathfinder error: {e})"


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--map", default="Zone_WarehouseLab")
    a = p.parse_args()
    src = a.map
    needs = load_needs()
    names = json.load(open(MAPS / src / "map_data.json", encoding="utf-8"))["map_info"]["metadata"]["artifacts_placed"]

    packed = pack(names, needs)
    packed_name = write_packed(src, packed)

    base = stats_for(src)
    pk = stats_for(packed_name)

    trials = ROOT.parent / "ada_encyclopedia" / "public" / "sculpture-gallery" / "_trials"
    trials.mkdir(parents=True, exist_ok=True)
    rb = SB.render(src, trials / "_pack_base.png")
    rp = SB.render(packed_name, trials / "_pack_packed.png")

    # stitch side by side with a stats header
    from PIL import Image, ImageDraw, ImageFont
    ib = Image.open(trials / "_pack_base.png").convert("RGB")
    ip = Image.open(trials / "_pack_packed.png").convert("RGB")
    head = 92
    H = max(ib.height, ip.height) + head
    W = ib.width + ip.width + 16
    sheet = Image.new("RGB", (W, H), (15, 16, 20))
    d = ImageDraw.Draw(sheet)
    try:
        fT = ImageFont.truetype("arialbd.ttf", 20); fs = ImageFont.truetype("arial.ttf", 15)
    except Exception:
        fT = fs = ImageFont.load_default()
    bdens = rb["score"] / max(1, base["floor"]); pdens = rp["score"] / max(1, pk["floor"])
    d.text((12, 10), "fill the grid  vs  smallest walkable footprint", font=fT, fill=(230, 230, 180))
    d.text((12, 40), f"BASELINE {src}:  {base['cols']}×{base['rows']} = {base['bbox']} cells · "
                     f"{base['floor']} floor · score {rb['score']} · score/floor {bdens:.2f}",
           font=fs, fill=(170, 190, 210))
    d.text((12, 64), f"PACKED:  {pk['cols']}×{pk['rows']} = {pk['bbox']} cells · "
                     f"{pk['floor']} floor · score {rp['score']} · score/floor {pdens:.2f}   "
                     f"→ {100 - round(100 * pk['floor'] / max(1, base['floor']))}% less floor",
           font=fs, fill=(150, 210, 150))
    sheet.paste(ib, (0, head)); sheet.paste(ip, (ib.width + 16, head))
    out = trials / "_pack_compare.png"
    sheet.save(out)

    print(f"\n  {'':12s} {'bbox':>10s} {'floor':>7s} {'score':>7s} {'score/floor':>12s}  walkable")
    print(f"  {'baseline':12s} {base['cols']}x{base['rows']}={base['bbox']:<5d} {base['floor']:>7d} {rb['score']:>7d} {bdens:>12.2f}  {pathfinder(src)}")
    print(f"  {'packed':12s} {pk['cols']}x{pk['rows']}={pk['bbox']:<5d} {pk['floor']:>7d} {rp['score']:>7d} {pdens:>12.2f}  {pathfinder(packed_name)}")
    print(f"\n  packed uses {100 - round(100 * pk['floor'] / max(1, base['floor']))}% less floor and "
          f"{100 - round(100 * pk['bbox'] / max(1, base['bbox']))}% less bounding box.")
    print(f"  wrote {packed_name} + {out}")


if __name__ == "__main__":
    main()
