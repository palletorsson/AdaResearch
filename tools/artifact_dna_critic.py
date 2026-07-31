#!/usr/bin/env python3
"""
artifact_dna_critic.py — round two: does each declared axis actually BITE?

Stage 2 sweeps an artifact's axes and publishes the variants. It never asks whether
the variants DIFFER. info_board taught this the hard way: six tiles, all identical,
filed as a finished experiment. That was diagnosed as a time-domain problem, but the
real fault is general — ANY axis can be decoration, and a sweep cannot tell.

So this reads the rendered variants back and measures them. For each axis it compares
the pairs that differ in that axis ALONE and reports the mean pixel change. An axis
whose renders are identical is not a parameter, it is a label on a knob that is not
connected to anything.

Two numbers per axis, because one was not enough. FRAME is the mean change over the
whole image; FOCUS is the mean over the most-changed 5% of pixels.

  focus < 3%    INERT   flat even at its hottest: the knob is decoration
  focus < 12%   WEAK    it moves, but barely
  else, frame < 2%      LOCAL — decisive where it happens, diluted by a wide shot
  otherwise     BITES

Usage:
  python tools/artifact_dna_critic.py                 # judge the readymades gallery
  python tools/artifact_dna_critic.py --gallery=props-dna-gallery
  python tools/artifact_dna_critic.py --json=doc/reports/dna_bite.json
"""
from __future__ import annotations
import json
import sys
from collections import defaultdict
from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
ENC = REPO.parent / "ada_encyclopedia" / "public"

INERT = 0.005          # frame-wide floor, kept for reporting
WEAK = 0.020
INERT_FOCUS = 0.030    # even the hottest 5% barely moved: the knob is decoration
WEAK_FOCUS = 0.120


def _subject_bbox(p: Path):
    """The box containing everything that is not background, or None if the frame is empty.

    Background is read from a corner, which is background by construction in these
    captures: the camera is auto-framed on the subject, so it is always centred.
    """
    from PIL import Image, ImageChops
    im = Image.open(p).convert("RGB")
    bg = Image.new("RGB", im.size, im.getpixel((3, 3)))
    mask = ImageChops.difference(im, bg).convert("L").point(lambda v: 255 if v > 10 else 0)
    return mask.getbbox()


def load_img(p: Path, box=None):
    from PIL import Image
    im = Image.open(p).convert("L")
    if box is not None:
        im = im.crop(box)
    return list(im.resize((160, 160)).getdata())


def load_rgb(p: Path, box=None):
    from PIL import Image
    im = Image.open(p).convert("RGB")
    if box is not None:
        im = im.crop(box)
    return list(im.resize((160, 160)).getdata())


def focus_rgb(a: list, b: list) -> float:
    """Hottest-5% change measured PER CHANNEL rather than on luminance.

    THE CRITIC IS COLOUR-BLIND, and it costs it twins. Everything above converts to
    "L" first, so a hue change at constant brightness reads as nothing. AntColonyV2
    paints pale green anchor discs on pale tan ground: to the eye the four anchorage
    values are obviously different, and in luminance `pair` vs `ring` measures 5.52%
    — under the twin bar — while per channel it is 12.06%. Measured across both swarm
    artifacts the luminance number is about HALF the per-channel one, systematically.

    This is used ONLY to veto a false twin, never to score. Switching the verdict
    itself to per-channel would roughly double every number in the project's history
    and invalidate thresholds calibrated on luminance across six sequences. So the
    verdict stays comparable and the twin check stops accusing colour of being
    nothing.
    """
    if not a or len(a) != len(b):
        return 0.0
    d = [max(abs(x[0] - y[0]), abs(x[1] - y[1]), abs(x[2] - y[2])) for x, y in zip(a, b)]
    d.sort(reverse=True)
    top = max(1, len(d) // 20)
    return sum(d[:top]) / (255.0 * top)


def diff(a: list[int], b: list[int]) -> tuple[float, float]:
    """Returns (frame, focus), both normalised 0..1.

    FRAME is the mean change over the whole image. FOCUS is the mean over the most-
    changed 5% of pixels. Both are needed, and the first version shipped only the
    frame — which produced six 'weak' verdicts landing within 0.2% of each other, a
    tell that the metric was measuring framing rather than the artifacts. An axis that
    moves one small screen in a wide shot is diluted to nothing by a frame-wide mean;
    it is not weak, it is LOCAL. Focus separates 'small but decisive' from 'nothing
    happened', because an inert axis is flat everywhere including its hottest pixels.
    """
    if not a or len(a) != len(b):
        return 0.0, 0.0
    d = [abs(x - y) for x, y in zip(a, b)]
    frame = sum(d) / (255.0 * len(d))
    d.sort(reverse=True)
    top = max(1, len(d) // 20)
    focus = sum(d[:top]) / (255.0 * top)
    return frame, focus


def subject_fraction(img: list[int]) -> float:
    """How much of the frame has ANYTHING in it, 0..1.

    WHY THIS EXISTS. library_rack was swept across five `guard` values and reported
    INERT at 2.20% frame / 2.20% focus. Those two numbers being EQUAL to two decimals
    is the tell: a real localised change makes focus far exceed frame, because focus
    is the hottest 5% and frame is the mean. Equal means the difference is uniform,
    i.e. there is no subject at all. The artifact had rendered NOTHING — five files of
    identical 3428 bytes, flat background — because library_rack deliberately refuses
    to build until a collection arrives via apply_grid_config, and cabinet_sweep sets
    @export properties without ever calling it.

    So the critic confidently reported a fact about an artifact's design when the truth
    was that its own harness never gave the artifact anything to draw. That is the same
    disease this whole loop keeps finding: an instrument reporting a fact about itself
    as a fact about the thing it measures. A verdict on an empty picture is not a weak
    verdict, it is not a verdict.

    Measured against the corner pixel, which is background by construction in these
    captures (the subject is centred by the auto-framing camera).
    """
    if not img:
        return 0.0
    bg = img[0]
    return sum(1 for v in img if abs(v - bg) > 10) / float(len(img))


# Below this share of the frame carrying any subject at all, the render FAILED and no
# verdict is honest.
#
# CALIBRATED, NOT GUESSED, and the first guess was wrong. 1% seemed "deliberately
# generous" and immediately produced a FALSE POSITIVE on floating_sphere_field, which is
# a legitimately sparse artifact — eighteen small spheres drifting in a void, 0.83% of
# the frame, and every one of them really there. A blank frame is not "a small subject",
# it is NO subject: library_rack measured 0.000. So the bar sits between the two, far
# closer to zero than to anything that has ever rendered. Sparse is not empty, and an
# instrument that cannot tell them apart would have introduced a new false verdict while
# fixing an old one.
BLANK_SUBJECT = 0.002

# Two values whose renders differ by less than this in FOCUS are twins: the axis
# declares two things and shows one. Set at half the WEAK bar, so a twin is
# unambiguous rather than merely subtle.
TWIN_FOCUS = 0.060


def main() -> int:
    gallery = "readymades-dna"
    out_json = None
    for a in sys.argv[1:]:
        if a.startswith("--gallery="):
            gallery = a.split("=", 1)[1]
        if a.startswith("--json="):
            out_json = REPO / a.split("=", 1)[1]

    mdir = ENC / gallery
    mf = mdir / "manifest.json"
    if not mf.exists():
        print(f"no manifest at {mf}")
        return 1
    entries = json.loads(mf.read_text(encoding="utf-8")).get("entries", [])

    by_prop: dict[str, list[dict]] = defaultdict(list)
    for e in entries:
        by_prop[str(e.get("prop", "?"))].append(e)

    cache: dict[str, list[int]] = {}
    boxes: dict[str, object] = {}
    report: list[dict] = []
    print(f"{'artifact':24} {'axis':22} {'frame':>7} {'focus':>8}  verdict")
    print("-" * 74)

    for prop, es in by_prop.items():
        # every axis mentioned by this artifact's variants
        axes = sorted({k for e in es for k in (e.get("dna") or {}).keys()})
        for axis in axes:
            pairs: list[tuple[dict, dict]] = []
            for i in range(len(es)):
                for j in range(i + 1, len(es)):
                    da = es[i].get("dna") or {}
                    db = es[j].get("dna") or {}
                    if da.get(axis) == db.get(axis):
                        continue
                    # differ in THIS axis only — otherwise the change is confounded
                    others = set(da) | set(db)
                    others.discard(axis)
                    if all(da.get(k) == db.get(k) for k in others):
                        pairs.append((es[i], es[j]))
            if not pairs:
                continue
            fr: list[float] = []
            fo: list[float] = []
            pair_focus: list[tuple] = []
            # MEASURE THE ARTIFACT, NOT THE MARGIN. capture_config_sweep frames the
            # camera on the bounding SPHERE (the AABB diagonal) and then multiplies the
            # distance by PAD = 1.9, so a tile is roughly three-quarters empty
            # background by area. Diffing the whole frame therefore divides every real
            # change by the padding, and the padding is a property of the harness, not
            # of the artifact.
            #
            # This was found by hand three waves running and corrected by hand each
            # time: the postcrisis capstone (assertion 11.8 -> 39.9 focus, rim 21.3 ->
            # 44.6), lab_room.witness (6.0 -> 16.8), and then SIX of the thirteen
            # foundationscrisis axes at once, every one of which crossed from WEAK to
            # bites on the same crop with nothing redesigned. A correction that has to
            # be applied by hand every time is a bug in the instrument.
            #
            # Cropping to the union of the two frames' subject boxes makes the verdict
            # scale-invariant and changes no rendered image. PAD is deliberately left
            # alone: lowering it would re-render every gallery and invalidate the
            # thresholds below, which were calibrated at 1.9.
            for x, y in pairs:
                for e in (x, y):
                    fid = str(e["id"])
                    if fid not in cache:
                        p = mdir / f"{fid}.png"
                        if p.exists():
                            boxes[fid] = _subject_bbox(p)
                            cache[fid] = load_img(p)
                        else:
                            boxes[fid] = None
                            cache[fid] = []
                xid, yid = str(x["id"]), str(y["id"])
                bx, byy = boxes.get(xid), boxes.get(yid)
                if bx and byy:
                    box = (min(bx[0], byy[0]), min(bx[1], byy[1]),
                           max(bx[2], byy[2]), max(bx[3], byy[3]))
                    px, py = mdir / f"{xid}.png", mdir / f"{yid}.png"
                    f1, f2 = diff(load_img(px, box), load_img(py, box))
                else:
                    # No subject in one of them — the frame is empty. Diff it whole so
                    # the NO RENDER check below still sees near-zero everything.
                    f1, f2 = diff(cache[xid], cache[yid])
                fr.append(f1)
                fo.append(f2)
                # Remember WHICH pair, so twins can be named below. A candidate twin
                # is re-measured PER CHANNEL before being called one — see focus_rgb.
                rgbf = 1.0
                if f2 < TWIN_FOCUS and bx and byy:
                    px2, py2 = mdir / f"{xid}.png", mdir / f"{yid}.png"
                    rgbf = focus_rgb(load_rgb(px2, box), load_rgb(py2, box))
                pair_focus.append((f2, str(x.get("dna", {}).get(axis, "?")),
                                   str(y.get("dna", {}).get(axis, "?")), rgbf))
            frame = sum(fr) / len(fr)
            focus = sum(fo) / len(fo)

            # TWINS: value pairs that render the same. The verdict above is a MEAN over
            # every pair, so an axis can pass while several of its values are one
            # picture — pca_visualization scored 11.6% overall while four of its five
            # values (crosswise, curve, none, plane) were mutually identical at ~1%, the
            # whole score coming from the fifth. A five-value axis that is really a
            # two-value axis is a false declaration, and averaging hid it. Reported, not
            # scored: a twin is a design fault for a human to judge, not a verdict.
            # A twin must be dim in BOTH luminance and colour. Anything the eye can
            # see is not a twin, whatever the greyscale says.
            twins = sorted((p for p in pair_focus
                            if p[0] < TWIN_FOCUS and p[3] < TWIN_FOCUS),
                           key=lambda p: p[0])
            colour_only = sorted((p for p in pair_focus
                                  if p[0] < TWIN_FOCUS and p[3] >= TWIN_FOCUS),
                                 key=lambda p: p[0])
            # Did the artifact draw ANYTHING? Checked before any verdict, because a
            # verdict on an empty picture is a statement about the harness, not the axis.
            seen = {str(e["id"]) for pair in pairs for e in pair}
            subject = max((subject_fraction(cache[f]) for f in seen), default=0.0)
            # Judged on FOCUS. A knob that is connected to something changes its hottest
            # pixels a lot even when the frame barely moves; a knob connected to nothing
            # is flat everywhere.
            # NO RENDER needs BOTH: nothing to see AND nothing changing. Subject alone
            # is not enough, and using it alone produced two false verdicts the moment
            # the capturer started suppressing debug chrome — enhanced_kmeans measured
            # 13.88% focus (a strong bite) on a subject of 0.10%, and mst_visualization
            # 7.47% on 0.02%. Their debug panels had been padding the subject count;
            # without them a sparse scatter of small points is a legitimately tiny
            # subject that still changes a lot. A frame that truly rendered nothing has
            # near-zero focus too — library_rack sits at 2.20% with frame == focus,
            # which is the uniform-difference signature of an empty picture.
            if subject < BLANK_SUBJECT and focus < INERT_FOCUS:
                verdict = "NO RENDER"
            elif focus < INERT_FOCUS:
                verdict = "INERT"
            elif focus < WEAK_FOCUS:
                verdict = "WEAK"
            elif frame < WEAK:
                verdict = "local"
            else:
                verdict = "bites"
            print(f"{prop:24} {axis:22} {frame*100:6.2f}% {focus*100:7.2f}%  {verdict}")
            report.append({"artifact": prop, "axis": axis, "frame": round(frame, 5),
                           "focus": round(focus, 5), "verdict": verdict,
                           "subject": round(subject, 5), "pairs": len(pairs),
                           "twins": [{"a": a, "b": b, "focus": round(f, 5),
                                      "rgb": round(g, 5)} for f, a, b, g in twins],
                           "colour_only": [{"a": a, "b": b, "focus": round(f, 5),
                                            "rgb": round(g, 5)}
                                           for f, a, b, g in colour_only]})

    inert = [r for r in report if r["verdict"] == "INERT"]
    weak = [r for r in report if r["verdict"] == "WEAK"]
    blank = [r for r in report if r["verdict"] == "NO RENDER"]
    print("-" * 74)
    local = [r for r in report if r["verdict"] == "local"]
    bites = [r for r in report if r["verdict"] == "bites"]
    print(f"{len(report)} axes measured · {len(bites)} bite · {len(local)} local"
          f" · {len(weak)} weak · {len(inert)} inert · {len(blank)} not rendered")
    if blank:
        print("\nNO RENDER — the frames are empty, so NOTHING here is a verdict about the"
              " axis. The artifact drew nothing in the sweep. Usual causes: it builds only"
              " on apply_grid_config (which cabinet_sweep never calls, it sets @exports),"
              " or it needs map context. Fix the harness, then re-measure:")
        for r in blank:
            print(f"  {r['artifact']}.{r['axis']}"
                  f"  subject {r['subject']*100:.2f}% of frame")
    colourful = [r for r in report if r.get("colour_only")]
    if colourful:
        n = sum(len(r["colour_only"]) for r in colourful)
        print("\nCOLOUR-ONLY — pairs the greyscale verdict would call twins but the eye"
              " would not. The change is in HUE at roughly constant brightness, which"
              " luminance cannot see: AntColonyV2's pale-green anchor discs on pale tan"
              " measure 5.5% in luminance and 12.1% per channel. NOT twins:")
        for r in colourful:
            for t in r["colour_only"]:
                print(f"  {r['artifact']}.{r['axis']}  {t['a']} vs {t['b']}"
                      f"  (focus {t['focus']*100:.2f}%, colour {t['rgb']*100:.2f}%)")
        print(f"  {n} pair(s) rescued from a false twin verdict")

    twinned = [r for r in report if r.get("twins")]
    if twinned:
        n = sum(len(r["twins"]) for r in twinned)
        print("\nTWINS — declared values that render the SAME. The verdict above is a MEAN"
              " over pairs, so an axis can pass while several of its values are one"
              " picture. pca_visualization scored 11.6% overall while four of its five"
              " values were mutually identical at ~1%, the whole score coming from the"
              " fifth. A five-value axis that is really a two-value axis is a false"
              " declaration, and averaging hid it:")
        for r in twinned:
            for t in r["twins"]:
                print(f"  {r['artifact']}.{r['axis']}  {t['a']} == {t['b']}"
                      f"  (focus {t['focus']*100:.2f}%, colour {t['rgb']*100:.2f}%)")
        print(f"  {n} twin pair(s) across {len(twinned)} axes")
    if inert:
        print("\nINERT — these knobs are not connected to anything you can see:")
        for r in inert:
            print(f"  {r['artifact']}.{r['axis']}")
    if local:
        print("\nLOCAL — decisive where it happens, diluted by a wide frame."
              " These want a tighter capture, not a redesign:")
        for r in local:
            print(f"  {r['artifact']}.{r['axis']}"
                  f"  frame {r['frame']*100:.2f}% / focus {r['focus']*100:.1f}%")
    if weak:
        print("\nWEAK — moves, but barely, even at its hottest pixels:")
        for r in weak:
            print(f"  {r['artifact']}.{r['axis']}  (focus {r['focus']*100:.1f}%)")
    if out_json:
        out_json.parent.mkdir(parents=True, exist_ok=True)
        out_json.write_text(json.dumps({
            "_note": "Per-axis bite: mean pixel change between variants differing in that "
                     "axis alone. An axis whose renders are identical is decoration.",
            "gallery": gallery,
            "thresholds": {"inert_focus": INERT_FOCUS, "weak_focus": WEAK_FOCUS,
                           "frame_local_ceiling": WEAK},
            "axes": report,
        }, indent=1), encoding="utf-8")
        print(f"\nwrote {out_json.relative_to(REPO)}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
