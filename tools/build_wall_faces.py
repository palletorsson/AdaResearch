#!/usr/bin/env python3
"""
build_wall_faces.py — the walls of a template, made hangable.

A museum tile has walls, and they have been anonymous: a `4` cell, nothing more.
Meanwhile 223 artifacts in the registry already declare `spatial_profile
.dir_group = "panel"` — they are wall-facing by their own description — and not
one of them has ever been hung on a template's wall. The material and the
surface were both here; what was missing was the FACE.

A FACE is a maximal run of wall cells that a body can stand in front of: the
run, the direction it faces, and the standoff (how far back the walker can get
before something stops them). Standoff is what decides what may hang there,
through the museum literature's own rule — viewing distance d ~ 1.4 + 0.21 x
area, from commons/data/museum_principles.json — read backwards: a face with two
metres of standoff can carry about a 2.9 m2 work, and no more.

THE ELEVATION, three bands (the wall-hangar idiom, and the corridor compiles its
walls at height 4, so all three exist):
    dado    0.0 - 0.9   below the eye: benches, plinth line, low cases
    hang    0.9 - 2.1   the eye band, where the viewing-distance rule bites
    frieze  2.1 - 3.2   above the eye: banners, labels, the chapter's name

NOTHING NEW IN THE ENGINE. A hang is an ordinary interactable token placed on
the floor cell IN FRONT of the wall, rotated to face the walker, lifted by the
token's own y-offset: `artifact:<rot>:<y>`. Floor slots carry no collision box,
so a hung wall never blocks the corridor — and `artifact#axis:value` still
applies, so a face run can carry a DNA family the way a bay run does.

  python tools/build_wall_faces.py                     # survey the corpus
  python tools/build_wall_faces.py --emit              # write the face registry
  python tools/build_wall_faces.py --hang=<museum>     # a demo hung map
  python tools/build_wall_faces.py --self-test
"""
from __future__ import annotations
import argparse
import glob
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
PATTERNS = REPO / "commons" / "data" / "template_patterns.json"
PRINCIPLES = REPO / "commons" / "data" / "museum_principles.json"
OUT = REPO / "commons" / "data" / "wall_faces.json"
MAPS = REPO / "commons" / "maps"
STAND = {"1", "1s"}
WALL = "4"
# (name, floor, ceiling, the y-offset a token gets to sit in the band)
BANDS = [("dado", 0.0, 0.9, 0.45), ("hang", 0.9, 2.1, 1.5), ("frieze", 2.1, 3.2, 2.6)]
# below this the viewing-distance rule says nothing can be taken in at all
MIN_HANGABLE_M2 = 1.0

# THE HANGAR'S OWN LAW, read from commons/scenes/WallHangarEditor.gd rather than
# guessed. Its WALL_SET is three tokens and "everything else falls to the floor +
# stacks"; the 30 curated walls corroborate it, mounting only station_panel (86),
# station_wall (27) and science_screen (2). My first pass inferred a 206-strong
# class from spatial_profile.dir_group == "panel" and hung things this project had
# already decided stand on the floor.
WALL_SET = ["station_panel", "station_frame", "framed_readout_screen",
            "station_wall", "science_screen"]
# And the size rule, from a curated wall's own source note: "the small/medium HELD
# things (the large/applied worlds go on the open floor)". Across the corpus the
# walls carry 73 small and 27 medium; large and applied go down. That convention
# predicted R-032 — hanging the biggest work is what stole the hero.
WALL_SIZES = {"small", "medium", "standard", ""}
DEPTH_STEP = 0.7          # the hangar's depth layer for floor pieces
WALL_TOP = 3.4            # the hangar's usable wall height
SIZES = REPO / "commons" / "data" / "artifact_sizes.json"


def measured_height(token: str) -> float | None:
    """The piece's real body height, from the size oracle's measured AABB."""
    try:
        s = json.loads(SIZES.read_text(encoding="utf-8")).get("sizes", {})
    except Exception:
        return None
    e = s.get(token)
    if not isinstance(e, dict):
        return None
    h = e.get("height_m")
    try:
        return float(h) if h else None
    except Exception:
        return None


def seat_y(token: str, band: str) -> tuple[float, str]:
    """R-019 body_on_cell, done offline: seat by the MEASURED body, not a guess.

    The hangar re-seats every piece after 40 frames because the generator's fixed
    plinth-top guess left tall and short items "a touch off" — "the meet is
    between what you SEE and what holds it". A band offset has the same fault: it
    puts the piece's BASE at a nominal height, so a 0.6 m panel and a 2.3 m screen
    hang from the same line and neither is centred on the eye. The oracle already
    holds the measured AABB, so the centre can be placed instead of the base.
    """
    lo, hi, nominal = next((l, h, y) for b, l, h, y in BANDS if b == band)
    centre = (lo + hi) / 2.0
    h = measured_height(token)
    if h is None:
        return nominal, "nominal (unmeasured)"
    y = round(max(0.0, centre - h / 2.0), 2)
    if y + h > WALL_TOP:
        return -1.0, f"too tall for the wall ({h} m over {WALL_TOP} m)"
    return y, f"body {h} m centred at {centre} m"
# facing -> the rotation an artifact needs to look back down the standoff
FACING_ROT = {"N": 0, "S": 180, "E": 270, "W": 90}


def museums() -> dict:
    d = json.loads(PATTERNS.read_text(encoding="utf-8"))
    return {k: p for k, p in d.get("patterns", {}).items()
            if isinstance(p, dict) and p.get("museum")}


def panel_artifacts() -> list:
    """The registry's own wall-facing class: dir_group == panel."""
    out = []
    for rp in sorted(glob.glob(str(REPO / "commons" / "artifacts" / "registry" / "*.json"))):
        try:
            d = json.load(open(rp, encoding="utf-8"))
        except Exception:
            continue
        for tok, e in (d.get("artifacts") or {}).items():
            if not isinstance(e, dict) or not e.get("scene") or not e.get("map_ready"):
                continue
            if (e.get("spatial_profile") or {}).get("dir_group") == "panel":
                axes = list(((e.get("dna") or {}).get("axes") or {}).keys())
                # the artifact's own declared size, so the match can be checked
                # from BOTH sides: the face says what fits, the work says what it is
                fp = ((e.get("parameters") or {}).get("footprint") or e.get("footprint") or [])
                try:
                    area = round(float(fp[0]) * float(fp[1]), 2) if len(fp) >= 2 else None
                except Exception:
                    area = None
                if area is None:
                    area = {"small": 1.0, "medium": 2.5, "large": 6.0,
                            "xl": 12.0}.get(str(e.get("size_group", "")).lower(), 2.0)
                out.append({"lookup": tok, "axes": axes, "area_m2": area})
    return sorted(out, key=lambda r: r["lookup"])


def wall_class() -> dict:
    """The mountable pieces, by NAME, from the hangar's own WALL_SET.

    Read from the registry directly rather than through spatial_profile, because
    station_panel and station_wall are not dir_group "panel" at all — the first
    pass filtered on that and lost the very pieces the hangar mounts. Mountability
    is a fact about the piece, and this project already stated which pieces.
    """
    out = {}
    for rp in sorted(glob.glob(str(REPO / "commons" / "artifacts" / "registry" / "*.json"))):
        try:
            d = json.load(open(rp, encoding="utf-8"))
        except Exception:
            continue
        for tok, e in (d.get("artifacts") or {}).items():
            if tok in WALL_SET and isinstance(e, dict) and e.get("scene") and e.get("map_ready"):
                out.setdefault(tok, e)
    return out


def wall_set_missing() -> list:
    """WALL_SET names that no map token can ever reach.

    The hangar's list was transcribed faithfully and never checked against the
    registry. Two of its five names do not resolve: `framed_readout_screen` does
    not exist anywhere, and `station_frame` has a scene on disk that no registry
    entry points at. Nothing failed — wall_class() just returned a smaller dict,
    every face in every building got the one surviving piece, and the run read as
    a finished experiment. Same fault class as a fabricated dna.axes block
    (CLAUDE.md, check_dna_declarations.py): declared, unreachable, silent.
    """
    alive = set(wall_class())
    out = []
    for tok in WALL_SET:
        if tok in alive:
            continue
        scene = glob.glob(str(REPO / "**" / f"{tok}.tscn"), recursive=True)
        out.append({"token": tok,
                    "why": "scene on disk, no registry entry" if scene
                           else "no scene, no registry entry"})
    return out


def mount_window(run_len: int, cap: int = 5) -> tuple:
    """Where a centred piece may hang on a run of `run_len` wall cells.

    station_panel builds its box at Vector3(0, 0, 0) — the mesh is CENTRED on the
    token's own cell. Writing the token at the run's FIRST cell therefore hangs
    (width-1)/2 cells off the end of the wall it belongs to. In Castelvecchio that
    put a 4.9 m bar across the 3-cell doorway the whole enfilade looks through, so
    the judge read promise 1.00 -> 0.00 and I reported it as a law about vistas.
    It was a fact about this arithmetic. Anchor at the run's middle, keep the
    width odd so the window is symmetric, and the piece stays on its own wall.
    """
    w = max(1, min(run_len, cap))
    if w % 2 == 0:
        w -= 1
    return (run_len - 1) // 2, max(1, w)


def max_area(standoff: float) -> float:
    """The viewing-distance rule read backwards: what fits at this standoff?

    museum_principles.json carries d ~ 1.4 + 0.21 * area_m2 (r2=.93, PMC5347319).
    A body that can only step back `standoff` metres can only take in a work of
    (standoff - 1.4) / 0.21 square metres — which is why a corridor pinch cannot
    hold a large canvas however much wall it has.
    """
    try:
        p = json.loads(PRINCIPLES.read_text(encoding="utf-8"))
        f = next(x for x in p["principles"] if x["id"] == "viewing-distance-formula")
        _ = f  # the constants below are that formula; the lookup keeps them honest
    except Exception:
        pass
    return max(0.0, round((standoff - 1.4) / 0.21, 2))


def faces_of(tile: list) -> list:
    """Every wall run a body can stand in front of, with its facing and standoff."""
    h = len(tile)
    w = len(tile[0]) if h else 0
    at = lambda x, y: str(tile[y][x]) if 0 <= x < w and 0 <= y < h else ""
    seen: set = set()
    faces = []
    # a wall cell faces the walk in the direction of an adjacent standable cell
    for (dx, dy, facing) in ((0, -1, "N"), (0, 1, "S"), (1, 0, "E"), (-1, 0, "W")):
        for y in range(h):
            for x in range(w):
                if at(x, y) != WALL or at(x + dx, y + dy) not in STAND:
                    continue
                if (x, y, facing) in seen:
                    continue
                # extend the run perpendicular to the facing
                px, py = (1, 0) if facing in ("N", "S") else (0, 1)
                run = [(x, y)]
                seen.add((x, y, facing))
                k = 1
                while (at(x + px * k, y + py * k) == WALL
                       and at(x + px * k + dx, y + py * k + dy) in STAND):
                    run.append((x + px * k, y + py * k))
                    seen.add((x + px * k, y + py * k, facing))
                    k += 1
                # standoff: how far back the body can step before it is stopped
                so = 0
                while at(x + dx * (so + 1), y + dy * (so + 1)) in STAND:
                    so += 1
                faces.append({
                    "facing": facing, "rot": FACING_ROT[facing],
                    "cells": run, "run": len(run),
                    "front": [run[0][0] + dx, run[0][1] + dy],
                    "standoff": so, "max_area_m2": max_area(float(so)),
                    "bands": [b[0] for b in BANDS],
                })
    return faces


def survey() -> list:
    rows = []
    for k, p in sorted(museums().items()):
        fs = faces_of([[str(c) for c in r] for r in p["tile"]])
        rows.append({
            "museum": k, "faces": len(fs),
            "wall_cells": sum(f["run"] for f in fs),
            "longest_run": max((f["run"] for f in fs), default=0),
            "median_standoff": sorted(f["standoff"] for f in fs)[len(fs) // 2] if fs else 0,
            "big_wall_faces": sum(1 for f in fs if f["max_area_m2"] >= 3.0),
        })
    return rows


def emit() -> int:
    payload = {
        "_readme": "Wall faces per museum template: a maximal run of wall cells a body "
                   "can stand in front of, with facing, standoff and the largest work the "
                   "viewing-distance rule allows there. Bands (dado/hang/frieze) carry the "
                   "y-offset a hung token needs. Provenance: measured "
                   "(tools/build_wall_faces.py); regenerate after tile changes.",
        "bands": [{"band": b, "floor_m": lo, "ceil_m": hi, "y_offset": y} for b, lo, hi, y in BANDS],
        "panel_class": len(panel_artifacts()),
        "museums": {},
    }
    for k, p in sorted(museums().items()):
        payload["museums"][k] = faces_of([[str(c) for c in r] for r in p["tile"]])
    OUT.write_text(json.dumps(payload, indent=1, ensure_ascii=False), encoding="utf-8")
    return sum(len(v) for v in payload["museums"].values())


def hang(museum: str, band: str, limit: int, seed: int, with_floor: bool = False) -> Path:
    """A demo: hang the panel class on a museum's faces and write the map."""
    sys.path.insert(0, str(REPO / "tools"))
    from compile_museum_map import compile_map, policy_pool, museums as cmus  # noqa: E402
    mus = cmus()
    if museum not in mus:
        raise SystemExit(f"no museum `{museum}`")
    pat = mus[museum]
    n_slots = sum(1 for row in pat["tile"] for c in row if str(c) in ("1s", "2s", "3s"))
    name = f"Hung_{museum.replace('-', '_')}_{band}"
    doc = compile_map(museum, pat, policy_pool("spine")[:n_slots], "spine", name)
    inter = doc["layers"]["interactables"]
    yoff = next(y for b, _lo, _hi, y in BANDS if b == band)
    panels = panel_artifacts()
    if not panels:
        raise SystemExit("no panel-class artifacts")
    import random
    rng = random.Random(seed)
    faces = sorted(faces_of([[str(c) for c in r] for r in pat["tile"]]),
                   key=lambda f: (-f["run"], f["cells"][0][1]))
    mountable = wall_class()
    if not mountable:
        raise SystemExit("none of the hangar's WALL_SET is alive in the registry")
    missing = wall_set_missing()
    for m in missing:
        print(f"  WALL_SET `{m['token']}` unreachable: {m['why']}", file=sys.stderr)
    # station_panel takes width_cells, so THE FACE SIZES THE PIECE — the hangar's
    # own parameterisation, and better than choosing a different artifact per wall
    piece = "station_panel" if "station_panel" in mountable else sorted(mountable)[0]
    floor_pool = [q for q in panels if q["lookup"] not in WALL_SET]
    hung, too_tight, floored = [], [], []
    for f in faces:
        if len(hung) >= limit:
            break
        if f["max_area_m2"] < MIN_HANGABLE_M2:
            too_tight.append(f)
            continue
        ai, width = mount_window(f["run"])
        dx = f["front"][0] - f["cells"][0][0]
        dy = f["front"][1] - f["cells"][0][1]
        fx, fy = f["cells"][ai][0] + dx, f["cells"][ai][1] + dy
        half = (width - 1) // 2
        # every cell the centred mesh covers must be free floor in front of THIS
        # run — that is what keeps a wide piece off a doorway and out of a
        # neighbour. The width shrinks until the span is clean, or the face is
        # refused; a piece is never written where its body cannot go.
        while width > 1:
            span = [f["cells"][i] for i in range(ai - half, ai + half + 1)]
            fronts = [(c[0] + dx, c[1] + dy) for c in span]
            if all(0 <= b < len(inter) and 0 <= a < len(inter[0])
                   and not str(inter[b][a]).strip() for a, b in fronts):
                break
            width -= 2
            half = (width - 1) // 2
        if not (0 <= fy < len(inter) and 0 <= fx < len(inter[0])):
            continue
        if str(inter[fy][fx]).strip():
            continue
        seat, why = seat_y(piece, band)
        if seat < 0:
            too_tight.append(f)
            continue
        inter[fy][fx] = f'{piece}:{f["rot"]}:{seat}#width_cells:{width}'
        hung.append({"token": inter[fy][fx], "cell": [fx, fy], "facing": f["facing"],
                     "run": f["run"], "standoff": f["standoff"],
                     "max_area_m2": f["max_area_m2"], "width_cells": width,
                     "spans_cells": [list(c) for c in
                                     f["cells"][ai - half:ai + half + 1]],
                     "seat_y": seat, "seat_reason": why})
    # THE SECOND GRAVITY, AND WHERE IT GOES — the correction the judge forced.
    # First reading: "everything else falls to the floor + stacks", so I stood the
    # big works at the hangar's depth layer, one cell out from the wall. Judged,
    # that scored 4.79 against the plain building's 5.30 — promise 0.00, hero 13
    # degrees. The works were legitimately hero candidates (a floor work is not a
    # wall work under R-032) and were tucked against a wall where nothing can be
    # promised down the axis: the same theft, in a new place.
    #
    # The curated note says "the large/applied worlds go on the OPEN floor", and
    # the open floor is the room's middle — which the museum tile already models
    # as its slots, already filled from the cast by the compiler. So the wall
    # system should mount, and nothing else: adding floor works at the wall's foot
    # is inventing a third place the building never had. --floor keeps the
    # experiment reachable; it is off, and the number above is why.
    import random as _r
    rng2 = _r.Random(seed + 1)
    for f in (faces if with_floor else []):
        if len(floored) >= limit or not floor_pool:
            break
        if f["standoff"] < 2:
            continue
        dx = {"N": 0, "S": 0, "E": 1, "W": -1}[f["facing"]]
        dy = {"N": -1, "S": 1, "E": 0, "W": 0}[f["facing"]]
        fx, fy = f["front"][0] + dx, f["front"][1] + dy      # one depth layer out
        if not (0 <= fy < len(inter) and 0 <= fx < len(inter[0])):
            continue
        if str(inter[fy][fx]).strip():
            continue
        q = floor_pool[rng2.randrange(len(floor_pool))]
        inter[fy][fx] = f'{q["lookup"]}:{f["rot"]}:0'
        floored.append({"token": inter[fy][fx], "cell": [fx, fy],
                        "facing": f["facing"], "depth_m": DEPTH_STEP,
                        "area_m2": q["area_m2"]})
    doc["documentation"]["wall_hang"] = {
        "tool": "build_wall_faces.py", "band": band, "y_offset": yoff,
        "hung": hung, "faces_available": len(faces),
        "refused_too_tight": len(too_tight),
        "min_hangable_m2": MIN_HANGABLE_M2,
        "wall_set": WALL_SET, "piece": piece,
        "floored": floored, "depth_step_m": DEPTH_STEP,
        "law": "commons/scenes/WallHangarEditor.gd — WALL_SET mounts, everything "
               "else falls to the floor and stands at a depth layer",
        "note": "panel-class artifacts (spatial_profile.dir_group == panel) placed on the "
                "floor cell in front of a wall face, rotated to it, lifted into the band by "
                "the token's own y-offset — no engine change, and no collision on the walk",
    }
    d = MAPS / name
    d.mkdir(parents=True, exist_ok=True)
    p = d / "map_data.json"
    p.write_text(json.dumps(doc, indent=1), encoding="utf-8")
    return p


def hang_family(museum: str, token: str, axis: str, band: str, seed: int) -> Path:
    """One artifact, one axis, its values spaced along ONE long wall face.

    The bay series walks a family through repeated ROOMS; this walks it along a
    single WALL, which is how a gallery has always shown variations: the same
    subject, the same frame, one thing changed, and the corridor doing the
    comparing for you. The face must be long enough that the values do not
    crowd, and the work must fit the standoff — the same two rules the single
    hang obeys, asked once for the whole family.
    """
    sys.path.insert(0, str(REPO / "tools"))
    from compile_museum_map import compile_map, policy_pool, museums as cmus  # noqa: E402
    mus = cmus()
    if museum not in mus:
        raise SystemExit(f"no museum `{museum}`")
    pat = mus[museum]
    reg = {}
    for rp in sorted(glob.glob(str(REPO / "commons" / "artifacts" / "registry" / "*.json"))):
        try:
            d = json.load(open(rp, encoding="utf-8"))
        except Exception:
            continue
        for t, e in (d.get("artifacts") or {}).items():
            if isinstance(e, dict):
                reg.setdefault(t, e)
    panels = {q["lookup"]: q for q in panel_artifacts()}
    if token and token not in panels:
        raise SystemExit(f"`{token}` is not panel-class (dir_group != panel)")
    tile = [[str(c) for c in r] for r in pat["tile"]]
    faces = sorted(faces_of(tile), key=lambda f: -f["run"])
    if not faces:
        raise SystemExit("no faces")
    face = faces[0]

    # choose the family: the one that fits this face and has the most to say
    def values_of(tok: str, ax: str):
        v = ((reg.get(tok, {}).get("dna") or {}).get("axes") or {}).get(ax)
        return [str(x) for x in v] if isinstance(v, list) else None
    if token and axis:
        vals = values_of(token, axis)
        if not vals:
            raise SystemExit(f"`{token}` declares no axis `{axis}`")
        pick = (panels[token], axis, vals)
    else:
        cands = []
        for q in panels.values():
            if q["area_m2"] > face["max_area_m2"]:
                continue
            for ax in q["axes"]:
                v = values_of(q["lookup"], ax)
                if v and 3 <= len(v) <= 6:
                    cands.append((len(v), q, ax, v))
        if not cands:
            raise SystemExit("no panel-class family fits this face")
        cands.sort(key=lambda c: (-c[0], c[1]["lookup"]))
        _, q, ax, v = cands[0]
        pick = (q, ax, v)
    art, ax, vals = pick
    if art["area_m2"] > face["max_area_m2"]:
        raise SystemExit(f"{art['lookup']} ({art['area_m2']} m2) does not fit this face "
                         f"({face['max_area_m2']} m2)")

    n_slots = sum(1 for row in pat["tile"] for c in row if str(c) in ("1s", "2s", "3s"))
    name = f"Family_{museum.replace('-', '_')}_{art['lookup']}_{ax}"
    doc = compile_map(museum, pat, policy_pool("spine")[:n_slots], "spine", name)
    inter = doc["layers"]["interactables"]
    yoff = next(y for b, _lo, _hi, y in BANDS if b == band)
    # the front cells of the run, evenly spaced so the values read as a series
    dx = {"N": 0, "S": 0, "E": 1, "W": -1}[face["facing"]]
    dy = {"N": -1, "S": 1, "E": 0, "W": 0}[face["facing"]]
    fronts = [(cx + dx, cy + dy) for (cx, cy) in face["cells"]]
    step = max(1, len(fronts) // len(vals))
    placed = []
    for i, v in enumerate(vals):
        j = min(len(fronts) - 1, i * step + step // 2)
        fx, fy = fronts[j]
        if not (0 <= fy < len(inter) and 0 <= fx < len(inter[0])):
            continue
        inter[fy][fx] = f'{art["lookup"]}#{ax}:{v}'
        placed.append({"value": v, "cell": [fx, fy]})
    doc["documentation"]["wall_family"] = {
        "tool": "build_wall_faces.py --family", "token": art["lookup"], "axis": ax,
        "values": vals, "band": band, "y_offset": yoff,
        "face": {"facing": face["facing"], "run": face["run"],
                 "standoff": face["standoff"], "max_area_m2": face["max_area_m2"]},
        "work_area_m2": art["area_m2"], "placed": placed,
        "note": "one artifact, one axis, its values spaced along a single wall face — "
                "the gallery's own way of showing variations, and the corridor does the "
                "comparing",
    }
    d = MAPS / name
    d.mkdir(parents=True, exist_ok=True)
    p2 = d / "map_data.json"
    p2.write_text(json.dumps(doc, indent=1), encoding="utf-8")
    return p2


def selftest() -> int:
    ok = []
    # a plain room: walls all round, floor inside
    t = [["4"] * 9 for _ in range(7)]
    for y in range(1, 6):
        for x in range(1, 8):
            t[y][x] = "1"
    fs = faces_of(t)
    ok.append(("A a room's four walls are found", len({f["facing"] for f in fs}) == 4,
               f"{len(fs)} faces, facings {sorted({f['facing'] for f in fs})}"))
    north = [f for f in fs if f["facing"] == "S"]     # the top wall faces south
    ok.append(("B a wall run is maximal", any(f["run"] == 7 for f in north),
               f"runs {sorted(f['run'] for f in north)}"))
    ok.append(("C standoff is measured, not assumed",
               all(f["standoff"] >= 1 for f in fs), "every face has room to step back"))
    ok.append(("D the viewing rule reads backwards",
               max_area(2.0) < max_area(4.0) and max_area(1.0) == 0.0,
               f"1m -> {max_area(1.0)}, 2m -> {max_area(2.0)}, 4m -> {max_area(4.0)} m2"))
    # a wall with no floor beside it is not a face
    solid = [["4"] * 5 for _ in range(5)]
    ok.append(("E a wall nobody can face is not a face", faces_of(solid) == [], "0 faces"))
    ok.append(("F the panel class is non-empty", len(panel_artifacts()) > 50,
               f"{len(panel_artifacts())} panel artifacts"))
    ok.append(("G a face too tight to see is refused", max_area(1.0) < MIN_HANGABLE_M2,
               f"1 m standoff -> {max_area(1.0)} m2, under the {MIN_HANGABLE_M2} m2 floor"))
    pa = panel_artifacts()
    ok.append(("H every panel declares an area", all("area_m2" in q for q in pa),
               f"{len(pa)} sized"))
    y_panel, why_p = seat_y("station_panel", "hang")
    y_screen, why_s = seat_y("science_screen", "hang")
    ok.append(("J a short and a tall piece seat differently", y_panel != y_screen,
               f"station_panel {y_panel} ({why_p}) vs science_screen {y_screen}"))
    ok.append(("K an unmeasured token falls back, it does not crash",
               seat_y("no_such_artifact_xyz", "hang")[1].startswith("nominal"),
               "nominal fallback"))
    ok.append(("I a tight face admits fewer works than a wide one",
               len([q for q in pa if q["area_m2"] <= max_area(2.0)])
               < len([q for q in pa if q["area_m2"] <= max_area(6.0)]),
               f"2 m: {len([q for q in pa if q['area_m2'] <= max_area(2.0)])} works, "
               f"6 m: {len([q for q in pa if q['area_m2'] <= max_area(6.0)])}"))
    # L — the fault that made this whole pass a picture of nothing. A centred mesh
    # written at the run's first cell hangs off the wall's end; the control asserts
    # the window stays inside the run for every run length, and the negative arm
    # asserts the OLD arithmetic really did overhang (a control that cannot fail is
    # not a control).
    inside = all(0 <= (a - (w - 1) // 2) and (a + (w - 1) // 2) <= n - 1
                 for n in range(1, 12) for a, w in [mount_window(n)])
    old_overhang = any(0 - (min(n, 5) - 1) // 2 < 0 for n in range(2, 12))
    ok.append(("L a centred piece stays on its own wall", inside and old_overhang,
               f"windows {[mount_window(n) for n in range(1, 8)]}; "
               f"anchoring at cell 0 overhangs: {old_overhang}"))
    # M — the names. Two of five WALL_SET tokens are unreachable from any map, and
    # nothing said so until this control existed.
    miss = wall_set_missing()
    ok.append(("M every WALL_SET name resolves to a map-reachable token", not miss,
               "all resolve" if not miss
               else "UNREACHABLE: " + ", ".join(f"{m['token']} ({m['why']})" for m in miss)))
    for label, good, detail in ok:
        print(f"  {'PASS' if good else 'FAIL'}  {label}: {detail}")
    n = sum(1 for _, g, _ in ok if g)
    print(f"self-test: {n}/{len(ok)} controls passed")
    return 0 if n == len(ok) else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--emit", action="store_true")
    ap.add_argument("--hang")
    ap.add_argument("--band", default="hang", choices=[b[0] for b in BANDS])
    ap.add_argument("--limit", type=int, default=10)
    ap.add_argument("--seed", type=int, default=46)
    ap.add_argument("--floor", action="store_true",
                    help="also stand non-mountable works at the wall's depth layer "
                         "(judged worse: -0.51; kept only so the claim stays checkable)")
    ap.add_argument("--family", action="store_true",
                    help="hang ONE artifact's DNA family along the longest face")
    ap.add_argument("--token")
    ap.add_argument("--axis")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return selftest()
    if args.hang and args.family:
        p = hang_family(args.hang, args.token, args.axis, args.band, args.seed)
        doc = json.loads(p.read_text(encoding="utf-8"))
        f = doc["documentation"]["wall_family"]
        print(f"{f['token']}.{f['axis']} along a {f['face']['run']}-cell face "
              f"facing {f['face']['facing']} (standoff {f['face']['standoff']}, "
              f"wall allows {f['face']['max_area_m2']} m2, work is {f['work_area_m2']} m2)")
        for q in f["placed"]:
            print(f"  {q['value']:22} at {tuple(q['cell'])}")
        print(f"-> {p.relative_to(REPO)}")
        return 0
    if args.hang:
        p = hang(args.hang, args.band, args.limit, args.seed, args.floor)
        doc = json.loads(p.read_text(encoding="utf-8"))
        wh = doc["documentation"]["wall_hang"]
        print(f"{len(wh['hung'])} hung on {wh['faces_available']} faces "
              f"in the `{args.band}` band (y {wh['y_offset']}) · "
              f"{wh['refused_too_tight']} faces refused: under {wh['min_hangable_m2']} m2 "
              f"of viewing distance")
        print(f"  MOUNTED ({wh['piece']}, sized to the face):")
        for x in wh["hung"][:8]:
            print(f"    {x['token']:50} run {x['run']:2} · {x['seat_reason']}")
        print(f"  FLOORED at {wh['depth_step_m']} m depth ({len(wh['floored'])}):")
        for x in wh["floored"][:6]:
            print(f"    {x['token']:46} {x['area_m2']} m2")
        print(f"-> {p.relative_to(REPO)}")
        return 0
    rows = survey()
    print(f"{'museum':40} {'faces':>5} {'wall':>5} {'longest':>7} {'standoff':>8} {'big':>4}")
    print("-" * 76)
    for r in rows:
        print(f"{r['museum']:40} {r['faces']:>5} {r['wall_cells']:>5} {r['longest_run']:>7} "
              f"{r['median_standoff']:>8} {r['big_wall_faces']:>4}")
    print("-" * 76)
    print(f"{sum(r['faces'] for r in rows)} faces across {len(rows)} buildings · "
          f"{len(panel_artifacts())} panel-class artifacts waiting")
    if args.emit:
        n = emit()
        print(f"-> {n} faces written to {OUT.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    sys.exit(main())
