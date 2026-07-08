"""curate.py — compile an exhibition.json into a walkable map.

The Curator pipeline's DRAFT stage: reads doc/exhibitions/<id>/exhibition.json
(brief, argument form, rooms with modes + artifacts + reasons + exclusions)
and emits commons/maps/Exhibition_<Id>/map_data.json — an enfilade of rooms
partitioned by the walls layer, each dressed with its mode-kit, artifacts at
their slots, wrapped in the museum shell. The decision record travels with
the map (map_info.exhibition points back at the truth-file).

v1 supports argument_form=enfilade and modes: mode_crown (anchor at center),
mode_dialogue (two artifacts at +-gap/2 along X), mode_witness_wall (wall
across the room's north side).

Usage: python tools/curate.py <exhibition_id> [--room-w=14] [--room-d=12]
"""
import json
import re
import sys
from pathlib import Path

sys.stdout.reconfigure(encoding="utf-8", errors="replace")

ROOT = Path(__file__).resolve().parent.parent


def compact(obj) -> str:
    text = json.dumps(obj, indent=1)
    return re.sub(r'\[\s+((?:"[^"]*",?\s+)+)\]',
                  lambda m: '[' + ', '.join(x.strip().rstrip(',')
                                            for x in m.group(1).split('\n') if x.strip()) + ']',
                  text)


def token(artifact_token: str, cfg: dict | None = None) -> str:
    t = artifact_token
    if cfg:
        for k, v in cfg.items():
            t += f"#{k}:{v}"
    return t


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)
    ex_id = sys.argv[1]
    room_w = 14
    room_d = 12
    for a in sys.argv[2:]:
        if a.startswith("--room-w="):
            room_w = int(a.split("=")[1])
        if a.startswith("--room-d="):
            room_d = int(a.split("=")[1])

    ex_path = ROOT / "doc" / "exhibitions" / ex_id / "exhibition.json"
    ex = json.loads(ex_path.read_text(encoding="utf-8"))
    rooms = ex["rooms"]
    if ex.get("argument_form") != "enfilade":
        print("v1 compiles enfilade only")
        sys.exit(1)

    # ── enfilade geometry: rooms in a row along X, doors on the axis ────────
    n = len(rooms)
    W = n * room_w + 2          # margin col each end
    D = room_d + 2
    axis_r = D // 2

    structure = [["1"] * W for _ in range(D)]
    utilities = [[" "] * W for _ in range(D)]
    inter = [[" "] * W for _ in range(D)]
    walls = [[""] * W for _ in range(D)]

    def add_wall(r, c, code):
        walls[r][c] += code

    # room bounds: room i occupies cols [1 + i*room_w, 1 + (i+1)*room_w - 1]
    for i in range(n):
        c0 = 1 + i * room_w
        c1 = c0 + room_w - 1
        # perimeter of each room (shared edges dedupe in the component)
        cx_room = c0 + room_w // 2
        for c in range(c0, c1 + 1):
            # north entries near each room's center (double) — testers arrive from 0,0
            add_wall(1, c, "N" if c in (cx_room, cx_room + 1) else "n")
            add_wall(D - 2, c, "s")
        door_rows = (axis_r, axis_r + 1)   # double doors — VR-wide openings
        for r in range(1, D - 1):
            add_wall(r, c0, "W" if r in door_rows else "w")
            if i == n - 1:
                add_wall(r, c1, "E" if r in door_rows else "e")

    # spawn before room 0's door; teleporter past the last room's door
    utilities[axis_r][0] = "s"
    utilities[axis_r][W - 1] = "t"
    structure[axis_r][W - 1] = "0"

    # ── dress each room with its mode + artifacts ───────────────────────────
    for i, room in enumerate(rooms):
        c0 = 1 + i * room_w
        cx = c0 + room_w // 2
        mode = room["mode"]
        mcfg = dict(room.get("mode_config", {}))
        arts = room.get("artifacts", [])

        if mode == "mode_crown":
            inter[axis_r][cx] = token("mode_crown", mcfg)
            if arts:
                inter[axis_r][cx - 1] = token(arts[0]["token"])
        elif mode == "mode_dialogue":
            gap = float(mcfg.get("gap", 7.0))
            inter[axis_r][cx] = token("mode_dialogue", mcfg)
            half = max(2, int(round(gap / 2)))
            if len(arts) >= 2:
                inter[axis_r][cx - half] = token(arts[0]["token"]) + ":90"
                inter[axis_r][cx + half] = token(arts[1]["token"]) + ":270"
        elif mode == "mode_witness_wall":
            inter[2][cx] = token("mode_witness_wall", mcfg)
        else:
            print(f"warning: unknown mode {mode} — room {room['id']} left bare")

    # the shell around everything
    inter[axis_r + 2][W // 2] = f"museum_hall_shell#width:{W}#depth:{D}#height:9#sky:0"

    title = "Exhibition_" + "".join(w.capitalize() for w in ex_id.split("_"))
    data = {
        "map_info": {
            "name": "Exhibition: " + ex_id.replace("_", " ").title(),
            "title": title,
            "lookup_name": title,
            "description": ex["brief"] + " — compiled by the Curator from "
                           f"doc/exhibitions/{ex_id}/exhibition.json; the decision record "
                           "(reasons, exclusions, rulings, sieve pass) travels with the map.",
            "version": "0.1", "format": "json",
            "dimensions": {"width": W, "depth": D, "max_height": 1},
            "exhibition": f"doc/exhibitions/{ex_id}/exhibition.json",
            "metadata": {
                "difficulty": "beginner", "category": "museum",
                "estimated_time": "6-10 minutes",
                "learning_objectives": [ex["brief"]],
            },
        },
        "utility_definitions": {
            "s": {"type": "spawn", "description": "the exhibition entrance"},
            "t": {"type": "teleporter", "description": "exit, past the last room"},
        },
        "settings": {
            "cube_size": 1.0, "gutter": 0.02, "show_grid": True, "enable_physics": True,
            "auto_reveal_on_entry": False, "initial_tile_visibility": "all",
            "background": "dark",
            "wall_segments": {"height": 3.6, "thickness": 0.18, "door_width": 2.6, "color": [0.82, 0.79, 0.72]},
        },
        "lighting": {
            "ambient_color": [0.32, 0.31, 0.34], "ambient_energy": 0.35,
            "directional_light": {"enabled": True, "direction": [-0.2, -0.9, -0.2],
                                  "color": [0.95, 0.93, 0.88], "energy": 0.55},
        },
        "layers": {"structure": structure, "utilities": utilities,
                   "walls": walls, "interactables": inter},
    }

    out = ROOT / "commons" / "maps" / title / "map_data.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(compact(data), encoding="utf-8")

    n_pending = sum(1 for r in rooms if r.get("ruling") == "pending")
    print(f"compiled {ex_id} -> {out}")
    print(f"  {n} rooms, {W}x{D}, argument={ex['argument_form']}")
    if n_pending:
        print(f"  NOTE: {n_pending}/{n} rooms have ruling=pending — the draft awaits the curator")


if __name__ == "__main__":
    main()
