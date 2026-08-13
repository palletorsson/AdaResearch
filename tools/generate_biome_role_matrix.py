"""Generate Biome_Role_Matrix — one isolated cell per (kingdom x role) emitter.

Biome_Kingdom_Matrix already varies kingdom x INTENSITY, which only ever exercises
the seed path. But the biome layer has four visual emitters, and three of them
have never been looked at cell by cell:

    seed    -> the dispatcher's substrate (DNA morphologies for flora/fungus/fauna,
               hand-built specimens for mineral/water/meta)
    halo    -> a ground strip + scattered cover, OUTSIDE the map edge
    edge    -> the same cover recipes, thinning inward from a cell's rim
    marker  -> what a cell renders when nothing else claims it

halo only fires on a PERIMETER cell (GridBiomeComponent._spawn_halo returns early
and falls through to _spawn_marker otherwise), so the halo row has to sit on row 0
and the marker row is just a halo token painted inland — which is not a contrived
test but the exact mistake a map author makes.

Six kingdoms x four roles = 24 emitters, each alone in its own cell.
"""
import json
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
NAME = "Biome_Role_Matrix"

KINGDOMS = ["flora", "fungus", "fauna", "mineral", "water", "meta"]
# row -> (role, token suffix). Row 0 is the rim: the only place halo renders.
ROWS = [
    (0, "halo", "halo:d=0.9"),
    (4, "seed", "seed:t=3"),
    (7, "edge", "edge:d=0.9"),
    (10, "marker", "halo:d=0.9"),   # inland halo == the marker fallback
]

W, D = 13, 13


def main():
    structure = [["1"] * W for _ in range(D)]
    utilities = [[""] * W for _ in range(D)]
    utilities[D - 1][W - 1] = "sp"
    biome = [["" for _ in range(W)] for _ in range(D)]
    cells = []
    for row, role, suffix in ROWS:
        for k, kingdom in enumerate(KINGDOMS):
            col = k * 2 + 1
            algo = "dna" if role == "seed" else "scatter"
            biome[row][col] = "%s:%s:%s" % (kingdom, algo, suffix)
            cells.append({"kingdom": kingdom, "role": role, "row": row, "col": col,
                          "token": "%s_%s" % (kingdom, role)})

    m = {
        "map_info": {
            "name": NAME, "title": "Biome Role Matrix",
            "description": "one isolated cell per (kingdom x role) biome emitter — "
                           "the curation audit bench",
            "dimensions": {"width": W, "depth": D},
        },
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": [[""] * W for _ in range(D)],
            "biome": {"_meta": {"budget_instances": 4000, "visibility_range": 0},
                      "rows": biome},
        },
        "settings": {
            "background": {"color": [0.05, 0.055, 0.07], "type": "sky"},
            "cube_size": 1.0, "gutter": 0.0, "show_grid": False,
            "grid_animation": {"enabled": False},
            "disable_biome": True,   # legacy ring off; the LAYER path is unaffected
        },
    }
    d = os.path.join(ROOT, "commons", "maps", NAME)
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "map_data.json"), "w", encoding="utf-8") as f:
        json.dump(m, f, indent=1)
    with open(os.path.join(d, "role_matrix_cells.json"), "w", encoding="utf-8") as f:
        json.dump(cells, f, indent=1)
    print("wrote %s — %d emitters (%d kingdoms x %d roles)"
          % (NAME, len(cells), len(KINGDOMS), len(ROWS)))


if __name__ == "__main__":
    main()
