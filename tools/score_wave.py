#!/usr/bin/env python3
"""score_wave.py — score every pre-registered pair prediction in a wave against its sweep.

The prediction names a PAIR on an axis; that pair's RANK among all pairs differing only on
that axis is what is scored. A rank is unit-free. Comparing the predicted percentage to the
measured one is not, because predictions are written as a share of the subject and the sweep
reports a share of the frame — wave 13 lost an hour to that mismatch. The number is still
printed, as a floor, and a sweep landing UNDER it is the signal to look for a capture fault.

Usage: python tools/score_wave.py --slug=wave14 --tokens=a,b,c
Writes ada_run/<slug>_scores.json for the gallery builder.
"""
from __future__ import annotations
import json, pathlib, sys
REPO = pathlib.Path(__file__).resolve().parents[1]
REG = REPO / "commons" / "artifacts" / "registry"

def main() -> int:
    slug, toks = "", []
    for a in sys.argv[1:]:
        if a.startswith("--slug="): slug = a.split("=",1)[1]
        if a.startswith("--tokens="): toks = [t for t in a.split("=",1)[1].split(",") if t]
    if not slug or not toks:
        print(__doc__); return 2
    out = {}
    print(f"{'synthesis':<18}{'predicted pair':<28}{'rank':>9}   closest pair            meas%")
    print("-"*100)
    for tok in toks:
        e = json.loads((REG / f"{tok}.json").read_text(encoding="utf-8"))["artifacts"][tok]
        pd = (e.get("dna") or {}).get("predicted_degeneracy") or {}
        pair = str(pd.get("pair",""))
        # "<A> against <B>, in the <ctx> ..." — the two values are the words around "against"
        head = pair.split(",")[0]
        if " against " not in head:
            print(f"{tok:<18} prediction not parseable: {pair!r}"); continue
        va, vb = [s.strip() for s in head.split(" against ",1)]
        axes = list(((e.get("dna") or {}).get("axes") or {}).keys())
        bite = REPO / "doc" / "reports" / f"sweep_{tok}_bite.json"
        if not bite.exists():
            print(f"{tok:<18} no bite file"); continue
        d = json.loads(bite.read_text(encoding="utf-8"))
        # which axis holds both values?
        axis = next((a for a in axes if any(str(r["a"].get(a)) in (va,vb) for r in d["variants"])), axes[0] if axes else "")
        same = [r for r in d["variants"]
                if [q for q in r["a"] if str(r["a"][q]) != str(r["b"].get(q))] == [axis]]
        same.sort(key=lambda r: r["changed_pct"])
        idx = next((i for i,r in enumerate(same)
                    if {str(r["a"][axis]),str(r["b"][axis])} == {va,vb}), None)
        if idx is None:
            avail = sorted({f"{r['a'][axis]}/{r['b'][axis]}" for r in same})
            print(f"{tok:<18}{va+' vs '+vb:<28} pair not measured; have {avail[:5]}"); continue
        c = same[0]
        out[tok] = dict(pred=pd.get("percent"), pair=f"{va} vs {vb}", axis=axis,
            rank=idx+1, n=len(same), hit=(idx==0), meas=round(same[idx]["changed_pct"],2),
            closest=f'{c["a"][axis]} vs {c["b"][axis]}', closest_pct=round(c["changed_pct"],2))
        print(f"{tok:<18}{va+' vs '+vb:<28}#{idx+1:>2}/{len(same):<3} {'HIT ' if idx==0 else 'MISS'}  "
              f"{out[tok]['closest']:<22}{out[tok]['meas']:>6}")
    (REPO/"ada_run"/f"{slug}_scores.json").write_text(json.dumps(out,indent=1),encoding="utf-8")
    print("\n  %d of %d named the closest pair"
          % (sum(1 for v in out.values() if v["hit"]), len(out)))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
