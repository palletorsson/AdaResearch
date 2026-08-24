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

Two modes:
  python tools/em_map_halls.py            trial — writes ada_run/_trial_map_plan.json
                                          only; never touches live files (the
                                          probe-isolation rule)
  python tools/em_map_halls.py --apply    PLAN MODE — patches the LIVE
                                          ada_run/em_plan.json (backup kept at
                                          em_plan.backup.json) and ships via
                                          em_ship.py, so desktop AND the Quest
                                          export walk the map-authored halls

The chapters and maps come from commons/data/map_authored.json — the
declaration binds, this tool derives (Scene -> Registry discipline: never
transcribe a hall by hand).
"""
from __future__ import annotations

import copy
import json
import pathlib
import subprocess
import sys

ROOT = pathlib.Path(__file__).resolve().parents[1]
DECLARATION = ROOT / "commons" / "data" / "map_authored.json"
OUT = ROOT / "ada_run" / "_trial_map_plan.json"
LIVE = ROOT / "ada_run" / "em_plan.json"
BACKUP = ROOT / "ada_run" / "em_plan.backup.json"


def declared() -> dict[str, list[tuple[str, str]]]:
    """chapter -> [(pearl, map_name)] from the declaration; the pearl name is
    the map name lowercased minus its chapter-ish prefix (Point_One -> point
    one) — short, stable, unique within the chapter."""
    doc = json.loads(DECLARATION.read_text(encoding="utf-8"))
    out: dict[str, list[tuple[str, str]]] = {}
    for chapter, maps in doc.items():
        if chapter.startswith("_") or not isinstance(maps, list):
            continue
        pairs = []
        for m in maps:
            pearl = str(m).replace("_", " ").lower()
            pairs.append((pearl, str(m)))
        out[chapter] = pairs
    return out


def derive_row(pearl: str, map_name: str, museum_key: str, idx: int, total: int, chapter: str = "primitives") -> dict:
    md = json.loads((ROOT / "commons" / "maps" / map_name / "map_data.json").read_text(encoding="utf-8"))
    raw = md["layers"]["structure"]

    def eff(v):
        # numbers = legacy heights; "w" = wall (3), "p"/"p:N" = platform (N)
        s = str(v).strip()
        if s == "w":
            return 3
        if s == "p" or s.startswith("p:"):
            try:
                return max(1, int(s.split(":")[1])) if ":" in s else 1
            except ValueError:
                return 1
        return int(s) if s.isdigit() else 0

    struct = [[eff(v) for v in row] for row in raw]
    inter = md["layers"].get("interactables", [])
    # ORIGIN-PINNED (the ruling drift lesson: tile cells ARE map cells,
    # forever). Cropping to the content bbox moved (0,0) whenever the map's
    # content changed, which silently re-addressed every saved ruling —
    # walls, artifact moves, all of them. Only the FAR edges trim now.
    rows = [r for r, row in enumerate(struct) if any(v > 0 for v in row)]
    cols = [c for row in struct for c, v in enumerate(row) if v > 0]
    r0, r1 = 0, max(rows)
    c0, c1 = 0, max(cols)
    tile = []
    for r in range(r0, r1 + 1):
        line = []
        for c in range(c0, c1 + 1):
            v = struct[r][c] if c < len(struct[r]) else 0
            # EVERY interior cell is FLOOR (Palle: "there is a gap in the
            # floor between segments"): the grid's height-0 cells (teleporter
            # zones, designed voids) are pits in a museum — the hall floors
            # them and keeps only the walls as walls.
            # h>=2 wall, h==1 floor, 0 stays a HOLE — the docstring promised
            # `else "0"` from day one but the code flattened holes to floor
            # (caught 2026-08-23, Palle: "value 0 for floating objects").
            # LETTERS end the double meaning of "2" (same day): "w" is an
            # explicit WALL, "p"/"p:N" an explicit PLATFORM (tile "p"/"pN" —
            # a climbable block, never a wall).
            sv2 = str(raw[r][c]).strip() if r < len(raw) and c < len(raw[r]) else ""
            if sv2 == "w":
                line.append("4")
            elif sv2 == "p" or sv2.startswith("p:"):
                n = 1
                if ":" in sv2:
                    try: n = max(1, int(sv2.split(":")[1]))
                    except ValueError: n = 1
                line.append("p" if n == 1 else "p%d" % n)
            else:
                line.append("4" if v >= 2 else ("1" if v >= 1 else "0"))
        tile.append(line)
    # NO inserted walls (Palle: "there is a wall where the sliding door
    # should be — you can simplify"): the museum's vestibule + gate already
    # own the entrance; an added wall row stood exactly where the gate's
    # sliding door slides. The hall stays the pure map tile — the gate
    # centres a normal-width door on an open edge by itself now.
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
            # the token's #k:v#k:v config rides into the row — the stamp
            # applies row["config"] via set_meta + apply_grid_config, so a
            # map's #ink / #resolution / #board_width reach the hall's
            # bodies. Dropped silently until 2026-08-23: the RGB rank stood
            # in the museum at default magenta and nothing complained.
            config = {}
            for cseg in tok.split("#")[1:]:
                if ":" in cseg:
                    ck, cv = cseg.split(":", 1)
                    if ck.strip():
                        config[ck.strip()] = cv.strip()
            under = struct[r][c] if r < len(struct) and c < len(struct[r]) else 0
            # a body ON a "p"/"p:N" platform stands on the platform's own
            # height (parity with em-pack's plinths dict and _derive_map_row)
            raw_under = str(raw[r][c]).strip() if r < len(raw) and c < len(raw[r]) else ""
            plat_h = 0.0
            if raw_under == "p" or raw_under.startswith("p:"):
                plat_h = float(under)
            tc = [c - c0, r - r0]
            arts.append({
                "token": name, "cell": list(tc), "tile_cell": list(tc),
                "rotation": ((rot % 360) + 360) % 360,
                "mode": "freestanding", "venue": "interior",
                "support_height_m": plat_h if plat_h > 0.0 else (0.95 if under >= 2 else 0.0),
                # hand stays FALSE: the curator's rulings may rebind by
                # nearest when the plan re-derives (hand:true blocks rebind —
                # that is bake_rulings' contract, not the map's)
                "hand": False, "ruled": {"by": "map: " + map_name, "cell": list(tc)},
                **({"config": config} if config else {}),
            })
    # OUTDOOR HALLS (2026-08-24, Palle: "the first outdoor space courtyard to
    # host the long portal corridor" / "open roof, the Durer example"): a map
    # declares map_info.museum.open_roof and the museum skips that hall's
    # ceiling (dress_segment's "ceiling" flag, the one roof feed).
    open_roof = bool(md.get("map_info", {}).get("museum", {}).get("open_roof", False))
    # THE BASIN (2026-08-24, Palle: "like a basin with walls under the floor,
    # like a pool ... covered with transparent glass so we can walk over it"):
    # map_info.museum.basin {depth, glass} rides the row; the museum sinks the
    # hall's enclosed void regions into glass-covered pools (and re-reads the
    # map fresh each build — this copy serves /transplant and the plan readers).
    basin = md.get("map_info", {}).get("museum", {}).get("basin")
    # museum.simulation {depth, margin}: the courtyard pattern in one key —
    # the museum synthesizes roof/basin/margins from it at build time; the
    # copy here serves the plan readers.
    simulation = md.get("map_info", {}).get("museum", {}).get("simulation")
    # museum.passage {kind, width, offset, side}: the hall owns its crossing
    # (the museum builds it; this copy serves the plan readers and /paint)
    passage = md.get("map_info", {}).get("museum", {}).get("passage")
    return {
        "museum": museum_key,
        **({"open_roof": True} if (open_roof or isinstance(simulation, dict)) else {}),
        **({"basin": basin} if isinstance(basin, dict) else {}),
        **({"simulation": simulation} if isinstance(simulation, dict) else {}),
        **({"passage": passage} if isinstance(passage, dict) else {}),
        "tile": tile, "h": len(tile),
        "rooms": 0, "artifacts": arts, "rejected": [],
        "room": {"w": len(tile[0]) if tile else 0, "h": len(tile)}, "apron": 0,
        "interior_count": sum(1 for tr in tile for cv in tr if cv == "1"),
        "ordered": True, "pages": [],
        "sequence": chapter, "pearl": pearl, "pearl_index": idx,
        "map": map_name, "pearls_total": total,
        "authored": "map",
        "source": "em_map_halls: the map IS the hall",
    }


def build(plan: dict) -> dict:
    out = copy.deepcopy(plan)
    for chapter, pairs in declared().items():
        rows_for = [r for r in plan["plans"] if r.get("sequence") == chapter]
        if not rows_for:
            print(f"  ! chapter '{chapter}' has no plan rows — skipped")
            continue
        museum_key = rows_for[0]["museum"]
        new_rows = [derive_row(p, m, museum_key, i, len(pairs), chapter)
                    for i, (p, m) in enumerate(pairs)]
        out["plans"] = [r for r in out["plans"] if r.get("sequence") != chapter] + new_rows
        print(f"  {chapter}: {len(new_rows)} map-authored hall(s) replace {len(rows_for)} dealt row(s)")
        for row in new_rows:
            firsts = {a["token"]: a["tile_cell"] for a in row["artifacts"][:2]}
            print(f"    {row['pearl']:<12} {row['map']:<14} tile {row['room']['w']}x{row['h']}"
                  f"  artifacts {len(row['artifacts'])}  first: {firsts}")
    return out


def main() -> None:
    apply_live = "--apply" in sys.argv
    plan = json.loads(LIVE.read_text(encoding="utf-8"))
    patched = build(plan)
    if apply_live:
        BACKUP.write_text(json.dumps(plan), encoding="utf-8")
        LIVE.write_text(json.dumps(patched), encoding="utf-8")
        print(f"APPLIED -> {LIVE.name} (backup: {BACKUP.name})")
        subprocess.run([sys.executable, str(ROOT / "tools" / "em_ship.py")], cwd=ROOT, check=False)
    else:
        OUT.write_text(json.dumps(patched), encoding="utf-8")
        print(f"trial plan -> {OUT.name} (live untouched; --apply to make it the museum)")


if __name__ == "__main__":
    main()
