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


def seq_vector(seq):
    """Mean (L2-normed) embedding of a sequence's pearls; n_pearls; display name."""
    d = to.compute(seq, min_pearls=1)
    if not d:
        return None, 0, ""
    id2vec, _ = to._atlas()
    vecs = [id2vec[a] for a in d["pearls"] if a in id2vec]
    if not vecs:
        return None, 0, d.get("name", "")
    m = np.array(vecs).mean(axis=0)
    n = float(np.linalg.norm(m))
    return (m / n if n > 0 else m), len(d["pearls"]), d.get("name", "")


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
        vec, npearls, disp = seq_vector(name)
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
        print(f"{r['order']:2d} [{r['phase']:11s}] {r['name']:22s} p{r['n_pearls']:<3d}{ts}{flag}")


if __name__ == "__main__":
    main()
