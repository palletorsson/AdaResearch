# -*- coding: utf-8 -*-
"""fix_facing.py — turn the curriculum's text toward the walker.

338 of the 687 text-bearing placements in the spine carry no rotation token. A
placement without one is not neutral: it is a bet that the walker arrives from
the artifact's front, and when the bet loses the reader sees the back of a panel,
which renders as mirrored text. Proved by shooting one map from both sides.

The arrival direction is not a guess. walk_polish already walks each map from
spawn to exit and records, for every cell, the cell it was reached FROM. That
parent is where the body stands when it meets the artifact, and the artifact
should face it.

CONVENTION, MEASURED NOT ASSUMED: rot 0 leaves an artifact's front pointing -z
(established by shooting VectorCrossProduct from both sides — legible from -z,
mirrored from +z). So facing direction d wants rot = ROT[d] + 180.

Only text-bearing artifacts are touched, and only where no rotation was written.
A rotationless sculpture is a different question from a rotationless sign, and
this tool has no opinion about sculpture.

    python tools/fix_facing.py                 # the diff, nothing written
    python tools/fix_facing.py --apply
    python tools/fix_facing.py --only=science_screen --apply
"""
import json, argparse, pathlib, subprocess, sys
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import walk_polish as wp                       # noqa: E402
import spine_typologies as sty                 # noqa: E402

ROT = {(0, 1): 0, (1, 0): 90, (0, -1): 180, (-1, 0): 270}
TEXT_HINTS = ("label", "text", "readout", "screen", "board", "plaque", "sign", "display")


def registry():
    reg = {}
    for f in (ROOT / "commons/artifacts/registry").glob("*.json"):
        try:
            d = json.loads(f.read_text(encoding="utf-8"))
        except Exception:
            continue
        for k, v in (d.get("artifacts", d) or {}).items():
            if isinstance(v, dict):
                reg[k] = v
    return reg


def is_text(tok, reg):
    return any(w in json.dumps(reg.get(tok, {})).lower() for w in TEXT_HINTS)


def approach(md):
    """cell -> the cell the walk reached it FROM. That is where the body stands."""
    S, U, I, WL = wp.grids(md)
    D = len(S); W = max((len(r) for r in S), default=0)
    floor = {(x, z) for z in range(D) for x in range(W) if 0 < wp.h_at(S, x, z) <= 3}
    spawn = None
    for z, row in enumerate(U):
        for x, c in enumerate(row):
            if str(c).strip() == "s":
                spawn = (x, z)
    if spawn is None or spawn not in floor:
        spawn = min(floor) if floor else None
    if spawn is None:
        return {}
    from collections import deque
    dist, dq = {spawn: 0}, deque([spawn])
    while dq:
        c = dq.popleft()
        for d in wp.DIRS:
            nb = (c[0] + d[0], c[1] + d[1])
            if nb in floor and nb not in dist and not wp.wall_between(WL, c, nb):
                dist[nb] = dist[c] + 1
                dq.append(nb)
    return dist


def plan(only=""):
    reg = registry()
    out, skipped = [], Counter()
    for seq, nm in sty.spine_maps():
        md = wp.load(nm)
        if not md:
            continue
        S, U, I, WL = wp.grids(md)
        par = approach(md)   # cell -> walk distance from spawn
        for z, row in enumerate(I):
            for x, c in enumerate(row):
                s = str(c).strip()
                if not s or s.startswith(wp.PRE):
                    continue
                tok = s.split(":")[0]
                if only and tok != only:
                    continue
                bits = s.split(":")
                if len(bits) > 1 and bits[1].lstrip("-").isdigit():
                    continue                      # the author said which way
                if not is_text(tok, reg):
                    continue
                # where does the body stand? the walkable neighbour the walk
                # reached first; its parent tells us which way the body came
                # WHERE THE BODY ARRIVES, not whichever neighbour the dict
                # yields first. The first cut took DIRS order and produced a
                # flood of identical rotations because that order prefers +x —
                # a plausible-looking answer driven by nothing.
                nbs = [(x + d[0], z + d[1]) for d in wp.DIRS]
                reach = [n for n in nbs if n in par]
                stand = min(reach, key=lambda n: par[n]) if reach else None
                if stand is None:
                    skipped["no walkable neighbour"] += 1
                    continue
                d = (stand[0] - x, stand[1] - z)
                if d not in ROT:
                    skipped["diagonal"] += 1
                    continue
                rot = (ROT[d] + 180) % 360        # rot 0 faces -z, measured
                rest = ":".join(bits[1:])
                new = "%s:%d%s" % (tok, rot, (":" + rest) if rest else "")
                out.append({"map": nm, "seq": seq, "cell": [x, z], "token": tok,
                            "from": s, "to": new, "faces": list(d)})
    return out, skipped


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--apply", action="store_true")
    ap.add_argument("--only", default="")
    ap.add_argument("--limit", type=int, default=0)
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    rows, skipped = plan(a.only)
    if a.limit:
        rows = rows[:a.limit]
    print("%d text placements would turn to face the walker" % len(rows))
    if skipped:
        print("  skipped: %s" % dict(skipped))
    print()
    print("%-28s %-9s %-26s -> %s" % ("map", "cell", "was", "becomes"))
    for r in rows[:24]:
        print("%-28s %-9s %-26s -> %s" % (r["map"][:28], str(r["cell"]), r["from"][:26], r["to"]))
    if len(rows) > 24:
        print("  ... and %d more" % (len(rows) - 24))
    by = Counter(r["token"] for r in rows)
    print("\nby token:", by.most_common(8))
    if not a.apply:
        print("\n(dry run — pass --apply to write)")
        return 0
    touched = Counter()
    for r in rows:
        p = ROOT / "commons/maps" / r["map"] / "map_data.json"
        md = json.loads(p.read_text(encoding="utf-8"))
        I = (md.get("layers") or md)["interactables"]
        x, z = r["cell"]
        if str(I[z][x]).strip() != r["from"]:
            continue                              # moved under us; leave it
        I[z][x] = r["to"]
        # COMPACT-ROWS, not one line. The first run wrote json.dumps(md) and
        # collapsed 105 shipped maps to a single line each — 64,472 deletions of
        # formatting nobody asked to change. The project's canonical map format
        # is one grid row per line; tools/compact_map_json.py owns it.
        p.write_text(json.dumps(md), encoding="utf-8")
        subprocess.run([sys.executable, str(ROOT / "tools/compact_map_json.py"), str(p)],
                       capture_output=True)
        touched[r["map"]] += 1
    print("\nwrote %d placements across %d maps" % (sum(touched.values()), len(touched)))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
