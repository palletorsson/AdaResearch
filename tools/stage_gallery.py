"""stage_gallery.py — lay a cast on a consistent grid, each on its right BED,
with a guaranteed walkable aisle between every artifact.

Each artifact gets its measured bed (staging_beds.select_bed): plinth / table /
platform / pit / panel / floor_work, sized to its footprint. Beds are placed on
a CONSISTENT lattice — a bed cell, then an aisle ring — so the player can always
path between any two artifacts. Wall works (panels) line the hull. The result is
verified: a door-graph BFS confirms every bed is reachable with clearance.

Usage: python tools/stage_gallery.py --map=Staged_Demo --cast=a,b,c[,...]
       python tools/stage_gallery.py --wings         # the Museum_Wings 16
"""
import json
import re
import sys
from pathlib import Path
from collections import deque

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(__file__).resolve().parent.parent
sys.path.insert(0, str(ROOT / "tools"))
import staging_beds as sb

WINGS = ["menger_toy", "koch_curve", "cantor_bench", "galton_board", "dice_throw",
         "coin_toss", "random_number_book_page_1955", "newton_cradle",
         "parametric_pendulum_waves", "mass_spring_bench", "game_of_life_petri",
         "radiolaria", "romanesco", "pompeii_mosaic_floor", "russell_set_box", "jelly_cube"]

PITCH = 3          # cell lattice: a bed cell every PITCH cells => PITCH-1 aisle
MARGIN = 2


def compact(data):
    text = json.dumps(data, indent=1)
    return re.sub(r'\[\s+((?:"[^"]*",?\s+)+)\]',
                  lambda m: '[' + ', '.join(x.strip().rstrip(',')
                                            for x in m.group(1).split('\n') if x.strip()) + ']', text)


def main():
    title, cast = "Staged_Demo", []
    for a in sys.argv[1:]:
        if a.startswith("--map="):
            title = a.split("=", 1)[1]
        elif a.startswith("--cast="):
            cast = [x.strip() for x in a.split("=", 1)[1].split(",") if x.strip()]
        elif a == "--wings":
            cast = WINGS[:]
    if not cast:
        print(__doc__)
        sys.exit(1)

    # classify: wall works (panels) vs floor works (everything else)
    beds = [(t, sb.select_bed(t)) for t in cast]
    wall_works = [(t, b) for t, b in beds if b["is_wall"]]
    floor_works = [(t, b) for t, b in beds if not b["is_wall"]]

    # grid: N floor beds on a consistent lattice (PITCH), squarish
    import math
    n = len(floor_works)
    cols = max(1, int(math.ceil(math.sqrt(n))))
    rows = int(math.ceil(n / cols))
    inner_w = cols * PITCH - (PITCH - 1)
    inner_d = rows * PITCH - (PITCH - 1)
    W = inner_w + 2 * MARGIN
    D = inner_d + 2 * MARGIN + 2      # +2 for a wall-work strip on the north

    structure = [["1"] * W for _ in range(D)]
    utilities = [[" "] * W for _ in range(D)]
    inter = [[" "] * W for _ in range(D)]

    placements = []   # (r, c, token, bed)
    for i, (t, b) in enumerate(floor_works):
        gr, gc = i // cols, i % cols
        r = MARGIN + 2 + gr * PITCH
        c = MARGIN + gc * PITCH
        inter[r][c] = b["bed"]
        placements.append((r, c, t, b["bed"]))

    # wall works line the north edge (row MARGIN), spaced
    wc = MARGIN
    for (t, b) in wall_works:
        while wc < W - MARGIN and inter[MARGIN][wc].strip() != "":
            wc += 2
        if wc < W - MARGIN:
            inter[MARGIN][wc] = b["bed"] + ":180"     # faces south into the room
            placements.append((MARGIN, wc, t, b["bed"]))
            wc += 3

    # spawn west, teleporter east
    sr = D // 2
    utilities[sr][0] = "s"
    utilities[sr][W - 1] = "t"
    structure[sr][W - 1] = "0"

    # ── verify: every bed reachable with a free approach cell (pathfinding) ──
    occupied = {(r, c) for (r, c, _, _) in placements}
    free = {(r, c) for r in range(D) for c in range(W)
            if str(structure[r][c]).strip() not in ("", "0") and (r, c) not in occupied}
    start = (sr, 0)
    seen = {start}
    q = deque([start])
    while q:
        r, c = q.popleft()
        for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            nb = (r + dr, c + dc)
            if nb in free and nb not in seen:
                seen.add(nb)
                q.append(nb)
    reachable_beds = 0
    for (r, c, t, bed) in placements:
        if any((r + dr, c + dc) in seen for dr, dc in ((-1, 0), (1, 0), (0, -1), (0, 1))):
            reachable_beds += 1

    data = {
        "map_info": {"name": f"Staged: {title}", "title": title, "lookup_name": title,
                     "description": f"{len(cast)} works, each on its measured bed (plinth/table/platform/pit/"
                                    f"panel/floor_work), on a consistent lattice with a guaranteed aisle between "
                                    f"every artifact. {reachable_beds}/{len(placements)} beds reachable with clearance.",
                     "version": "0.1", "format": "json",
                     "dimensions": {"width": W, "depth": D, "max_height": 1},
                     "metadata": {"difficulty": "beginner", "category": "museum",
                                  "estimated_time": "4-6 minutes",
                                  "learning_objectives": ["the bed fits the footprint; the aisle fits the body"]}},
        "utility_definitions": {"s": {"type": "spawn", "description": "enter"},
                                "t": {"type": "teleporter", "description": "exit"}},
        "settings": {"cube_size": 1.0, "gutter": 0.02, "show_grid": True, "enable_physics": True,
                     "auto_reveal_on_entry": False, "initial_tile_visibility": "all", "background": "dark",
                     "bare_world": True,
                     "wall_segments": {"height": 3.4, "thickness": 0.16, "door_width": 2.6, "color": [0.85, 0.83, 0.78]}},
        "lighting": {"ambient_color": [0.5, 0.5, 0.53], "ambient_energy": 0.6,
                     "directional_light": {"enabled": True, "direction": [-0.2, -0.85, -0.25],
                                           "color": [1.0, 0.98, 0.93], "energy": 0.9}},
        "layers": {"structure": structure, "utilities": utilities, "interactables": inter},
    }
    out = ROOT / "commons/maps" / title / "map_data.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(compact(data), encoding="utf-8")

    print(f"{title} {W}x{D}: {len(floor_works)} floor beds + {len(wall_works)} wall panels, pitch {PITCH}")
    for (r, c, t, bed) in placements:
        kind = bed.split("kind:")[1].split("#")[0] if "kind:" in bed else bed.replace("exhibit_", "")
        print(f"  {t:30s} -> {kind}")
    print(f"CLEARANCE: {reachable_beds}/{len(placements)} beds reachable with a free approach (pathfinding-verified)")


if __name__ == "__main__":
    main()
