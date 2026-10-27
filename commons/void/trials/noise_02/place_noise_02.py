"""Batch 25 / worker C: place the five Noise halls on noise_02 floors 1-5.

Run from the repo root:  python commons/void/trials/noise_02/place_noise_02.py
Writes rooms.json (floors 1-5; floors 0 and 6 untouched) and moves.json beside it.

Rule (WORKER_BRIEF): rigid 180-degree turn, x = cx - col, z = cz - row, chosen so the
source spawn lands on the arrival (0, 12); facing = (yaw + 180) mod 360; token height
and scale kept. Moves are listed in MOVES with the rigid position, the new one and the
reason. Nothing is scaled. Config values are strings; a bare #key becomes "true".
"""
from pathlib import Path
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ARRIVAL = (0.0, 12.0)

# Placement IDs listed first are built first on a lazily loaded floor (one factory
# per frame). The voxel volume must exist before the bench's deferred broadcast,
# and the two rooms before the strands cast their anchor rays.
ORDER = {
    2: ["f2_voxelnoise_16_24", "f2_science_screen_18_4", "f2_perlin_terrain_sculptor_13_7", "f2_dark_sphere_5_8"],
    5: ["f5_cellular_womb_space_17_19", "f5_cellular_atrium_space_51_19", "f5_voronoi_strands_34_40"],
}

# id -> (new position, facing override or None, reason). Static inference unless noted.
MOVES = {
    "f1_film_noise_layers_1_2": ((-1.5, 10.0), None,
        "The case is 2.68 m wide along z at facing 270; at the rigid spot its corner enters the arrival "
        "keep-out (x -1..1, z 11..13) by 0.26 x 0.34 m. Moved 0.5 m west, away from the arrival."),
    "f1_dark_sphere_8_10": ((-8.0, 4.0), None,
        "The rigid spot lies inside shaft A's opening, on floor 1's landing pad (x -9.07..-7.53, z 0.8..3.0). "
        "Moved 2 m south onto solid floor, 0.34 m clear of the basin rail."),
    "f2_voxelnoise_16_24": ((-6.0, -30.1), None,
        "stand:volume + cell_size:1 builds 24 x 24 x 24 one-metre cells and flight_box:true a 28 m glass "
        "enclosure with collision walls, floor and roof. At the rigid spot it covers shaft A (the descent), "
        "reaches shaft B and runs 9 m past the north edge; every on-slab spot crosses a shaft or carries the "
        "cells and glass walls through floor 1 and the roof. Moved 19.1 m north along its own axis so the "
        "enclosure's south face and door stand at the slab edge: external extent, carried by its own glass "
        "floor. Bench and screen stay rigid (bench-to-volume 36 m, source 17 m)."),
    "f3_dark_sphere_10_10": ((-10.2, 4.4), None,
        "The rigid spot is at the edge of shaft A's opening on floor 3's landing pad (z 0.8..3.0). Moved 1.8 m "
        "onto solid floor, west of the pad's walk-off corridor."),
    "f4_dark_sphere_3_3": ((4.0, 2.0), None,
        "Floor 4 is translated as a whole by (+3, -19): the source spawn is at the hall's south end (row 12), "
        "so the spawn-anchored turn put the hall behind the arrival (z 15..21, off the 32 m floor). The orb "
        "stays inside the 10 m enclosure, as in the source."),
    "f4_noisesphere_6_5": ((1.0, 0.0), None,
        "Floor 4 translated by (+3, -19), see the orb. The enclosure (r 5 m, relief to 5.8 m, top 7.3 m) "
        "clears both shafts, the arrival, the floor sign and floor 5's room caps."),
    "f4_film_noise_relief_11_9": ((-4.0, -4.0), None,
        "Floor 4 translated by (+3, -19), see the orb. Same distance to the enclosure as in the source."),
    "f5_cellular_womb_space_17_19": ((14.5, 17.2), None,
        "Womb about 23.4 x 28 m and atrium 25.3 x 25.3 m (mesher bounds 27 x 29 m), 34 m apart in the source: "
        "56 m across against a 42 m floor. At the rigid spots the womb covers shaft B and the atrium shaft A "
        "(the descent onto this floor), and both run 7-9 m past the side edges. No on-slab pair clears shaft A "
        "without the rooms intersecting. Both keep their rigid side and facing (entrances face the slab and "
        "the strands, as in the source) and straddle the south edge: entrance and front half on the slab, "
        "back half unsupported (floor:false). Womb shell 0.4 m clear of shaft B's south-east corner."),
    "f5_cellular_atrium_space_51_19": ((-14.0, 16.0), None,
        "See the womb. Atrium centre on the slab edge; shell 0.4 m clear of shaft A's south-west corner and 1.3 m "
        "clear of floor 5's landing pad; arrival corridor between the rooms (x -2.4..4.1 at z 11) kept clear."),
    "f5_voronoi_strands_34_40": ((17.0, -10.5), None,
        "The rigid spot (0, -27) is 11 m past the north edge. The work is a 6.6 x 7 x 5.8 m Voronoi core "
        "(0.8..7.8 m) plus up to 36 cords that ray-cast to whatever solid surface they meet within 80 m, as they "
        "ran to the museum hall's floor, walls and rooms. At (0, -12) the cords spanned x -15.8..20.5, z "
        "-15.9..12.1 and up to 11.7 m (measured, bounds-5), and the coarse test put them in both shafts, the "
        "arrival and the floor sign 1.3 m away. Moved into the north-east bay between columns (14, -14) and "
        "(20, -14), north of the womb: no floor sign within 8 m, shaft B (no pads) to the south-west, shaft A's "
        "landing pads 25 m away; the core clears the columns and the z -14 beam. Not on the source's centre axis."),
}


def spawn_cell(map_name):
    data = json.loads((ROOT / "commons/maps" / map_name / "map_data.json").read_text(encoding="utf-8"))
    for row, cells in enumerate(data["layers"]["utilities"]):
        for col, value in enumerate(cells):
            if value.strip().split(":")[0] in ("s", "sp"):
                return col, row
    raise SystemExit("no spawn in " + map_name)


def parse(token):
    head, *fragments = token.split("#")
    fields = head.split(":")
    yaw = float(fields[1]) if len(fields) > 1 and fields[1] else 0.0
    height = float(fields[2]) if len(fields) > 2 and fields[2] else 0.0
    scale = float(fields[3]) if len(fields) > 3 and fields[3] else 1.0
    config = {}
    for fragment in fragments:
        key, _, value = fragment.partition(":")
        config[key] = value or "true"
    return fields[0], yaw, height, scale, config


def station(x, z):
    return ("S" if z >= 0 else "N") + ("E" if x >= 0 else "W")


def number(v):
    return int(v) if float(v).is_integer() else round(float(v), 3)


def main():
    inventory = json.loads((HERE / "source-inventory.json").read_text(encoding="utf-8"))
    rooms_path = HERE / "rooms.json"
    rooms = json.loads(rooms_path.read_text(encoding="utf-8"))
    by_floor = {}
    moves = []
    for p in inventory["placements"]:
        col, row = p["source_cell"]
        sx, sz = spawn_cell(p["map"])
        cx, cz = ARRIVAL[0] + sx, ARRIVAL[1] + sz
        name, yaw, height, scale, config = parse(p["token"])
        assert name == p["artifact"], p["id"]
        rigid = (cx - col, cz - row)
        facing = int((yaw + 180) % 360)
        at = rigid
        if p["id"] in MOVES:
            at, override, reason = MOVES[p["id"]]
            if override is not None:
                facing = override
            moves.append({"id": p["id"], "rigid": [number(rigid[0]), number(rigid[1])],
                          "placed": [number(at[0]), number(at[1])], "facing": facing, "reason": reason})
        entry = {"id": p["id"], "artifact": p["artifact"], "station": station(*at),
                 "position": [number(at[0]), number(at[1])], "facing": facing,
                 "height": number(height), "scale": number(scale), "config": config}
        by_floor.setdefault(p["floor"], []).append(entry)
    for floor, entries in by_floor.items():
        order = ORDER.get(floor)
        if order:
            assert sorted(order) == sorted(e["id"] for e in entries), floor
            entries.sort(key=lambda e: order.index(e["id"]))
        record = rooms["floors"][floor]
        assert record["map"] == next(p["map"] for p in inventory["placements"] if p["floor"] == floor), floor
        record["artifacts"] = entries
    rooms_path.write_text(json.dumps(rooms, indent=2) + "\n", encoding="utf-8")
    (HERE / "moves.json").write_text(json.dumps(moves, indent=2) + "\n", encoding="utf-8")
    for floor in sorted(by_floor):
        for e in by_floor[floor]:
            print(floor, e["id"], e["position"], e["facing"], e["height"], e["scale"], e["config"])
    print(len(moves), "moves")


if __name__ == "__main__":
    main()
