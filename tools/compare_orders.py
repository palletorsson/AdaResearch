"""compare_orders.py — how does the MANUAL trajectory differ from every other order?

Takes doc/book/manual_order.json (the ghost's editorial sort: beats as spine,
voltage placed for drama, deliberate inversions) and correlates it, per spine
sequence, against every other order the project owns:

  · consensus   — three-orders (ped+onto+crit)/3 (the old /tutorial order)
  · pedagogy    — the ped axis alone
  · ontology    — the onto axis alone
  · criticality — the crit axis alone
  · engine      — Godot docs-order stage + inheritance depth (miner v2)
  · atoms       — the atom-ladder construction grade (miner v1)

Spearman rank correlation on common artifacts. High rho = the manual sort was
already implicit in that lens; low/negative = the editor did something none of
the metrics would have done (that residue is the craft).

Output: doc/book/order_comparison.json  (+ printed table)

Usage:
  python tools/compare_orders.py [--seq=<id>]
"""

import json
import os
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ENC = Path(os.environ.get("ADA_ENCYCLOPEDIA_PATH", ROOT.parent / "ada_encyclopedia"))
MANUAL = ROOT / "doc" / "book" / "manual_order.json"
THREE_ORDERS = ENC / "public" / "three-orders.json"
CONSTRUCTION = ROOT / "doc" / "book" / "construction_edges.json"
OUT = ROOT / "doc" / "book" / "order_comparison.json"

LENSES = ["consensus", "pedagogy", "ontology", "criticality", "engine", "atoms"]


def jload(p):
    return json.loads(Path(p).read_text(encoding="utf-8"))


def spearman(xs, ys):
    n = len(xs)
    if n < 4:
        return None

    def ranks(v):
        order = sorted(range(n), key=lambda i: v[i])
        r = [0.0] * n
        i = 0
        while i < n:
            j = i
            while j + 1 < n and v[order[j + 1]] == v[order[i]]:
                j += 1
            avg = (i + j) / 2 + 1
            for k in range(i, j + 1):
                r[order[k]] = avg
            i = j + 1
        return r

    rx, ry = ranks(xs), ranks(ys)
    mx, my = sum(rx) / n, sum(ry) / n
    cov = sum((rx[i] - mx) * (ry[i] - my) for i in range(n))
    vx = sum((rx[i] - mx) ** 2 for i in range(n)) ** 0.5
    vy = sum((ry[i] - my) ** 2 for i in range(n)) ** 0.5
    return cov / (vx * vy) if vx and vy else None


def main():
    only = None
    for a in sys.argv[1:]:
        if a.startswith("--seq="):
            only = a.split("=", 1)[1]

    manual = jload(MANUAL)["sequences"]
    orders = {s["seq"]: s for s in jload(THREE_ORDERS).get("sequences", [])}
    nodes = jload(CONSTRUCTION)["nodes"]

    out = {"generated_by": "tools/compare_orders.py", "sequences": {}}
    rows = []
    for seq, entry in manual.items():
        if only and seq != only:
            continue
        order = entry["order"]
        mrank = {a: i for i, a in enumerate(order)}
        o = orders.get(seq, {})
        pearls = o.get("pearls", [])
        pos = {ax: {} for ax in ("ped", "onto", "crit")}
        for i, name in enumerate(pearls):
            for ax in pos:
                arr = o.get(ax, [])
                if i < len(arr):
                    pos[ax][name] = arr[i]

        res = {}
        for lens in LENSES:
            xs, ys = [], []
            for a in order:
                base = a.split("#")[0]
                m = mrank[a]
                if lens == "consensus":
                    vals = [pos[ax].get(base) for ax in pos]
                    vals = [v for v in vals if v is not None]
                    if len(vals) == 3:
                        xs.append(m)
                        ys.append(sum(vals) / 3)
                elif lens in ("pedagogy", "ontology", "criticality"):
                    ax = {"pedagogy": "ped", "ontology": "onto", "criticality": "crit"}[lens]
                    v = pos[ax].get(base)
                    if v is not None:
                        xs.append(m)
                        ys.append(v)
                elif lens == "engine":
                    n = nodes.get(base)
                    if n and n.get("engine", {}).get("base"):
                        e = n["engine"]
                        xs.append(m)
                        ys.append(e["stage"] * 100 + e["engine_depth"] + e["script_hops"])
                elif lens == "atoms":
                    n = nodes.get(base)
                    if n and "grade" in n:
                        xs.append(m)
                        ys.append(n["grade"])
            rho = spearman(xs, ys)
            res[lens] = {"rho": round(rho, 3) if rho is not None else None, "n": len(xs)}

        best = max((l for l in LENSES if res[l]["rho"] is not None),
                   key=lambda l: res[l]["rho"], default=None)
        out["sequences"][seq] = {"arc": entry.get("arc", ""), "lenses": res,
                                 "closest_lens": best}
        rows.append((seq, res, best))

    OUT.write_text(json.dumps(out, ensure_ascii=False, indent=1), encoding="utf-8")

    hdr = f"{'sequence':24}" + "".join(f"{l[:7]:>9}" for l in LENSES) + "   closest"
    print(hdr)
    for seq, res, best in rows:
        cells = "".join(
            f"{(str(res[l]['rho']) if res[l]['rho'] is not None else '—'):>9}" for l in LENSES)
        print(f"{seq:24}{cells}   {best}")
    # per-lens mean across sequences
    print()
    for l in LENSES:
        vals = [r[1][l]["rho"] for r in rows if r[1][l]["rho"] is not None]
        if vals:
            print(f"mean rho vs {l}: {sum(vals)/len(vals):+.3f} ({len(vals)} seqs)")
    from collections import Counter
    print("closest-lens census:", dict(Counter(r[2] for r in rows if r[2])))
    print(f"-> {OUT}")


if __name__ == "__main__":
    main()
