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
