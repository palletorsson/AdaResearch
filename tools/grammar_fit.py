# -*- coding: utf-8 -*-
"""grammar_fit.py — THE INVERSE COMPOSER (round 11, the ARC lens).

Forward, the composer runs spec -> map. This runs map -> rule: for any
existing map it induces the best-fitting program in the canon's vocabulary
and reports it as a readable sentence of clauses, e.g.

    Thread_Gate: frame:ring + order:crescendo(0.95) + elevation:procession
                 + arrival:compression   [4 clauses, organization 0.71]

Organization = how much of the map the induced rule explains (a BAND, not a
maximand: too low is noise, too high is monotony — doc/ARC_ORGANIZATION.md).
Residual = 1 - organization = the mass the grammar cannot express. For hand
maps the residual is not a defect; it is the protected irreducible.

CLI:
  python tools/grammar_fit.py <MapName> [<MapName> ...]   # rule sentences
  python tools/grammar_fit.py --all                       # sweep -> index
  python tools/grammar_fit.py --extremes                  # top/bottom from index
"""
import json, math, sys, argparse, pathlib
from collections import deque

ROOT = pathlib.Path(__file__).resolve().parents[1]
MAPS = ROOT / "commons/maps"
elems = json.loads((ROOT / "commons/data/artifact_elements.json").read_text(encoding="utf-8"))["artifacts"]
PRE = ("cluster:", "mc:", "gridagent:", "criticalinfo:")


def afp(k):
    s = (elems.get(k, {}).get("union_aabb") or {}).get("size") or [1.0, 1.0, 1.0]
    w, d = max(0.2, s[0]), max(0.2, s[2])
    if max(w, d) / min(w, d) > 4.0:            # REACH law: body, not beam
        w = d = min(w, d)
    return max(1, math.ceil(w) * math.ceil(d))


def spearman(xs, ys):
    n = len(xs)
    if n < 3: return 0.0
    def rank(v):
        order = sorted(range(n), key=lambda i: v[i])
        r = [0.0] * n
        i = 0
        while i < n:
            j = i
            while j + 1 < n and v[order[j + 1]] == v[order[i]]: j += 1
            avg = (i + j) / 2.0
            for k2 in range(i, j + 1): r[order[k2]] = avg
            i = j + 1
        return r
    rx, ry = rank(xs), rank(ys)
    mx, my = sum(rx) / n, sum(ry) / n
    num = sum((rx[i] - mx) * (ry[i] - my) for i in range(n))
    den = math.sqrt(sum((rx[i] - mx) ** 2 for i in range(n)) * sum((ry[i] - my) ** 2 for i in range(n)))
    return num / den if den else 0.0


def load_map(name):
    p = MAPS / name / "map_data.json"
    if not p.exists(): return None
    try:
        return json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return None


def fit(name, md):
    L = md.get("layers", {})
    S = L.get("structure") or []
    U = L.get("utilities") or []
    I = L.get("interactables") or []
    if not S or not S[0]: return None
    D, W = len(S), max(len(r) for r in S)

    def h_at(x, z):
        row = S[z] if z < len(S) else []
        c = row[x] if x < len(row) else "0"
        try: return int(float(str(c).strip() or "0"))
        except Exception: return 1 if str(c).strip() else 0

    floor = {(x, z) for z in range(D) for x in range(W) if 0 < h_at(x, z) <= 3}
    if len(floor) < 12: return None
    xs = [c[0] for c in floor]; zs = [c[1] for c in floor]
    bw, bd = max(xs) - min(xs) + 1, max(zs) - min(zs) + 1
    long_side, short_side = max(bw, bd), min(bw, bd)

    # spawn + BFS encounter order (the walker's experience of the map)
    spawn = None
    for z, row in enumerate(U):
        for x, c in enumerate(row):
            if str(c).strip() == "s": spawn = (x, z)
    if spawn is None or spawn not in floor:
        spawn = min(floor)
    dist = {spawn: 0}
    dq = deque([spawn])
    while dq:
        x, z = dq.popleft()
        for nb in ((x + 1, z), (x - 1, z), (x, z + 1), (x, z - 1)):
            if nb in floor and nb not in dist:
                dist[nb] = dist[(x, z)] + 1
                dq.append(nb)

    arts = []
    for z, row in enumerate(I):
        for x, c in enumerate(row):
            tok = str(c).strip()
            if not tok or tok.startswith(PRE): continue
            base = tok.split(":")[0]
            if base in elems:
                arts.append((dist.get((x, z), 10 ** 6), base, (x, z)))
    arts.sort()
    order = [a[1] for a in arts if a[0] < 10 ** 6]
    cells_seq = [afp(k) for k in order]

    clauses, strengths = [], []

    # frame: band / ring / massed. A ring here is OUR ring — a court with
    # rooms as petals (artifacts spread around the centroid) — not an annulus.
    aspect = long_side / max(1, short_side)
    ring = False
    cx, cz = (min(xs) + max(xs)) / 2, (min(zs) + max(zs)) / 2
    art_cells = [(x, z) for z, row in enumerate(I) for x, c in enumerate(row)
                 if str(c).strip() and not str(c).strip().startswith(PRE)]
    if aspect < 2.0 and short_side >= 14 and len(art_cells) >= 5:
        sectors = set()
        for (x, z) in art_cells:
            ang = math.atan2(z - cz, x - cx)
            sectors.add(int(((ang + math.pi) / (2 * math.pi)) * 12) % 12)
        ring = len(sectors) >= 8
    if ring:
        clauses.append("frame:ring"); strengths.append(1.0)
    elif aspect >= 3.0 and short_side <= 16:
        clauses.append("frame:band"); strengths.append(min(1.0, aspect / 5))
    elif aspect >= 1.8:
        clauses.append("frame:spine"); strengths.append(min(1.0, aspect / 3))
    else:
        strengths.append(0.0)          # massed / no frame clause

    # order pattern along the walk
    if len(cells_seq) >= 4:
        rho = spearman(cells_seq, list(range(len(cells_seq))))
        diffs = [cells_seq[i + 1] - cells_seq[i] for i in range(len(cells_seq) - 1)]
        signs = [1 if d > 0 else -1 if d < 0 else 0 for d in diffs]
        flips = sum(1 for i in range(len(signs) - 1)
                    if signs[i] and signs[i + 1] and signs[i] != signs[i + 1])
        fliprate = flips / max(1, len(signs) - 1)
        if rho >= 0.6:
            clauses.append(f"order:crescendo({round(rho, 2)})"); strengths.append(rho)
        elif rho <= -0.6:
            clauses.append(f"order:diminuendo({round(-rho, 2)})"); strengths.append(-rho)
        elif fliprate >= 0.6:
            clauses.append(f"order:rhythm({round(fliprate, 2)})"); strengths.append(fliprate)
        else:
            strengths.append(0.0)
    elif cells_seq:
        strengths.append(0.0)

    # elevation along the walk
    if len(arts) >= 4:
        hs = [h_at(*a[2]) for a in arts if a[0] < 10 ** 6]
        if hs and len(set(hs)) > 1:
            rho = spearman(hs, list(range(len(hs))))
            if rho >= 0.55:
                clauses.append(f"elevation:procession({round(rho, 2)})"); strengths.append(rho)
            else:
                strengths.append(0.3)  # varied but unpatterned height
        else:
            clauses.append("elevation:flat"); strengths.append(0.5)

    # symmetry of the floor mask (ARC prior)
    ax = sum(1 for (x, z) in floor if (min(xs) + max(xs) - x, z) in floor) / len(floor)
    az = sum(1 for (x, z) in floor if (x, min(zs) + max(zs) - z) in floor) / len(floor)
    sym = max(ax, az)
    if sym >= 0.75:
        clauses.append(f"symmetry:mirror({round(sym, 2)})"); strengths.append(sym)
    else:
        strengths.append(sym * 0.5)

    # room discipline: local free area correlates with artifact size
    if len(arts) >= 4:
        local = []
        for _, k, (x, z) in arts[:24]:
            area = sum(1 for dx in range(-3, 4) for dz in range(-3, 4) if (x + dx, z + dz) in floor)
            local.append(area)
        rho = spearman(local, [afp(a[1]) for a in arts[:24]])
        if rho >= 0.5:
            clauses.append(f"rooms:banded({round(rho, 2)})"); strengths.append(rho)
        else:
            strengths.append(max(0.0, rho))

    # arrival: compression near the spawn
    if dist:
        near = [c for c in floor if dist.get(c, 10 ** 6) <= max(4, len(floor) // 25)]
        far_width = len(floor) / max(1, long_side)
        near_width = len(near) / max(1, max(4, len(floor) // 25))
        if near and near_width <= 0.55 * far_width:
            clauses.append("arrival:compression"); strengths.append(1.0)
        else:
            strengths.append(0.2)

    organization = round(sum(strengths) / max(1, len(strengths)), 3)
    band = "alive" if 0.35 <= organization <= 0.8 else ("monotone-risk" if organization > 0.8 else "noise-risk")
    return {"map": name, "W": W, "D": D, "artifacts": len(order),
            "rule": clauses, "clauses": len(clauses),
            "organization": organization, "residual": round(1 - organization, 3),
            "band": band}


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("names", nargs="*")
    ap.add_argument("--all", action="store_true")
    ap.add_argument("--extremes", action="store_true")
    a = ap.parse_args()
    sys.stdout.reconfigure(encoding="utf-8")
    idx_path = ROOT / "commons/data/grammar_fit_index.json"

    if a.extremes:
        idx = json.loads(idx_path.read_text(encoding="utf-8"))["maps"]
        rows = sorted(idx, key=lambda r: -r["organization"])
        print("MOST organized:")
        for r in rows[:8]: print(f"  {r['organization']:.2f} {r['map']:34s} {' + '.join(r['rule'])}")
        print("LEAST organized (residual-heavy — noise or protected hand-craft):")
        for r in rows[-8:]: print(f"  {r['organization']:.2f} {r['map']:34s} {' + '.join(r['rule']) or '(no rule found)'}")
        return

    if a.all:
        out, skipped = [], 0
        for d in sorted(MAPS.iterdir()):
            if not (d / "map_data.json").exists(): continue
            md = load_map(d.name)
            r = fit(d.name, md) if md else None
            if r: out.append(r)
            else: skipped += 1
        from statistics import mean
        orgs = [r["organization"] for r in out]
        bands = {}
        for r in out: bands[r["band"]] = bands.get(r["band"], 0) + 1
        summary = {"maps": len(out), "skipped": skipped,
                   "organization_mean": round(mean(orgs), 3),
                   "bands": bands}
        idx_path.write_text(json.dumps({"summary": summary, "maps": out}, indent=0), encoding="utf-8")
        print(json.dumps(summary, indent=1))
        return

    for n in a.names:
        md = load_map(n)
        r = fit(n, md) if md else None
        if not r:
            print(f"{n}: unfittable (missing or too small)")
            continue
        print(f"{n}: {' + '.join(r['rule']) or '(no rule found)'}")
        print(f"   [{r['clauses']} clauses, organization {r['organization']}, residual {r['residual']}, {r['band']}]")


if __name__ == "__main__":
    main()
