"""gallery_gen.py — empty exhibition architecture as DNA, iterated.

Palle: "good architecture: create exhibit space with exhibit possibilities —
podium, niches, walls — WITHOUT the artifacts. make like 20 spaces and improve
them for the best way to place artifacts later. iterate, make it DNA, iterate
again."

GENOME (commons/data/gallery_dna.json): width, depth, form (court|axis|loop),
niche_every, podium_rows, podium_spacing, vitrines, dais. Each genome compiles
to a walkable EMPTY gallery: floor, walls-layer architecture with niches
(1-cell recesses in the hull), empty podiums/daises/vitrines as affordances.

SCORE = hosting capacity, measured:
  slots        podiums + daises + vitrines + niches (capacity)
  diversity    how many affordance kinds present (mix)
  hang_m       interior wall meters minus openings (hanging capacity)
  loop         does circulation close a ring (no forced backtrack)
  open_center  fraction of the central third left free (breath)
  spacing      min distance between slots (no crowding)

Generation 1: 20 genomes (seeded variety). Generation 2: the top genomes
mutate; children replace the bottom of the table. Every space validated by
the pathfinder. Scores -> doc/reports/gallery_dna_scores.json; DNA (with
lineage) back into gallery_dna.json.

Usage: python tools/gallery_gen.py
"""
import json
import random
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import map_pathfinder as mp

SEED = 461
N_GEN1 = 20
N_CHILDREN = 8


def make_genome(rng, gid):
    return {
        "id": gid,
        "w": rng.randint(12, 22),
        "d": rng.randint(10, 16),
        "form": rng.choice(["court", "axis", "loop"]),
        "niche_every": rng.choice([0, 3, 4, 5]),
        "podium_rows": rng.choice([1, 1, 2]),
        "podium_spacing": rng.choice([3, 4, 5]),
        "vitrines": rng.choice([0, 2, 4]),
        "dais": rng.choice([0, 1]),
        "parent": None,
    }


def mutate(rng, g, gid):
    child = dict(g)
    child["id"] = gid
    child["parent"] = g["id"]
    gene = rng.choice(["w", "d", "form", "niche_every", "podium_rows",
                       "podium_spacing", "vitrines", "dais"])
    if gene == "w":
        child["w"] = max(10, min(24, g["w"] + rng.choice([-3, -2, 2, 3])))
    elif gene == "d":
        child["d"] = max(9, min(18, g["d"] + rng.choice([-2, 2])))
    elif gene == "form":
        child["form"] = rng.choice([f for f in ["court", "axis", "loop"] if f != g["form"]])
    elif gene == "niche_every":
        child["niche_every"] = rng.choice([v for v in [0, 3, 4, 5] if v != g["niche_every"]])
    elif gene == "podium_rows":
        child["podium_rows"] = 3 - g["podium_rows"]
    elif gene == "podium_spacing":
        child["podium_spacing"] = max(2, min(6, g["podium_spacing"] + rng.choice([-1, 1])))
    elif gene == "vitrines":
        child["vitrines"] = rng.choice([v for v in [0, 2, 4, 6] if v != g["vitrines"]])
    else:
        child["dais"] = 1 - g["dais"]
    return child


def compile_gallery(g):
    """Genome -> map layers. Returns (data dict, slot list, metrics helpers)."""
    W, D = g["w"], g["d"]
    structure = [["0"] * (W + 2) for _ in range(D + 2)]
    utilities = [[" "] * (W + 2) for _ in range(D + 2)]
    inter = [[" "] * (W + 2) for _ in range(D + 2)]
    walls = [[""] * (W + 2) for _ in range(D + 2)]
    # interior floor is (1..W, 1..D) in the padded grid
    for r in range(1, D + 1):
        for c in range(1, W + 1):
            structure[r][c] = "1"

    def add_wall(r, c, code):
        walls[r][c] += code

    slots = []          # (r, c, kind)
    niches = []

    # hull with optional niches (a niche = one floor cell pushed outside the hull line)
    ne = g["niche_every"]
    for c in range(1, W + 1):
        if ne and c % ne == 0 and 1 < c < W:
            structure[0][c] = "1"                    # recess floor
            add_wall(0, c, "n")
            add_wall(0, c, "w")
            add_wall(0, c, "e")
            niches.append((0, c))
            slots.append((0, c, "niche"))
        else:
            add_wall(1, c, "n")
        add_wall(D, c, "s")
    for r in range(1, D + 1):
        add_wall(r, 1, "w")
        add_wall(r, W, "e")

    # form: interior architecture
    axis_r = (D + 1) // 2
    if g["form"] == "axis":
        # a central spine wall broken by doors — two long rooms
        for c in range(2, W):
            if c % 5 == 0:
                add_wall(axis_r, c, "N")
            else:
                add_wall(axis_r, c, "n")
    elif g["form"] == "loop":
        # a central block the visitor circles
        b_w = max(3, W // 3)
        b_d = max(2, D // 3)
        r0 = (D - b_d) // 2 + 1
        c0 = (W - b_w) // 2 + 1
        for r in range(r0, r0 + b_d):
            for c in range(c0, c0 + b_w):
                structure[r][c] = "0"
        for c in range(c0, c0 + b_w):
            add_wall(r0 - 1, c, "s")
            add_wall(r0 + b_d, c, "n")
        for r in range(r0, r0 + b_d):
            add_wall(r, c0 - 1, "e")
            add_wall(r, c0 + b_w, "w")
    # court: open — nothing

    # podiums
    rows = [axis_r] if g["podium_rows"] == 1 else [max(2, axis_r - 2), min(D - 1, axis_r + 2)]
    if g["form"] == "loop":
        rows = [2, D - 1]
    if g["form"] == "axis":
        rows = [max(2, axis_r - 2), min(D - 1, axis_r + 2)][:g["podium_rows"]]
    sp = g["podium_spacing"]
    for rr in rows:
        for c in range(3, W - 1, sp):
            if structure[rr][c] == "1" and inter[rr][c] == " ":
                inter[rr][c] = "exhibit_podium"
                slots.append((rr, c, "podium"))

    # dais at the court/axis focus
    if g["dais"]:
        fc = W - 2
        if structure[axis_r][fc] == "1" and inter[axis_r][fc] == " ":
            inter[axis_r][fc] = "exhibit_podium#kind:dais"
            slots.append((axis_r, fc, "dais"))

    # vitrines along the south wall
    placed_v = 0
    for c in range(2, W, 3):
        if placed_v >= g["vitrines"]:
            break
        if structure[D][c] == "1" and inter[D][c] == " ":
            inter[D][c] = "exhibit_vitrine"
            slots.append((D, c, "vitrine"))
            placed_v += 1

    # spawn west on the axis; teleporter east (void)
    utilities[axis_r][1] = "s"
    inter[axis_r][1] = " "
    te_c = W
    utilities[axis_r][te_c] = "t"
    structure[axis_r][te_c] = "0"
    # make sure no slot shares the teleporter cell
    slots = [s for s in slots if not (s[0] == axis_r and s[1] == te_c)]
    inter[axis_r][te_c] = " "

    title = f"Gallery_{g['id']}"
    data = {
        "map_info": {
            "name": f"Gallery {g['id']} ({g['form']})",
            "title": title, "lookup_name": title,
            "description": f"Empty exhibition architecture, genome {g['id']}: form={g['form']}, "
                           f"{len(slots)} exhibit slots (podiums, niches, vitrines) and no artifacts - "
                           f"hosting capacity waiting for a collection. Generated by gallery-DNA.",
            "version": "0.1", "format": "json",
            "dimensions": {"width": W + 2, "depth": D + 2, "max_height": 1},
            "gallery_genome": g,
            "metadata": {"difficulty": "beginner", "category": "museum",
                         "estimated_time": "2-4 minutes",
                         "learning_objectives": ["architecture before collection"]},
        },
        "utility_definitions": {
            "s": {"type": "spawn", "description": "enter the empty gallery"},
            "t": {"type": "teleporter", "description": "exit"}},
        "settings": {"cube_size": 1.0, "gutter": 0.02, "show_grid": True,
                     "enable_physics": True, "auto_reveal_on_entry": False,
                     "initial_tile_visibility": "all", "background": "dark",
                     "wall_segments": {"height": 3.4, "thickness": 0.16,
                                       "door_width": 2.6, "color": [0.85, 0.83, 0.78]}},
        "lighting": {"ambient_color": [0.42, 0.42, 0.45], "ambient_energy": 0.55,
                     "directional_light": {"enabled": True, "direction": [-0.2, -0.85, -0.25],
                                           "color": [1.0, 0.98, 0.93], "energy": 0.9}},
        "layers": {"structure": structure, "utilities": utilities,
                   "walls": walls, "interactables": inter},
    }
    return data, slots


def score(data, slots):
    g = data["map_info"]["gallery_genome"]
    W, D = g["w"], g["d"]
    graph = mp.MapGraph(data)
    reach = graph.bfs_flood()
    n_floor = sum(1 for row in data["layers"]["structure"] for c in row if c == "1")
    reachable_ok = len(reach) >= n_floor * 0.95

    kinds = {}
    for (_, _, k) in slots:
        kinds[k] = kinds.get(k, 0) + 1
    diversity = len(kinds)

    # hanging capacity: solid interior+hull wall edges (rough meters)
    hang = sum(1 for row in data["layers"]["walls"] for cell in row
               for ch in cell if ch in "nesw")

    # circulation loop: edges >= nodes in the reachable floor graph => a cycle
    edges = 0
    rset = reach
    for (r, c) in rset:
        for (dr, dc) in ((0, 1), (1, 0)):
            if (r + dr, c + dc) in rset and (r + dr, c + dc) in graph.neighbors((r, c)):
                edges += 1
    has_loop = edges >= len(rset)

    # open center: free cells in the middle third
    r0, r1 = 1 + D // 3, 1 + 2 * D // 3
    c0, c1 = 1 + W // 3, 1 + 2 * W // 3
    center = [(r, c) for r in range(r0, r1 + 1) for c in range(c0, c1 + 1)]
    inter_layer = data["layers"]["interactables"]
    st = data["layers"]["structure"]
    open_cells = sum(1 for (r, c) in center
                     if st[r][c] == "1" and inter_layer[r][c].strip() == "")
    open_frac = open_cells / max(1, len(center))

    # spacing: min pairwise slot distance
    import math
    min_d = 99.0
    for i in range(len(slots)):
        for j in range(i + 1, len(slots)):
            d = math.dist(slots[i][:2], slots[j][:2])
            min_d = min(min_d, d)
    spacing_ok = min_d >= 2.0

    s = (min(len(slots), 14) * 1.0          # capacity (capped — hoarding isn't hosting)
         + diversity * 2.0
         + min(hang, 80) * 0.05
         + (4.0 if has_loop else 0.0)
         + open_frac * 6.0
         + (2.0 if spacing_ok else -2.0)
         + (0.0 if reachable_ok else -20.0))
    return round(s, 2), {"slots": len(slots), "kinds": kinds, "hang_edges": hang,
                         "loop": has_loop, "open_center": round(open_frac, 2),
                         "min_slot_dist": round(min_d, 1), "reachable": reachable_ok}


def write_map(data):
    title = data["map_info"]["title"]
    out = ROOT / "commons" / "maps" / title
    out.mkdir(parents=True, exist_ok=True)
    text = json.dumps(data, indent=1)
    text = re.sub(r'\[\s+((?:"[^"]*",?\s+)+)\]',
                  lambda m: '[' + ', '.join(x.strip().rstrip(',')
                                            for x in m.group(1).split('\n') if x.strip()) + ']', text)
    (out / "map_data.json").write_text(text, encoding="utf-8")


def main():
    rng = random.Random(SEED)
    table = []

    # ── generation 1 ─────────────────────────────────────────────────────────
    for i in range(N_GEN1):
        g = make_genome(rng, f"G{i+1:02d}")
        data, slots = compile_gallery(g)
        sc, detail = score(data, slots)
        write_map(data)
        table.append({"genome": g, "score": sc, "detail": detail, "gen": 1})
    table.sort(key=lambda x: -x["score"])
    print("GEN 1 (top 6):")
    for row in table[:6]:
        g = row["genome"]
        print(f"  {g['id']}  {row['score']:6.2f}  form={g['form']:5s} slots={row['detail']['slots']:2d} "
              f"loop={row['detail']['loop']} open={row['detail']['open_center']}")

    # ── generation 2: mutate the top, replace nothing — add children ────────
    parents = table[:4]
    for i in range(N_CHILDREN):
        p = parents[i % len(parents)]["genome"]
        child = mutate(rng, p, f"H{i+1:02d}")
        data, slots = compile_gallery(child)
        sc, detail = score(data, slots)
        write_map(data)
        table.append({"genome": child, "score": sc, "detail": detail, "gen": 2})
    table.sort(key=lambda x: -x["score"])

    print("\nFINAL TABLE (top 10 of %d):" % len(table))
    for row in table[:10]:
        g = row["genome"]
        par = f" <- {g['parent']}" if g.get("parent") else ""
        print(f"  {g['id']}{par:8s} {row['score']:6.2f}  form={g['form']:5s} "
              f"slots={row['detail']['slots']:2d} kinds={len(row['detail']['kinds'])} "
              f"loop={row['detail']['loop']} open={row['detail']['open_center']} "
              f"hang={row['detail']['hang_edges']}")

    # persist DNA + scores
    dna = {"generated_by": "tools/gallery_gen.py", "seed": SEED,
           "genes": ["w", "d", "form", "niche_every", "podium_rows",
                     "podium_spacing", "vitrines", "dais"],
           "population": [row["genome"] | {"score": row["score"], "gen": row["gen"]}
                          for row in table]}
    (ROOT / "commons" / "data" / "gallery_dna.json").write_text(
        json.dumps(dna, indent=1), encoding="utf-8")
    rep = {"generated_by": "tools/gallery_gen.py",
           "scoring": "slots(cap 14) + 2*diversity + 0.05*hang(cap 80) + 4*loop + 6*open_center + 2*spacing - 20*unreachable",
           "table": [{"id": r["genome"]["id"], "gen": r["gen"], "score": r["score"],
                      **r["detail"], "genome": r["genome"]} for r in table]}
    rep_dir = ROOT / "doc" / "reports"
    rep_dir.mkdir(exist_ok=True)
    (rep_dir / "gallery_dna_scores.json").write_text(json.dumps(rep, indent=1), encoding="utf-8")
    print(f"\nwrote {len(table)} galleries, gallery_dna.json, gallery_dna_scores.json")


if __name__ == "__main__":
    main()
