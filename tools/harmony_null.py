#!/usr/bin/env python3
"""harmony_null.py — does the harmony meter distinguish a layout from a shuffle?

THE METER, transcribed from ada_encyclopedia/src/app/book/page.tsx (the `harmony` useMemo):
for every pair of placed artifacts it takes a semantic similarity `sim` and a grid distance
`d`, min-max normalises BOTH within the current map, and scores

    tension = |norm(sim) - (1 - norm(d))|        score = round((1 - mean(tension)) * 100)

with the page colouring >=66 green, >=40 amber, below that red.

THE TEST. A meter that measures alignment between the spatial and the semantic order must
score a real layout differently from the same artifacts thrown down at random. So: score the
map as authored, then score N random permutations of the SAME positions among the SAME
artifacts. If the authored score sits inside the shuffle distribution, the number is not
reporting alignment — it is reporting the shape of the position set, which the shuffle does
not change.

This is the designed-null discipline from waves 14-16 pointed at a tool instead of an
artifact: a control that says what the instrument reads when there is nothing to read.

Usage: python tools/harmony_null.py --maps=A,B,C [--shuffles=200]
"""
from __future__ import annotations
import json
import pathlib
import random
import sys
import urllib.request

REPO = pathlib.Path(__file__).resolve().parents[1]
MAPS = REPO / "commons" / "maps"
API = "http://localhost:3003/api/artifact-pairs"


def placed(map_name: str) -> dict:
    """First occurrence of each artifact token, exactly as the page reads it."""
    p = MAPS / map_name / "map_data.json"
    if not p.exists():
        return {}
    inter = (json.loads(p.read_text(encoding="utf-8")).get("layers") or {}).get("interactables") or []
    pos: dict = {}
    for r, row in enumerate(inter):
        for c, cell in enumerate(row or []):
            s = str(cell or "").strip()
            if not s or s.startswith("#"):
                continue
            lk = s.split("#")[0].split(":")[0]
            if lk and lk not in pos:
                pos[lk] = (r, c)
    return pos


def sims(ids: list) -> list:
    body = json.dumps({"ids": ids}).encode()
    req = urllib.request.Request(API, data=body, headers={"Content-Type": "application/json"})
    return json.loads(urllib.request.urlopen(req, timeout=120).read()).get("pairs") or []


def score(pairs: list, pos: dict):
    use = []
    for p in pairs:
        a, b = pos.get(p["a"]), pos.get(p["b"])
        if a is None or b is None:
            continue
        d = ((a[0] - b[0]) ** 2 + (a[1] - b[1]) ** 2) ** 0.5
        use.append((float(p["sim"]), d))
    if len(use) < 2:
        return None
    ss = [u[0] for u in use]
    ds = [u[1] for u in use]
    lo_s, hi_s, lo_d, hi_d = min(ss), max(ss), min(ds), max(ds)
    n_sim = (lambda s: (s - lo_s) / (hi_s - lo_s)) if hi_s > lo_s else (lambda s: 0.5)
    n_cl = (lambda d: 1 - (d - lo_d) / (hi_d - lo_d)) if hi_d > lo_d else (lambda d: 0.5)
    t = [abs(n_sim(s) - n_cl(d)) for s, d in use]
    return round((1 - sum(t) / len(t)) * 100)


def main() -> int:
    names, n_shuf = [], 200
    for a in sys.argv[1:]:
        if a.startswith("--maps="):
            names = [x for x in a.split("=", 1)[1].split(",") if x]
        elif a.startswith("--shuffles="):
            n_shuf = int(a.split("=", 1)[1])
    if not names:
        print(__doc__)
        return 2

    print(f"{'map':<34}{'n':>4}{'authored':>10}{'shuffled mean':>15}{'min':>6}{'max':>6}{'pctile':>8}  verdict")
    print("-" * 104)
    rows = []
    for m in names:
        pos = placed(m)
        if len(pos) < 4:
            print(f"{m:<34}{len(pos):>4}   fewer than 4 placed artifacts — skipped")
            continue
        ids = sorted(pos)
        pr = sims(ids)
        if not pr:
            print(f"{m:<34}{len(ids):>4}   no similarities returned")
            continue
        real = score(pr, pos)
        coords = list(pos.values())
        rng = random.Random(20260815)          # seeded: the control must be reproducible
        shuf = []
        for _ in range(n_shuf):
            perm = coords[:]
            rng.shuffle(perm)
            s = score(pr, dict(zip(ids, perm)))
            if s is not None:
                shuf.append(s)
        if not shuf:
            continue
        below = sum(1 for s in shuf if s < real)
        pct = 100.0 * below / len(shuf)
        # A meter that reads alignment should put an authored map high in its own null
        # distribution. Inside the middle 80% means the shuffle explains it.
        verdict = ("indistinguishable from chance" if 10 <= pct <= 90
                   else "above chance" if pct > 90 else "BELOW chance")
        rows.append((m, real, sum(shuf) / len(shuf), pct))
        print(f"{m:<34}{len(ids):>4}{real:>10}{sum(shuf)/len(shuf):>15.1f}"
              f"{min(shuf):>6}{max(shuf):>6}{pct:>7.0f}%  {verdict}")
    if rows:
        print("-" * 104)
        n_ind = sum(1 for _, _, _, p in rows if 10 <= p <= 90)
        print(f"  {n_ind} of {len(rows)} authored layouts sit inside the middle 80% of their own "
              f"shuffle distribution.")
        print(f"  mean authored {sum(r[1] for r in rows)/len(rows):.1f}   "
              f"mean shuffled {sum(r[2] for r in rows)/len(rows):.1f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
