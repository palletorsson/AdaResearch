"""script_compose.py — experience-first map composition (the-edge pilot).

The inversion: the script is the input, the geometry is solved from it,
and observation (gaze_ride) is the fitness function.

  python tools/script_compose.py --map Point_Lines \
      --scripts doc/book/look_scripts/primitives.json --seeds 5

Reads the composed source map only for its CAST (interactable tokens, full
fidelity) and its settings/lighting blocks (the register's darkness). Layout
comes from the script: register (arrival|promenade|close), hero, counter.
N seed variants are generated; each is scored by running the real gaze_ride
and comparing its ride log to the script (encounter order, hero prominence,
cast coverage); the pathfinder is a hard gate. Champion is written to
commons/maps/Script_<Map>/ with the script, seed, and score in its
documentation block — the seam of authorship, legible (edge-5).

Not to be confused with tools/compose_map.py (April's narrative-grammar
composer) — this one solves geometry from a per-map experience script and
judges candidates with the observer.
"""
import argparse
import json
import math
import os
import re
import shutil
import subprocess
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
MAPS_DIR = os.path.join(ROOT, "commons", "maps")
SIZES_PATH = os.path.join(ROOT, "commons", "data", "artifact_sizes.json")


def load_sizes():
    try:
        d = json.load(open(SIZES_PATH, encoding="utf-8"))
        return d.get("sizes", d)
    except Exception:
        return {}


SIZES = load_sizes()


def base_of(token):
    return token.split(":")[0].split("#")[0]


def size_of(token):
    e = SIZES.get(base_of(token))
    if not e:
        return 1.0
    return max(float(e.get("base_m", 1.0)), float(e.get("height_m", 1.0)))


def cells_of(token):
    e = SIZES.get(base_of(token))
    if not e or not e.get("grid_cells"):
        return 1
    return max(1, int(math.ceil(max(e["grid_cells"]))))


def read_cast(map_name):
    p = os.path.join(MAPS_DIR, map_name, "map_data.json")
    d = json.load(open(p, encoding="utf-8"))
    cast = []
    for row in d["layers"]["interactables"]:
        for c in row:
            if c and str(c).strip():
                cast.append(str(c))
    # exit token, if the composed map declares one
    exit_tok = "t"
    for row in d["layers"]["utilities"]:
        for c in row:
            if str(c).strip().startswith("t"):
                exit_tok = str(c).strip()
    return d, cast, exit_tok


def pick(cast, prefs, exclude=None):
    for pref in prefs:
        for i, tok in enumerate(cast):
            if i != exclude and base_of(tok).lower().startswith(pref.lower()):
                return i
    return None


def set_rotation(token, rot):
    parts = token.split("#")
    head = parts[0].split(":")
    while len(head) < 2:
        head.append("0")
    head[1] = str(rot)
    parts[0] = ":".join(head)
    return "#".join(parts)


# ── layout registers ─────────────────────────────────────────────────────

def lay_promenade(cast, hero_i, counter_i, seed, hero_last=False):
    """Stations along a spine; smalls hug walls, hero centered in vacuum."""
    order = [i for i in range(len(cast)) if i not in (hero_i, counter_i)]
    if hero_last:
        hero_slot = len(order)
    else:
        hero_slot = max(1, int(len(order) * 0.72))
    width = max(7, cells_of(cast[hero_i]) + 4)
    if width % 2 == 0:
        width += 1
    cx = width // 2
    placements = []  # (x, z, token)
    z = 2
    side = seed % 2  # alternation phase
    jitter = (seed // 2) % 2
    slot = 0
    seq = order[:hero_slot] + ["HERO"] + order[hero_slot:]
    hero_size = size_of(cast[hero_i])
    for item in seq:
        if item == "HERO":
            pre = max(4, int(round(2.5 * hero_size))) + ((seed % 3) - 1)
            z += max(3, pre)
            if counter_i is not None:
                # counter two rows before the hero, off-axis, facing it
                cxp = 1 if side else width - 2
                placements.append((cxp, z - 2, set_rotation(cast[counter_i], 0)))
            placements.append((cx, z, cast[hero_i]))
            z += max(3, int(round(2.0 * hero_size)))
            continue
        tok = cast[item]
        s = size_of(tok)
        gap = min(7, max(2, int(round(1.8 * s)))) + (jitter if slot % 3 == 2 else 0)
        if s <= 1.2:  # small: hug a wall
            x = 1 if side else width - 2
            side = 1 - side
        else:  # medium: inner lane, alternating
            x = 2 if slot % 2 else width - 3
        placements.append((x, z, tok))
        z += gap
        slot += 1
    depth = z + 2
    floor = [["1"] * width for _ in range(depth)]
    return width, depth, floor, placements, (cx, 0), (cx, depth - 1)


def lay_arrival(cast, hero_i, counter_i, seed):
    """A plate of void; a platform; the hero in a vacuum; approach strip."""
    W = D = 20
    floor = [["0"] * W for _ in range(D)]
    pcx, pcz, pr = 10, 12, 4  # platform centre + radius
    for z in range(pcz - pr, pcz + pr + 1):
        for x in range(pcx - pr, pcx + pr + 1):
            floor[z][x] = "1"
    for z in range(1, pcz - pr):  # approach strip, 3 wide
        for x in (pcx - 1, pcx, pcx + 1):
            floor[z][x] = "1"
    placements = [(pcx, pcz, cast[hero_i])]
    if counter_i is not None:
        placements.append((pcx + (1 if seed % 2 else -1), pcz - pr + 1,
                           set_rotation(cast[counter_i], 0)))
    ring = [(pcx - pr, pcz - pr), (pcx + pr, pcz - pr), (pcx - pr, pcz),
            (pcx + pr, pcz), (pcx - pr, pcz + pr), (pcx + pr, pcz + pr),
            (pcx - pr + 1, pcz + pr), (pcx + pr - 1, pcz - pr),
            (pcx, pcz + pr), (pcx - pr, pcz - pr + 2), (pcx + pr, pcz + pr - 2)]
    rest = [i for i in range(len(cast)) if i not in (hero_i, counter_i)]
    off = seed % max(1, len(ring))
    for k, i in enumerate(rest):
        x, z = ring[(k + off) % len(ring)]
        if (x, z) != (pcx, pcz):
            placements.append((x, z, cast[i]))
    return W, D, floor, placements, (pcx, 1), (pcx, pcz + pr)


# ── candidate assembly + scoring ─────────────────────────────────────────

def build_map(source, cast_note, width, depth, floor, placements, spawn, exit_xy,
              exit_tok, script, seed):
    utils = [[" "] * width for _ in range(depth)]
    inter = [[" "] * width for _ in range(depth)]
    utils[spawn[1]][spawn[0]] = "s"
    utils[exit_xy[1]][exit_xy[0]] = exit_tok
    dropped = []
    for x, z, tok in placements:
        if 0 <= x < width and 0 <= z < depth and inter[z][x].strip() == "":
            inter[z][x] = tok
        else:
            dropped.append(base_of(tok))
    d = {
        "documentation": {
            "composer": {
                "tool": "script_compose.py",
                "register": script["register"],
                "script_note": script.get("note", ""),
                "seed": seed,
                "dropped": dropped,
            },
            "authored_by": "script (language) + solver (geometry) + gaze_ride (observation)",
        },
        "layers": {"structure": floor, "utilities": utils, "interactables": inter},
        "lighting": source.get("lighting", {}),
        "map_info": {
            "dimensions": {"width": float(width), "depth": float(depth),
                           "max_height": 4.0},
            "lookup_name": cast_note,
            "name": cast_note,
            "format": "json",
        },
        "settings": source.get("settings", {}),
        "utility_definitions": source.get("utility_definitions", {}),
    }
    return d, dropped


def write_map(name, data):
    p = os.path.join(MAPS_DIR, name)
    os.makedirs(p, exist_ok=True)
    with open(os.path.join(p, "map_data.json"), "w", encoding="utf-8") as f:
        json.dump(data, f, indent=1)


def run(cmd):
    r = subprocess.run(cmd, capture_output=True, text=True, cwd=ROOT, timeout=120)
    return r.returncode, r.stdout + r.stderr


def kendall(a, b):
    common = [x for x in a if x in b]
    if len(common) < 2:
        return 0.0
    pos = {v: i for i, v in enumerate(b)}
    conc = disc = 0
    for i in range(len(common)):
        for j in range(i + 1, len(common)):
            d = pos[common[i]] - pos[common[j]]
            if d < 0:
                conc += 1
            elif d > 0:
                disc += 1
    n = conc + disc
    return (conc - disc) / n if n else 0.0


def score_candidate(name, cast, hero_i, dropped):
    rc, out = run([sys.executable, "tools/map_pathfinder.py", "check", name])
    if rc != 0 or "0 FAIL" not in out:
        return None, "pathfinder FAIL"
    rc, ride = run([sys.executable, "tools/gaze_ride.py", name])
    if rc != 0:
        return None, "gaze_ride error"
    visits, seen_deg = [], {}
    for m in re.finditer(r"-> (\S+)", ride):
        b = base_of(m.group(1))
        if b not in visits:
            visits.append(b)
    for m in re.finditer(r"^\s+(\S+)\s+\w+\s+(\d+)deg", ride, re.M):
        b = base_of(m.group(1))
        seen_deg[b] = max(seen_deg.get(b, 0), int(m.group(2)))
    cast_bases = []
    for t in cast:
        b = base_of(t)
        if b not in cast_bases:
            cast_bases.append(b)
    hero_b = base_of(cast[hero_i])
    coverage = len([b for b in cast_bases if b in visits or b in seen_deg]) / len(cast_bases)
    tau = kendall(cast_bases, visits)
    hd = seen_deg.get(hero_b, 0)
    hero_bonus = 1.0 if 25 <= hd <= 80 else (0.5 if hd > 0 else 0.0)
    rank1 = 1.0 if seen_deg and hd == max(seen_deg.values()) else 0.0
    fidelity = 1.0 - len(dropped) / max(1, len(cast))
    s = 2 * tau + coverage + hero_bonus + rank1 + fidelity
    return s, f"tau={tau:+.2f} cov={coverage:.2f} heroDeg={hd} rank1={int(rank1)} fid={fidelity:.2f}"


def compose(map_name, scripts, seeds, prefix):
    script = scripts["maps"][map_name]
    source, cast, exit_tok = read_cast(map_name)
    hero_i = pick(cast, script["hero"])
    if hero_i is None:
        hero_i = max(range(len(cast)), key=lambda i: size_of(cast[i]))
    counter_i = pick(cast, script.get("counter", []), exclude=hero_i)
    best = None
    cand_name = f"ScriptCand_{map_name}"
    for seed in range(seeds):
        if script["register"] == "arrival":
            w, dep, floor, pl, sp, ex = lay_arrival(cast, hero_i, counter_i, seed)
        else:
            w, dep, floor, pl, sp, ex = lay_promenade(
                cast, hero_i, counter_i, seed,
                hero_last=(script["register"] == "close"))
        data, dropped = build_map(source, cand_name, w, dep, floor, pl, sp, ex,
                                  exit_tok, script, seed)
        write_map(cand_name, data)
        s, detail = score_candidate(cand_name, cast, hero_i, dropped)
        print(f"  seed {seed}: {'--' if s is None else f'{s:.2f}'}  {detail}")
        if s is not None and (best is None or s > best[0]):
            best = (s, seed, data, detail)
    shutil.rmtree(os.path.join(MAPS_DIR, cand_name), ignore_errors=True)
    if best is None:
        print(f"{map_name}: NO candidate passed the gate")
        return False
    s, seed, data, detail = best
    out_name = f"{prefix}{map_name}"
    data["map_info"]["lookup_name"] = out_name
    data["map_info"]["name"] = out_name
    data["documentation"]["composer"]["score"] = round(s, 3)
    data["documentation"]["composer"]["ride"] = detail
    write_map(out_name, data)
    print(f"{map_name} -> {out_name}  champion seed {seed}  score {s:.2f}  ({detail})")
    return True


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", help="single map; omit for every map in the script file")
    ap.add_argument("--scripts", default="doc/book/look_scripts/primitives.json")
    ap.add_argument("--seeds", type=int, default=5)
    ap.add_argument("--prefix", default="Script_")
    args = ap.parse_args()
    scripts = json.load(open(os.path.join(ROOT, args.scripts), encoding="utf-8"))
    targets = [args.map] if args.map else list(scripts["maps"].keys())
    ok = 0
    for m in targets:
        print(f"== {m} ==")
        ok += compose(m, scripts, args.seeds, args.prefix)
    print(f"done: {ok}/{len(targets)} composed")


if __name__ == "__main__":
    main()
