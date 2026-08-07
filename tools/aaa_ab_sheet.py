#!/usr/bin/env python3
"""
aaa_ab_sheet.py — blind A/B sheets for a visual-quality pass, plus the numbers.

WHY BLIND. The request that produced this tool was "have a critic compare them side by side
blind and say which looks better". A critic told which image is the NEW one will find the new
one better; that is not a measurement, it is a courtesy. So each sheet pastes the two frames
left and right with the sides CHOSEN BY A HASH OF THE FILENAME — deterministic, so a rerun
produces the identical sheet, but not guessable from the picture. The answer key is written to
a separate file the critic is never given.

WHAT THIS CANNOT DO. It cannot compare anything to Call of Duty. There are no CoD frames here
and there is no honest way to get them, so the comparison this tool actually runs is
before-vs-after on our own renders. A verdict of "B looks better" means the pass improved the
picture — it does not mean the picture beats a game built by a thousand people.

THE NUMBERS beside the vote, because a vote alone has been wrong before in this project:
  tonal_range     spread of luminance actually used (clipped highlights are NOT range)
  midtone_sd      standard deviation away from the mean — flat plastic scores low
  edge_density    fraction of pixels on a luminance gradient: bevels, detail, breakup
  unique_colours  distinct quantised colours; a richer material response uses more
  clipped_hi      fraction at 250+, which is blown highlight, not brightness
These describe the IMAGE, not its beauty. A blown-out render scores well on range and badly on
clipping; read them together or not at all.

Usage:
  python tools/aaa_ab_sheet.py --before=<dir> --after=<dir> --out=<dir>
  python tools/aaa_ab_sheet.py --before=... --after=... --out=... --only=cctv
"""
from __future__ import annotations
import hashlib
import json
import sys
from pathlib import Path


def metrics(im) -> dict:
    """Image statistics over the CENTRAL CROP, which is the only honest window here.

    THIS WAS WRONG ONCE, AND LOUDLY. The first version took the corner pixel as background
    and measured everything that differed from it — the DNA critic's convention, and correct
    while every frame was a subject floating on flat colour. The showcase rig then put a lit
    ground under the subject, the "subject" mask swallowed the entire floor, and
    edge_density fell 16x between two renders of the SAME artifact. Reported as a quality
    collapse, it was a fact about the mask.

    Both rigs are built to frame identically — same FOV, same pad, silhouettes aligned to
    the pixel — so a fixed central window holds the subject in either one and compares like
    with like across a lighting change. subject_share is still reported from the old mask,
    but only as context: on a showcase frame it means "how much is not sky", not "how much
    is artifact".
    """
    from PIL import Image, ImageChops, ImageFilter
    w, h = im.size
    m = int(min(w, h) * 0.225)                    # central ~55% box
    crop = im.crop((m, m, w - m, h - m))
    g = crop.convert("L")
    bg = im.getpixel((3, 3))
    mask = ImageChops.difference(im, Image.new("RGB", im.size, bg)).convert("L")
    px = list(g.getdata())
    mk_full = list(mask.getdata())
    subj = px
    mk = [255] * len(px)
    im = crop
    if len(subj) < 50:
        return {"subject_share": round(len(subj) / len(px), 4), "empty": True}
    mean = sum(subj) / len(subj)
    sd = (sum((v - mean) ** 2 for v in subj) / len(subj)) ** 0.5
    lo, hi = min(subj), max(subj)
    edges = list(g.filter(ImageFilter.FIND_EDGES).getdata())
    edge_n = sum(1 for e, m in zip(edges, mk) if m > 10 and e > 28)
    q = {(r // 16, gg // 16, b // 16)
         for (r, gg, b), m in zip(im.convert("RGB").getdata(), mk) if m > 10}
    return {
        "subject_share": round(sum(1 for v in mk_full if v > 10) / len(mk_full), 4),
        "tonal_range": round((hi - lo) / 255.0, 4),
        "midtone_sd": round(sd / 255.0, 4),
        "edge_density": round(edge_n / max(1, len(subj)), 4),
        "unique_colours": len(q),
        "clipped_hi": round(sum(1 for v in subj if v >= 250) / len(subj), 4),
    }


def main() -> int:
    before = after = out = ""
    only = ""
    for a in sys.argv[1:]:
        if a.startswith("--before="):
            before = a.split("=", 1)[1]
        elif a.startswith("--after="):
            after = a.split("=", 1)[1]
        elif a.startswith("--out="):
            out = a.split("=", 1)[1]
        elif a.startswith("--only="):
            only = a.split("=", 1)[1]
    if not (before and after and out):
        print(__doc__)
        return 2
    from PIL import Image, ImageDraw

    B, A, O = Path(before), Path(after), Path(out)
    O.mkdir(parents=True, exist_ok=True)
    key, rows = {}, []
    for bp in sorted(B.glob("*.png")):
        ap = A / bp.name
        if not ap.exists():
            continue
        if only and only.lower() not in bp.name.lower():
            continue
        bi, ai = Image.open(bp).convert("RGB"), Image.open(ap).convert("RGB")
        if bi.size != ai.size:
            ai = ai.resize(bi.size)
        # Deterministic but unguessable: the hash of the name decides which side is the new one.
        after_on_left = int(hashlib.sha1(bp.name.encode()).hexdigest(), 16) % 2 == 0
        left, right = (ai, bi) if after_on_left else (bi, ai)
        w, h, gap, band = bi.size[0], bi.size[1], 16, 34
        sheet = Image.new("RGB", (w * 2 + gap, h + band), (24, 24, 27))
        sheet.paste(left, (0, band))
        sheet.paste(right, (w + gap, band))
        d = ImageDraw.Draw(sheet)
        d.text((8, 10), "A", fill=(235, 235, 235))
        d.text((w + gap + 8, 10), "B", fill=(235, 235, 235))
        d.text((w // 2, 10), bp.stem[:64], fill=(150, 150, 155))
        sheet.save(O / bp.name)
        key[bp.name] = {"after_side": "A" if after_on_left else "B",
                        "before": metrics(bi), "after": metrics(ai)}
        rows.append(bp.name)
    (O.parent / (O.name + "_key.json")).write_text(
        json.dumps({"_note": "Which side is the NEW render, and the per-frame numbers. "
                             "The critic must not be given this file.",
                    "sheets": key}, indent=1), encoding="utf-8")
    print(f"{len(rows)} sheet(s) -> {O}")
    print(f"key -> {O.parent / (O.name + '_key.json')}")
    # A compact console summary so the orchestrator sees movement without opening the key.
    if rows:
        def mean_of(side, k):
            vals = [key[r][side].get(k) for r in rows if not key[r][side].get("empty")]
            vals = [v for v in vals if isinstance(v, (int, float))]
            return sum(vals) / len(vals) if vals else 0.0
        print("\n            metric   before    after")
        for k in ("tonal_range", "midtone_sd", "edge_density", "unique_colours", "clipped_hi"):
            print(f"  {k:>18s}  {mean_of('before', k):7.4f}  {mean_of('after', k):7.4f}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
