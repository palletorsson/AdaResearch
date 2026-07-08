"""spaceform.py — the map as the equilibrium form of its relations under pressure.

Formfinding applied to curriculum space (the game's own chapter as method):
artifacts are nodes, measured relations are SPRINGS (kinship = LSA cosine in
the book's space; maker = shared commons-ledger source; lineage = construction
edges; theme = shared wing/pocket), and PRESSURE prices every inch of hull.
Relax to equilibrium, carve the floor, wall the hull, write the map — and an
ENERGY RECEIPT naming the spring that paid for every adjacency. Everyone is
close for a reason, and the reason is printed.

Three pressures, one cast:
  P low  -> the COURT  (space is cheap; the layout breathes)
  P mid  -> the HOUSE  (rooms with reasons)
  P high -> the SHIP   (every corridor earns itself)

Usage: python tools/spaceform.py            # builds all three Spaceform_* maps
"""
import json
import math
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

import numpy as np
from sklearn.decomposition import TruncatedSVD
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.preprocessing import normalize

ROOT = Path(__file__).resolve().parent.parent
SEED = 461

# the Museum_Wings cast — sixteen artifacts, four families
CAST = [
    ("menger_toy", "fractal"), ("koch_curve", "fractal"),
    ("cantor_bench", "fractal"), ("menger_bench", "fractal"),
    ("galton_board", "chance"), ("dice_throw", "chance"),
    ("coin_toss", "chance"), ("random_number_book_page_1955", "chance"),
    ("newton_cradle", "motion"), ("parametric_pendulum_waves", "motion"),
    ("mass_spring_bench", "motion"), ("exercise_3_15_double_pendulum_vr", "motion"),
    ("game_of_life_petri", "life"), ("radiolaria", "life"),
    ("branching_growth_algorithm", "life"), ("random_butterflies", "life"),
]

PRESSURES = [
    ("Court", 0.012, 3.4),   # (name, pressure, min separation in cells)
    ("House", 0.06, 2.6),
    ("Ship", 0.22, 2.0),
]


def card_text(c):
    return " ".join(str(c.get(k, "")) for k in
                    ("lookup_name", "description", "essence", "truth", "family"))


def extract_relations():
    """Typed springs among the cast, from the ontology's instruments."""
    names = [c[0] for c in CAST]
    theme = {c[0]: c[1] for c in CAST}
    idx = {n: i for i, n in enumerate(names)}
    springs = {}   # (i,j) -> list of (type, weight)

    def add(a, b, typ, w):
        i, j = idx[a], idx[b]
        if i == j:
            return
        key = (min(i, j), max(i, j))
        springs.setdefault(key, []).append((typ, round(w, 3)))

    # ── kinship: LSA cosine in the book's space ─────────────────────────────
    cards = json.loads((ROOT / "doc/atlas/artifact_cards.json").read_text(encoding="utf-8"))
    by_name = {str(c.get("lookup_name", "")): c for c in cards}
    corpus = [card_text(c) for c in cards]
    for pat in ("commons/maps/*/walked.md", "commons/maps/*/tutorial.md",
                "commons/maps/*/blurb.md"):
        for p in ROOT.glob(pat):
            try:
                corpus.append(p.read_text(encoding="utf-8", errors="replace"))
            except OSError:
                pass
    vec = TfidfVectorizer(min_df=2, max_df=0.5, sublinear_tf=True,
                          token_pattern=r"[a-zA-Zφλ]{3,}")
    X = vec.fit_transform(corpus)
    svd = TruncatedSVD(n_components=min(128, X.shape[1] - 1), random_state=SEED)
    svd.fit(X)
    V = normalize(svd.transform(vec.transform(
        [card_text(by_name.get(n, {"lookup_name": n})) for n in names])))
    S = V @ V.T
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            if S[i, j] > 0.18:
                add(names[i], names[j], "kin", float(S[i, j]))

    # ── maker: shared commons-ledger source ────────────────────────────────
    ledger = json.loads((ROOT / "doc/book/commons_ledger.json").read_text(encoding="utf-8"))
    for sid, s in ledger.get("sources", {}).items():
        credited = [str(x) for x in s.get("credited_in", [])]
        members = [n for n in names if any(n in c or c in n for c in credited)]
        for a in range(len(members)):
            for b in range(a + 1, len(members)):
                add(members[a], members[b], "maker", 0.5)

    # ── lineage: construction edges (A uses B) ──────────────────────────────
    cons = json.loads((ROOT / "doc/book/construction_edges.json").read_text(encoding="utf-8"))
    nodes = cons.get("nodes", {})
    for n in names:
        for used in nodes.get(n, {}).get("uses", []):
            if used in idx:
                add(n, used, "lineage", 0.8)

    # ── theme: same wing/pocket (weak; keeps families acquainted) ───────────
    for i in range(len(names)):
        for j in range(i + 1, len(names)):
            if theme[names[i]] == theme[names[j]]:
                add(names[i], names[j], "theme", 0.30)

    return names, theme, springs


def relax(names, springs, pressure, min_sep, steps=900):
    """Force relaxation: springs pull, min-separation pushes, pressure squeezes."""
    rng = np.random.RandomState(SEED)
    n = len(names)
    pos = rng.uniform(-9, 9, (n, 2))
    W = np.zeros((n, n))
    for (i, j), ss in springs.items():
        w = sum(x[1] for x in ss)
        W[i, j] = W[j, i] = w
    rest = 3.2
    for step in range(steps):
        f = np.zeros((n, 2))
        centroid = pos.mean(axis=0)
        for i in range(n):
            for j in range(n):
                if i == j:
                    continue
                d = pos[j] - pos[i]
                dist = float(np.linalg.norm(d)) + 1e-6
                u = d / dist
                if W[i, j] > 0:                       # spring toward rest length
                    f[i] += u * W[i, j] * (dist - rest) * 0.10
                if dist < min_sep:                     # hard shoulder
                    f[i] -= u * (min_sep - dist) * 0.8
            f[i] += (centroid - pos[i]) * pressure     # the hull squeezes
        pos += f * (1.0 - 0.7 * step / steps)          # cooling
    return pos


def build_map(tag, pressure, names, theme, springs, pos, min_sep):
    """Snap to grid, carve floor + corridors, wall the hull, write the map."""
    # snap with collision resolution
    cells = {}
    taken = set()
    order = sorted(range(len(names)), key=lambda i: -sum(
        sum(x[1] for x in ss) for (a, b), ss in springs.items() if i in (a, b)))
    for i in order:
        c = (int(round(pos[i][0])), int(round(pos[i][1])))
        r = 0
        while True:
            found = False
            for dx in range(-r, r + 1):
                for dy in range(-r, r + 1):
                    cand = (c[0] + dx, c[1] + dy)
                    if all(max(abs(cand[0] - t[0]), abs(cand[1] - t[1])) >= 2 for t in taken):
                        cells[i] = cand
                        taken.add(cand)
                        found = True
                        break
                if found:
                    break
            if found:
                break
            r += 1

    # floor: neighborhoods + corridors along the strongest spanning springs
    floor = set()
    for i, c in cells.items():
        for dx in range(-1, 2):
            for dy in range(-1, 2):
                floor.add((c[0] + dx, c[1] + dy))
    # MST over spring weights so the hull is always connected
    n = len(names)
    W = np.zeros((n, n))
    for (i, j), ss in springs.items():
        W[i, j] = W[j, i] = sum(x[1] for x in ss)
    in_tree = {0}
    edges = []
    while len(in_tree) < n:
        best = None
        for i in in_tree:
            for j in range(n):
                if j in in_tree:
                    continue
                d = np.linalg.norm(np.array(cells[i]) - np.array(cells[j]))
                score = W[i, j] + 0.01 - 0.002 * d
                if best is None or score > best[0]:
                    best = (score, i, j)
        edges.append((best[1], best[2]))
        in_tree.add(best[2])
    # carve L-corridors for tree edges + any strong spring
    strong = [(i, j) for (i, j), ss in springs.items() if sum(x[1] for x in ss) >= 0.55]
    for (i, j) in edges + strong:
        (x0, y0), (x1, y1) = cells[i], cells[j]
        for x in range(min(x0, x1), max(x0, x1) + 1):
            floor.add((x, y0))
        for y in range(min(y0, y1), max(y0, y1) + 1):
            floor.add((x1, y))

    # normalize to grid with margin
    xs = [c[0] for c in floor]
    ys = [c[1] for c in floor]
    ox, oy = min(xs) - 1, min(ys) - 1
    Wg = max(xs) - ox + 2
    Dg = max(ys) - oy + 2

    structure = [["0"] * Wg for _ in range(Dg)]
    utilities = [[" "] * Wg for _ in range(Dg)]
    inter = [[" "] * Wg for _ in range(Dg)]
    walls = [[""] * Wg for _ in range(Dg)]
    fset = set()
    for (x, y) in floor:
        structure[y - oy][x - ox] = "1"
        fset.add((x - ox, y - oy))
    for i, (x, y) in cells.items():
        inter[y - oy][x - ox] = names[i]

    # hull walls on every floor/void boundary edge
    for (cx, cy) in fset:
        if (cx, cy - 1) not in fset:
            walls[cy][cx] += "n"
        if (cx, cy + 1) not in fset:
            walls[cy][cx] += "s"
        if (cx - 1, cy) not in fset:
            walls[cy][cx] += "w"
        if (cx + 1, cy) not in fset:
            walls[cy][cx] += "e"

    # spawn at west-most floor cell; teleporter at east-most (void per rule)
    west = min(fset, key=lambda c: (c[0], c[1]))
    east = max(fset, key=lambda c: (c[0], c[1]))
    utilities[west[1]][west[0]] = "s"
    utilities[east[1]][east[0]] = "t"
    structure[east[1]][east[0]] = "0"

    # ── the energy receipt: why every neighbor is a neighbor ────────────────
    receipt = {"pressure": pressure, "adjacencies": []}
    for (i, j), ss in sorted(springs.items(), key=lambda kv: -sum(x[1] for x in kv[1])):
        d = float(np.linalg.norm(np.array(cells[i]) - np.array(cells[j])))
        if d <= 6.5:
            receipt["adjacencies"].append({
                "a": names[i], "b": names[j], "distance_cells": round(d, 1),
                "paid_by": [{"type": t, "w": w} for t, w in ss]})
    total_w = sum(sum(x[1] for x in ss) for ss in springs.values())
    e_springs = sum(sum(x[1] for x in ss) *
                    float(np.linalg.norm(np.array(cells[i]) - np.array(cells[j])))
                    for (i, j), ss in springs.items())
    receipt["energy"] = {"springs_x_distance": round(e_springs, 1),
                         "area_cells": len(fset),
                         "pressure_cost": round(pressure * len(fset), 2),
                         "total_spring_weight": round(total_w, 2)}
    # unplugged check
    plugged = set()
    for (i, j) in springs.keys():
        plugged.add(i)
        plugged.add(j)
    receipt["unplugged"] = [names[i] for i in range(n) if i not in plugged]

    title = f"Spaceform_{tag}"
    data = {
        "map_info": {
            "name": f"Spaceform: The {tag}",
            "title": title, "lookup_name": title,
            "description": f"The same sixteen artifacts, the same measured relations, at pressure {pressure} - "
                           f"the map as the equilibrium form of its springs under the hull. Everyone is close for a "
                           f"reason and the reason is printed (energy_receipt.json). Formfinding applied to curriculum space.",
            "version": "0.1", "format": "json",
            "dimensions": {"width": Wg, "depth": Dg, "max_height": 1},
            "metadata": {"difficulty": "intermediate", "category": "museum",
                         "estimated_time": "5-8 minutes",
                         "learning_objectives": [
                             "Form = relations at equilibrium under pressure",
                             "Pressure is a curatorial dial: court, house, ship"]},
        },
        "utility_definitions": {
            "s": {"type": "spawn", "description": "enter the hull"},
            "t": {"type": "teleporter", "description": "exit"}},
        "settings": {"cube_size": 1.0, "gutter": 0.02, "show_grid": True,
                     "enable_physics": True, "auto_reveal_on_entry": False,
                     "initial_tile_visibility": "all", "background": "dark",
                     "wall_segments": {"height": 3.2, "thickness": 0.16,
                                       "color": [0.55, 0.58, 0.62]}},
        "lighting": {"ambient_color": [0.3, 0.31, 0.36], "ambient_energy": 0.45,
                     "directional_light": {"enabled": True, "direction": [-0.3, -0.8, -0.3],
                                           "color": [0.95, 0.95, 1.0], "energy": 0.8}},
        "layers": {"structure": structure, "utilities": utilities,
                   "walls": walls, "interactables": inter},
    }
    out = ROOT / "commons" / "maps" / title
    out.mkdir(parents=True, exist_ok=True)
    text = json.dumps(data, indent=1)
    text = re.sub(r'\[\s+((?:"[^"]*",?\s+)+)\]',
                  lambda m: '[' + ', '.join(x.strip().rstrip(',')
                                            for x in m.group(1).split('\n') if x.strip()) + ']', text)
    (out / "map_data.json").write_text(text, encoding="utf-8")
    (out / "energy_receipt.json").write_text(json.dumps(receipt, indent=1), encoding="utf-8")
    return title, Wg, Dg, len(fset), receipt


def main():
    names, theme, springs = extract_relations()
    print(f"cast {len(names)} · springs {len(springs)} "
          f"(types: {sorted(set(t for ss in springs.values() for t, _ in ss))})")
    for tag, P, sep in PRESSURES:
        pos = relax(names, springs, P, sep)
        title, W, D, area, receipt = build_map(tag, P, names, theme, springs, pos, sep)
        e = receipt["energy"]
        print(f"{title:18s} {W}x{D}  floor={area:4d} cells  "
              f"springsE={e['springs_x_distance']:7.1f}  hullCost={e['pressure_cost']:6.2f}  "
              f"unplugged={receipt['unplugged'] or 'none'}")


if __name__ == "__main__":
    main()
