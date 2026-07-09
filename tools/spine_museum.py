"""spine_museum.py — the whole curriculum as ONE departmental museum.

The lesson of the great museum plans: a set of themed DEPARTMENT-WINGS around
a central ROTUNDA, threaded by a NUMBERED TRAIL (= the curatorial sequence),
zoned by phase, amenities and back-of-house behind. Ada's spine IS that: 24
sequences = 24 departments; the curriculum order = the trail; the QFEP Lab =
the rotunda at the crossing; foundations at the entrance, crisis at the far end.

v1: an entrance ROTUNDA (monument + info) opening onto a boustrophedon GRID of
24 department rooms, each carrying its sequence's HERO artifact, walls between,
a DOOR only on the edge shared with the next-in-curriculum room (so the doors
ARE the numbered trail). Spawn in the rotunda, exit past department 24.

Usage: python tools/spine_museum.py
"""
import json
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")
ROOT = Path(__file__).resolve().parent.parent

COLS, ROWS = 6, 4          # 24 department rooms
RW, RD = 8, 6              # interior of each department (fits real heroes)
ROT_D = 7                  # rotunda band depth at the south entrance

# phase -> department accent colour (the wayfinding zoning, washed by an el light)
PHASE_COLOR = {
    "F_order":     "#8fb8e8",   # cool blue — foundations of order
    "oscillation": "#7fe0d0",   # teal — waves
    "E_entropy":   "#e8c46a",   # amber — entropy/heat
    "lambda_edge": "#e08bd0",   # magenta — the living edge
    "integration": "#9be08b",   # green — integration/life
    "relation":    "#e8a06a",   # orange — relation
    "synthesis":   "#c98be0",   # violet — synthesis/crisis
}


def tokens_of_map(map_name):
    p = ROOT / "commons/maps" / map_name / "map_data.json"
    if not p.exists():
        return []
    try:
        d = json.loads(p.read_text(encoding="utf-8"))
    except json.JSONDecodeError:
        return []
    out = []
    for row in d.get("layers", {}).get("interactables", []):
        for cell in row:
            s = str(cell).strip()
            if not s:
                continue
            name = s.split("#")[0].split(":")[0].strip()
            if name.startswith(("gallery_marker", "exhibit_", "mode_", "museum_")):
                continue
            if re.match(r"^[A-Za-z_][A-Za-z0-9_-]*$", name):
                out.append(name)
    return out


GENERIC = {"science_screen", "dark_sphere", "clipboard", "floating_sphere_field",
           "you_are_here", "CoordinateSystem3M", "frame_counter_display", "tt",
           "grab_long_stick", "pick_up_cube", "catalyst_target",
           # environment-builders / oversized (fill the whole room):
           # only truly hang/crash-prone headless (memory) stay denied:
           "boid_flocking", "mc_torus_sculpture"}
try:
    _SIZES = json.loads((ROOT / "commons/data/artifact_sizes.json").read_text(encoding="utf-8"))["sizes"]
except Exception:
    _SIZES = {}
MAX_HERO_M = 3.5   # must fit a 6x5 department with clearance


def fits_room(token):
    e = _SIZES.get(token)
    if not e:
        return False  # require measurement — unmeasured procedural meshes engulf the room
    return float(e.get("max_dimension_m", 99.0)) <= MAX_HERO_M


def seq_maps(seq_name):
    seq_file = ROOT / "commons/maps/sequences" / f"{seq_name}.json"
    if not seq_file.exists():
        return []
    sdata = json.loads(seq_file.read_text(encoding="utf-8"))
    maps = []
    for _sid, s in sdata.get("sequences", {}).items():
        for m in s.get("maps", []) or s.get("content", []):
            maps.append(m if isinstance(m, str) else m.get("map", m.get("name")))
    return [m for m in maps if m]


def footprint_m(token):
    e = _SIZES.get(token)
    return float(e.get("max_dimension_m", 1.5)) if e else 1.5


def hero_of(seq_name, cross_freq):
    """The sequence's signature artifact (most-placed here, rare across the
    spine). Size is handled by the room, not by exclusion."""
    from collections import Counter
    freq = Counter()
    for m in seq_maps(seq_name):
        for t in set(tokens_of_map(m)):
            if t not in GENERIC:
                freq[t] += 1
    if not freq:
        return None
    ranked = sorted(freq, key=lambda t: -freq[t] / (1 + cross_freq.get(t, 0)))
    for t in ranked:
        if footprint_m(t) <= 15.0:      # fits a hall; true giants (koch 41m) skipped
            return t
    return ranked[0] if ranked else None


def main():
    spine = json.loads((ROOT / "commons/maps/curriculum_spine.json").read_text(encoding="utf-8"))
    seqs = spine.get("spine", spine).get("sequences", [])
    seqs = sorted(seqs, key=lambda s: s.get("order", 999))[:COLS * ROWS]

    from collections import Counter
    cross_freq = Counter()
    for s in seqs:
        seen = set()
        for m in seq_maps(s["name"]):
            seen |= set(tokens_of_map(m))
        for t in seen:
            cross_freq[t] += 1
    heroes = {}
    for s in seqs:
        heroes[s["name"]] = hero_of(s["name"], cross_freq)

    # ── geometry: rotunda band (south) + grid of departments (north) ────────
    grid_w = COLS * RW
    grid_d = ROWS * RD
    W = grid_w + 2
    D = grid_d + ROT_D + 2
    grid_r0 = 1                      # departments start at row 1 (north)
    rot_r0 = 1 + grid_d             # rotunda band below the grid

    structure = [["1"] * W for _ in range(D)]
    utilities = [[" "] * W for _ in range(D)]
    inter = [[" "] * W for _ in range(D)]
    walls = [[""] * W for _ in range(D)]

    def aw(r, c, code):
        walls[r][c] += code

    # room (gr,gc) interior cells
    def room_cells(gr, gc):
        r0 = grid_r0 + gr * RD
        c0 = 1 + gc * RW
        return r0, c0, r0 + RD - 1, c0 + RW - 1

    # boustrophedon curriculum order -> (gr, gc), starting at the BOTTOM row
    # (adjacent to the south rotunda) and snaking UP: dept 1 by the entrance,
    # dept 24 at the far top.
    def order_to_grid(i):
        band = i // COLS
        gr = ROWS - 1 - band
        col = i % COLS
        gc = col if band % 2 == 0 else (COLS - 1 - col)
        return gr, gc

    placed_seq = []
    for i, s in enumerate(seqs):
        gr, gc = order_to_grid(i)
        r0, c0, r1, c1 = room_cells(gr, gc)
        # perimeter walls
        for c in range(c0, c1 + 1):
            aw(r0, c, "n")
            aw(r1, c, "s")
        for r in range(r0, r1 + 1):
            aw(r, c0, "w")
            aw(r, c1, "e")
        # hero centrepiece
        h = heroes.get(s["name"])
        cx, cz = (c0 + c1) // 2, (r0 + r1) // 2
        if h:
            inter[cz][cx] = h
        # department name (3t text on the north wall) — legibility
        label = f"{i + 1}. {s['name'].upper()}"
        utilities[r0][cx] = f"3t:{label}"
        # phase colour-zoning: a tinted extra light in the room's corner
        col = PHASE_COLOR.get(s.get("phase"), "#cccccc")
        utilities[r0 + 1][c0 + 1] = f"el:2.5:0:{col}"
        placed_seq.append({"order": i + 1, "seq": s["name"], "phase": s.get("phase"),
                           "hero": h, "grid": [gr, gc], "cell": [cz, cx]})

    # DOORS = the numbered trail: open the shared edge between consecutive rooms
    def _open(r, c, edge):        # lowercase edge -> uppercase (a doorway)
        walls[r][c] = walls[r][c].replace(edge, edge.upper())

    def carve_door(a, b):
        (gra, gca), (grb, gcb) = order_to_grid(a), order_to_grid(b)
        ra0, ca0, ra1, ca1 = room_cells(gra, gca)
        rb0, cb0, rb1, cb1 = room_cells(grb, gcb)
        if gra == grb and abs(gca - gcb) == 1:          # horizontal neighbours
            rr = [(ra0 + ra1) // 2, (ra0 + ra1) // 2 + 1]   # TWO cells wide
            for r in rr:
                if gca < gcb:
                    _open(r, ca1, "e"); _open(r, cb0, "w")
                else:
                    _open(r, ca0, "w"); _open(r, cb1, "e")
        elif gca == gcb and abs(gra - grb) == 1:         # vertical neighbours
            cc = [(ca0 + ca1) // 2, (ca0 + ca1) // 2 + 1]
            for c in cc:
                if gra < grb:
                    _open(ra1, c, "s"); _open(rb0, c, "n")
                else:
                    _open(ra0, c, "n"); _open(rb1, c, "s")

    for i in range(len(seqs) - 1):
        carve_door(i, i + 1)

    # redundant circulation (the enfilade + bypass lesson): a door between EVERY
    # grid-adjacent department, so vistas align and no room can be isolated.
    grid_at = {order_to_grid(i): i for i in range(len(seqs))}
    for (gr, gc), i in grid_at.items():
        for (dr, dc) in ((0, 1), (1, 0)):
            j = grid_at.get((gr + dr, gc + dc))
            if j is not None:
                carve_door(i, j)

    # ── the rotunda: entrance hall + monument, opening to department 1 ──────
    rc0, rc1 = 1, W - 2
    rr0, rr1 = rot_r0, rot_r0 + ROT_D - 2
    for c in range(rc0, rc1 + 1):
        aw(rr1, c, "s")
    for r in range(rr0, rr1 + 1):
        aw(r, rc0, "w")
        aw(r, rc1, "e")
    # the monument at the rotunda centre
    mono_r, mono_c = (rr0 + rr1) // 2, (rc0 + rc1) // 2
    inter[mono_r][mono_c] = "incompleteness_scale:180"
    # a WIDE opening from the rotunda up into department 1 (now bottom-adjacent)
    d1r0, d1c0, d1r1, d1c1 = room_cells(*order_to_grid(0))
    for door_c in range(d1c0 + 1, d1c1):                          # nearly full-width
        walls[d1r1][door_c] = walls[d1r1][door_c].replace("s", "S")
        walls[rr0][door_c] = walls[rr0][door_c].replace("n", "N")
    # amenities flanking the rotunda entrance
    inter[mono_r][rc0 + 2] = "exhibit_furniture#kind:infoboard"
    inter[mono_r][rc1 - 2] = "exhibit_furniture#kind:sign_exit"
    inter[rr1 - 1][rc0 + 4] = "exhibit_furniture#kind:sign_fire"

    # spawn in the rotunda; teleporter past the last department
    utilities[mono_r + 2][mono_c] = "s"
    lr0, lc0, lr1, lc1 = room_cells(*order_to_grid(len(seqs) - 1))
    te_r = (lr0 + lr1) // 2
    # open the last department's east edge to the void, teleporter just outside
    walls[te_r][lc1] = walls[te_r][lc1].replace("e", "E")
    utilities[te_r][W - 1] = "t"
    structure[te_r][W - 1] = "0"

    # the shell
    inter[rr0][mono_c] = inter[rr0][mono_c]   # noop guard
    inter[mono_r - 1][mono_c] = f"museum_hall_shell#width:{W}#depth:{D}#height:10#sky:0" \
        if inter[mono_r - 1][mono_c] == " " else inter[mono_r - 1][mono_c]

    data = {
        "map_info": {
            "name": "The Spine Museum", "title": "Spine_Museum", "lookup_name": "Spine_Museum",
            "description": "The whole curriculum as one departmental museum: an entrance rotunda "
                           "(the incompleteness monument) opening onto 24 department wings, one per "
                           "spine sequence, each with its hero artifact. The doors ARE the numbered "
                           "trail — walk the curriculum in order, foundations to crisis.",
            "version": "0.1", "format": "json",
            "dimensions": {"width": W, "depth": D, "max_height": 1},
            "spine_trail": placed_seq,
            "metadata": {"difficulty": "beginner", "category": "museum",
                         "estimated_time": "15-25 minutes",
                         "learning_objectives": ["the curriculum as a walkable institution",
                                                 "24 departments, one rotunda, one trail"]},
        },
        "utility_definitions": {"s": {"type": "spawn", "description": "the rotunda"},
                                "t": {"type": "teleporter", "description": "exit past department 24"}},
        "settings": {"cube_size": 1.0, "gutter": 0.02, "show_grid": True, "enable_physics": True,
                     "auto_reveal_on_entry": False, "initial_tile_visibility": "all", "background": "dark",
                     "bare_world": True,
                     "wall_segments": {"height": 3.6, "thickness": 0.18, "door_width": 2.6,
                                       "color": [0.85, 0.83, 0.78]}},
        "lighting": {"ambient_color": [0.46, 0.46, 0.5], "ambient_energy": 0.6,
                     "directional_light": {"enabled": True, "direction": [-0.2, -0.88, -0.25],
                                           "color": [1.0, 0.98, 0.93], "energy": 0.9}},
        "layers": {"structure": structure, "utilities": utilities, "walls": walls, "interactables": inter},
    }
    out = ROOT / "commons/maps/Spine_Museum/map_data.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    text = json.dumps(data, indent=1)
    text = re.sub(r'\[\s+((?:"[^"]*",?\s+)+)\]',
                  lambda m: '[' + ', '.join(x.strip().rstrip(',')
                                            for x in m.group(1).split('\n') if x.strip()) + ']', text)
    out.write_text(text, encoding="utf-8")

    n_hero = sum(1 for p in placed_seq if p["hero"])
    print(f"Spine_Museum {W}x{D}: {len(seqs)} departments, {n_hero} with heroes, rotunda + trail")
    for p in placed_seq:
        print(f"  {p['order']:2d}. {p['seq']:22s} [{p['phase']:12s}] hero={p['hero']}")
    print(f"wrote {out}")


if __name__ == "__main__":
    main()
