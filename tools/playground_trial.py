"""A playground spec as a walkable Void trial, and the slab check that would have caught floor 210.

Palle, 2026-11-02: "make a new map with the artifacts that do not fit on the floor - I can not walk to these and
inspect them", and "test this inside their maps, then later move to the skyscraper". A place spec (places + boards,
commons/modular/places/place_spec.gd) becomes a separate Void trial: a folder under commons/void/trials/<id>/ with
trial.tscn, rooms.json (floor 1 holds the playground_spec_hall token, config {spec}) and layout.json, its slab
sized to hold every place and board, plus one entry in commons/void/trials/playable.json. Trials are desktop and
editor drafts (room_source.trials_available is false on the Quest); a tower floor is the headset's.

  python tools/playground_trial.py make  --spec commons/data/playgrounds/halls/playground_annex.json --id playground_annex --title "..." [--map Map] [--spawn X Y Z]
  python tools/playground_trial.py stack --id playground_floors --title "..." --floor <spec>@<Map>@<title>@x,y,z ...
  python tools/playground_trial.py check --spec <file> [--slab 42 18] [--offset 0 -1]
  python tools/playground_trial.py check --sidecar commons/void/trials/principal_places/activities.json --slab 42 18 --offset 0 -1

stack puts several specs on the floors of ONE trial, joined the tower's way (Palle, 2026-11-02: "can I walk all
floors"): a slab sized to the widest, two shafts A and B through every slab past the content, a soft corner pad on
each floor below in shaft B - jump into B and land on the next map. Floor 0 is an empty canopy, the last a catch
floor. check exits with the number of pieces that do not stand on the slab: the tower's slab is 42 x 18 m and the hall
on floor 210 sits at room position (0, -1).
"""
import argparse, json, math, sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PLAYABLE = ROOT / "commons/void/trials/playable.json"
YAW_AXIS = {"south": "x", "north": "x", "east": "z", "west": "z"}


def load(path):
    p = Path(path)
    if not p.is_absolute():
        p = ROOT / str(path).replace("res://", "")
    return json.loads(p.read_text(encoding="utf-8"))


def place_box(p):
    """place_spec.envelope: the place's operating space - rim, rails, ramps, the descent's arrival."""
    hx, hz, y = p["size"][0] / 2, p["size"][1] / 2, p["y"]
    outer = p["access"]["outer"]
    left = min(-hx - 1, -2 * y - 3) if outer == "ramp" else -hx - 1
    rear = hz + (7 if outer == "tc" else 3)
    x, z = p["at"]
    return (x + left, x + hx + 1, z - hz - 1, z + rear)


def board_boxes(b):
    """Each copy of a board as an (x0, x1, z0, z1) footprint, after count, step and rows."""
    r = b.get("repeat", {})
    n, st = r.get("count", 1), r.get("step", [0, 0, 0])
    rows = r.get("rows", {})
    rn, rs = rows.get("count", 1), rows.get("step", [0, 0, 0])
    w, h = b["size"]
    out = []
    for i in range(n * rn):
        c = [b["at"][k] + st[k] * (i % n) + rs[k] * (i // n) for k in range(3)]
        if b.get("orient", "floor") == "wall":
            if YAW_AXIS.get(b.get("facing", "south"), "x") == "x":
                out.append((c[0] - w / 2, c[0] + w / 2, c[2], c[2]))
            else:
                out.append((c[0], c[0], c[2] - w / 2, c[2] + w / 2))
        else:
            sw, sh = (h, w) if (r.get("turn", 0) * (i % n)) % 180 else (w, h)
            out.append((c[0] - sw / 2, c[0] + sw / 2, c[2] - sh / 2, c[2] + sh / 2))
    return out


def pieces(spec):
    for p in spec.get("places", []):
        yield "place " + p["id"], place_box(p)
    for b in spec.get("boards", []):
        boxes = board_boxes(b)
        yield "board " + b["id"], (min(x[0] for x in boxes), max(x[1] for x in boxes), min(x[2] for x in boxes), max(x[3] for x in boxes))


def check(spec, slab, offset):
    hw, hd = slab[0] / 2, slab[1] / 2
    bad = []
    for name, (x0, x1, z0, z1) in pieces(spec):
        x0, x1, z0, z1 = x0 + offset[0], x1 + offset[0], z0 + offset[1], z1 + offset[1]
        ok = x0 >= -hw and x1 <= hw and z0 >= -hd and z1 <= hd
        print(("ON   " if ok else "OFF  ") + name + "  x %.1f..%.1f  z %.1f..%.1f" % (x0, x1, z0, z1))
        if not ok:
            bad.append(name)
    print("%d of %d pieces off the %g x %g slab" % (len(bad), len(list(pieces(spec))), slab[0], slab[1]))
    return bad


def even_up(v):
    return int(math.ceil(v / 2.0) * 2)


def make(args):
    spec = load(args.spec)
    boxes = [b for _, b in pieces(spec)]
    reach_x = max(max(abs(b[0]), abs(b[1])) for b in boxes) + 2
    reach_z = max(max(abs(b[2]), abs(b[3])) for b in boxes) + 2
    width, depth = max(24, even_up(2 * reach_x)), max(16, even_up(2 * reach_z))
    spec_res = "res://" + Path(args.spec).as_posix().replace("res://", "").lstrip("/")
    folder = ROOT / "commons/void/trials" / args.id
    folder.mkdir(parents=True, exist_ok=True)
    spawn = args.spawn or [0, 0.14, depth / 2 - 2]
    layout = {
        "cliff_landings": {"enabled": False}, "column_width": 0.9,
        "column_x": [-(width / 2 - 1), width / 2 - 1], "column_z": [-(depth / 2 - 1), depth / 2 - 1],
        "depth": float(depth), "descent": {"mode": "shaft_ledges"},
        "floor_roles": ["Canopy", args.title.split(" / ")[0], "Catch floor"],
        "floor_styles": {"0": "abstract", "1": "abstract", "2": "abstract"},
        "levels": [0, -16.0, -32.0], "service_x": [-(width / 2 - 2), width / 2 - 2], "service_z": -(depth / 2 - 4),
        "shaft_depth": 6, "shaft_width": 5, "shafts": [], "slab_thickness": 0.36,
        "spawn_points": {"1": spawn}, "status": "Playground spec trial, written by tools/playground_trial.py from " + spec_res,
        "storey_height": 16.0, "width": float(width)}
    floor = lambda title, arts: {"map": "", "title": title, "origin": False, "walls": [], "artifacts": arts,
                                 "props": [], "impact_cells": [], "supply_leads": False}
    rooms = {"version": 1, "floors": [
        floor("Trial canopy", []),
        dict(floor(args.title, [{"id": args.id.replace("_", "-"), "artifact": "playground_spec_hall", "station": "SE",
                                  "position": [0, 0], "height": 0.08, "facing": 0, "scale": 1,
                                  "config": {"spec": spec_res}}]), map=args.map),
        floor("Catch floor", [])]}
    (folder / "layout.json").write_text(json.dumps(layout, indent=2) + "\n", encoding="utf-8")
    (folder / "rooms.json").write_text(json.dumps(rooms, indent=2) + "\n", encoding="utf-8")
    (folder / "trial.tscn").write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://commons/void/void.tscn" id="1"]\n'
                                       '[node name="PlaygroundSpecTrial" instance=ExtResource("1")]\ntrial_id = "%s"\n' % args.id, encoding="utf-8")
    entry = {"title": args.title, "label": args.title.upper(), "map": args.map, "start_floor": 1,
             "notice": spec.get("title", args.title) + "\nR / B returns to the start.",
             "rooms": "res://commons/void/trials/%s/rooms.json" % args.id,
             "layout": "res://commons/void/trials/%s/layout.json" % args.id,
             "scene": "res://commons/void/trials/%s/trial.tscn" % args.id,
             "retry_floors": {"0": 1, "1": 1, "2": 1}, "spawn_points": {"1": spawn}}
    register(PLAYABLE, args.id, entry)
    print("trial %s: slab %d x %d, %d pieces, spawn %s" % (args.id, width, depth, len(boxes), spawn))
    bad = check(spec, (width, depth), (0, 0))
    print("walk it:  python tools/launch_void_desktop.py --trial " + args.id)
    return len(bad)


def stack(args):
    floors = []
    for f in args.floor:
        parts = f.split("@")
        spec_path, map_name, title = parts[0], parts[1], parts[2]
        spawn = [float(v) for v in parts[3].split(",")] if len(parts) > 3 else None
        spec = load(spec_path)
        floors.append((spec_path, spec, map_name, title, spawn))
    boxes = [b for _, spec, _, _, _ in floors for _, b in pieces(spec)]
    reach_x = max(max(abs(b[0]), abs(b[1])) for b in boxes)
    reach_z = max(max(abs(b[2]), abs(b[3])) for b in boxes) + 2
    shaft_w = 6
    shaft_x = math.ceil(reach_x + 3 + shaft_w / 2)          # a 3 m walk between the content and the hole's edge
    width = even_up(2 * (shaft_x + shaft_w / 2 + 2))
    depth = max(16, even_up(2 * reach_z))
    storey = 12.0
    n = len(floors) + 2
    folder = ROOT / "commons/void/trials" / args.id
    folder.mkdir(parents=True, exist_ok=True)
    spawns = {str(i + 1): (f[4] or [0, 0.14, depth / 2 - 2]) for i, f in enumerate(floors)}
    layout = {
        "cliff_landings": {"enabled": False}, "column_width": 0.9,
        "column_x": [-(width / 2 - 1), width / 2 - 1], "column_z": [-(depth / 2 - 1), depth / 2 - 1],
        "depth": float(depth),
        "descent": {"mode": "corner_pads", "pad_shaft": "B", "boards_per_pad": 2,
                    "pad_shafts": {str(i): "B" for i in range(1, n)}},
        "floor_roles": ["Canopy"] + [f[3].split(" / ")[0] for f in floors] + ["Catch floor"],
        "floor_styles": {str(i): "abstract" for i in range(n)},
        "levels": [-storey * i for i in range(n)], "service_x": [-(width / 2 - 2), width / 2 - 2], "service_z": -(depth / 2 - 4),
        "shaft_depth": shaft_w, "shaft_width": shaft_w, "shafts": [{"name": "A", "x": -shaft_x}, {"name": "B", "x": shaft_x}],
        "slab_thickness": 0.36, "spawn_points": spawns,
        "status": "Stacked playground trial, written by tools/playground_trial.py stack: " + ", ".join(f[2] for f in floors),
        "storey_height": storey, "width": float(width)}
    def floor(title, arts, map_name=""):
        return {"map": map_name, "title": title, "origin": False, "walls": [], "artifacts": arts,
                "props": [], "impact_cells": [], "supply_leads": False}
    records = [floor("Trial canopy", [])]
    for i, (spec_path, spec, map_name, title, _) in enumerate(floors):
        res = "res://" + Path(spec_path).as_posix().replace("res://", "").lstrip("/")
        records.append(floor(title, [{"id": "%s-%d" % (args.id.replace("_", "-"), i + 1), "artifact": "playground_spec_hall", "station": "SE",
                                      "position": [0, 0], "height": 0.08, "facing": 0, "scale": 1, "config": {"spec": res}}], map_name))
    records.append(floor("Catch floor", []))
    (folder / "layout.json").write_text(json.dumps(layout, indent=2) + "\n", encoding="utf-8")
    (folder / "rooms.json").write_text(json.dumps({"version": 1, "floors": records}, indent=2) + "\n", encoding="utf-8")
    (folder / "trial.tscn").write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="PackedScene" path="res://commons/void/void.tscn" id="1"]\n'
                                       '[node name="PlaygroundStackTrial" instance=ExtResource("1")]\ntrial_id = "%s"\n' % args.id, encoding="utf-8")
    entry = {"title": args.title, "label": args.title.upper(), "map": floors[0][2], "start_floor": 1,
             "notice": " -> ".join(f[3].split(" / ")[0] for f in floors) + "\nJump into shaft B (east) for the next floor; R / T resets the encounter.",
             "rooms": "res://commons/void/trials/%s/rooms.json" % args.id,
             "layout": "res://commons/void/trials/%s/layout.json" % args.id,
             "scene": "res://commons/void/trials/%s/trial.tscn" % args.id,
             "retry_floors": {str(i): min(max(i, 1), len(floors)) for i in range(n)}, "spawn_points": spawns}
    register(PLAYABLE, args.id, entry)
    print("trial %s: %d floors (+ canopy and catch), slab %d x %d, shafts at x +-%d, storey %g m" % (args.id, len(floors), width, depth, shaft_x, storey))
    bad = 0
    for i, (_, spec, _, title, _) in enumerate(floors):
        print("floor %d: %s" % (i + 1, title))
        bad += len(check(spec, (width, depth), (0, 0)))
    print("walk it:  python tools/launch_void_desktop.py --trial " + args.id)
    return bad


def register(path, trial_id, entry):
    """Add or replace one trial, keeping the file's own format (indent 2, ASCII, its line endings)."""
    raw = path.read_bytes()
    crlf = b"\r\n" in raw
    data = json.loads(raw.decode("utf-8"))
    data["trials"][trial_id] = entry
    text = json.dumps(data, indent=2) + "\n"
    if crlf:
        text = text.replace("\n", "\r\n")
    path.write_bytes(text.encode("utf-8"))


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = ap.add_subparsers(dest="cmd", required=True)
    m = sub.add_parser("make")
    m.add_argument("--spec", required=True)
    m.add_argument("--id", required=True)
    m.add_argument("--title", required=True)
    m.add_argument("--map", default="Random_Walk")
    m.add_argument("--spawn", type=float, nargs=3)
    st = sub.add_parser("stack")
    st.add_argument("--id", required=True)
    st.add_argument("--title", required=True)
    st.add_argument("--floor", action="append", required=True, help="<spec>@<Map>@<title>[@x,y,z spawn]")
    c = sub.add_parser("check")
    c.add_argument("--spec")
    c.add_argument("--sidecar")
    c.add_argument("--slab", type=float, nargs=2, default=[42, 18])
    c.add_argument("--offset", type=float, nargs=2, default=[0, 0])
    args = ap.parse_args()
    if args.cmd == "make":
        sys.exit(make(args))
    if args.cmd == "stack":
        sys.exit(stack(args))
    spec = load(args.spec or args.sidecar)
    sys.exit(len(check(spec, args.slab, args.offset)))


if __name__ == "__main__":
    main()
