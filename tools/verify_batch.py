#!/usr/bin/env python3
"""Sweep a batch of freshly promoted artifacts and say which axes did nothing.

Eleven batches promoted roughly 130 axes and NONE of them were verified. Agents
are told not to run Godot — captures are serialised centrally — so the loop has
been: promote, commit, maybe sweep later. A thin axis, a mis-framed subject or a
value that never reaches its node is therefore discovered weeks later, if ever.

This closes it. Run it on the tokens a batch just promoted, before the commit:

    python tools/verify_batch.py --tokens=a,b,c [--slug=verify] [--floor=1.0]

For each token it sweeps the declared axes and reports the CLOSEST PAIR of
variants — the two frames that look most alike. That is the honest statistic: an
axis is only as good as its least distinguishable pair, and a mean hides exactly
the case where four values are fine and the fifth is a duplicate.

Tokens whose closest pair falls under --floor are printed as a repair list, ready
to paste into the next round's `improve` targets with the number attached. A
measurement handed to an agent is worth more than a warning.

WHAT A LOW NUMBER DOES NOT MEAN. It is not a verdict on the artifact. Seven things
produce a flat sweep and only one of them is a dead axis — see
doc/DNA_PROMOTION_BRIEF.md.

Read the subject share printed beside it, but do NOT read it alone. A low share
has two causes and only one is a framing fault: the subject can be SMALL (camera
too far back) or AIRY (correctly framed and simply full of gaps). This tool asks
the bounding box which it is — see subject_box(). It called both a framing fault
until 2026-08-13, and was wrong twice: `taxonomy_hall` at 10.4% share and
`selection_garden` at 5.7% are both framed correctly, with boxes filling 75.7%
and 81.7% of frame width. Tightening either would have clipped the ends.
"""

from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys

REPO = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PUB = r"C:/Users/palle/Documents/GitHub/ada_encyclopedia/public"


def warn_truncation(tokens: list, max_variants: int) -> None:
    """Say when --max is about to hide an axis entirely.

    build_dna_gallery sweeps the first TWO declared axes as a matrix and trims
    values from the end to fit --max. A two-axis artifact at 4 x 4 = 16 with
    --max=5 therefore sweeps four values of the first axis and ONE of the second
    — so the second axis is not measured at all, and the run reports a closest
    pair as if it had been.

    foresight_range was verified twice that way and passed as a single-axis
    artifact. Swept properly at --max=16 its closest pair is 0.01%, and the pair
    is `vectors = gravity` against `vectors = sum` — the axis the trim had been
    hiding is the near-inert one. A verification that silently drops half the
    question is worse than none, because it is believed.
    """
    import sys as _s
    _s.path.insert(0, os.path.join(REPO, "tools"))
    try:
        import artifact_dna_research as _R
        reg = _R.registry()
    except Exception:
        return
    for tok in tokens:
        axes = ((reg.get(tok, {}).get("dna") or {}).get("axes") or {})
        swept = list(axes.items())[:2]          # the gallery's own rule
        if len(swept) < 2:
            continue
        full = 1
        for _n, vals in swept:
            full *= max(1, len(vals))
        if full > max_variants:
            names = " x ".join(f"{n}({len(v)})" for n, v in swept)
            need = full
            print(f"  ! {tok}: {names} = {full} combinations but --max={max_variants}. "
                  f"Values are trimmed FROM THE END, so an axis may be reduced to a "
                  f"single value and never measured. Re-run with --max={need}.")


def sweep(slug: str, tokens: list, max_variants: int) -> dict:
    cmd = [sys.executable, "tools/build_dna_gallery.py",
           f"--slug={slug}", "--tokens=" + ",".join(tokens), f"--max={max_variants}"]
    env = dict(os.environ, PYTHONIOENCODING="utf-8")
    subprocess.run(cmd, cwd=REPO, env=env, timeout=5400)
    man = os.path.join(PUB, slug, "manifest.json")
    if not os.path.exists(man):
        return {}
    out: dict = {}
    for e in json.load(open(man, encoding="utf-8")).get("entries", []):
        out.setdefault(e["prop"], []).append(e)
    return out


def subject_box(im) -> tuple:
    """(box width %, box height %, how full the box is %) for one frame.

    A LOW SUBJECT SHARE HAS TWO CAUSES AND ONLY ONE IS A FRAMING FAULT. If the
    artifact's bounding box is small in frame, the camera is too far back and
    `dna.framing` is the fix. If the box is large but AIRY — a bench of thin
    pickets, four separated bays on an apron — then the framing is already right
    and tightening it only clips the ends.

    Measured, both cases exist and the old share-only test called both a framing
    fault: `taxonomy_hall` reads 10.4% share with its box filling 75.7% of frame
    width, and `selection_garden` reads 5.7% share with its box filling 81.7% of
    width and only 27.6% of the box's own area. Neither is mis-framed.
    """
    W, H = im.size
    bg = im.getpixel((3, 3))
    px = im.load()
    xs0, ys0, xs1, ys1, ink = W, H, 0, 0, 0
    for y in range(H):
        for x in range(W):
            t = px[x, y]
            if abs(t[0] - bg[0]) + abs(t[1] - bg[1]) + abs(t[2] - bg[2]) > 26:
                ink += 1
                if x < xs0: xs0 = x
                if x > xs1: xs1 = x
                if y < ys0: ys0 = y
                if y > ys1: ys1 = y
    if ink == 0:
        return (0.0, 0.0, 0.0)
    bw, bh = max(1, xs1 - xs0), max(1, ys1 - ys0)
    return (100.0 * bw / W, 100.0 * bh / H, 100.0 * ink / (bw * bh))


def measure(entries: list, slug: str) -> tuple:
    """(closest pair %, its two labels, mean subject share %, box of one frame)"""
    from PIL import Image, ImageChops
    ims = []
    for e in entries:
        p = os.path.join(PUB, slug, os.path.basename(e["image"]))
        if not os.path.exists(p):
            continue
        ims.append((e["label"], Image.open(p).convert("RGB")))
    if len(ims) < 2:
        return (None, None, None, None)

    n = ims[0][1].size[0] * ims[0][1].size[1]
    shares = []
    for _lbl, im in ims:
        bg = im.getpixel((3, 3))
        px = sum(1 for t in im.getdata()
                 if sum(abs(a - b) for a, b in zip(t, bg)) > 26)
        shares.append(100.0 * px / n)
    box = subject_box(ims[0][1])

    worst, pair = 101.0, None
    for i in range(len(ims)):
        for j in range(i + 1, len(ims)):
            d = ImageChops.difference(ims[i][1], ims[j][1])
            pct = 100.0 * sum(1 for t in d.getdata() if sum(t) > 24) / n
            if pct < worst:
                worst, pair = pct, (ims[i][0], ims[j][0])
    return (worst, pair, sum(shares) / len(shares), box)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--tokens", required=True)
    ap.add_argument("--slug", default="verify")
    ap.add_argument("--max", type=int, default=5)
    ap.add_argument("--floor", type=float, default=1.0)
    a = ap.parse_args()

    tokens = [t.strip() for t in a.tokens.split(",") if t.strip()]
    print(f"sweeping {len(tokens)} tokens…\n")
    swept = sweep(a.slug, tokens, a.max)

    rows, repair = [], []
    for tok in tokens:
        entries = swept.get(tok)
        if not entries:
            rows.append((tok, None, None, None, "NO FRAMES — the sweep produced nothing"))
            repair.append((tok, "sweep produced no frames at all"))
            continue
        worst, pair, share, box = measure(entries, a.slug)
        if worst is None:
            rows.append((tok, None, None, share, "only one frame"))
            continue
        note = ""
        if share is not None and share < 6.0:
            # A LOW SHARE IS NOT BY ITSELF A FRAMING FAULT. Ask the bounding box
            # whether the subject is SMALL (camera too far back) or AIRY (correctly
            # framed and simply full of gaps). See subject_box().
            bw, bh, fill = box if box else (0.0, 0.0, 0.0)
            if max(bw, bh) >= 55.0:
                note = (f"sparse, not small — box is {bw:.0f}x{bh:.0f}% of frame and "
                        f"{fill:.0f}% full. The framing is fine; do not tighten it")
            else:
                note = (f"subject under 6% and box only {bw:.0f}x{bh:.0f}% of frame "
                        f"— suspect the FRAMING, not the axis")
        rows.append((tok, worst, pair, share, note))
        if worst < a.floor:
            repair.append((tok, f"closest pair {worst:.2f}% ({pair[0]} vs {pair[1]}), "
                                f"subject {share:.1f}% of frame"
                                + (" — " + note if note else "")))

    print(f"{'token':<44}{'closest':>9}{'subject':>9}   reading")
    for tok, worst, pair, share, note in rows:
        w = f"{worst:.2f}%" if worst is not None else "—"
        s = f"{share:.1f}%" if share is not None else "—"
        print(f"{tok:<44}{w:>9}{s:>9}   {note}")

    if repair:
        print(f"\n{len(repair)} of {len(tokens)} want a second pass:\n")
        for tok, why in repair:
            print(f"  {tok}\n      {why}")
        print("\nHand these to the next round's `improve` targets WITH the numbers.")
    else:
        print(f"\nevery axis separates by at least {a.floor}%.")
    return len(repair)


if __name__ == "__main__":
    sys.exit(main())
