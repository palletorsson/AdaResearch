#!/usr/bin/env python3
"""ROOMS PER PEARL — how much of a template tile a pearl gets.

    python tools/em_rooms.py --survey [primitives]   # how deep each pearl actually goes today
    python tools/em_rooms.py --set primitives point 4  # rule it (hand_pearls.rooms) — then regen + bake

A pearl used to get the WHOLE template tile (Sainsbury: 30 rows), so a pearl
with 11 bodies stood in a hall built for 30 and looked empty. Palle: "we
need a way to control how big the area of each map is … the point map is
four rooms and the line takes over and is 6 rooms then triangle 8".

One number per pearl, `rooms`, kept with the pearl (trunk_branches
hand_pearls -> pearls[].rooms -> hero_walk pearl walk -> spine_run), and ONE
crop function used by the negotiator (spatial_floorplan.from_museum) — the
runtime never crops: the cropped tile is written INTO the plan row (`tile`,
`h`, `rooms`) and endless_museum reads it, so the two sides cannot disagree.

A "room" is the tile's own rhythm: the pitch in rows between its pier /
divider rows (rows whose inner cells are mostly wall). Sainsbury: 6. The
crop keeps rooms x pitch rows and ends on the nearest divider at or beyond
that depth (its door becomes the exit); a tile with no divider there gets a
closing wall row with a centred door. rooms >= the tile's own = whole tile.
"""
from __future__ import annotations
import argparse, json, math, sys
from pathlib import Path
REPO = Path(__file__).resolve().parent.parent
PATTERNS = REPO / "commons" / "data" / "template_patterns.json"
TRUNK = REPO / "commons" / "data" / "trunk_branches.json"
PLAN = REPO / "ada_run" / "em_plan.json"
WALL = "4"
DEFAULT_PITCH = 6
if sys.stdout.encoding and sys.stdout.encoding.lower() != "utf-8":
    sys.stdout.reconfigure(encoding="utf-8")


def _wall_share(row) -> float:
    inner = [str(c) for c in row][1:-1]
    return (sum(1 for c in inner if c == WALL) / len(inner)) if inner else 0.0


def divider_rows(tile, share: float = 0.5) -> list[int]:
    """Rows (after the entry row) whose inner cells are mostly wall — piers and cross-walls."""
    return [y for y in range(1, len(tile)) if _wall_share(tile[y]) >= share]


def pitch_rows(tile) -> int:
    d = divider_rows(tile)
    return d[0] if d else DEFAULT_PITCH


def rooms_in(tile) -> int:
    return max(1, math.ceil(len(tile) / pitch_rows(tile)))


def crop_tile(tile, rooms) -> list[list[str]]:
    """The first `rooms` rooms of `tile`, ending on a divider (or a made one). rooms<=0/None = whole."""
    tile = [[str(c) for c in row] for row in tile]
    if not rooms or int(rooms) <= 0:
        return tile
    h = len(tile)
    depth = int(rooms) * pitch_rows(tile)
    if depth >= h - 1:
        return tile
    end = None
    for y in divider_rows(tile):
        if y >= depth - 1 and y <= depth + 2:
            end = y
            break
    if end is None:
        end = depth - 1
    out = tile[: end + 1]
    if _wall_share(out[end]) < 0.5:
        # close it: a wall row with a centred door the width of the entry row's
        w = len(out[end])
        entry = tile[0]
        door = [x for x in range(w) if entry[x] != WALL] or [w // 2 - 1, w // 2, w // 2 + 1]
        out[end] = [("1" if x in door else WALL) for x in range(w)]
    return out


def survey(seq_filter: str = "") -> int:
    pats = json.loads(PATTERNS.read_text(encoding="utf-8"))["patterns"]
    plan = json.loads(PLAN.read_text(encoding="utf-8")) if PLAN.exists() else {"plans": []}
    trunk = json.loads(TRUNK.read_text(encoding="utf-8")) if TRUNK.exists() else {}
    ruled: dict[tuple[str, str], int] = {}
    for node, edits in (trunk.get("hand_pearls") or {}).items():
        for e in edits:
            if e.get("rooms") is not None and (e.get("pearl") or e.get("map")):
                ruled[(node, str(e.get("pearl") or ""))] = int(e["rooms"])
                ruled[(node, "map:" + str(e.get("map") or ""))] = int(e["rooms"])
    # THE MAP'S OWN SPACE (Palle, 2026-08-19: "now we can see approx. how much
    # space each map needs"): the grid map behind the pearl — its floor cells,
    # its interactables, its long side in rows — beside what the hall gives it.
    def map_space(name: str):
        f = REPO / "commons" / "maps" / name / "map_data.json"
        if not f.exists():
            return None
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            return None
        L = d.get("layers", d)
        S, I = L.get("structure", []), L.get("interactables", [])
        floor = sum(1 for row in S for c in row if str(c).strip() not in ("", "0", " "))
        arts = sum(1 for row in I for c in row if str(c).strip() not in ("", "0", " "))
        return {"w": len(S[0]) if S else 0, "h": len(S), "floor": floor, "arts": arts}
    print(f"{'chapter':18s} {'pearl':18s} {'museum':28s} tile  pitch rooms | bodies deepest  needs   ruled | map          size   floor  arts  ~rooms")
    for p in plan.get("plans", []):
        if seq_filter and p["sequence"] != seq_filter:
            continue
        t = pats.get(p["museum"], {}).get("tile", [])
        if not t:
            continue
        pitch = pitch_rows(t)
        interior = [a for a in p.get("artifacts", []) if a.get("venue") == "interior"]
        zmax = max((int(a["tile_cell"][1]) for a in interior), default=0)
        needs = max(1, math.ceil((zmax + 2) / pitch))
        r = ruled.get((p["sequence"], str(p.get("pearl") or ""))) or ruled.get((p["sequence"], "map:" + str(p.get("map") or "")))
        ms = map_space(str(p.get("map") or ""))
        # ~rooms: the map's floor against one room of this tile (its width x pitch),
        # and its interactables at three to a room — whichever asks for more
        if ms and ms["floor"] > 0:
            room_cells = max(1, (len(t[0]) - 2) * pitch)
            by_floor = math.ceil(ms["floor"] / room_cells)
            by_arts = math.ceil(ms["arts"] / 3) if ms["arts"] else 1
            approx = max(1, min(rooms_in(t), max(by_floor, by_arts)))
            mtxt = f"{str(p.get('map') or '')[:12]:12s} {ms['w']:2d}x{ms['h']:<3d} {ms['floor']:6d} {ms['arts']:5d}   {approx:3d}"
        else:
            mtxt = f"{str(p.get('map') or '-')[:12]:12s} {'-':6s} {'-':6s} {'-':5s}   {'-':3s}"
        print(f"{p['sequence']:18s} {str(p.get('pearl') or '-'):18s} {p['museum'][:28]:28s} {len(t):4d}  {pitch:5d} {rooms_in(t):5d} | {len(interior):6d} {zmax:7d}  {needs:5d}   {str(r) if r is not None else '-':5s} | {mtxt}")
    return 0


def set_rooms(node: str, pearl: str, rooms: int) -> int:
    d = json.loads(TRUNK.read_text(encoding="utf-8"))
    d.setdefault("hand_pearls", {})
    edits = d["hand_pearls"].setdefault(node, [])
    # find the pearl's map from the seeded pearls (edits are keyed by map)
    seeded = next((t for t in d.get("trunk", []) if t.get("node") == node), {}) or {}
    pmap = next((q.get("map") for q in seeded.get("pearls", []) if q.get("pearl") == pearl), "")
    hit = next((e for e in edits if (e.get("pearl") == pearl) or (pmap and e.get("map") == pmap)), None)
    if hit is None:
        hit = {"map": pmap, "pearl": pearl}
        edits.append(hit)
    hit["rooms"] = int(rooms)
    TRUNK.write_text(json.dumps(d, indent=1, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"ruled: {node} · {pearl} = {rooms} room(s) (hand_pearls). Now: python tools/build_trunk_pearls.py && python tools/spine_run.py --sequence={node} --write-plan && python tools/em_bake.py")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--survey", nargs="?", const="", default=None, metavar="SEQ")
    ap.add_argument("--set", nargs=3, metavar=("NODE", "PEARL", "ROOMS"))
    a = ap.parse_args()
    if a.set:
        return set_rooms(a.set[0], a.set[1], int(a.set[2]))
    return survey(a.survey or "")


if __name__ == "__main__":
    raise SystemExit(main())
