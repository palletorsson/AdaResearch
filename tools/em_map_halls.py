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
              plinth = `#plinth:H` on the token (travels WITH the artifact;
              `#plinth:0` opts out), else a `p`/`p:N` platform, else the
              legacy structure-2-under-the-anchor rule -> support 0.95
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
    # WHERE THIS MAP'S FLOOR IS (2026-08-25, Palle: "the last transformation
    # hall has no way out"). Trans_Pit walks on height-3 slabs over fire, so
    # the default h>=2 rule read its entire floor as wall and derived a solid
    # block with holes where the fire was — the map INVERTED. map_info.museum
    # .wall_height says which height starts being a wall; everything above 0
    # and below it is floor. Default 2 = the rule every other map already has.
    mus_decl = (md.get("map_info", {}) or {}).get("museum", {}) or {}
    wall_h = int(mus_decl.get("wall_height", 2)) if isinstance(mus_decl, dict) else 2
    inter = md["layers"].get("interactables", [])
    # ORIGIN-PINNED (the ruling drift lesson: tile cells ARE map cells,
    # forever). Cropping to the content bbox moved (0,0) whenever the map's
    # content changed, which silently re-addressed every saved ruling —
    # walls, artifact moves, all of them. Only the FAR edges trim now.
    rows = [r for r, row in enumerate(struct) if any(v > 0 for v in row)]
    cols = [c for row in struct for c, v in enumerate(row) if v > 0]
    # artifacts can stand BEYOND the structure's content (interactables grid
    # larger than the built floor) — cropping to structure alone stranded 20
    # of them outside their own halls (measured 2026-08-29). The tile covers
    # every artifact cell too.
    for r, irow in enumerate(inter):
        for c, v in enumerate(irow):
            if str(v).strip() and str(v).strip() != "0":
                rows.append(r)
                cols.append(c)
    r0, r1 = 0, max(rows)
    c0, c1 = 0, max(cols)
    tile = []
    for r in range(r0, r1 + 1):
        line = []
        for c in range(c0, c1 + 1):
            v = struct[r][c] if r < len(struct) and c < len(struct[r]) else 0
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
                line.append("4" if v >= wall_h else ("1" if v >= 1 else "0"))
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

            # THE PLINTH IS A TAG ON THE ARTIFACT, NOT A HEIGHT UNDER IT.
            #
            # 2026-09-01, Palle: "when I move the line demo I drag the plinth and
            # then the line demo moves and the plinth thinks move another step,
            # very strange indeed. Can we move to a plinth system not based on
            # height but on plinth tag?"
            #
            # The bug is structural and the diagnosis is exactly right. A plinth
            # was `structure[r][c] >= 2` — a cell in the STRUCTURE layer — while
            # the artifact is a cell in INTERACTABLES. Two layers, two cells, and
            # a drag in the editor moves one of them. So the pedestal stays where
            # it was, or the artifact steps off it, and moving either one again
            # compounds the mismatch. Nothing was going to make that feel sane,
            # because the two things were never one thing.
            #
            # `#plinth:H` on the token makes them one thing: it travels with the
            # artifact because it IS the artifact's token. It is also the grid's
            # own existing spelling (`#plinth:0.66`, `#plinth:1.05,micropod`,
            # `#plinth:0` to opt out), so this teaches the museum a convention
            # the maps already use rather than inventing a second one.
            #
            # PRECEDENCE, and the legacy path is kept because 269 maps rely on it:
            #   1  #plinth:H   the tag wins, including #plinth:0 meaning NONE
            #   2  p / p:N     a platform in the utilities layer
            #   3  structure>=2  the old rule, still honoured where no tag says
            tag_h = None
            if "plinth" in config:
                head = str(config["plinth"]).split(",")[0].strip()
                try:
                    tag_h = float(head)
                except ValueError:
                    tag_h = 0.95          # `#plinth:micropod` etc — on, default
                if tag_h > 0.0 and tag_h < 0.25:
                    # em_plinths: the deck is max(top_height, 0.25) EXACTLY, so
                    # asking for less silently gets 0.25 and the artifact then
                    # sits higher than the plan says. Ask for what will be given.
                    tag_h = 0.25
            tc = [c - c0, r - r0]
            arts.append({
                "token": name, "cell": list(tc), "tile_cell": list(tc),
                "rotation": ((rot % 360) + 360) % 360,
                "mode": "freestanding", "venue": "interior",
                "support_height_m": (tag_h if tag_h is not None
                                     else (plat_h if plat_h > 0.0
                                           else (0.95 if under >= 2 else 0.0))),
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
    # museum.gate = false: this hall wants no sliding door
    gate = md.get("map_info", {}).get("museum", {}).get("gate")
    return {
        "museum": museum_key,
        **({"open_roof": True} if (open_roof or isinstance(simulation, dict)) else {}),
        **({"basin": basin} if isinstance(basin, dict) else {}),
        **({"simulation": simulation} if isinstance(simulation, dict) else {}),
        **({"passage": passage} if isinstance(passage, dict) else {}),
        **({"gate": bool(gate)} if gate is not None else {}),
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


def spine_names() -> list:
    """The sequences the curriculum actually has, in order."""
    p = ROOT / "commons" / "maps" / "curriculum_spine.json"
    doc = json.loads(p.read_text(encoding="utf-8"))
    rows = doc["spine"]["sequences"]
    return [str(r["name"]) for r in sorted(rows, key=lambda r: r.get("order", 0))]


# --- THE WIDTH-AND-WALLS RULING (2026-08-29, Palle: "all maps use be between
# 13 - 19 wide, all after color must have outer walls and if they have lit
# [little] structure give them museum structure") ---------------------------
#
# Derivation-side only: the SOURCE maps are untouched; the ruling normalizes
# the derived hall. Post-color chapters (change onward) additionally get an
# outer wall ring — with centred 3-cell door gaps on the walk axis, exactly
# the idiom TemplateMap_Promenade13's own walls use ("#####...#####"), so a
# ring never seals a hall. Bare halls (zero interior walls) get the museum's
# pier colonnade from the same templates ("..#...#...#.." every 4th row).

def _rotate_cw(tile: list, arts: list) -> list:
    h = len(tile)
    new = [[tile[h - 1 - r2][c2] for r2 in range(h)] for c2 in range(len(tile[0]))]
    for a in arts:
        x, y = a["tile_cell"]
        a["tile_cell"] = [h - 1 - y, x]
        a["cell"] = list(a["tile_cell"])
        a["rotation"] = (int(a.get("rotation", 0)) + 90) % 360
    return new


def normalize_row(row: dict, post_color: bool, dirlocked: bool,
                  width_exempt: bool = False) -> None:
    tile = row["tile"]
    arts = row["artifacts"]
    W = len(tile[0]) if tile else 0
    H = len(tile)
    # the ruling's ledger: everything done to this hall, so a writer can
    # replay the SAME transforms onto the source map (one implementation,
    # the long_museum drift scar) — em_ruling_to_maps.py reads it
    ruling = {"src_w": W, "src_h": H, "rotated": False, "pad": 0,
              "pad_closed": False, "ring": None}
    row["_ruling"] = ruling

    # rotate a fresh post-color hall when its depth CAN be a legal width but
    # its width cannot — landing anywhere in 11..19 works (<=17 gets the
    # expanding ring, 18-19 the in-place one). Width-exempt chapters (forces,
    # 2026-08-29: "force are not 13 to 19") keep their native orientation.
    if post_color and not dirlocked and not width_exempt and W > 19 and 11 <= H <= 19:
        tile = _rotate_cw(tile, arts)
        W, H = H, W
        ruling["rotated"] = True

    def _walled() -> bool:
        walls = 0
        border = 0
        for r in range(H):
            for c in range(W):
                if r in (0, H - 1) or c in (0, W - 1):
                    border += 1
                    if tile[r][c] == "4":
                        walls += 1
        # absolute allowance, not a fraction: a ring this pass built carries
        # two 3-cell doors, which is 12.5%% of a small hall's border — the
        # old 0.9 fraction re-ringed our own rings (the idempotence gate
        # caught 85 double-ringed halls, 2026-08-29)
        return walls >= border - 8

    ring_needed = post_color and not _walled()
    # pad RIGHT with floor — right-only, so cell (0,0) stays cell (0,0) and
    # nothing is re-addressed by the padding itself. The target depends on
    # whether a ring is coming: an expanding ring adds 2 to the width.
    lo = 11 if (ring_needed and W <= 17) else 13
    if width_exempt:
        lo = 0
    if W < lo:
        pad = lo - W
        for r, line in enumerate(tile):
            if post_color and not ring_needed:
                # an ALREADY-WALLED narrow hall grows a closed shelf: floor
                # strip, walled on its outer edge and its ends
                fill = "4" if r in (0, H - 1) else "1"
                line.extend([fill] * (pad - 1) + ["4"])
            else:
                line.extend(["1"] * pad)
        ruling["pad"] = pad
        ruling["pad_closed"] = post_color and not ring_needed
        W = lo

    art_cells = {tuple(a["tile_cell"]) for a in arts}
    if post_color:
        gap = set(range((W - 3) // 2, (W - 3) // 2 + 3))
        if ring_needed:
            if W <= 17 and not width_exempt:
                # EXPAND: wrap the ring outside; the door gaps north and south
                # are FLOOR thresholds (the templates' "#####...#####" idiom),
                # never holes
                top = ["4" if c not in {g + 1 for g in gap} else "1" for c in range(W + 2)]
                bot = list(top)
                tile = [top] + [["4"] + line + ["4"] for line in tile] + [bot]
                for a in arts:
                    a["tile_cell"] = [a["tile_cell"][0] + 1, a["tile_cell"][1] + 1]
                    a["cell"] = list(a["tile_cell"])
                W += 2
                H += 2
                ruling["ring"] = "expand"
            else:
                # IN-PLACE: the band has no room to grow — border floor
                # becomes wall, artifact cells and the door gaps spared
                for r in range(H):
                    for c in range(W):
                        if r not in (0, H - 1) and c not in (0, W - 1):
                            continue
                        if (c, r) in art_cells:
                            continue
                        if r in (0, H - 1) and c in gap:
                            continue
                        tile[r][c] = "4"
                ruling["ring"] = "inplace"
        art_cells = {tuple(a["tile_cell"]) for a in arts}
        # MUSEUM STRUCTURE for bare halls: the templates' pier colonnade —
        # piers on the 4-beat inside the ring, never on or beside a body
        interior_walls = sum(1 for r in range(1, H - 1) for c in range(1, W - 1) if tile[r][c] == "4")
        if interior_walls == 0 and H >= 8:
            near = set()
            for (x, y) in art_cells:
                for dx in (-1, 0, 1):
                    for dy in (-1, 0, 1):
                        near.add((x + dx, y + dy))
            stamped = 0
            for r in range(3, H - 2, 4):
                for c in range(2, W - 2, 4):
                    if tile[r][c] == "1" and (c, r) not in near:
                        tile[r][c] = "4"
                        stamped += 1
            if stamped:
                row["dressing"] = "piers: template colonnade x%d (bare map)" % stamped

    if post_color:
        # NO SEALED HALLS: the walk axis runs north-south, and a hall whose
        # first or last row is solid wall is a box (the walkable-end-to-end
        # scar). Carve the templates' centred 3-cell door, up to two rows
        # deep where the map's own wall is thick.
        gap = range((W - 3) // 2, (W - 3) // 2 + 3)
        for edge, step in ((0, 1), (H - 1, -1)):
            if all(tile[edge][c] == "4" for c in range(W)):
                for c in gap:
                    for depth in (0, 1):
                        rr = edge + step * depth
                        if 0 <= rr < H and tile[rr][c] == "4":
                            tile[rr][c] = "1"
        # AND A WAY THROUGH: a door onto a blocked interior is still a box.
        # Dijkstra from the north door to the south door, floor nearly free,
        # holes cheap to bridge, walls dear to breach, artifact cells never —
        # then carve the minimal path to floor. Measured before this existed:
        # 48 of the new halls had doors and no way between them.
        import heapq
        def cost(rr, cc):
            v = tile[rr][cc]
            if (cc, rr) in art_cells:
                return 100000
            if v == "4":
                return 60
            if v == "0":
                return 25
            return 1
        start = (0, W // 2)
        goal = (H - 1, W // 2)
        best = {start: cost(*start)}
        prev = {}
        pq = [(best[start], start)]
        while pq:
            d, (rr, cc) = heapq.heappop(pq)
            if (rr, cc) == goal:
                break
            if d > best.get((rr, cc), 1 << 30):
                continue
            for dr, dc in ((1, 0), (-1, 0), (0, 1), (0, -1)):
                n = (rr + dr, cc + dc)
                if 0 <= n[0] < H and 0 <= n[1] < W:
                    nd = d + cost(*n)
                    if nd < best.get(n, 1 << 30):
                        best[n] = nd
                        prev[n] = (rr, cc)
                        heapq.heappush(pq, (nd, n))
        carved = 0
        node = goal
        while node in prev or node == start:
            rr, cc = node
            if tile[rr][cc] in ("4", "0") and (cc, rr) not in art_cells:
                tile[rr][cc] = "1"
                carved += 1
            if node == start:
                break
            node = prev[node]
        if carved:
            row["dressing"] = (row.get("dressing", "") + (" | " if "dressing" in row else "")
                               + "channel: %d cell(s) carved for the walk" % carved)

    if (W > 19 or W < 13) and not width_exempt:
        print(f"    RULING VIOLATION {row['map']}: final width {W} outside 13-19 (content too large to conform)")

    row["tile"] = tile
    row["h"] = H
    row["room"] = {"w": W, "h": H}
    row["interior_count"] = sum(1 for line in tile for v in line if v == "1")


def build(plan: dict) -> dict:
    out = copy.deepcopy(plan)

    # A CHAPTER THAT LEFT THE SPINE MUST LEAVE THE WALK.
    #
    # Dissolving a sequence edits curriculum_spine.json; it does not touch the
    # plan, and nothing else was checking the two against each other. So the
    # museum kept walking two chapters that no longer exist: `symmetry` (6
    # halls) and `array_tutorial` (7), both folded into color on 2026-08-24 —
    # symmetry into the census room Symmetry_Seventeen, array_tutorial into
    # color's index and rule rungs. Thirteen halls of it, standing between
    # transformation and color, dealt from templates because a dissolved
    # chapter has no map-authored rows and no pool of its own.
    #
    # Found from the other end: Palle walked past transformation expecting
    # colour and got rooms they did not recognise.
    spine = set(spine_names())
    ghosts = sorted({str(r.get("sequence", "")) for r in out["plans"]} - spine)
    if ghosts:
        for g in ghosts:
            n = sum(1 for r in out["plans"] if r.get("sequence") == g)
            print(f"  DROPPED '{g}' — {n} hall(s) in the plan, not in the spine")
        out["plans"] = [r for r in out["plans"] if str(r.get("sequence", "")) in spine]
    for chapter, pairs in declared().items():
        rows_for = [r for r in plan["plans"] if r.get("sequence") == chapter]
        if not rows_for:
            print(f"  ! chapter '{chapter}' has no plan rows — skipped")
            continue
        museum_key = rows_for[0]["museum"]
        new_rows = [derive_row(p, m, museum_key, i, len(pairs), chapter)
                    for i, (p, m) in enumerate(pairs)]
        # the width-and-walls ruling: 13-19 wide everywhere; ring + piers
        # for every chapter after color (the ruling's own boundary)
        order = spine_names()
        post = chapter in order and order.index(chapter) > order.index("color")
        for row in new_rows:
            dirlocked = any(k in row for k in ("basin", "passage", "simulation"))
            normalize_row(row, post, dirlocked, width_exempt=(chapter == "forces"))
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
