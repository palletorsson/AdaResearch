"""tools/zone_grammar.py — a constrained scene-archetype map generator.

The §11 prototype from the "map is a compressed machine for possible actions" essay,
grounded in Ada's real pipeline. Where `place.py` takes a fixed room and places artifacts
INTO it, and `grow_map.py` lets the placement leave the room behind, this tool starts from a
*named scene archetype* — a grammar — and paints a whole floor that obeys it.

The essay asked for six design-time layers (floor / zone / occupancy / services / danger /
visibility). Ada's runtime only reads three (structure / utilities / interactables), so this
tool works in the richer set and then PROJECTS DOWN:

    design layer          ->  runtime layer
    --------------------------------------------
    floor + heights       ->  structure   (0 void, 1 floor, 2/4 wall, 3 pedestal)
    services + danger     ->  utilities   (sp, t, h:toxic ...)
    occupancy             ->  interactables (artifact tokens, filtered by the archetype)
    zone + visibility     ->  map_info.metadata.zone_grid  (kept as 2D metadata — the
                                                            3D->2D compression, made explicit)

That projection is the essay's claim in code: we do not lose the third dimension, we compress
it into symbols, layers, constraints, affordances. The zone layer is preserved as metadata so
the design intent survives the compression; the runtime never needs it.

Five archetypes (the essay's scene types):
    warehouse_lab        open hall of working instruments
    temporal_storage     tiered shelves, things stored deeper = older = taller
    observation_chamber  a ring catwalk around a void, one centrepiece across a bridge
    forbidden_wet_lab    sealed containment cells, toxic thresholds, life behind glass
    archive_of_machines  dense parallel aisles of pattern machines

Each archetype is { paint(size, rng) -> layers+slots, want/avoid keyword filter }. The filter
scores the whole 2671-artifact registry pool by tag/category/theme overlap and fills the
grammar's slots with the best real artifacts for that scene.

Run:
    python tools/zone_grammar.py --archetype=warehouse_lab --size=12 --seed=3
    python tools/zone_grammar.py --list
    python tools/zone_grammar.py --all          # one map per archetype

Then validate + capture:
    python tools/map_pathfinder.py check Zone_WarehouseLab --verbose
    godot_console --path . --xr-mode off --no-window \
      --script res://commons/testing/capture_multi_angle.gd -- --mode=map --target=Zone_WarehouseLab
"""
from __future__ import annotations

import argparse
import glob
import json
import random
import sys
from pathlib import Path

if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    try:
        sys.stdout.reconfigure(encoding="utf-8")  # type: ignore[attr-defined]
    except Exception:
        pass

ROOT = Path(__file__).resolve().parents[1]
MAPS_DIR = ROOT / "commons" / "maps"
REG_DIR = ROOT / "commons" / "artifacts" / "registry"

sys.path.insert(0, str(ROOT / "tools"))
from compact_map_json import _ser  # canonical compact-rows serialiser

VOID, FLOOR, WALL, PEDESTAL, PILLAR = "0", "1", "2", "3", "4"


# ─────────────────────────────────────────────────────────────────────────────
# Artifact pool — scan every registry once, keep the placeable ones.
# ─────────────────────────────────────────────────────────────────────────────
def load_pool() -> list[dict]:
    pool: list[dict] = []
    seen: set[str] = set()
    for f in sorted(glob.glob(str(REG_DIR / "*.json"))):
        try:
            d = json.load(open(f, encoding="utf-8"))
        except Exception:
            continue
        arts = d.get("artifacts", d)
        if not isinstance(arts, dict):
            continue
        for name, a in arts.items():
            if not isinstance(a, dict) or name in seen:
                continue
            if "#" in name or ":" in name:
                continue
            if not a.get("scene"):
                continue
            if a.get("map_ready") is False or a.get("include_in_map_data") is False:
                continue
            sn = a.get("spatial_needs", {}) or {}
            fp = sn.get("footprint_cells", sn.get("measured_footprint_cells", 1)) or 1
            if isinstance(fp, (list, tuple)):       # some registries store [w, d]
                fp = max([int(x) for x in fp] or [1])
            seen.add(name)
            words = set()
            for t in a.get("tags", []):
                words.add(str(t).lower())
            for t in a.get("dev_themes", []):
                words.add(str(t).lower())
            if a.get("category"):
                words.add(str(a["category"]).lower())
            words |= set(name.lower().replace("_", " ").split())
            pool.append({"name": name, "words": words, "footprint": int(fp),
                         "complexity": a.get("complexity", "")})
    return pool


def pick(pool: list[dict], want: set[str], avoid: set[str], n: int,
         rng: random.Random, max_fp: int = 6) -> list[str]:
    """Score the pool by keyword overlap with the archetype, return n best names."""
    scored = []
    for a in pool:
        if a["footprint"] > max_fp:
            continue
        if a["words"] & avoid:
            continue
        score = len(a["words"] & want)
        if score <= 0:
            continue
        scored.append((score, rng.random(), a["name"]))
    scored.sort(reverse=True)
    return [name for _, _, name in scored[:n]]


# ─────────────────────────────────────────────────────────────────────────────
# Paint functions — each returns (structure, utilities, slots, zone_grid).
# A "slot" is {"r","c","phase"}; the placement step fills it with an artifact.
# ─────────────────────────────────────────────────────────────────────────────
def _blank(size: int, fill: str):
    return [[fill for _ in range(size)] for _ in range(size)]


def _doors(structure, utilities, zone, size: int):
    """Open a spawn door (south-centre) + teleporter door (north-centre)."""
    mid = size // 2
    structure[size - 1][mid] = FLOOR
    structure[0][mid] = FLOOR
    utilities[size - 1][mid] = "sp"
    utilities[0][mid] = "t"
    zone[size - 1][mid] = "E"
    zone[0][mid] = "Z"


def paint_warehouse(size, rng):
    """Open hall: wall border, big clear floor, two aisles of instruments."""
    S = _blank(size, WALL)
    U = _blank(size, " ")
    Z = _blank(size, "#")
    for r in range(1, size - 1):
        for c in range(1, size - 1):
            S[r][c] = FLOOR
            Z[r][c] = " "
    _doors(S, U, Z, size)
    slots = []
    for c in range(2, size - 2, 2):
        slots.append({"r": size // 3, "c": c, "phase": "teaching"})
        slots.append({"r": 2 * size // 3, "c": c, "phase": "exploration"})
    for s in slots:
        Z[s["r"]][s["c"]] = "T" if s["phase"] == "teaching" else "X"
    return S, U, slots, Z


def paint_temporal(size, rng):
    """Tiered shelves: flat walkway, pedestals in bands that grow TALLER toward the
    back (stored deeper = older). Artifacts sit on the pedestal tops."""
    S = _blank(size, WALL)
    U = _blank(size, " ")
    Z = _blank(size, "#")
    for r in range(1, size - 1):
        for c in range(1, size - 1):
            S[r][c] = FLOOR
            Z[r][c] = " "
    _doors(S, U, Z, size)
    slots = []
    bands = [r for r in range(2, size - 1, 3)]
    for bi, r in enumerate(bands):
        # deeper band (smaller r, further north) = taller pedestal = older storage
        depth = len(bands) - 1 - bi
        h = PEDESTAL if depth < 1 else PILLAR
        for c in range(2, size - 2, 2):
            S[r][c] = h                       # the shelf cell (walked around, not on)
            slots.append({"r": r, "c": c, "phase": "teaching" if depth == 0 else "exploration"})
            Z[r][c] = "T" if depth == 0 else "X"
    return S, U, slots, Z


def paint_observation(size, rng):
    """A 2-thick ring catwalk framing a central void, with a bridge you walk OUT over the
    emptiness to reach the one centrepiece. The void is the point; the bridge is the nerve."""
    ring = 2
    S = _blank(size, VOID)
    U = _blank(size, " ")
    Z = _blank(size, ".")
    mid = size // 2
    # the outer ring frame — a closed, fully-connected loop
    for r in range(size):
        for c in range(size):
            if r < ring or r >= size - ring or c < ring or c >= size - ring:
                S[r][c] = FLOOR
                Z[r][c] = " "
    # bridge: from the inner edge of the south ring inward to the centre
    for r in range(mid, size - ring):
        S[r][mid] = FLOOR
        Z[r][mid] = "X"
    # a small reachable platform at the bridge's end — you arrive at the centre
    for dr in (0, -1):
        for dc in (0, 1):
            rr, cc = mid + dr, mid + dc
            if 0 <= rr < size and 0 <= cc < size:
                S[rr][cc] = FLOOR
                Z[rr][cc] = "T"
    # spawn on the south ring, teleporter on the north ring
    S[size - 1][mid] = FLOOR; U[size - 1][mid] = "sp"; Z[size - 1][mid] = "E"
    S[0][mid] = FLOOR;        U[0][mid] = "t";          Z[0][mid] = "Z"
    slots = [{"r": mid, "c": mid, "phase": "teaching"}]      # the centrepiece, across the void
    for c in range(ring, size - ring, 3):                    # a few on the catwalk to circle
        slots.append({"r": 1, "c": c, "phase": "exploration"})
        Z[1][c] = "X"
    return S, U, slots, Z


def paint_wetlab(size, rng):
    """Sealed containment cells flanking a clean central corridor. Each 2×2 cell opens onto
    the corridor across a toxic threshold — you may look in, but crossing to the specimen
    costs you. The main spawn→exit path stays clean; the danger is in going closer."""
    S = _blank(size, WALL)
    U = _blank(size, " ")
    Z = _blank(size, "#")
    mid = size // 2
    # the clean walkable net: a north-south spine + a cross corridor
    for r in range(size):
        S[r][mid] = FLOOR; Z[r][mid] = " "
    for c in range(1, size - 1):
        S[mid][c] = FLOOR; Z[mid][c] = " "
    slots = []
    # four 2×2 chambers, each sitting flush against the spine corridor
    chambers = [(2, mid - 2, "W"), (2, mid + 1, "E"),
                (size - 4, mid - 2, "W"), (size - 4, mid + 1, "E")]
    for (r0, c0, side) in chambers:
        if not (0 <= r0 and r0 + 1 < size):
            continue
        for dr in range(2):
            for dc in range(2):
                rr, cc = r0 + dr, c0 + dc
                if 0 <= rr < size and 0 <= cc < size:
                    S[rr][cc] = FLOOR; Z[rr][cc] = "X"
        # toxic threshold = the chamber cell touching the corridor; specimen in the far cell
        if side == "W":
            thr_c, art_c = c0 + 1, c0          # cols (mid-2, mid-1); mid-1 touches the spine
        else:
            thr_c, art_c = c0, c0 + 1          # cols (mid+1, mid+2); mid+1 touches the spine
        U[r0][thr_c] = "h:toxic"; Z[r0][thr_c] = "R"
        slots.append({"r": r0 + 1, "c": art_c, "phase": "exploration"})
    _doors(S, U, Z, size)                       # spawn + exit are already corridor floor
    return S, U, slots, Z


def paint_archive(size, rng):
    """Dense parallel aisles: walkway columns alternate with rack columns (machines on
    raised shelves), joined by a corridor at each end."""
    S = _blank(size, WALL)
    U = _blank(size, " ")
    Z = _blank(size, "#")
    for r in range(1, size - 1):
        for c in range(1, size - 1):
            S[r][c] = FLOOR; Z[r][c] = " "
    slots = []
    for c in range(2, size - 2, 2):                 # every other interior column is a rack
        for r in range(2, size - 2):
            S[r][c] = PEDESTAL
            Z[r][c] = "X"
        # keep the end corridors clear so every aisle connects
        S[1][c] = FLOOR; S[size - 2][c] = FLOOR
        Z[1][c] = " ";   Z[size - 2][c] = " "
        slots.append({"r": size // 2, "c": c, "phase": "exploration"})
        slots.append({"r": 2, "c": c, "phase": "teaching"})
    for s in slots:
        Z[s["r"]][s["c"]] = "T" if s["phase"] == "teaching" else "X"
    _doors(S, U, Z, size)
    return S, U, slots, Z


# ─────────────────────────────────────────────────────────────────────────────
# Archetype registry
# ─────────────────────────────────────────────────────────────────────────────
ARCHETYPES = {
    "warehouse_lab": {
        "title": "Warehouse Lab",
        "name": "Warehouse Lab — open hall of instruments",
        "desc": "A wide, high-ceilinged hall. Working instruments stand in two clean aisles; "
                "nothing is hidden, everything is at hand. The lab as a place you move through.",
        "paint": paint_warehouse,
        "want": {"lab", "instrument", "instruments", "machinelearning", "algorithm",
                 "physics", "interactive", "vr", "tool", "demo", "vectors", "force"},
        "avoid": {"hazard", "creature", "danger"},
        "category": "lab", "temperature": 0.3,
    },
    "temporal_storage": {
        "title": "Temporal Storage",
        "name": "Temporal Storage — the deeper shelf is the older one",
        "desc": "Tiered shelving where storage runs back in time: the pedestals grow taller "
                "the deeper you go, the oldest records held highest at the back.",
        "paint": paint_temporal,
        "want": {"array", "graph", "datastructure", "datastructures", "change", "sequence",
                 "memory", "queue", "stack", "pattern", "grid", "time", "sort"},
        "avoid": {"hazard", "creature"},
        "category": "datastructures", "temperature": 0.4,
    },
    "observation_chamber": {
        "title": "Observation Chamber",
        "name": "Observation Chamber — cross the void to the thing you watch",
        "desc": "A ring catwalk around a central void. One centrepiece waits at the end of a "
                "thin bridge over emptiness — the thing you cross nothing to contemplate.",
        "paint": paint_observation,
        "want": {"qfep", "emergence", "wave", "waves", "visualization", "simulation",
                 "field", "shader", "cosmos", "quantum", "fractal", "chaos"},
        "avoid": {"hazard"},
        "category": "qfep", "temperature": 0.6,
    },
    "forbidden_wet_lab": {
        "title": "Forbidden Wet Lab",
        "name": "Forbidden Wet Lab — life behind toxic glass",
        "desc": "Sealed containment cells off a clean corridor. Living, growing specimens sit "
                "behind toxic thresholds; you may look, but lingering inside costs you.",
        "paint": paint_wetlab,
        "want": {"emergence", "cellular_automata", "dna", "nature", "creature", "softbody",
                 "softbodies", "biology", "growth", "simulation", "computationalbiology", "organism"},
        "avoid": set(),
        "category": "emergence", "temperature": 0.7, "hazard": True,
    },
    "archive_of_machines": {
        "title": "Archive of Machines",
        "name": "Archive of Machines — aisles of pattern engines",
        "desc": "Dense parallel aisles of machines on raised racks. Walk the narrow lanes "
                "between rows of pattern engines, grammars, and transforms, end to end.",
        "paint": paint_archive,
        "want": {"dna", "grammar", "pattern", "procedural", "transform", "transforms",
                 "machine", "loom", "mill", "proceduralgeneration", "lsystem", "mosaic"},
        "avoid": {"hazard", "creature"},
        "category": "dna_grammar", "temperature": 0.5,
    },
}


def generate(key: str, size: int, seed: int, pool: list[dict]) -> dict:
    arc = ARCHETYPES[key]
    rng = random.Random(seed)
    structure, utilities, slots, zone = arc["paint"](size, rng)
    names = pick(pool, arc["want"], arc["avoid"], n=len(slots) + 4, rng=rng)
    if not names:
        names = pick(pool, arc["want"], set(), n=len(slots) + 4, rng=rng)

    interactables = _blank(size, " ")
    placed = []
    ni = 0
    for s in slots:
        if ni >= len(names):
            break
        token = names[ni]; ni += 1
        interactables[s["r"]][s["c"]] = f"{token}:180:0.0"
        placed.append({"name": token, "r": s["r"], "c": s["c"], "phase": s["phase"]})

    util_defs = {
        "sp": {"name": "Spawn", "description": "Player spawn point", "type": "spawn"},
        "t": {"name": "Exit Portal", "description": "Step here to leave", "type": "teleporter",
              "properties": {"action": "next_in_sequence"}},
    }
    if arc.get("hazard"):
        util_defs["h:toxic"] = {"name": "Toxic Zone", "description": "Containment hazard — do not linger",
                                "type": "hazard", "properties": {"damage": 18, "interval": 0.4}}

    title = arc["title"].replace(" ", "")
    lookup = f"Zone_{title}"
    zone_rows = ["".join(row) for row in zone]
    map_data = {
        "map_info": {
            "name": arc["name"],
            "lookup_name": lookup,
            "title": arc["title"],
            "description": arc["desc"],
            "version": "zone-grammar-0.1",
            "format": "json",
            "created_from": "tools/zone_grammar.py",
            "dimensions": {"width": size, "depth": size, "max_height": 5},
            "metadata": {
                "category": arc["category"],
                "difficulty": "intermediate",
                "estimated_time": "3-6 minutes",
                "spatial_temperature": arc["temperature"],
                "archetype": key,
                "seed": seed,
                "artifacts_placed": [p["name"] for p in placed],
                "zone_legend": {"E": "entry", "T": "teaching", "X": "exploration",
                                "R": "reflection/threshold", "Z": "exit",
                                "#": "wall", ".": "void", " ": "floor"},
                "zone_grid": zone_rows,
            },
        },
        "utility_definitions": util_defs,
        "lighting": {
            "ambient_color": [0.30, 0.32, 0.40],
            "ambient_energy": 0.85,
            "directional_light": {"enabled": True, "direction": [-0.3, -1.0, -0.2], "energy": 0.8},
        },
        "settings": {"cube_size": 1.0, "gutter": 0.0, "show_grid": True,
                     "enable_physics": True, "auto_reveal_on_entry": True},
        "layers": {
            "structure": structure,
            "utilities": utilities,
            "interactables": interactables,
        },
    }
    return {"map_data": map_data, "lookup": lookup, "placed": placed, "slots": len(slots)}


def write_map(result: dict, key: str) -> Path:
    arc = ARCHETYPES[key]
    out_dir = MAPS_DIR / result["lookup"]
    out_dir.mkdir(exist_ok=True)
    map_path = out_dir / "map_data.json"
    map_path.write_text(_ser(result["map_data"], 0) + "\n", encoding="utf-8", newline="\n")

    placed = result["placed"]
    intent = [
        f"Concept: {arc['desc']}",
        "",
        f"Actualizes: the scene-archetype principle — the room is not a neutral container but a "
        f"grammar. '{arc['title']}' is one named way space can be organised for action; the floor, "
        f"the walls, the void, and which artifacts belong are all consequences of that one choice.",
        "",
        "Sequence role: generated by tools/zone_grammar.py as a constrained scene generator. "
        "The §11 prototype of the 'map is a compressed machine for possible actions' essay.",
        "",
        "Technical angle: the generator works in six design-time layers (floor / zone / occupancy / "
        "services / danger / visibility) and projects down to Ada's three runtime layers. The zone "
        "layer survives as map_info.metadata.zone_grid — the 3D->2D compression kept legible.",
        "",
        "Key artifacts:",
        *[f"- {p['name']}  ({p['phase']})" for p in placed],
    ]
    (out_dir / "intent.md").write_text("\n".join(intent), encoding="utf-8")
    (out_dir / "blurb.md").write_text(
        f"{arc['desc']}\n\nStep in at the south door. The archetype decides everything you find: "
        f"{len(placed)} artifacts chosen because they belong to a {arc['title'].lower()}, placed where "
        f"the grammar says their kind goes. Leave by the north portal.\n", encoding="utf-8")
    return map_path


def main():
    p = argparse.ArgumentParser()
    p.add_argument("--archetype", type=str, help="one of: " + ", ".join(ARCHETYPES))
    p.add_argument("--size", type=int, default=12)
    p.add_argument("--seed", type=int, default=0)
    p.add_argument("--list", action="store_true")
    p.add_argument("--all", action="store_true")
    args = p.parse_args()

    if args.list:
        for k, a in ARCHETYPES.items():
            print(f"  {k:22s} {a['name']}")
        return

    pool = load_pool()
    print(f"loaded {len(pool)} placeable artifacts from registry\n")

    keys = list(ARCHETYPES) if args.all else [args.archetype]
    if not args.all and (args.archetype not in ARCHETYPES):
        p.error("--archetype must be one of: " + ", ".join(ARCHETYPES))

    for key in keys:
        res = generate(key, args.size, args.seed, pool)
        path = write_map(res, key)
        print(f"  {res['lookup']:24s} {len(res['placed'])}/{res['slots']} slots filled  -> {path.relative_to(ROOT)}")
        for pl in res["placed"]:
            print(f"      ({pl['r']:2d},{pl['c']:2d}) {pl['phase']:12s} {pl['name']}")
        print()
    print("validate: python tools/map_pathfinder.py check <lookup> --verbose")


if __name__ == "__main__":
    main()
