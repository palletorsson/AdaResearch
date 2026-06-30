#!/usr/bin/env python
"""build_spine_narrative.py — the curriculum spine as one readable narrative,
plus the measure of whether the order holds.

The spine is the project's one ordered story: 22 sequences across 7 QFEP
phases (structure -> oscillation -> entropy -> edge-of-chaos -> emergence ->
relation -> synthesis). Reading it top-to-bottom is the human coherence test.
But narrative is forgiving, so we also MEASURE: each sequence is embedded as
the mean of its artifacts' vectors (doc/atlas), and we report the distance
from the previous sequence in concept space. Where the story feels like it
jumps, the transition distance spikes — three-orders at the spine scale.

  Out: ada_encyclopedia/public/spine-narrative.json

Run: python tools/build_spine_narrative.py
"""
import json
import os

import numpy as np

import three_orders as to

ROOT = to.ROOT
ENC = os.path.join(os.path.dirname(ROOT), "ada_encyclopedia")
OUT = os.path.join(ENC, "public", "spine-narrative.json")


_SIZES = None


def base_of(a):
    """Footprint (base_m) of an artifact — max(static, live), the truth the size-gate uses."""
    global _SIZES
    if _SIZES is None:
        st = to.load(os.path.join(ROOT, "commons", "data", "artifact_sizes.json")).get("sizes", {})
        lvp = os.path.join(ROOT, "commons", "data", "artifact_sizes_live.json")
        lv = to.load(lvp).get("sizes", {}) if os.path.exists(lvp) else {}
        _SIZES = (st, lv)
    st, lv = _SIZES
    return max(float((st.get(a) or {}).get("base_m", 0) or 0),
               float((lv.get(a) or {}).get("base_m", 0) or 0))


def seq_metrics(seq):
    """Embedding + footprint of a sequence's pearls. The footprint is what determines the grid:
    each artifact claims cells sized to its base, so a sequence's total footprint is the floor
    its maps must hand out, and the biggest pearl sets the cell scale."""
    d = to.compute(seq, min_pearls=1)
    if not d:
        return None, 0, "", 0.0, 0.0, "", {}
    id2vec, _ = to._atlas()
    pearls = d["pearls"]
    vecs = [id2vec[a] for a in pearls if a in id2vec]
    vec = None
    if vecs:
        m = np.array(vecs).mean(axis=0)
        n = float(np.linalg.norm(m))
        vec = (m / n) if n > 0 else m
    fps = [(a, base_of(a)) for a in pearls]
    total = round(sum(b for _, b in fps), 1)
    biggest, fmax = (max(fps, key=lambda x: x[1]) if fps else ("", 0.0))
    tiers = {"small": 0, "medium": 0, "large": 0}
    for _, b in fps:
        tiers["small" if b < 1.5 else "medium" if b < 3.0 else "large"] += 1
    return vec, len(pearls), d.get("name", ""), total, round(fmax, 2), biggest, tiers


def seq_text(seq):
    p = os.path.join(to.SEQ_DIR, seq + ".json")
    if not os.path.exists(p):
        return {}
    sd = (to.load(p).get("sequences", {}) or {}).get(seq, {}) or {}
    return {
        "truth": str(sd.get("truth", "")),
        "description": str(sd.get("description", "")),
        "n_maps": len(sd.get("maps", [])),
    }


def main():
    spine = to.load(os.path.join(ROOT, "commons", "maps", "curriculum_spine.json"))
    phases = spine.get("phases", {})
    seqs = sorted(spine["spine"]["sequences"], key=lambda x: float(x.get("order", 0)))

    rows = []
    prev_vec = None
    for q in seqs:
        name = q["name"]
        vec, npearls, disp, fp_total, fp_max, biggest, tiers = seq_metrics(name)
        txt = seq_text(name)
        trans = None
        if vec is not None and prev_vec is not None:
            trans = round(1.0 - float(np.dot(vec, prev_vec)), 3)  # distance: 0 near, 2 far
        if vec is not None:
            prev_vec = vec
        ph = q.get("phase", "")
        phd = phases.get(ph, {})
        rows.append({
            "order": int(float(q.get("order", 0))),
            "name": name,
            "title": disp or name,
            "phase": ph,
            "phase_desc": phd.get("description", "") if isinstance(phd, dict) else str(phd),
            "role": q.get("qfep_role", ""),
            "truth": txt.get("truth", ""),
            "description": txt.get("description", ""),
            "n_pearls": npearls,
            "n_maps": txt.get("n_maps", 0),
            "footprint": fp_total,
            "footprint_max": fp_max,
            "biggest": biggest,
            "tiers": tiers,
            "transition": trans,
        })

    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    json.dump(rows, open(OUT, "w", encoding="utf-8"), indent=2, ensure_ascii=False)
    print(f"wrote {OUT} ({len(rows)} sequences)")

    # the narrative + transitions, biggest jumps flagged
    trans_vals = [r["transition"] for r in rows if r["transition"] is not None]
    hi = sorted(trans_vals, reverse=True)[:5] if trans_vals else []
    for r in rows:
        t = r["transition"]
        flag = "  << JUMP" if (t is not None and t in hi) else ""
        ts = f"  d={t:.3f}" if t is not None else "  (start)"
        print(f"{r['order']:2d} [{r['phase']:11s}] {r['name']:22s} p{r['n_pearls']:<3d} fp{r['footprint']:<6.1f}{ts}{flag}")


if __name__ == "__main__":
    main()
