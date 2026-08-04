#!/usr/bin/env python3
"""
compile_museum_map.py — a museum you can actually walk (unification step 5).

Until now a museum tile only ever became a SCORING map: museum_match stamps one
to be judged, and the endless museum builds its own world around synthetic
lobbies. Neither produces a map the game can simply load and play, and two
things were quietly lost on the way down to the grid:

  THE PODIUMS WERE FLAT. Every tile cell — floor, platform, podium, hero plinth
  — compiled to structure height 1. The tile has a vertical vocabulary (1 / 2 /
  2s / 3s) and none of it reached the world; a podium was a floor tile with an
  artifact standing on it. Here 2 and 2s compile to height 2 and the hero
  plinth to 3, which is also what the validator already assumes: platforms are
  not standable, you walk AROUND a podium, not over it.

  THE EXIT HAD NOTHING BEHIND IT. Pathfinder rule 2 wants a floor row behind a
  teleporter to catch the player, and a tile's last row is its last row — so
  every stamped museum has carried that warning. The exit now stands one row
  inside the threshold and the final row is its landing.

Interactables are dealt by a DECLARED ORDER POLICY (step 4) — spine, dig, size
or text — so a compiled museum states who chose its sequence.

  python tools/compile_museum_map.py --museum=grande-galerie-axial --policy=text
  python tools/compile_museum_map.py --all --policy=spine
  python tools/compile_museum_map.py --self-test

The gate is the pathfinder: a compiled map must pass with NO issues and NO
teleport warnings, which is the difference between a map that scores and a map
that plays.
"""
from __future__ import annotations
import argparse
import glob
import json
import subprocess
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
MAPS = REPO / "commons" / "maps"
PATTERNS = REPO / "commons" / "data" / "template_patterns.json"
POLICIES = REPO / "commons" / "data" / "artifact_order_policies.json"
BAYS = REPO / "commons" / "data" / "museum_bays.json"

WALL_H, PODIUM_H, HERO_H = "4", "2", "3"
STAND = ("1", "1s")


def museums() -> dict:
    d = json.loads(PATTERNS.read_text(encoding="utf-8"))
    return {k: p for k, p in d.get("patterns", {}).items()
            if isinstance(p, dict) and p.get("museum")}


def live_registry() -> dict:
    out: dict = {}
    for rp in sorted(glob.glob(str(REPO / "commons" / "artifacts" / "registry" / "*.json"))):
        try:
            d = json.load(open(rp, encoding="utf-8"))
        except Exception:
            continue
        for tok, e in (d.get("artifacts") or {}).items():
            if isinstance(e, dict) and tok not in out and e.get("scene") and e.get("map_ready"):
                out[tok] = e
    return out


def policy_pool(policy: str) -> list:
    d = json.loads(POLICIES.read_text(encoding="utf-8"))
    rows = d["policies"].get(policy)
    if rows is None:
        raise SystemExit(f"no order policy `{policy}` (have {sorted(d['policies'])})")
    live = live_registry()
    return [r["lookup"] for r in rows if r["lookup"] in live]


def compile_map(key: str, pat: dict, cast: list, policy: str, name: str) -> dict:
    w, h = int(pat["w"]), int(pat["h"])
    grid = [[str(c) for c in row] for row in pat["tile"]]
    structure = [["0"] * w for _ in range(h)]
    utils = [[" "] * w for _ in range(h)]
    inter = [[" "] * w for _ in range(h)]
    slots: list = []
    for y in range(h):
        for x in range(w):
            c = grid[y][x]
            if c == "4":
                structure[y][x] = WALL_H
            elif c in ("1", "1s"):
                structure[y][x] = "1"
            elif c in ("2", "2s"):
                structure[y][x] = PODIUM_H
            elif c == "3s":
                structure[y][x] = HERO_H
            if c in ("1s", "2s", "3s"):
                slots.append((0 if c == "3s" else 1 if c == "2s" else 2, y, x))

    # SEAT THE PLINTHS. Raising podiums is what the tile always meant, but a
    # plinth is only furniture if you can reach what stands on it: the
    # pathfinder's rule 4 caught four museums where a hero at h=3 beside a floor
    # at h=1 is a two-step climb and therefore unreachable. So a raised slot is
    # lowered to one step above the best neighbour it actually has — the plinth
    # is as tall as the room allows you to reach it, which is also how a museum
    # builds one. A slot whose neighbours are all void cannot be fixed by
    # height; that is a fault in the tile and it is reported, not papered over.
    islands = []
    for rank, y, x in slots:
        if structure[y][x] in ("1", "0"):
            continue
        nb = [int(structure[y + dy][x + dx])
              for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1))
              # only cells a BODY can occupy count as a step: a podium beside a
              # plinth is not a stair, and counting it left the heroes at h=3
              # exactly as unreachable as before (the validator's own STAND set)
              if 0 <= y + dy < h and 0 <= x + dx < w
              and grid[y + dy][x + dx] in STAND]
        if not nb:
            islands.append([x, y])
            continue
        structure[y][x] = str(min(int(structure[y][x]), max(nb) + 1))

    # RAMPS. The grid's movement law is one-directional about height: a drop of
    # one is free, but "climbing up requires a wp ramp". Raising the podiums
    # therefore put every raised slot out of reach — the pathfinder said so on
    # four museums, and would have been right about the rest for the same
    # reason. So each raised slot gets a walkway on the floor cell beside it:
    # the step a museum builds under a dais, declared rather than assumed.
    ramps = []
    for _rank, y, x in slots:
        if int(structure[y][x]) <= 1:
            continue
        # a single step is not always enough: the Guggenheim's hero stands on a
        # dais ringed by platform, so the way up is floor -> platform -> plinth.
        # Walk outward until the ground drops to floor level, ramping each tread
        # — a stair, which is what a dais has.
        best = None
        for dy, dx in ((-1, 0), (1, 0), (0, -1), (0, 1)):
            tread = []
            for step in range(1, 4):
                ny, nx = y + dy * step, x + dx * step
                if not (0 <= ny < h and 0 <= nx < w):
                    tread = []
                    break
                if grid[ny][nx] not in ("1", "1s", "2", "2s"):
                    tread = []
                    break
                tread.append((ny, nx))
                if int(structure[ny][nx]) <= 1:
                    break
            else:
                tread = []
            if tread and int(structure[tread[-1][0]][tread[-1][1]]) <= 1:
                if best is None or len(tread) < len(best):
                    best = tread
        for ny, nx in (best or []):
            if not utils[ny][nx].strip():
                utils[ny][nx] = "wp"
                ramps.append([nx, ny])

    entry = [x for x in range(w) if grid[0][x] in STAND]
    utils[0][entry[len(entry) // 2]] = "s"

    # rule 2 wants a floor row BEHIND the teleporter, so the exit stands one row
    # inside the threshold and the last row becomes its landing
    ty = h - 2
    row = [x for x in range(w) if grid[ty][x] in STAND]
    while not row and ty > 1:
        ty -= 1
        row = [x for x in range(w) if grid[ty][x] in STAND]
    tx = row[len(row) // 2]
    utils[ty][tx] = "t"
    structure[ty][tx] = "0"          # rule 5: a teleporter stands on void
    for x in range(w):               # the catcher
        if grid[h - 1][x] in STAND and structure[h - 1][x] == "0":
            structure[h - 1][x] = "1"
    if all(structure[h - 1][x] == "0" for x in range(w)):
        structure[h - 1][tx] = "1"

    slots.sort(key=lambda s: (s[0], s[1], s[2]))
    hero = [s for s in slots if s[0] == 0]
    rest = [s for s in slots if s[0] != 0]
    rest.sort(key=lambda s: (s[1], s[2]))
    ordered = hero + rest
    dealt = 0
    for _, y, x in ordered:
        if dealt >= len(cast):
            break
        inter[y][x] = cast[dealt]
        dealt += 1

    return {
        "map_info": {
            "name": name,
            "description": f"{pat.get('museum', key)} compiled as a walkable map — "
                           f"podiums raised, exit landed, cast dealt in {policy} order.",
        },
        "dimensions": {"width": w, "depth": h, "max_height": 5},
        "layers": {"structure": structure, "utilities": utils, "interactables": inter},
        "documentation": {
            "compiler": {
                "tool": "compile_museum_map.py", "museum": key, "policy": policy,
                "slots": len(slots), "dealt": dealt,
                "heights": {"wall": WALL_H, "podium": PODIUM_H, "hero": HERO_H},
                "anchors": {"spawn": [entry[len(entry) // 2], 0], "exit": [tx, ty],
                            "landing_row": h - 1},
                "island_slots": islands, "ramps": ramps,
                "note": "step 5 of doc/plans/template_museum_unification.md: the tile's "
                        "vertical vocabulary reaches the grid and the exit has a floor "
                        "behind it, so the map plays instead of only scoring.",
            }
        },
    }


def pathfinder(name: str) -> tuple[bool, list]:
    r = subprocess.run([sys.executable, "tools/map_pathfinder.py", "check", name,
                        "--verbose"], capture_output=True, text=True, cwd=str(REPO))
    warns = [ln.strip() for ln in r.stdout.splitlines()
             if "[WARN]" in ln or "[FAIL]" in ln]
    ok = "0 FAIL" in r.stdout and not warns
    return ok, warns


def write(doc: dict, name: str) -> Path:
    d = MAPS / name
    d.mkdir(parents=True, exist_ok=True)
    p = d / "map_data.json"
    p.write_text(json.dumps(doc, indent=1), encoding="utf-8")
    return p


def selftest() -> int:
    mus = museums()
    key = "grande-galerie-axial"
    pool = policy_pool("spine")[:14]
    doc = compile_map(key, mus[key], pool, "spine", "SelfTest_Compile")
    st, ut = doc["layers"]["structure"], doc["layers"]["utilities"]
    h = len(st)
    ok = []
    heights = {c for row in st for c in row}
    ok.append(("A the tile's vertical vocabulary survives",
               PODIUM_H in heights and WALL_H in heights,
               f"heights present {sorted(heights)}"))
    tp = [(y, x) for y in range(h) for x in range(len(st[0])) if ut[y][x] == "t"]
    ok.append(("B exactly one exit teleporter", len(tp) == 1, str(tp)))
    y, x = tp[0]
    ok.append(("C the exit stands on void (rule 5)", st[y][x] == "0", f"height {st[y][x]!r}"))
    ok.append(("D a floor row catches the player (rule 2)",
               y + 1 < h and any(c != "0" for c in st[y + 1]),
               f"row {y+1} has floor"))
    sp = [(yy, xx) for yy in range(h) for xx in range(len(st[0])) if ut[yy][xx] == "s"]
    ok.append(("E exactly one spawn", len(sp) == 1, str(sp)))
    for label, good, detail in ok:
        print(f"  {'PASS' if good else 'FAIL'}  {label}: {detail}")
    n = sum(1 for _, g, _ in ok if g)
    print(f"self-test: {n}/{len(ok)} controls passed")
    return 0 if n == len(ok) else 1


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--museum")
    ap.add_argument("--policy", default="spine")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()
    if args.self_test:
        return selftest()
    mus = museums()
    keys = sorted(mus) if args.all else [args.museum]
    if not keys or keys == [None]:
        raise SystemExit("--museum=<key> or --all required")
    pool = policy_pool(args.policy)
    bad = 0
    for key in keys:
        if key not in mus:
            raise SystemExit(f"no museum `{key}`")
        n_slots = sum(1 for row in mus[key]["tile"] for c in row
                      if str(c) in ("1s", "2s", "3s"))
        name = f"Walk_{key.replace('-', '_')}_{args.policy}"
        doc = compile_map(key, mus[key], pool[:n_slots], args.policy, name)
        write(doc, name)
        ok, warns = pathfinder(name)
        c = doc["documentation"]["compiler"]
        print(f"{'ok  ' if ok else 'WARN'} {name:52} {c['dealt']}/{c['slots']} slots "
              f"· exit {tuple(c['anchors']['exit'])}")
        for wln in warns:
            print(f"       {wln}")
        bad += 0 if ok else 1
    print(f"\n{len(keys) - bad}/{len(keys)} compiled maps pass the pathfinder cleanly")
    return bad


if __name__ == "__main__":
    sys.exit(main())
