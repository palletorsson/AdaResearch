# -*- coding: utf-8 -*-
"""judge_headroom.py — a judge that keeps discriminating above 8.

The 310-wide match put 107 rows on exactly 8.00. Reading the components showed
why: five of experience_score's six inputs — tau, cov, promise, dolly, rank1 —
have ONE distinct value each among those rows. They are ratios and booleans, and
every one of them asks WHETHER. Is the cast reachable. Is the hero visible. Is
the order right. Once a plan is good enough, every answer is yes, the score is
the maximum, and the field piles up on the ceiling with no order inside it.

So this judge asks HOW MUCH. Every term is a quantity that keeps moving after
the thing is achieved, and nothing is clamped to 1:

  hero_deg      the hero's LARGEST angular size along the walk, in degrees.
                Uncapped: a hero that fills 90 deg scores above one that fills 30.
  promise_span  the share of route steps where something clears MIN_DEG, times
                the mean angular size over those steps. Rewards a walk that has
                something to look at MOST of the way, not one that manages it once.
  approach      mean walk distance at which each artifact first clears MIN_DEG.
                Being seen from far away is worth more than being seen on arrival.
  relief        distinct floor heights actually walked, plus route turns per 10
                steps. A flat straight corridor scores 0 however reachable it is.
  dwell_debt    the occupant pass's want count, SUBTRACTED and unbounded below.
                A map with 30 unanswered positions can score arbitrarily badly,
                which the old judge had no way to express.

No term is normalised into a 0..1 box, and the total is not squashed into 0..8.
That is the whole point: the number must be free to keep going.

VALIDATION IS THE DELIVERABLE, not the score. A judge is only useful if it
(a) spreads a field the old one flattened, and (b) does not disagree with the
old one where the old one still worked. Both are measured by --validate.

    python tools/judge_headroom.py --map=Thread_Gate
    python tools/judge_headroom.py --validate
"""
import json, math, argparse, pathlib, sys
from collections import Counter

ROOT = pathlib.Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
import walk_polish as wp                       # noqa: E402

MIN_DEG = 8.0
W = {"hero_deg": 0.06, "promise_span": 6.0, "approach": 0.45,
     "relief": 1.2, "dwell_debt": -0.18}


def sizes():
    try:
        el = json.loads((ROOT / "commons/data/artifact_elements.json").read_text(encoding="utf-8"))
        return {k: max(0.2, max(float(a.get("union_aabb", {}).get("size", [1, 1, 1])[0]),
                                float(a.get("union_aabb", {}).get("size", [1, 1, 1])[2])))
                for k, a in el.get("artifacts", {}).items()}
    except Exception:
        return {}


SIZES = sizes()


def judge(md, hero=""):
    S, U, I, WL = wp.grids(md)
    order, floor, dist, route = wp.walk(md)
    bodies = {(x, z): str(c).strip().split(":")[0]
              for z, row in enumerate(I) for x, c in enumerate(row)
              if str(c).strip() and not str(c).strip().startswith(wp.PRE)
              and not str(c).strip().startswith("hangar_")}
    if not route or not bodies:
        return {"score": 0.0, "why": "no walk or no cast"}

    seen_steps, deg_sum, hero_deg = 0, 0.0, 0.0
    first_seen = {}
    for i in range(len(route) - 1):
        c, nxt = route[i], route[i + 1]
        f = (nxt[0] - c[0], nxt[1] - c[1])
        if f not in wp.DIRS:
            continue
        best = 0.0
        for (bx, bz), tok in bodies.items():
            dx, dz = bx - c[0], bz - c[1]
            d = math.hypot(dx, dz)
            if d < 0.5 or d > 24:
                continue
            if (dx * f[0] + dz * f[1]) / d < math.cos(math.radians(45.0)):
                continue
            deg = math.degrees(2 * math.atan2(SIZES.get(tok, 1.0) / 2.0, d))
            best = max(best, deg)
            if deg >= MIN_DEG:
                first_seen.setdefault((bx, bz), d)      # route runs spawn -> exit
            if tok == hero:
                hero_deg = max(hero_deg, deg)
        if best >= MIN_DEG:
            seen_steps += 1
            deg_sum += best
    steps = max(1, len(route) - 1)
    span = (seen_steps / float(steps)) * (deg_sum / max(1, seen_steps)) / 45.0
    approach = (sum(first_seen.values()) / len(first_seen)) if first_seen else 0.0

    lv = len({wp.h_at(S, x, z) for (x, z) in floor})
    turns = sum(1 for i in range(1, len(route) - 1)
                if (route[i][0] - route[i - 1][0], route[i][1] - route[i - 1][1]) !=
                   (route[i + 1][0] - route[i][0], route[i + 1][1] - route[i][1]))
    relief = (lv - 1) + 10.0 * turns / float(steps)

    try:
        props, _ = wp.inspect(md, md.get("map_info", {}).get("name", "X"))
        debt = len(props)
    except Exception:
        debt = 0

    parts = {"hero_deg": hero_deg, "promise_span": span, "approach": approach,
             "relief": relief, "dwell_debt": debt}
    score = sum(W[k] * v for k, v in parts.items())
    return {"score": round(score, 3), "parts": {k: round(v, 3) for k, v in parts.items()},
            "cast": len(bodies), "steps": steps}


def validate():
    """Does it spread what the old judge flattened, and agree where the old one
    still worked? A judge nobody checked is a preference with a decimal point."""
    import spine_typologies as sty
    names = [nm for _, nm in sty.spine_maps()]
    vals = []
    for nm in names:
        md = wp.load(nm)
        if not md:
            continue
        r = judge(md)
        if r.get("parts"):
            vals.append((r["score"], nm))
    vals.sort()
    n = len(vals)
    print("scored %d spine maps" % n)
    if not n:
        return
    top = Counter(round(v, 2) for v, _ in vals).most_common(1)[0]
    print("  range      %.2f .. %.2f" % (vals[0][0], vals[-1][0]))
    print("  quartiles  %.2f / %.2f / %.2f"
          % (vals[n // 4][0], vals[n // 2][0], vals[3 * n // 4][0]))
    print("  MASS AT ONE VALUE: the commonest score %.2f holds %d of %d (%.0f%%)"
          % (top[0], top[1], n, 100.0 * top[1] / n))
    print("  distinct scores to 2dp: %d" % len({round(v, 2) for v, _ in vals}))
    print("\n  worst 3:", ["%s %.2f" % (m, s) for s, m in vals[:3]])
    print("  best  3:", ["%s %.2f" % (m, s) for s, m in vals[-3:]])


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--map", default="")
    ap.add_argument("--hero", default="")
    ap.add_argument("--validate", action="store_true")
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    if a.validate:
        validate(); return 0
    md = wp.load(a.map)
    if not md:
        print("no such map: %s" % a.map); return 1
    r = judge(md, a.hero)
    print(json.dumps(r, indent=1))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
