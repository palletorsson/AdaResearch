#!/usr/bin/env python3
"""
render_lint.py — the faults this project learned the hard way, as an automatic check.

WHY THIS EXISTS. Finding two render bugs cost eleven Godot renders and six wrong
hypotheses, plus three rounds of four blind critic agents. That does not scale to 721
swept artifacts. But every fault the critics found was ultimately a NUMBER, and the ones
below are the numbers. A linter that encodes them turns a per-artifact critique into a
per-artifact assertion, and the agents can then be spent only where it fires.

Each check below cost something to learn. The comment says what.

  CLIPPED / CRUSHED. "Any bright surface goes straight to 255 with no rolloff" was the
  root cause of about half the failures in round one, measured up to 4.65% of a subject.
  Its mirror is worse: light_sphere rendered at 25.9% PURE BLACK — a mirror with nothing
  to reflect. Both are one-line measurements nobody was making.

WHAT THIS DELIBERATELY DOES NOT CHECK, and why it matters more than what it does.

  GRAIN AT NYQUIST is the fault that cost the most to find — dome's cast grain tiled so a
  FEATURE landed on one or two pixels, invisible under flat ambient and resolving into
  "television static" under a directional key. THREE metrics were written for it and all
  three were thrown away, because a proper control said they did not work:

    whole-image high-frequency ratio   known-bad 0.98  ·  known-CLEAN baseline 1.23
    flat-region residual energy        known-bad 1.11  ·  known-good 1.08
    horizontal correlation length      known-bad 1 px  ·  known-good 1-2 px

  The first RANKED A CLEAN FRAME AS WORSE than the defect, because it could not tell
  sub-pixel grain from crisp wireframe. The other two cannot see the fault at all, because
  the fix changed feature SIZE while leaving amplitude alone. So this check does not ship.
  A linter that fires on the wrong frames would cost more than the eleven renders it was
  meant to save, and shipping it would be the same disease as every bug in this session's
  log: an instrument reporting a fact about itself.

  Grain scale still needs an eye. Spend the agents there.

  (The calibration controls are real renders and are kept: a dome rendered at the broken
  0.32 tiles/m sits in ada_encyclopedia/public/aaa-control-static. Anyone who wants to try
  a fourth metric has a known-bad and a known-good to test it against, which is the only
  reason to trust a fourth metric.)

  FLAT PLASTIC. The critics' oldest and most repeated complaint — "one constant roughness
  across a whole object", "no variation anywhere". Proxied by tonal spread and distinct
  colour count inside the subject.

  TWINS and EMPTY. Two declared variants that render identically mean the axis did
  nothing; a frame with no subject means the harness, not the artifact, is being
  photographed. Both are already gospel in artifact_dna_critic.py; they are here so one
  pass answers every question about a gallery.

THESE ARE SMELLS, NOT VERDICTS. A cast-concrete artifact SHOULD have high-frequency
grain, and a genuinely emissive one will clip. The thresholds are set where the measured
failures sat, well clear of the measured successes, and every report prints the number so
a human can disagree with it.

Usage:
  python tools/render_lint.py --dir=<folder of PNGs>
  python tools/render_lint.py --gallery=<slug>          # under ada_encyclopedia/public
  python tools/render_lint.py --all                     # every gallery with a manifest
  python tools/render_lint.py --dir=... --verbose       # print every frame, not just hits
"""
from __future__ import annotations
import json
import sys
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ENC = REPO.parent / "ada_encyclopedia" / "public"

# Thresholds, each sitting between a measured failure and a measured success.
CLIP_PCT = 1.0      # light_sphere/softmill failures were 4.65%; healthy frames < 0.3%
CRUSH_PCT = 2.0     # the black-mirror failure was 25.9%; healthy frames ~0.0%
FLAT_SD = 0.055     # flat-plastic proxy; the corpus mean after materials work is ~0.14
FLAT_COLOURS = 40   # dome pre-materials measured 77 over the whole frame


def load(p: Path):
    from PIL import Image
    return Image.open(p).convert("RGB")


def subject_mask(im):
    """Pixels differing from the corner background, the convention the DNA critic uses."""
    from PIL import Image, ImageChops
    bg = im.getpixel((3, 3))
    return ImageChops.difference(im, Image.new("RGB", im.size, bg)).convert("L")


def measure(p: Path) -> dict:
    """Subject-only statistics, vectorised so a 1,200-frame corpus sweep is minutes.

    Only what the checks actually use is computed. Three further metrics were written for
    grain scale and all three were deleted after a control render disproved them; see the
    module docstring. Nothing here runs that is not gated on.
    """
    import numpy as np
    from PIL import Image
    im = Image.open(p).convert("RGB")
    a = np.asarray(im, dtype=np.int16)
    bg = a[3, 3]
    mask = np.abs(a - bg).sum(axis=2) > 36
    n = int(mask.sum())
    out = {"subject_share": round(n / mask.size, 4)}
    if n < 200:
        out["EMPTY"] = True
        return out
    g = (0.2126 * a[..., 0] + 0.7152 * a[..., 1] + 0.0722 * a[..., 2])
    subj = g[mask]
    out["clipped"] = round(float((subj >= 250).mean() * 100.0), 2)
    out["crushed"] = round(float((subj <= 4).mean() * 100.0), 2)
    out["midtone_sd"] = round(float(subj.std() / 255.0), 4)
    q = (a[mask] // 16).astype(np.int32)
    out["colours"] = int(len(np.unique(q[:, 0] * 4096 + q[:, 1] * 64 + q[:, 2])))
    return out


def faults(m: dict) -> list:
    if m.get("EMPTY"):
        return ["EMPTY: no subject in frame — the harness is being photographed, not the artifact"]
    f = []
    if m["clipped"] > CLIP_PCT:
        f.append(f"CLIPPED {m['clipped']}% of subject at 250+ (no highlight rolloff)")
    if m["crushed"] > CRUSH_PCT:
        f.append(f"CRUSHED {m['crushed']}% of subject at 4- (nothing to reflect, or exposure)")
    if m["midtone_sd"] < FLAT_SD and m["colours"] < FLAT_COLOURS:
        f.append(f"FLAT (sd {m['midtone_sd']}, {m['colours']} colours — one value across the object)")
    if m["subject_share"] < 0.06:
        f.append(f"TINY SUBJECT {100*m['subject_share']:.1f}% of frame (below measurable)")
    return f


def lint_dir(d: Path, verbose: bool) -> tuple:
    frames = sorted(d.glob("*.png"))
    if not frames:
        return 0, 0
    seen, twins, hits = {}, [], 0
    print(f"\n=== {d.name}  ({len(frames)} frames)")
    for p in frames:
        m = measure(p)
        fs = faults(m)
        # twins: identical bytes means a declared variant rendered the same picture
        h = p.read_bytes()
        key = hash(h)
        if key in seen:
            twins.append((seen[key], p.name))
        else:
            seen[key] = p.name
        if fs:
            hits += 1
            print(f"  {p.stem[:52]}")
            for x in fs:
                print(f"      {x}")
        elif verbose:
            print(f"  {p.stem[:52]}  ok  (nyq {m.get('nyquist')}, sd {m.get('midtone_sd')})")
    for a, b in twins:
        print(f"  TWINS byte-identical: {a}  ==  {b}")
    print(f"  -> {hits}/{len(frames)} frames with faults, {len(twins)} twin pair(s)")
    return hits, len(frames)


def main() -> int:
    d = ""
    verbose = "--verbose" in sys.argv
    do_all = "--all" in sys.argv
    for a in sys.argv[1:]:
        if a.startswith("--dir="):
            d = a.split("=", 1)[1]
        elif a.startswith("--gallery="):
            d = str(ENC / a.split("=", 1)[1])
    targets = []
    if do_all:
        targets = [mf.parent for mf in sorted(ENC.glob("*/manifest.json"))]
    elif d:
        targets = [Path(d)]
    else:
        print(__doc__)
        return 2
    th = tf = 0
    for t in targets:
        if not t.exists():
            print(f"missing: {t}")
            continue
        h, n = lint_dir(t, verbose)
        th += h
        tf += n
    print(f"\n{th} faulty frame(s) across {tf} frame(s) in {len(targets)} folder(s)")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
