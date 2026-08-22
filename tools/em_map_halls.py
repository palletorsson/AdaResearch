"""em_map_halls.py — TEST-PLACE edited grid maps as endless-museum halls.

Palle: "I have made the three first spine maps, can we test place them in the
endless museum with current placement and layout?" The museum already obeys a
plan row's own `tile` (rooms-per-pearl, endless_museum.gd ~3128), so the test
needs no museum changes: this tool derives a TRIAL plan whose primitives rows
come from the maps themselves —

  tile      : the map's structure, cropped to content (h>=2 wall "4",
              h==1 floor "1", else "0") — shorter z than the template halls,
              so the lobby spacing negotiates itself (everything reads tile/h)
  artifacts : the map's interactables at their cells (tile_cell = cropped),
              plinth = structure 2 under the anchor -> support 0.95
  pearls    : point / lines / trace (Point_One keeps its live pearl name, so
              origin + folding_past land exactly where the hand has them)

Writes ada_run/_trial_map_plan.json (a full copy of em_plan.json with the
primitives plans replaced). NEVER touches live files — the shot probe injects
the trial paths (the probe-isolation rule).

  python tools/em_map_halls.py
"""
from __future__ import annotations

import copy
import json
import pathlib

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAPS = [("point", "Point_One"), ("lines", "Point_Lines"), ("trace", "Point_Trace")]
CHAPTER = "primitives"
OUT = ROOT / "ada_run" / "_trial_map_plan.json"


def derive_row(pearl: str, map_name: str, museum_key: str, idx: int, total: int) -> dict:
    md = json.loads((ROOT / "commons" / "maps" / map_name / "map_data.json").read_text(encoding="utf-8"))
    struct = [[int(str(v)) if str(v).strip().isdigit() else 0 for v in row]
              for row in md["layers"]["structure"]]
    inter = md["layers"].get("interactables", [])
    # crop to content
    rows = [r for r, row in enumerate(struct) if any(v > 0 for v in row)]
    cols = [c for row in struct for c, v in enumerate(row) if v > 0]
    r0, r1 = min(rows), max(rows)
    c0, c1 = min(cols), max(cols)
    tile = []
    for r in range(r0, r1 + 1):
        line = []
        for c in range(c0, c1 + 1):
            v = struct[r][c] if c < len(struct[r]) else 0
            line.append("4" if v >= 2 else ("1" if v == 1 else "0"))
        tile.append(line)
    arts = []
    for r, row in enumerate(inter):
        for c, v in enumerate(row):
            tok = str(v).strip()
            if not tok or tok == " ":
                continue
            base = tok.split("#")[0]
            parts = base.split(":")
            name = parts[0]
            rot = int(float(parts[1])) if len(parts) > 1 and parts[1] else 0
            under = struct[r][c] if r < len(struct) and c < len(struct[r]) else 0
            tc = [c - c0, r - r0]
            arts.append({
                "token": name, "cell": list(tc), "tile_cell": list(tc),
                "rotation": ((rot % 360) + 360) % 360,
                "mode": "freestanding", "venue": "interior",
                "support_height_m": 0.95 if under >= 2 else 0.0,
                "hand": True, "ruled": {"by": "map: " + map_name, "cell": list(tc)},
            })
    return {
        "museum": museum_key,
        "tile": tile, "h": len(tile),
        "rooms": 0, "artifacts": arts, "rejected": [],
        "room": {"w": len(tile[0]) if tile else 0, "h": len(tile)}, "apron": 0,
        "interior_count": sum(1 for tr in tile for cv in tr if cv == "1"),
        "ordered": True, "pages": [],
        "sequence": CHAPTER, "pearl": pearl, "pearl_index": idx,
        "map": map_name, "pearls_total": total,
        "source": "em_map_halls: the map IS the hall",
    }


def main() -> None:
    plan = json.loads((ROOT / "ada_run" / "em_plan.json").read_text(encoding="utf-8"))
    trial = copy.deepcopy(plan)
    museum_key = next(r["museum"] for r in plan["plans"]
                      if r.get("sequence") == CHAPTER)
    new_rows = [derive_row(p, m, museum_key, i, len(MAPS)) for i, (p, m) in enumerate(MAPS)]
    trial["plans"] = [r for r in trial["plans"] if r.get("sequence") != CHAPTER] + new_rows
    OUT.write_text(json.dumps(trial), encoding="utf-8")
    print(f"trial plan -> {OUT.name}: {CHAPTER} = {len(new_rows)} map-authored hall(s)")
    for row in new_rows:
        firsts = {a["token"]: a["tile_cell"] for a in row["artifacts"][:2]}
        print(f"  {row['pearl']:<7} {row['map']:<12} tile {row['room']['w']}x{row['h']}"
              f"  artifacts {len(row['artifacts'])}  first: {firsts}")


if __name__ == "__main__":
    main()
