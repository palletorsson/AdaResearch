"""gallery_evolve.py — auto-research for empty exhibition architecture.

v2 of the gallery DNA, in the spirit of placement_research.py ("no base
algorithm wins"): a much richer genome, THREE taste-profiles evolved as
separate populations (best-for-CAPACITY, best-for-DRAMA, best-for-INTIMACY),
five generations each with tournament selection, crossover, mutation and
elitism — all scoring in memory, only champions written to disk.

GENOME v2:
  w, d               up to 26x18
  form               court | axis | loop | basilica | cross | rotunda |
                     pockets | terrace
  height             flat | step_down (terraces 3->2->1 toward the exit)
  niche_every        hull niche rhythm (0=none)
  niche_deep         1 or 2 cells deep
  podium_motif       axis_row | double_row | ring | constellation | spiral
  podium_spacing     2..6
  vitrines, dais     counts
  route_walls        freestanding hanging walls in the open floor (0..3)
  light              bright | dusk | dramatic

PROFILES (fitness):
  capacity  slots + diversity + hang meters + loop + spacing
  drama     vista length + focal dais + terraces + dramatic light + hang
  intimacy  niches + pockets + door count + SHORT sightlines + dusk

Report: doc/reports/gallery_dna_research.md (+ .json). Champions land as
Gallery_CAP_1.., Gallery_DRA_1.., Gallery_INT_1.. maps.

Usage: python tools/gallery_evolve.py
"""
import json
import math
import random
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import map_pathfinder as mp

SEED = 461
POP = 24
GENS = 5
ELITE = 4
CHAMPIONS = 4          # per profile written to disk

FORMS = ["court", "axis", "loop", "basilica", "cross", "rotunda", "pockets", "terrace"]

# furniture palettes: what the motif plants (token, slot_kind, slot_value)
PALETTES = {
    "classic": [("exhibit_podium", "podium", 1),
                ("exhibit_furniture#kind:plinth#size:m", "plinth_m", 1),
                ("exhibit_furniture#kind:vitrine_tall", "vitrine_tall", 1)],
    "mixed":   [("exhibit_furniture#kind:plinth#size:s", "plinth_s", 1),
                ("exhibit_furniture#kind:plinth#size:l", "plinth_l", 1),
                ("exhibit_furniture#kind:table_2m", "table", 2),
                ("exhibit_furniture#kind:platform#size:l", "platform", 2),
                ("exhibit_furniture#kind:hollow_plinth", "hollow", 1)],
    "cabinet": [("exhibit_furniture#kind:cabinet", "cabinet", 3),
                ("exhibit_furniture#kind:vitrine_tall", "vitrine_tall", 1),
                ("exhibit_vitrine", "vitrine", 1)],
    "full":    [("exhibit_podium", "podium", 1),
                ("exhibit_furniture#kind:table_2m", "table", 2),
                ("exhibit_furniture#kind:cabinet", "cabinet", 3),
                ("exhibit_furniture#kind:hollow_plinth", "hollow", 1),
                ("exhibit_furniture#kind:platform", "platform", 2),
                ("exhibit_furniture#kind:vitrine_tall", "vitrine_tall", 1)],
}
MOTIFS = ["axis_row", "double_row", "ring", "constellation", "spiral"]
LIGHTS = ["bright", "dusk", "dramatic"]


# ── genome ───────────────────────────────────────────────────────────────────

def make_genome(rng):
    return {
        "w": rng.randint(14, 26), "d": rng.randint(10, 18),
        "form": rng.choice(FORMS),
        "height": rng.choice(["flat", "flat", "step_down"]),
        "niche_every": rng.choice([0, 3, 4, 5]),
        "niche_deep": rng.choice([1, 1, 2]),
        "podium_motif": rng.choice(MOTIFS),
        "podium_spacing": rng.randint(2, 6),
        "vitrines": rng.choice([0, 2, 4, 6]),
        "dais": rng.choice([0, 1, 1, 2]),
        "route_walls": rng.choice([0, 0, 1, 2, 3]),
        "floating_walls": rng.choice([0, 0, 1, 2, 3, 4]),
        "furniture_mix": rng.choice(["classic", "mixed", "cabinet", "full"]),
        "signage": rng.choice([0, 1, 1]),
        "infoboard": rng.choice([0, 1, 1]),
        "light": rng.choice(LIGHTS),
    }


def crossover(rng, a, b):
    return {k: (a if rng.random() < 0.5 else b)[k] for k in a}


def mutate(rng, g):
    g = dict(g)
    k = rng.choice(list(g.keys()))
    fresh = make_genome(rng)
    g[k] = fresh[k]
    return g


# ── compiler: genome -> layers ───────────────────────────────────────────────

def compile_gallery(g, gid="X"):
    W, D = g["w"], g["d"]
    PW, PD = W + 4, D + 4          # padding for niches / rotunda ragged hull
    structure = [["0"] * PW for _ in range(PD)]
    utilities = [[" "] * PW for _ in range(PD)]
    inter = [[" "] * PW for _ in range(PD)]
    walls = [[""] * PW for _ in range(PD)]
    O = 2                           # interior origin offset

    def aw(r, c, code):
        walls[r][c] += code

    floor = set()
    if g["form"] == "rotunda":
        cx, cy = O + W / 2.0, O + D / 2.0
        rad = min(W, D) / 2.0
        for r in range(O, O + D):
            for c in range(O, O + W):
                if ((c - cx + 0.5) ** 2 / (W / 2.0) ** 2 +
                        (r - cy + 0.5) ** 2 / (D / 2.0) ** 2) <= 1.0:
                    floor.add((r, c))
    else:
        for r in range(O, O + D):
            for c in range(O, O + W):
                floor.add((r, c))

    axis_r = O + D // 2

    # heights: terraces descend west->east (drops are walkable; exit east)
    hmap = {}
    for (r, c) in floor:
        if g["height"] == "step_down" or g["form"] == "terrace":
            t = (c - O) / max(1, W - 1)
            hmap[(r, c)] = 3 if t < 0.33 else (2 if t < 0.66 else 1)
        else:
            hmap[(r, c)] = 1
    for (r, c) in floor:
        structure[r][c] = str(hmap[(r, c)])

    # hull niches (skip on rotunda/terrace-north to keep it simple)
    slots = []
    ne = g["niche_every"]
    if ne and g["form"] != "rotunda":
        for c in range(O + 1, O + W - 1):
            if (c - O) % ne == 0:
                depth = g["niche_deep"]
                ok = all((O - 1 - dd, c) not in floor for dd in range(depth))
                if not ok:
                    continue
                for dd in range(depth):
                    rr = O - 1 - dd
                    floor.add((rr, c))
                    structure[rr][c] = structure[O][c]
                    hmap[(rr, c)] = hmap[(O, c)]
                slots.append((O - depth, c, "niche"))

    # hull walls: every floor/void boundary
    for (r, c) in floor:
        if (r - 1, c) not in floor:
            aw(r, c, "n")
        if (r + 1, c) not in floor:
            aw(r, c, "s")
        if (r, c - 1) not in floor:
            aw(r, c, "w")
        if (r, c + 1) not in floor:
            aw(r, c, "e")

    # interior architecture by form
    doors = 0
    if g["form"] == "axis":
        for c in range(O + 1, O + W - 1):
            if (axis_r, c) in floor:
                if (c - O) % 5 == 0:
                    aw(axis_r, c, "N")
                    doors += 1
                else:
                    aw(axis_r, c, "n")
    elif g["form"] == "basilica":
        for rr in (O + D // 4, O + 3 * D // 4):
            for c in range(O + 1, O + W - 1):
                if (rr, c) in floor:
                    if (c - O) % 3 == 0:
                        aw(rr, c, "N")
                        doors += 1
                    else:
                        aw(rr, c, "n")
    elif g["form"] == "cross":
        cc = O + W // 2
        for c in range(O + 1, O + W - 1):
            if (axis_r, c) in floor and abs(c - cc) > 2:
                aw(axis_r, c, "n")
        for r in range(O + 1, O + D - 1):
            if (r, cc) in floor and abs(r - axis_r) > 2:
                aw(r, cc, "w")
    elif g["form"] == "loop":
        b_w, b_d = max(3, W // 3), max(2, D // 3)
        r0, c0 = O + (D - b_d) // 2, O + (W - b_w) // 2
        for r in range(r0, r0 + b_d):
            for c in range(c0, c0 + b_w):
                floor.discard((r, c))
                structure[r][c] = "0"
        for c in range(c0, c0 + b_w):
            aw(r0 - 1, c, "s")
            aw(r0 + b_d, c, "n")
        for r in range(r0, r0 + b_d):
            aw(r, c0 - 1, "e")
            aw(r, c0 + b_w, "w")
    elif g["form"] == "pockets":
        pw, pd = max(4, W // 3 - 1), max(3, D // 3)
        for (r0, c0) in [(O, O), (O, O + W - pw), (O + D - pd, O), (O + D - pd, O + W - pw)]:
            for c in range(c0, c0 + pw):
                edge_r = r0 + pd - 1 if r0 == O else r0
                code = "s" if r0 == O else "n"
                if (edge_r, c) in floor:
                    mid = c == c0 + pw // 2
                    aw(edge_r, c, code.upper() if mid else code)
                    if mid:
                        doors += 1
            for r in range(r0, r0 + pd):
                edge_c = c0 + pw - 1 if c0 == O else c0
                code = "e" if c0 == O else "w"
                if (r, edge_c) in floor:
                    aw(r, edge_c, code)

    # freestanding route walls (both faces hangable) in open floor
    rng_rw = random.Random(SEED + len(gid))
    for i in range(g["route_walls"]):
        rr = O + 2 + (i * 3) % max(1, D - 4)
        c0 = O + 3 + (i * 5) % max(1, W - 8)
        for c in range(c0, min(c0 + 4, O + W - 2)):
            if (rr, c) in floor and (rr - 1, c) in floor:
                aw(rr, c, "n")

    # podium motifs -- cycle the genome's furniture palette
    palette = PALETTES[g.get("furniture_mix", "classic")]
    put_count = [0]

    def put(r, c, kind_unused=None, token=None):
        if (r, c) in floor and inter[r][c] == " ":
            tok, slot_kind, value = palette[put_count[0] % len(palette)]
            if token is not None:
                tok = token
                slot_kind = kind_unused or "podium"
                value = 1
            inter[r][c] = tok
            slots.append((r, c, slot_kind, value))
            put_count[0] += 1

    sp = g["podium_spacing"]
    if g["podium_motif"] == "axis_row":
        for c in range(O + 2, O + W - 2, sp):
            put(axis_r, c, "podium")
    elif g["podium_motif"] == "double_row":
        for rr in (max(O + 1, axis_r - 2), min(O + D - 2, axis_r + 2)):
            for c in range(O + 2, O + W - 2, sp):
                put(rr, c, "podium")
    elif g["podium_motif"] == "ring":
        cx, cy = O + W / 2.0, O + D / 2.0
        rad = min(W, D) / 2.0 - 2.0
        n = max(6, int(2 * math.pi * rad / sp))
        for i in range(n):
            a = 2 * math.pi * i / n
            put(int(round(cy + math.sin(a) * rad * 0.8)),
                int(round(cx + math.cos(a) * rad)), "podium")
    elif g["podium_motif"] == "constellation":
        rng2 = random.Random(SEED + 7)
        for _ in range(10):
            put(rng2.randint(O + 1, O + D - 2), rng2.randint(O + 2, O + W - 3), "podium")
    else:  # spiral
        cx, cy = O + W / 2.0, O + D / 2.0
        for i in range(14):
            a = 0.9 * i
            rad = 1.0 + 0.45 * i
            put(int(round(cy + math.sin(a) * rad * 0.7)),
                int(round(cx + math.cos(a) * rad)), "podium")

    for i in range(g["dais"]):
        c = O + W - 3 - i * 4
        put(axis_r, c, "dais", token="exhibit_podium#kind:dais")
    placed_v = 0
    for c in range(O + 1, O + W - 1, 3):
        if placed_v >= g["vitrines"]:
            break
        r = O + D - 1
        if (r, c) in floor and inter[r][c] == " ":
            put(r, c, "vitrine", token="exhibit_vitrine")
            placed_v += 1

    # floating walls (MoMA hover) -- interactables, they don't block the floor
    fw = g.get("floating_walls", 0)
    for i in range(fw):
        rr = O + 2 + (i * 4) % max(1, D - 4)
        cc = O + 4 + (i * 6) % max(1, W - 8)
        rot = 90 if i % 2 else 0
        if (rr, cc) in floor and inter[rr][cc] == " ":
            inter[rr][cc] = "exhibit_furniture:%d#kind:floating_wall#w:4" % rot
            slots.append((rr, cc, "floating_wall", 2))

    # hospitality: infoboard near the entry, signage by the walls
    if g.get("infoboard", 0):
        cand = sorted(floor, key=lambda p: (p[1], abs(p[0] - axis_r)))
        for (rr, cc) in cand[2:8]:
            if inter[rr][cc] == " ":
                inter[rr][cc] = "exhibit_furniture#kind:infoboard"
                break
    if g.get("signage", 0):
        east_cells = sorted(floor, key=lambda p: (-p[1], abs(p[0] - axis_r)))
        for (rr, cc) in east_cells[1:6]:
            if inter[rr][cc] == " ":
                inter[rr][cc] = "exhibit_furniture#kind:sign_exit"
                break
        hullish = [pp for pp in floor if any(ch in walls[pp[0]][pp[1]] for ch in "ns")]
        for (rr, cc) in hullish[:: max(1, len(hullish) // 2)][:2]:
            if inter[rr][cc] == " ":
                inter[rr][cc] = "exhibit_furniture#kind:sign_fire"

    # spawn west (highest terrace), teleporter east on void
    spawn = min((p for p in floor), key=lambda p: (p[1], abs(p[0] - axis_r)))
    utilities[spawn[0]][spawn[1]] = "s"
    inter[spawn[0]][spawn[1]] = " "
    slots = [t for t in slots if (t[0], t[1]) != spawn]
    exit_c = max((p for p in floor), key=lambda p: (p[1], -abs(p[0] - axis_r)))
    utilities[exit_c[0]][exit_c[1]] = "t"
    structure[exit_c[0]][exit_c[1]] = "0"
    inter[exit_c[0]][exit_c[1]] = " "
    slots = [t for t in slots if (t[0], t[1]) != exit_c]

    light_cfg = {
        "bright": {"ambient_color": [0.5, 0.5, 0.52], "ambient_energy": 0.65,
                   "directional_light": {"enabled": True, "direction": [-0.2, -0.85, -0.25],
                                         "color": [1.0, 0.98, 0.93], "energy": 1.0}},
        "dusk": {"ambient_color": [0.3, 0.29, 0.36], "ambient_energy": 0.4,
                 "directional_light": {"enabled": True, "direction": [-0.5, -0.6, -0.3],
                                       "color": [0.95, 0.8, 0.65], "energy": 0.6}},
        "dramatic": {"ambient_color": [0.16, 0.16, 0.22], "ambient_energy": 0.25,
                     "directional_light": {"enabled": True, "direction": [-0.15, -0.95, -0.1],
                                           "color": [1.0, 0.95, 0.85], "energy": 1.3}},
    }[g["light"]]

    data = {
        "map_info": {
            "name": f"Gallery {gid} ({g['form']}/{g['podium_motif']})",
            "title": f"Gallery_{gid}", "lookup_name": f"Gallery_{gid}",
            "description": f"Empty exhibition architecture, evolved: form={g['form']}, motif={g['podium_motif']}, "
                           f"light={g['light']}, {len(slots)} exhibit slots and no artifacts. Auto-research champion.",
            "version": "0.2", "format": "json",
            "dimensions": {"width": PW, "depth": PD, "max_height": 3},
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
        "lighting": light_cfg,
        "layers": {"structure": structure, "utilities": utilities,
                   "walls": walls, "interactables": inter},
    }
    return data, slots


# ── measurement ──────────────────────────────────────────────────────────────

def measure(data, slots):
    g = data["map_info"]["gallery_genome"]
    graph = mp.MapGraph(data)
    reach = graph.bfs_flood()
    st = data["layers"]["structure"]
    floor_cells = {(r, c) for r, row in enumerate(st) for c, v in enumerate(row) if v != "0"}
    reachable = len(reach) >= len(floor_cells) * 0.92

    kinds = {}
    capacity = 0
    for t in slots:
        k = t[2]
        v = t[3] if len(t) > 3 else 1
        kinds[k] = kinds.get(k, 0) + 1
        capacity += v
    hang = sum(1 for row in data["layers"]["walls"] for cell in row for ch in cell if ch in "nesw")
    hang += kinds.get("floating_wall", 0) * 8   # both faces hangable

    # vista: longest straight walkable run (wall-edge aware)
    blocked = graph.wall_edges
    best_run = 0
    for (r, c) in floor_cells:
        run = 1
        cc = c
        while (r, cc + 1) in floor_cells and ("v", r, cc + 1) not in blocked:
            run += 1
            cc += 1
        best_run = max(best_run, run)
        run = 1
        rr = r
        while (rr + 1, c) in floor_cells and ("h", rr + 1, c) not in blocked:
            run += 1
            rr += 1
        best_run = max(best_run, run)

    doors = sum(1 for row in data["layers"]["walls"] for cell in row for ch in cell if ch in "NESW")
    heights = {int(st[r][c]) for (r, c) in floor_cells}
    edges = 0
    for (r, c) in reach:
        for nb in graph.neighbors((r, c)):
            edges += 1
    has_loop = edges / 2 >= len(reach)

    min_d = 99.0
    for i in range(len(slots)):
        for j in range(i + 1, len(slots)):
            min_d = min(min_d, math.dist(slots[i][:2], slots[j][:2]))

    g2 = data["map_info"]["gallery_genome"]
    hospitality = (1 if g2.get("infoboard", 0) else 0) + (1 if g2.get("signage", 0) else 0)
    return {"slots": capacity, "kinds": len(kinds), "n_niche": kinds.get("niche", 0),
            "hospitality": hospitality, "floating": kinds.get("floating_wall", 0),
            "hang": hang, "vista": best_run, "doors": doors,
            "terraced": len(heights) > 1, "loop": has_loop,
            "min_slot_dist": round(min_d, 1), "reachable": reachable,
            "dais": kinds.get("dais", 0), "light": g["light"]}


def fitness(profile, m):
    if not m["reachable"]:
        return -100.0
    spacing = 2.0 if m["min_slot_dist"] >= 2.0 else -4.0
    if profile == "capacity":
        return (min(m["slots"], 20) * 1.2 + m["kinds"] * 2.0 + min(m["hang"], 110) * 0.06
                + (4 if m["loop"] else 0) + m["hospitality"] * 1.5 + spacing)
    if profile == "drama":
        return (m["vista"] * 0.9 + m["dais"] * 3.0 + (6 if m["terraced"] else 0)
                + (4 if m["light"] == "dramatic" else 0) + min(m["hang"], 80) * 0.03
                + m["floating"] * 2.5 + min(m["slots"], 10) * 0.5
                + m["hospitality"] * 1.0 + spacing)
    # intimacy
    return (m["n_niche"] * 2.2 + m["doors"] * 1.2 - m["vista"] * 0.35
            + (4 if m["light"] == "dusk" else 0) + min(m["slots"], 14) * 0.8
            + m["kinds"] * 1.5 + m["hospitality"] * 2.0 + spacing)


# ── evolution ────────────────────────────────────────────────────────────────

def evolve(profile, rng):
    pop = [make_genome(rng) for _ in range(POP)]
    history = []
    scored = []
    for gen in range(GENS):
        scored = []
        for g in pop:
            data, slots = compile_gallery(g, "tmp")
            m = measure(data, slots)
            scored.append((fitness(profile, m), g, m))
        scored.sort(key=lambda x: -x[0])
        history.append({"gen": gen + 1,
                        "best": round(scored[0][0], 2),
                        "mean": round(sum(s[0] for s in scored) / len(scored), 2),
                        "best_form": scored[0][1]["form"]})
        nxt = [dict(s[1]) for s in scored[:ELITE]]
        while len(nxt) < POP:
            a = max(rng.sample(scored, 3), key=lambda x: x[0])[1]
            b = max(rng.sample(scored, 3), key=lambda x: x[0])[1]
            child = crossover(rng, a, b)
            if rng.random() < 0.7:
                child = mutate(rng, child)
            nxt.append(child)
        pop = nxt
    return scored[:CHAMPIONS], history


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
    report = {"generated_by": "tools/gallery_evolve.py", "seed": SEED,
              "pop": POP, "gens": GENS, "profiles": {}}
    all_champs = []
    for profile in ["capacity", "drama", "intimacy"]:
        champs, history = evolve(profile, rng)
        tag = profile[:3].upper()
        rows = []
        for i, (fit, g, m) in enumerate(champs):
            gid = f"{tag}_{i+1}"
            data, slots = compile_gallery(g, gid)
            write_map(data)
            rows.append({"id": f"Gallery_{gid}", "fitness": round(fit, 2),
                         "genome": g, "measure": m})
            all_champs.append((profile, f"Gallery_{gid}", fit, g, m))
        report["profiles"][profile] = {"history": history, "champions": rows}
        print(f"{profile.upper():9s} " + " -> ".join(
            f"g{h['gen']}:{h['best']}" for h in history))
        for r in rows:
            g = r["genome"]
            m = r["measure"]
            print(f"   {r['id']:16s} fit={r['fitness']:6.2f} form={g['form']:9s} "
                  f"mix={g.get('furniture_mix','?'):8s} float={g.get('floating_walls',0)} "
                  f"sign={g.get('signage',0)} light={g['light']:8s} "
                  f"slots={m['slots']:2d} kinds={m['kinds']} vista={m['vista']:2d}")
    (ROOT / "doc" / "reports" / "gallery_dna_research.json").write_text(
        json.dumps(report, indent=1), encoding="utf-8")

    # markdown research note
    md = ["# Gallery DNA — auto-research (v2)", "",
          "Three taste-profiles evolved as separate populations "
          f"(pop {POP}, {GENS} generations, tournament + crossover + elitism). "
          "Champions are on disk as walkable empty galleries.", ""]
    for profile, pdata in report["profiles"].items():
        md.append(f"## {profile}")
        md.append("")
        md.append("| gen | best | mean | best form |")
        md.append("|---|---|---|---|")
        for h in pdata["history"]:
            md.append(f"| {h['gen']} | {h['best']} | {h['mean']} | {h['best_form']} |")
        md.append("")
        for r in pdata["champions"]:
            g = r["genome"]
            m = r["measure"]
            md.append(f"- **{r['id']}** (fit {r['fitness']}): {g['form']} / {g['podium_motif']} / "
                      f"{g['light']}, {m['slots']} slots, vista {m['vista']}, "
                      f"{m['n_niche']} niches, terraced={m['terraced']}")
        md.append("")
    md.append("The three champions disagree on purpose: capacity, drama and intimacy "
              "are different buildings. No single form wins — the profile is the choice.")
    (ROOT / "doc" / "reports" / "gallery_dna_research.md").write_text(
        "\n".join(md), encoding="utf-8")
    print("\nwrote research report + %d champion maps" % len(all_champs))


if __name__ == "__main__":
    main()
