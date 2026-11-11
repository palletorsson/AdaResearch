#!/usr/bin/env python3
"""THE ARRIVAL WORKLIST: every floor of the Void tower read from where the player lands (doc/WORLD_UNITS.md, the
arrival rule; Palle, 2026-11-11: "sort the floors into a worklist").

From data alone - commons/void/rooms.json (placements, props, walls, routes), commons/void/layout.json (spawn points),
commons/void/catalog.json (prop sizes), commons/data/artifact_timeline.json (the order) and the measured boxes of the
last tower-wide size survey (ada_run/void-size-survey/all-*/survey.json, each box moved with its work) - it asks of
each floor, standing at its spawn point and looking at the middle of the slab:

    1 inside      the spawn point is inside a compact work's box             (the player arrives in it)
    2 in the face something taller than 0.8 m stands in the first 3 m ahead  (a wall, a back, a ramp)
                  - boxes, not bodies: a hall or a ground the player is meant to stand in (a box of 60 m2 or more,
                    or any box around the spawn point) is not counted, and an open frame still is
    3 nothing     at most one work lies ahead within 18 m                    (the player sees a bare slab)
    4 order       the floor's first works in timeline order are its farthest (space and timeline disagree)
    5 hero behind the floor's biggest work is not ahead
    6 thin        three works or fewer and no staging (no wall, prop, route or carrier)
    7 reads       none of the above

A floor gets its WORST finding as its class and keeps the others as notes. It is a sorter, not a verdict: the picture
(tools/blender/ada_void/arrival.py, tools/void_arrival_shots.py) and the walk decide.

    python tools/void_arrival_worklist.py [--markdown] [--json=ada_run/arrival_worklist.json] [--floors=77-92]
"""
from __future__ import annotations

import glob
import json
import math
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CLASSES = ["inside", "in the face", "nothing ahead", "order", "hero behind", "thin", "reads"]
ENCLOSURE = 60.0      # m2: a work whose box is this large is a room or a ground, not an obstacle


def measured() -> dict:
    """(map, placement id) -> (at [x, z], box [x0, y0, z0, x1, y1, z1]) from the last tower-wide size survey"""
    out = {}
    for p in glob.glob(str(ROOT / "ada_run/void-size-survey/all-*/survey.json")):
        for f in json.loads(Path(p).read_text(encoding="utf-8"))["floors"].values():
            for w in f.get("works", []):
                if w.get("box") and w.get("at") and all(isinstance(v, (int, float)) for v in list(w["box"]) + list(w["at"])):
                    out[(f.get("map"), w["id"])] = (w["at"], w["box"])
    return out


def boxes(floor: dict, catalog: dict, meas: dict) -> tuple:
    """-> (works [(id, artifact, x0, z0, x1, z1, top, measured)], blockers [(what, x0, z0, x1, z1, top)])"""
    works, blockers = [], []
    for a in floor.get("artifacts", []) + floor.get("copies", []):
        pos = a.get("position")
        if not pos:
            continue
        m = meas.get((floor.get("map"), a["id"]))
        if m:
            (ax, az), b = m
            dx, dz = pos[0] - ax, pos[1] - az
            row = (a["id"], a["artifact"], b[0] + dx, b[2] + dz, b[3] + dx, b[5] + dz, b[4], True)
        else:
            row = (a["id"], a["artifact"], pos[0] - 0.65, pos[1] - 0.65, pos[0] + 0.65, pos[1] + 0.65, 1.5, False)
        if (row[4] - row[2]) > 60 or (row[5] - row[3]) > 60:      # a stage, not a footprint: keep its place only
            row = (a["id"], a["artifact"], pos[0] - 0.65, pos[1] - 0.65, pos[0] + 0.65, pos[1] + 0.65, 1.5, False)
        works.append(row)
        blockers.append(("work " + a["id"],) + row[2:7])
    for p in floor.get("props", []):
        size = (catalog.get(p.get("kind")) or {}).get("size")
        if not size or not p.get("position"):
            continue
        w, h, d = (v * float(p.get("scale", 1)) for v in size)
        if int(p.get("facing", 0)) % 180 == 90:
            w, d = d, w
        x, z = p["position"]
        blockers.append(("prop " + str(p.get("kind")), x - w / 2, z - d / 2, x + w / 2, z + d / 2, h))
    for wall in floor.get("walls", []):
        (x1, z1), (x2, z2) = wall["from"], wall["to"]
        blockers.append(("wall " + str(wall.get("id")), min(x1, x2) - 0.09, min(z1, z2) - 0.09, max(x1, x2) + 0.09, max(z1, z2) + 0.09,
                         float(wall.get("base", 0)) + float(wall.get("height", 2.4))))
    return works, blockers


def read_floor(i: int, floor: dict, spawn: list, catalog: dict, meas: dict, order: list) -> dict:
    sx, sz = float(spawn[0]), float(spawn[2])
    n = math.hypot(sx, sz) or 1.0
    fx, fz = -sx / n, -sz / n                     # forward: toward the middle of the slab
    works, blockers = boxes(floor, catalog, meas)
    notes = []
    # A box is not a body. A hall, a ground or a field the player is MEANT to stand in has a box that holds the spawn
    # point and most of the floor (floors 5-12 each have a `hall`): such an enclosure neither holds the player captive
    # nor stands in the face. Only a compact work (under ENCLOSURE m2) around the spawn point counts as "inside".
    def area(b):
        return (b[3] - b[1]) * (b[4] - b[2])
    around = {b[0] for b in blockers if b[0].startswith("work ") and b[1] < sx < b[3] and b[2] < sz < b[4]}
    inside = [b[0] for b in blockers if b[0] in around and b[5] > 0.3 and area(b) < ENCLOSURE]
    if inside:
        notes.append(("inside", "the spawn point is inside " + ", ".join(x.removeprefix("work ") for x in inside[:3])))
    face = set()
    for t in [0.4 + 0.2 * k for k in range(14)]:          # 0.4 .. 3.0 m ahead
        for u in (-0.5, -0.25, 0.0, 0.25, 0.5):
            px, pz = sx + fx * t - fz * u, sz + fz * t + fx * u
            for b in blockers:
                if b[1] <= px <= b[3] and b[2] <= pz <= b[4] and b[5] > 0.8 and b[0] not in around and not (b[0].startswith("work ") and area(b) >= ENCLOSURE):
                    face.add((round(t, 1), b[0]))
    if face:
        nearest = min(face)
        notes.append(("in the face", f"{nearest[1]} {nearest[0]} m ahead"))
    ahead, behind = [], []
    for w in works:
        cx, cz = (w[2] + w[4]) / 2 - sx, (w[3] + w[5]) / 2 - sz
        dist = math.hypot(cx, cz)
        cos = (cx * fx + cz * fz) / dist if dist > 1e-6 else 1.0
        (ahead if cos >= 0.5 and dist <= 18.0 else behind).append((dist, w))
    if len(works) >= 1 and len(ahead) <= 1:
        notes.append(("nothing ahead", f"{len(ahead)} of {len(works)} works lie ahead within 18 m"))
    by_key = {}
    for w in works:
        by_key.setdefault(w[1], w)
    seq = [by_key[k] for k in order if k in by_key]
    if len(seq) >= 4:
        dist = [math.hypot((w[2] + w[4]) / 2 - sx, (w[3] + w[5]) / 2 - sz) for w in seq]
        rank = sorted(range(len(dist)), key=lambda k: dist[k])
        pos_rank = {k: r for r, k in enumerate(rank)}
        nn = len(seq)
        rho = 1 - 6 * sum((k - pos_rank[k]) ** 2 for k in range(nn)) / (nn * (nn * nn - 1))
        if rho < -0.3:
            notes.append(("order", f"timeline order against distance: {rho:+.2f} over {nn} works (the first, {seq[0][1]}, is {dist[0]:.0f} m away)"))
    if len(works) >= 3:
        def volume(w):
            return min(w[4] - w[2], 20) * min(w[5] - w[3], 20) * min(max(w[6], 0.2), 6)
        hero = max(works, key=volume)
        if hero[7] and not any(w is hero for _, w in ahead) and not inside:
            notes.append(("hero behind", f"the biggest work, {hero[1]}, is not ahead"))
    staging = len(floor.get("walls", [])) + len(floor.get("props", [])) + len(floor.get("route", []) or []) + sum(1 for a in floor.get("artifacts", []) if a.get("interface"))
    if len(works) <= 3 and staging == 0:
        notes.append(("thin", f"{len(works)} work(s), no wall, prop, route or carrier"))
    worst = min((CLASSES.index(c) for c, _ in notes), default=CLASSES.index("reads"))
    return {"floor": i, "map": floor.get("map"), "class": CLASSES[worst], "notes": [f"{c}: {t}" for c, t in notes],
            "works": len(works), "ahead": len(ahead), "props": len(floor.get("props", [])), "walls": len(floor.get("walls", [])),
            "route": len(floor.get("route", []) or []), "lights": sum(1 for p in floor.get("props", []) if p.get("kind") == "work_light"),
            "unmeasured": sum(1 for w in works if not w[7]), "spawn": [sx, sz]}


def main() -> int:
    args = sys.argv[1:]
    rooms = json.loads((ROOT / "commons/void/rooms.json").read_text(encoding="utf-8"))["floors"]
    layout = json.loads((ROOT / "commons/void/layout.json").read_text(encoding="utf-8"))
    catalog = json.loads((ROOT / "commons/void/catalog.json").read_text(encoding="utf-8"))["props"]
    timeline = json.loads((ROOT / "commons/data/artifact_timeline.json").read_text(encoding="utf-8"))
    by_floor = {}
    for r in timeline.get("main", []):
        if isinstance(r.get("floor"), int):
            by_floor.setdefault(r["floor"], []).append(r["key"])
    meas = measured()
    lo, hi = 0, len(rooms) - 1
    for a in args:
        if a.startswith("--floors="):
            lo, _, hi2 = a.split("=", 1)[1].partition("-")
            lo, hi = int(lo), int(hi2 or lo)
    rows = [read_floor(i, rooms[i], layout.get("spawn_points", {}).get(str(i), [0, 0.06, 7.8]), catalog, meas, by_floor.get(i, []))
            for i in range(lo, hi + 1)]
    for a in args:
        if a.startswith("--json="):
            out = ROOT / a.split("=", 1)[1]
            out.parent.mkdir(parents=True, exist_ok=True)
            out.write_text(json.dumps(rows, indent=1, ensure_ascii=False), encoding="utf-8")
    counts = {c: sum(1 for r in rows if r["class"] == c) for c in CLASSES}
    if "--markdown" in args:
        print("| class | floors |\n|---|---|")
        for c in CLASSES:
            print(f"| {c} | {counts[c]} |")
        print("\n| floor | map | class | works | ahead | staging | notes |\n|---|---|---|---|---|---|---|")
        for r in sorted(rows, key=lambda r: (CLASSES.index(r["class"]), r["floor"])):
            if r["class"] == "reads":
                continue
            print(f"| {r['floor']} | {r['map']} | {r['class']} | {r['works']} | {r['ahead']} | {r['walls']}w {r['props']}p {r['route']}r | {'; '.join(r['notes'])} |")
    else:
        for r in sorted(rows, key=lambda r: (CLASSES.index(r["class"]), r["floor"])):
            if r["class"] != "reads":
                print(f"{r['class']:13s} floor {r['floor']:3d} {str(r['map'])[:38]:38s} " + "; ".join(r["notes"])[:150])
    print("\n" + ", ".join(f"{counts[c]} {c}" for c in CLASSES) + f" - of {len(rows)} floors")
    return 0


if __name__ == "__main__":
    sys.exit(main())
