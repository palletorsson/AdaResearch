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
import json, pathlib, re, sys
REPO = pathlib.Path(__file__).resolve().parents[1]
REG = REPO / "commons" / "artifacts" / "registry"
ENC = pathlib.Path(__file__).resolve().parents[2] / "ada_encyclopedia"

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
        # A builder writing "rule 90 against rule 250" is writing English, not a lookup key.
        # Strip a leading axis-name word so the value matches the enum ("90"), and strip
        # surrounding quotes/backticks while we are here. Being brittle about this made a
        # correctly-registered prediction read as "pair not measured".
        def _bare(s: str) -> str:
            s = s.strip().strip("`'\"")
            # "cut=axis against cut=margin" — a builder naming the axis inline with an equals
            # sign, which is just as readable as "rule 90" and just as unparseable if we only
            # strip leading WORDS. Drop a "<name>=" prefix when <name> is one of this
            # artifact's axes. Second time this parser has been too literal about English.
            if "=" in s:
                head, _, tail = s.partition("=")
                axnames = {a.lower() for a in
                           ((json.loads((REG / f"{tok}.json").read_text(encoding="utf-8"))
                             ["artifacts"][tok].get("dna") or {}).get("axes") or {})}
                if head.strip().lower() in axnames and tail.strip():
                    s = tail.strip()
            parts = s.split()
            if len(parts) > 1 and parts[0].lower() in {a.lower() for a in
                    ((json.loads((REG / f"{tok}.json").read_text(encoding="utf-8"))
                      ["artifacts"][tok].get("dna") or {}).get("axes") or {})}:
                return " ".join(parts[1:])
            return s
        va, vb = _bare(va), _bare(vb)
        axes = list(((e.get("dna") or {}).get("axes") or {}).keys())
        bite = REPO / "doc" / "reports" / f"sweep_{tok}_bite.json"
        if not bite.exists():
            print(f"{tok:<18} no bite file"); continue
        d = json.loads(bite.read_text(encoding="utf-8"))
        # which axis holds both values?
        axis = next((a for a in axes if any(str(r["a"].get(a)) in (va,vb) for r in d["variants"])), axes[0] if axes else "")
        # THE PREDICTION NAMES A CONTEXT, AND THE RANKING MUST HONOUR IT. "planar against
        # fanned, in the PLANT reading" is a claim about one reading, and pooling every reading
        # into one ranking compares it against pairs from another — habit_grove's `crown` shows
        # 171 tips and almost no ink, so every crown pair reads frame-close and the six crown
        # pairs took the whole top of the ladder. The published gallery then reported a
        # crown-reading pair as the answer to a plant-reading prediction. Same fault the
        # critic's CONDITIONAL check exists for: one axis diluted by the axis it is crossed with.
        ctx = {}
        m2 = re.search(r",\s*(?:in|on)\s+the\s+(\S+)\s+(\w+)\s*$", pair.strip())
        if m2:
            cval, ckey = m2.group(1), m2.group(2)
            other = [a for a in axes if a != axis]
            if ckey in axes:
                ctx = {ckey: cval}
            elif other and any(str(r["a"].get(other[0])) == cval for r in d["variants"]):
                ctx = {other[0]: cval}
        same = [r for r in d["variants"]
                if [q for q in r["a"] if str(r["a"][q]) != str(r["b"].get(q))] == [axis]
                and all(str(r["a"].get(k)) == str(v) for k, v in ctx.items())]
        if ctx:
            print(f"{'':18}  (ranked within {ctx}, as the prediction names it)")
        # DESIGNED NULLS ARE NOT IN THE RACE. A builder who registers "row vs ramp in the
        # footprint reading is identical by construction" has said in advance that this pair
        # will be the closest, and that the prediction is for the closest pair that is NOT a
        # null. Ranking the prediction behind its own declared identities would score the
        # builder as wrong for being right twice. So null pairs are removed before ranking and
        # scored separately as HELD / BROKEN.
        fx0 = ((e.get("dna") or {}).get("fixture") or {})
        declared = (pd.get("designed_nulls") or []) + ((e.get("dna") or {}).get("designed_nulls") or [])
        def _is_null(r):
            for nd in declared:
                a, b = nd.get("a") or {}, nd.get("b") or {}
                ma = lambda side, want: all(str(side.get(k)) == str(v) for k, v in want.items() if k not in fx0)
                if (ma(r["a"], a) and ma(r["b"], b)) or (ma(r["a"], b) and ma(r["b"], a)):
                    return True
            return False
        removed = [r for r in same if _is_null(r)]
        same = [r for r in same if not _is_null(r)]
        # A RANK INHERITS ITS METRIC, the third thing after its denominator and its pool.
        # `changed_pct` COUNTS pixels differing by more than a threshold; it does not measure HOW
        # MUCH they differ. On an axis that changes only colour inside a fixed geometry, the set of
        # pixels that move is the same set for every pair, so the count is CONSTANT and the ranking
        # is not a ranking at all. ground_layer measured all six of its priming pairs at 12.994% —
        # equal to three decimals — and the arbitrary sort order put its prediction 5th of 6, a
        # MISS. Under the metric the prediction actually named (mean |luma delta| over the frame,
        # written into dna.predicted_degeneracy.metric) the same six pairs spread 1.9% to 8.7% and
        # the predicted pair is 1st, at 1.919% against a predicted 1.797%. So: honour a declared
        # magnitude metric, and refuse to report a rank at all when the chosen metric ties.
        want_mag = any(w in str(pd.get("metric", "")).lower()
                       for w in ("luma", "luminance", "mean absolute", "mean |", "grey", "gray"))
        metric_name = "changed_pct (count)"
        if want_mag and same:
            try:
                from PIL import Image, ImageChops
                gd = ENC / "public" / slug

                def _png(side: dict):
                    want = {f"{k}-{v}" for k, v in side.items()}
                    for h in sorted(gd.glob(f"{tok}__*.png")):
                        if want <= set(h.stem.split("__")[1:]):
                            return h
                    return None

                for r in same:
                    fa, fb = _png(r["a"]), _png(r["b"])
                    if not (fa and fb):
                        raise RuntimeError("frame missing")
                    da = list(ImageChops.difference(Image.open(fa).convert("L"),
                                                    Image.open(fb).convert("L")).getdata())
                    r["_mag"] = 100.0 * (sum(da) / len(da)) / 255.0
                metric_name = "mean |luma delta| (magnitude, as the prediction declared)"
                print(f"{'':18}  (ranked on {metric_name})")
            except Exception as ex:
                print(f"{'':18}  (declared a magnitude metric but could not compute it: {ex};"
                      f" falling back to changed_pct)")
                for r in same:
                    r.pop("_mag", None)
        key = (lambda r: r.get("_mag", r["changed_pct"]))
        same.sort(key=key)
        if len(same) > 1 and (key(same[-1]) - key(same[0])) < 1e-6:
            print(f"{'':18}  !! every pair measures {key(same[0]):.3f} on {metric_name} — this "
                  f"metric CANNOT rank this axis; the reported rank would be sort order, not a result")
        if removed:
            print(f"{'':18}  ({len(removed)} designed-null pair(s) set aside before ranking)")
        idx = next((i for i,r in enumerate(same)
                    if {str(r["a"][axis]),str(r["b"][axis])} == {va,vb}), None)
        if idx is None:
            # THE PREDICTION MAY BE ITS OWN NULL, and that is the strongest form of it: the
            # builder says "the closest pair on this axis is X against Y, and it is EXACTLY
            # ZERO by construction". configuration_yard did that — ring and lagrange enter the
            # same branch of _initial at the same radius and angles, differing only in a scalar
            # speed that `start` does not draw. Setting nulls aside before ranking then made a
            # correctly-registered prediction read as "pair not measured". A null-prediction is
            # rank #1 by construction; what is scored is whether the null HELD.
            hit_null = next((r for r in removed
                             if {str(r["a"][axis]),str(r["b"][axis])} == {va,vb}), None)
            if hit_null is not None:
                mv = round(hit_null["changed_pct"], 2)
                out[tok] = dict(pred=pd.get("percent"), pair=f"{va} vs {vb}", axis=axis,
                    rank=1, n=len(same) + len(removed), hit=True, meas=mv,
                    closest=f"{va} vs {vb}", closest_pct=mv, predicted_own_null=True)
                print(f"{tok:<18}{va+' vs '+vb:<28}#{1:>2}/{len(same)+len(removed):<3} HIT   "
                      f"{'(predicted its own null)':<22}{mv:>6}")
            else:
                avail = sorted({f"{r['a'][axis]}/{r['b'][axis]}" for r in same})
                print(f"{tok:<18}{va+' vs '+vb:<28} pair not measured; have {avail[:5]}")
                continue
        if idx is not None:
            c = same[0]
            out[tok] = dict(pred=pd.get("percent"), pair=f"{va} vs {vb}", axis=axis,
                rank=idx+1, n=len(same), hit=(idx==0),
                meas=round(same[idx].get("_mag", same[idx]["changed_pct"]),2), metric=metric_name,
                closest=f'{c["a"][axis]} vs {c["b"][axis]}',
                closest_pct=round(c.get("_mag", c["changed_pct"]),2))
            print(f"{tok:<18}{va+' vs '+vb:<28}#{idx+1:>2}/{len(same):<3} "
                  f"{'HIT ' if idx==0 else 'MISS'}  "
                  f"{out[tok]['closest']:<22}{out[tok]['meas']:>6}")
        # DESIGNED NULLS — pairs the builder said would be identical BY CONSTRUCTION, with a
        # ceiling. A held null is a negative control that proves the sweep can see a difference
        # when there is one and reports none when there is not; a broken null is a real finding
        # about the artifact. Wave 14 scored plumb_room's two by hand; this makes it routine.
        nulls = []
        for nd in (pd.get("designed_nulls") or []) + ((e.get("dna") or {}).get("designed_nulls") or []):
            a, b, cap = nd.get("a") or {}, nd.get("b") or {}, float(nd.get("under_percent") or 0.3)
            fx = ((e.get("dna") or {}).get("fixture") or {})
            # A NULL CONDITIONED ON A PINNED PARAMETER WAS NEVER TESTED, AND CALLING IT BROKEN IS
            # A LIE ABOUT THE ARTIFACT. Fixture keys are dropped from the match below so a builder
            # need not restate what the fixture already pins — but if the null asks for a
            # DIFFERENT value of a pinned key, dropping it silently rewrites the claim into one
            # about the pinned value instead, and then measures that. temperament_table registered
            # three nulls on `comma_gain` (at 1.0, 0.0 and 40.0) while dna.fixture pins it at 5.0:
            # at gain 1.0 the comma branch IS the just branch and at 0.0 it IS the tempered branch,
            # both true, and neither frame was ever rendered. Two came back BROKEN at ~4.9% and the
            # third as "no such pair", which read as the first null failures since wave 14. They are
            # UNTESTED. Same family as every other fault this programme has found in its own
            # instruments: a confident verdict that is a fact about the harness.
            conflict = {k: (fx[k], v) for k, v in list(a.items()) + list(b.items())
                        if k in fx and str(fx[k]) != str(v)}
            if conflict:
                nulls.append(dict(a=a, b=b, under=cap, measured=None, held=None,
                                  untested=True, conflict={k: {"pinned": p, "asked": q}
                                                           for k, (p, q) in conflict.items()}))
                for k, (p, q) in conflict.items():
                    print(f"{'':18}  null {a} vs {b}: UNTESTED — dna.fixture pins "
                          f"{k}={p}, the null is about {k}={q}; the sweep never rendered it")
                continue
            def _match(row_side, want):
                return all(str(row_side.get(k)) == str(v) for k, v in want.items() if k not in fx)
            hitrow = next((r for r in d["variants"]
                           if (_match(r["a"], a) and _match(r["b"], b)) or (_match(r["a"], b) and _match(r["b"], a))), None)
            if hitrow is None:
                # The bite file stores EVERY pair (C(n,2) rows — checked on depth_well: 105 of
                # 105), so a miss here means the null names a value the sweep did not render
                # (a dropped value under --max, or a typo in the registered dna). Say so.
                nulls.append(dict(a=a, b=b, under=cap, measured=None, held=None))
                print(f"{'':18}  null {a} vs {b}: no such pair in the sweep — value not rendered or misnamed")
                continue
            m = round(hitrow["changed_pct"], 2)
            # A NULL INHERITS ITS METRIC. The sweep's changed_pct is PER-CHANNEL; a builder who
            # solved two colours to equal LUMA has registered a greyscale identity and has to be
            # scored in greyscale. face_convention did exactly that: its two_tone/inverted pair
            # measures 0.00% in luma — max difference 2 of 255, the solve was right to the byte —
            # and 6.45% per channel, because red and blue swap at constant brightness. Scored on
            # the wrong metric, a held null was reported BROKEN. Same family as the context and
            # denominator faults already fixed here: the arithmetic was fine, the question was not.
            why = str(nd.get("why", "")).lower()
            grey = any(w in why for w in ("luma", "luminance", "grey", "gray", "greyscale"))
            lum = None
            if grey:
                try:
                    from PIL import Image, ImageChops
                    gd = ENC / "public" / slug

                    def _png(side: dict):
                        want = {f"{k}-{v}" for k, v in side.items()}
                        for h in sorted(gd.glob(f"{tok}__*.png")):
                            if want <= set(h.stem.split("__")[1:]):
                                return h
                        return None

                    fa, fb = _png(a), _png(b)
                    if fa and fb:
                        da = list(ImageChops.difference(Image.open(fa).convert("L"),
                                                        Image.open(fb).convert("L")).getdata())
                        lum = round(100.0 * sum(1 for v in da if v > 12) / len(da), 2)
                except Exception:
                    lum = None
            use = lum if lum is not None else m
            held = use <= cap
            tag = "luma" if lum is not None else "per-channel"
            extra = f"  [luma {lum}% · per-channel {m}%]" if lum is not None else ""
            nulls.append(dict(a=a, b=b, under=cap, measured=use, per_channel=m, luma=lum,
                              metric=tag, held=held))
            print(f"{'':18}  null {a} vs {b}: {use}% ({tag}) "
                  f"{'HELD' if held else 'BROKEN'} (< {cap}%){extra}")
        if nulls:
            out[tok]["nulls"] = nulls
    (REPO/"ada_run"/f"{slug}_scores.json").write_text(json.dumps(out,indent=1),encoding="utf-8")
    print("\n  %d of %d named the closest pair"
          % (sum(1 for v in out.values() if v["hit"]), len(out)))
    return 0

if __name__ == "__main__":
    raise SystemExit(main())
