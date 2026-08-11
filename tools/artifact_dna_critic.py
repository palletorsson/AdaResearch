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

A dead verdict is no longer issued on this tool's own authority. Every tile it reads was
shot from ONE standpoint (yaw 0.62, pitch -0.26) and an axis that resolves obliquely to
that camera is invisible here however loudly it differs in the room. Audited across the
corpus, five of seven dead verdicts were false. So INERT is now gated on evidence from
somewhere else, via doc/reports/anamorphic_<token>.json:

  INERT?       nobody has looked from another angle yet — not a verdict, a to-do
  ANAMORPHIC   flat from here, alive from elsewhere: the verdict was about the camera
  INERT        flat from all five standpoints — convicted

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
    """Greyscale samples with each frame's OWN background neutralised.

    THE BUG THIS FIXES, which contaminated every verdict this tool has produced.
    The capture environment has not settled on the first tile of a sweep, so tile 1 comes
    out at a different background tint from every later tile — measured at (148,174,149)
    against (130,165,118), a whole-frame shift across 85-93% of the image. Because
    apply_dna_block puts the axis DEFAULT leftmost, that tile is usually the baseline every
    other value gets compared against, so a harness artefact 2.5-6x larger than the real
    axis signal was being read as bite.

    cabinet_sweep.py already knew: its own bite computation masks each image against its own
    background for exactly this reason, and says so at cabinet_sweep.py:234. That fix never
    reached this file, which is the one whose numbers get reported.

    Fixing it in the CAPTURE was tried first and is the wrong place — three attempts moved
    the tint from 148 to 137 to 135 to 146 without eliminating it, because the render target
    converges over several frames rather than one. Neutralising per frame here is exact and
    costs nothing.
    """
    from PIL import Image, ImageChops
    im = Image.open(p).convert("RGB")
    if box is not None:
        im = im.crop(box)
    # The corner is background by construction — the subject is framed centrally.
    bg = im.getpixel((3, 3))
    im = ImageChops.difference(im, Image.new("RGB", im.size, bg))
    return list(im.convert("L").resize((160, 160)).getdata())


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


def _declared_axis(token: str, axis: str) -> bool:
    """Is this a promoted axis, or a raw export the gallery happened to vary?

    The props gallery predates dna.axes: its entries carry a hand-authored `dna` dict of
    plain @export values, so this tool synthesises pseudo-axes from them. slide_projector's
    `current_slide_number` is one — an int the gallery set to 1 / 23 / 0, never a declared
    family. The standpoint gate must not order a probe for those, because probe_anamorphic
    reads the REGISTRY and will refuse: "not a declared axis". It did, which is how this
    was found. A gate that emits commands nobody can run is worse than no gate.
    """
    for rp in (REPO / "commons" / "artifacts" / "registry").glob("*.json"):
        try:
            data = json.loads(rp.read_text(encoding="utf-8"))
        except Exception:
            continue
        arts = data.get("artifacts", data) if isinstance(data, dict) else None
        e = arts.get(token) if isinstance(arts, dict) else None
        if isinstance(e, dict) and axis in (((e.get("dna") or {}).get("axes")) or {}):
            return True
    return False


def _standpoint_checked(token: str, axis: str) -> dict | None:
    """Has this axis been looked at from anywhere but the canonical viewpoint?

    probe_anamorphic writes doc/reports/anamorphic_<token>.json when it runs. Its
    presence for the right axis is the evidence that somebody stood somewhere else;
    its absence is the reason an INERT verdict here is not yet a verdict.
    """
    p = REPO / "doc" / "reports" / f"anamorphic_{token}.json"
    if not p.exists():
        return None
    try:
        d = json.loads(p.read_text(encoding="utf-8"))
    except Exception:
        return None
    return d if str(d.get("axis", "")) == axis else None


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
    _manifest = json.loads(mf.read_text(encoding="utf-8"))
    entries = _manifest.get("entries", [])
    # THE DENOMINATOR, read back beside the measurement.
    #
    # The sweep trims a declared axis from the END of its value list until the cross
    # product fits its variant cap. dot_aligner declares workings(4); at the default cap
    # it rendered `outcome` and `trace` only, and this tool called the axis INERT at
    # 0.11% frame / 2.27% focus. Swept over all four values it reads 2.07% / 37.49% and
    # BITES — the whole signal was in `expression`, which the cap had dropped, and the
    # published verdict was a fact about the harness's budget.
    #
    # An axis listed here was measured over a SUBSET of what it declares, so its verdict
    # bounds nothing about the values that never rendered. Marked on the row, because a
    # verdict is read from the table and a caveat that is not on the table is not read.
    partial = _manifest.get("partial_axes") or {}

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
                # The CO-AXIS CONTEXT this pair was measured in — the values of every
                # other axis, which are equal across the pair by construction above.
                # Kept so the mean can be split by it; see the conditional-axis check.
                ctx = tuple(sorted((k, str(v)) for k, v in (x.get("dna") or {}).items()
                                   if k != axis))
                pair_focus.append((f2, str(x.get("dna", {}).get(axis, "?")),
                                   str(y.get("dna", {}).get(axis, "?")), rgbf, ctx))
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

            # CONDITIONAL: an axis whose meaning DEPENDS on a crossed axis, averaged
            # flat by a mean over the whole cross product.
            #
            # csg_union_demo taught this. `join` marks where two solids meet, crossed
            # with `fusion`, which sets how far apart they are. At fusion=distinct the
            # solids are DISJOINT: A intersect B is empty, so there is no seam curve and
            # no shared volume, and flush/seam/shared measure 0.00% to the byte. That is
            # not a dead knob and not an occlusion — marking a join where no join exists
            # is correctly nothing. But those three structural zeroes are averaged in
            # with fusion=single, where the same pairs measure 12.50 / 7.49 / 17.53, and
            # the axis came out WEAK at 8.3% overall.
            #
            # The corpus's whole promotion discipline is two crossed axes per artifact,
            # so any axis conditional on its partner has been understated this way for
            # as long as the tool has existed. Split the pairs by co-axis context: if
            # the best context bites while another is inert, the mean is the wrong
            # statistic and the report says so rather than quietly convicting.
            # Grouped by VALUE PAIR, not by context. The first attempt averaged each
            # co-axis context and missed the case entirely: at fusion=distinct the
            # `tinted` pairs still measure ~11% because recolouring B works whether or
            # not the solids touch, which drags that context's mean to 5.5% and hides
            # three structural zeroes inside it. The signal is that the SAME TWO VALUES
            # are identical in one context and plainly different in another.
            conditional = None
            if verdict in ("WEAK", "INERT", "local") and pair_focus:
                by_vals: dict[tuple, list[tuple]] = defaultdict(list)
                for p in pair_focus:
                    by_vals[tuple(sorted((p[1], p[2])))].append((p[0], p[4]))
                swings = []
                for vals, obs in by_vals.items():
                    if len(obs) < 2:
                        continue
                    lo = min(obs, key=lambda o: o[0])
                    hi = max(obs, key=lambda o: o[0])
                    if lo[0] < INERT_FOCUS and hi[0] >= WEAK_FOCUS:
                        swings.append({"values": list(vals),
                                       "dead": round(lo[0], 5), "dead_when": dict(lo[1]),
                                       "alive": round(hi[0], 5), "alive_when": dict(hi[1])})
                if swings:
                    conditional = {"was": verdict,
                                   "swings": sorted(swings, key=lambda s: -s["alive"])}
                    verdict = "CONDITIONAL"
            pc = partial.get(f"{prop}.{axis}")
            flag = ""
            if pc:
                flag = (f"   [PARTIAL {len(pc.get('swept', []))}/"
                        f"{len(pc.get('declared', []))} values — verdict covers only "
                        f"{', '.join(map(str, pc.get('swept', [])))}]")
            print(f"{prop:24} {axis:22} {frame*100:6.2f}% {focus*100:7.2f}%  {verdict}{flag}")
            report.append({"artifact": prop, "axis": axis, "frame": round(frame, 5),
                           "focus": round(focus, 5), "verdict": verdict,
                           "partial": pc or None, "conditional": conditional,
                           "subject": round(subject, 5), "pairs": len(pairs),
                           "twins": [{"a": a, "b": b, "focus": round(f, 5),
                                      "rgb": round(g, 5)} for f, a, b, g, _c in twins],
                           "colour_only": [{"a": a, "b": b, "focus": round(f, 5),
                                            "rgb": round(g, 5)}
                                           for f, a, b, g, _c in colour_only]})

    # Fold in any standpoint evidence that already exists, so a checked axis reports
    # the angle that rescued it (or confirms it really is flat from everywhere).
    for r in report:
        ev = _standpoint_checked(r["artifact"], r["axis"])
        if ev:
            r["standpoint"] = {"canonical": ev.get("canonical_mean_focus"),
                               "best_other_view": ev.get("best_other_view"),
                               "best_other": ev.get("best_other_mean_focus")}
            best = ev.get("best_other_mean_focus") or 0.0
            if r["verdict"] == "INERT" and best >= WEAK_FOCUS:
                r["verdict"] = "ANAMORPHIC"

    # ── THE STANDPOINT GATE ──────────────────────────────────────────────────
    #
    # Every tile this critic reads was shot from ONE place: capture_config_sweep's
    # YAW 0.62, PITCH -0.26. That is not a neutral default, it is a standpoint, and
    # an axis whose difference resolves obliquely to it is invisible here no matter
    # how loudly it differs in the room. So "INERT" has always meant, precisely,
    # "this axis does not change what the camera at 0.62 happened to be facing."
    #
    # Audited over the whole corpus, that cost FIVE FALSE NEGATIVES out of seven
    # dead verdicts. random_number_book_page_1955.disclosure measured 0.00% here and
    # 62.50% from the opposite side, because the RAND 1955 page is printed on one
    # face and this camera stands behind it — every published tile of that artifact
    # was the blank back of a sheet of paper. reaction_diffusion.inoculation measured
    # 0.00% and was written into the project's own notes as "genuinely inert"; it is
    # 21.84% from above. random_walk_collection.residue is 3.07x from the opposite.
    #
    # That audit was run by hand, which means it would have been forgotten. This
    # makes it a gate: an INERT verdict is no longer reportable until somebody has
    # looked from somewhere else. The critic cannot re-render (that needs Godot and
    # the user:// lock), so it does not pretend to — it REFUSES TO CONVICT, names the
    # command, and downgrades the verdict to UNCONFIRMED.
    unconfirmed = [r for r in report if r["verdict"] == "INERT"
                   and _declared_axis(r["artifact"], r["axis"])
                   and not _standpoint_checked(r["artifact"], r["axis"])]
    for r in unconfirmed:
        r["verdict"] = "INERT?"
        r["needs_standpoint_check"] = True

    anamorphic = [r for r in report if r["verdict"] == "ANAMORPHIC"]
    inert = [r for r in report if r["verdict"] == "INERT"]
    weak = [r for r in report if r["verdict"] == "WEAK"]
    blank = [r for r in report if r["verdict"] == "NO RENDER"]
    print("-" * 74)
    local = [r for r in report if r["verdict"] == "local"]
    bites = [r for r in report if r["verdict"] == "bites"]
    print(f"{len(report)} axes measured · {len(bites)} bite · {len(local)} local"
          f" · {len(weak)} weak · {len(inert)} inert · {len(unconfirmed)} unconfirmed"
          f" · {len([r for r in report if r.get('conditional')])} conditional"
          f" · {len(anamorphic)} anamorphic · {len(blank)} not rendered")
    if anamorphic:
        print("\nANAMORPHIC — flat from this pipeline's one standpoint, alive from another."
              " The verdict described where the camera stood, not the artifact:")
        for r in anamorphic:
            sp = r["standpoint"]
            print(f"  {r['artifact']}.{r['axis']}  canonical {sp['canonical']*100:.2f}%"
                  f"  ->  {sp['best_other']*100:.2f}% from {sp['best_other_view']}")
    if unconfirmed:
        print("\nINERT? — NOT CONVICTED. These look dead from the only place this pipeline"
              " has ever stood (yaw 0.62, pitch -0.26). Five of seven dead verdicts in this"
              " corpus turned out to be anamorphic — alive from another angle — so an"
              " unchecked INERT is not evidence. Run the probe, then re-read:")
        for r in unconfirmed:
            print(f"  python tools/probe_anamorphic.py --token={r['artifact']}"
                  f" --axis={r['axis']}")
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

    cond = [r for r in report if r.get("conditional")]
    if cond:
        print("\nCONDITIONAL — the axis DEPENDS on the one it is crossed with, and a mean"
              " over the whole cross product is the wrong statistic for it. csg_union_demo"
              " taught this: `join` marks where two solids meet, and at fusion=distinct"
              " they are DISJOINT, so there is no seam and no shared volume. Marking a"
              " join where no join exists is correctly nothing — but three structural"
              " zeroes averaged in with a context where the same pairs measure 12-17%"
              " produced a WEAK verdict on an axis that works wherever it is defined:")
        for r in cond:
            c = r["conditional"]
            print(f"  {r['artifact']}.{r['axis']}  (was {c['was']} at"
                  f" {r['focus']*100:.2f}% overall)")
            for s in c["swings"]:
                print(f"    {s['values'][0]} vs {s['values'][1]}:"
                      f"  {s['dead']*100:5.2f}% when {s['dead_when']}"
                      f"  ->  {s['alive']*100:5.2f}% when {s['alive_when']}")

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
        convicted = [r for r in inert if r.get("standpoint")]
        ungated = [r for r in inert if not r.get("standpoint")]
        if convicted:
            print("\nINERT — CONVICTED. Flat from the canonical view AND from the four other"
                  " standpoints the probe stood at. These knobs are not connected to"
                  " anything anyone can see from anywhere:")
            for r in convicted:
                sp = r["standpoint"]
                print(f"  {r['artifact']}.{r['axis']}"
                      f"  (best other view {(sp.get('best_other') or 0)*100:.2f}%"
                      f" from {sp.get('best_other_view')})")
        if ungated:
            print("\nINERT (undeclared) — flat, and NOT gated on a standpoint probe because"
                  " these are not promoted axes. The props gallery predates dna.axes: its"
                  " entries carry hand-authored @export dicts, so this tool synthesises an"
                  " axis per key. Promote the artifact if the knob is meant to be a family:")
            for r in ungated:
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
