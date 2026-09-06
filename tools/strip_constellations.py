#!/usr/bin/env python
"""Take the constellation figures off NASA's Deep Star Maps 2020 panorama.

2026-09-05, Palle, on the museum's new night sky: "no constellations just the
stars".

NASA SVS 4851 publishes both versions, but only the figures one is vendored in
godot-xr-tools, and the museum should not need a download to be reproducible. So
the overlay is removed rather than replaced.

WHY SUBTRACTION AND NOT A MASK. The figures are drawn as violet lines over the
sky, and a mask would leave holes — black gaps where a line crossed the Milky
Way, which is a real feature and the brightest thing in the image. But the
overlay is ADDITIVE and almost monochromatic: measured on the 4k file its colour
sits near (96, 92, 214), the only strongly blue-dominant thing in a picture whose
stars are white-to-warm and whose galaxy is cream and dust-brown. So each pixel
is asked how much of that violet it is carrying — b - max(r, g) — and that much
is taken away. Where a line crossed the galaxy the galaxy comes back, because
what is removed is the line's contribution and not the pixel.

WHAT CHROMA ALONE GETS WRONG, twice, both measured before anything was written:

  1. Hot O and B stars are blue-dominant too. Colour alone cost 7.7% of the
     bright population.
  2. The file is a 4k JPEG with subsampled chroma, so every line smears violet
     over a halo far wider than the line. 20.7% of the image reads as candidate,
     and a blue-white star anywhere near a figure loses its blue with it.

So chroma only PROPOSES. What decides is SHAPE, and shape is asked with connected
components rather than with a filter:

  A FIGURE  is one connected structure of thousands of pixels. Label the strongly
            violet pixels; anything in a component of LINE_MIN_PX or more is a
            line. Dilate by BLEED to take the chroma skirt with it.
  A STAR    is a small connected blob of bright ones. Label the bright pixels;
            anything in a component under STAR_MAX_PX is a disc, and discs are
            excluded from the subtraction entirely — a star is additive on top of
            whatever it sits on, so leaving it alone is also the correct model.

A LOCAL-MAXIMUM TEST WILL NOT DO THIS, and the version that used one protected
1,293,969 pixels including the line cores, which left the peak violet at 81
exactly where it started. A drawn line is a flat RIDGE: every pixel along it
equals its neighbours, so every pixel along it is a local maximum. Components
know the difference between a dot and a thousand-pixel snake; a 5x5 window does
not.

    python tools/strip_constellations.py

Reads the vendored xr-tools file, writes commons/scenes/em/sky/ — under commons/
because .gitignore excludes /assets/ wholesale and a sky that is not in the repo
is a sky that only exists on one machine. Idempotent.
"""

from __future__ import annotations

import os
import sys

import numpy as np
from PIL import Image
from scipy import ndimage

SRC = os.path.join(
    os.path.expanduser("~"),
    "Documents", "godot", "VR", "godot-xr-tools",
    "assets", "nasa", "starmap_and_constellation_figures_4k.jpg",
)
DST = os.path.join("commons", "scenes", "em", "sky", "starmap_2020_no_figures_4k.jpg")

# The overlay's own colour, measured off the line pixels rather than guessed.
# Only the ratios matter — the amount is read per pixel.
LINE_RGB = np.array([96.0, 92.0, 214.0], dtype=np.float32)
FLOOR = 6.0          # blue excess below this is sky noise, not overlay
# 22 broke every figure into pieces WHERE IT CROSSED THE GALAXY: the Milky Way
# raises r and g, so the same line has a smaller blue EXCESS there, the component
# ends at the galaxy's edge, and the fragments inside fall under LINE_MIN_PX and
# are read as stars. The residue was plainly visible as violet streaks over the
# brightest part of the sky. 12 keeps the figure connected across it; the size
# test is what rejects noise, and it is a better instrument for that than a
# threshold is.
CORE = 12.0          # blue excess above which a pixel may belong to a figure
LINE_MIN_PX = 800    # a component this big is a figure; smaller is a star
# MEASURED, not chosen: mean luma in rings out from a figure runs 27.2 at 4-7 px,
# 20.1 at 7-12, 16.4 at 12-20 — so the overlay's halo reaches about 12 px and a
# skirt of 4 left two thirds of it on the sky. It also made the ghost gate read
# the core against a control that was itself 11 luma bright.
BLEED = 10           # dilation, in px, of the violet-subtraction skirt
CORE_GROW = 1        # the figure body itself, which is REPLACED rather than corrected
FILL_K = 61          # box the replacement averages its non-figure neighbours over
RING_IN, RING_OUT = 14, 26   # the ghost gate's control ring, OUTSIDE the 12 px halo
GHOST_TOL = 1.5      # luma floor for the ghost gate...
GHOST_FRAC = 0.15    # ...or this fraction of the figure's ORIGINAL contrast, whichever is larger
STAR_ABOVE = 110     # a pixel this bright may be a star disc
STAR_MAX_PX = 60     # ...if its bright component is no larger than this
NEIGH8 = np.ones((3, 3), dtype=bool)


def _components_by_size(mask, keep):
    """Label `mask` and return the pixels whose component satisfies keep(size)."""
    lab, n = ndimage.label(mask, structure=NEIGH8)
    if n == 0:
        return np.zeros_like(mask), 0
    sizes = np.bincount(lab.ravel())
    good = keep(sizes)
    good[0] = False
    return good[lab], int(good.sum())


def _peaks(img: np.ndarray, thresh: int = 150) -> int:
    """Small bright components — a count of star DISCS, reported not gated."""
    luma = img.max(2)
    m, n = _components_by_size(luma > thresh, lambda s: s <= STAR_MAX_PX)
    return n


def main() -> int:
    force = "--force" in sys.argv
    if not os.path.exists(SRC):
        print("strip_constellations: source not found: %s" % SRC)
        return 2
    a = np.asarray(Image.open(SRC).convert("RGB")).astype(np.float32)
    excess = a[:, :, 2] - np.maximum(a[:, :, 0], a[:, :, 1])

    # ── which violet is a FIGURE ────────────────────────────────────────────
    line_mask, n_lines = _components_by_size(excess > CORE, lambda s: s >= LINE_MIN_PX)
    line_region = ndimage.binary_dilation(line_mask, structure=NEIGH8, iterations=BLEED)
    print("strip_constellations: %d violet component(s) of >=%d px are figures, "
          "%d px after a %d px dilation for the JPEG chroma skirt"
          % (n_lines, LINE_MIN_PX, int(line_region.sum()), BLEED))

    alpha = np.clip((excess - FLOOR) / (LINE_RGB[2] - LINE_RGB[:2].max()), 0.0, 1.0)
    alpha[~line_region] = 0.0
    core_region = ndimage.binary_dilation(line_mask, structure=NEIGH8, iterations=CORE_GROW)

    # ── and which bright thing is a STAR ────────────────────────────────────
    # DETECTED ON max(r, g), NOT ON LUMA. The overlay is violet: at full opacity
    # it puts 96 and 92 into red and green but 214 into blue, so luma finds the
    # LINE as bright as a star and a star touching a line merges into the line's
    # own component — which is thousands of pixels, so it fails the size test and
    # the star is not protected. Measured: 3239 discs lost that way. Read on
    # red-or-green the lines are under the threshold and every star stands alone.
    star_mask, n_stars = _components_by_size(
        np.maximum(a[:, :, 0], a[:, :, 1]) > STAR_ABOVE,
        lambda s: s <= STAR_MAX_PX)
    star_disc = ndimage.binary_dilation(star_mask, structure=NEIGH8, iterations=1)
    spared = int((alpha > 0.02).sum() - ((alpha > 0.02) & ~star_disc).sum())
    alpha[star_disc] = 0.0
    print("strip_constellations: %d star disc(s) found; %d px of them were inside a "
          "figure's skirt and are kept as they were" % (n_stars, spared))

    out = np.clip(a - alpha[:, :, None] * LINE_RGB[None, None, :], 0.0, 255.0)

    # ── AND THE GREY GHOST ──────────────────────────────────────────────────
    # Subtracting the violet leaves the line's ACHROMATIC half behind: the
    # overlay raises r and g as well, and b - max(r, g) is blind to the part that
    # raises all three together. The first run through here came out with the
    # colour gone and every figure still legible as a pale grey wire — the exact
    # shape of a fix that measures its own success on the only axis it can see.
    #
    # The core is therefore not corrected but REPLACED, from its own
    # surroundings: a normalised convolution, which is a box mean over the
    # neighbours that are NOT line. Where a figure crossed the galaxy the galaxy
    # is what is nearby, so the galaxy is what fills it. Star discs are held out
    # of the replacement, so a star drawn through by a line survives it.
    fill_region = core_region & ~star_disc
    # THE NEIGHBOURS MUST BE CLEAN SKY. Averaging over ~core_region includes the
    # SKIRT, which has just had violet subtracted out of it and is therefore
    # darker than the sky it stands in — so the fill came out 1.95 luma under its
    # own ring and the ghost gate caught it as a dark wire. Exclude the whole
    # line_region and the average is taken over sky nothing has touched.
    keep = (~line_region).astype(np.float32)
    num = np.empty_like(out)
    for c in range(3):
        num[:, :, c] = ndimage.uniform_filter(out[:, :, c] * keep, size=FILL_K, mode="nearest")
    den = ndimage.uniform_filter(keep, size=FILL_K, mode="nearest")
    bg = num / np.maximum(den, 1e-4)[:, :, None]
    out[fill_region] = bg[fill_region]
    print("strip_constellations: %d px of figure core replaced from a %d px "
          "neighbourhood of non-figure sky" % (int(fill_region.sum()), FILL_K))

    after_excess = out[:, :, 2] - np.maximum(out[:, :, 0], out[:, :, 1])
    print("strip_constellations: %d of %d px changed (%.1f%%); peak violet %.0f -> %.0f"
          % (int((alpha > 0.02).sum()), alpha.size,
             100.0 * (alpha > 0.02).sum() / alpha.size, excess.max(), after_excess.max()))

    # Reported, NOT gated: star discs are excluded from the subtraction by
    # construction, so of course they survive it, and a check that cannot fail is
    # worth nothing. It is here because a number that ought to be flat is worth
    # printing — if it ever moves, the construction above stopped holding.
    print("strip_constellations: star discs %d -> %d" % (_peaks(a), _peaks(out)))

    # ── THE GATE, on the claim that can still be wrong ──────────────────────
    # A wrong LINE_RGB, a CORE set too high, a LINE_MIN_PX that classified the
    # figures as stars — every one of those leaves the figures on the sky and
    # every one of them still writes a file. So: the violet must be GONE.
    # ASKED INSIDE THE FIGURES ONLY. Counting strong violet over the whole sky
    # counts every hot blue star as a leftover of the overlay, which is a
    # denominator that has nothing to do with the claim — and it is the claim
    # that is on trial here, not the sky's own colour.
    strong_before = int((excess[line_region] > 20.0).sum())
    strong_after = int((after_excess[line_region] > 20.0).sum())
    kept = 100.0 * strong_after / max(strong_before, 1)
    print("strip_constellations: px carrying strong violet INSIDE the figures "
          "%d -> %d (%.2f%% left)" % (strong_before, strong_after, kept))
    if kept > 8.0:
        print("strip_constellations: REFUSING — the figures are still there")
        return 1

    # ── AND THE SECOND GATE: NO GHOST ───────────────────────────────────────
    # The violet test above passed on an image with every figure still visible as
    # a grey wire, because it is a test about colour and the ghost has none. This
    # one is about LUMINANCE: the sky where a figure was must be as bright as the
    # sky just beside it. A ring two dilations out is the control — same part of
    # the sky, same galaxy, no line — and a ghost shows up as the core sitting
    # brighter than its own ring.
    # OUTSIDE THE WHOLE REGION, skirt included — a ring drawn inside the skirt is
    # made of pixels this tool has also changed, and would grade the work against
    # itself.
    ring = (ndimage.binary_dilation(line_mask, structure=NEIGH8, iterations=RING_OUT)
            & ~ndimage.binary_dilation(line_mask, structure=NEIGH8, iterations=RING_IN)
            & ~star_disc)
    # MEAN of the channels, not max. max() is not linear, so the average of three
    # noisy channels' maximum is higher than the maximum of their three averages
    # — and the fill above IS an average. Measured with max the filled core read
    # 7.50 luma DARK and the gate called it a dark wire; the wire was Jensen's
    # inequality. A mean is linear and smoothing does not move it.
    luma_out = out.mean(2)
    luma_in = a.mean(2)
    was = float(luma_in[core_region].mean() - luma_in[ring].mean())
    now = float(luma_out[fill_region].mean() - luma_out[ring].mean())
    print("strip_constellations: figure core stood %+.2f luma over its own ring, "
          "now %+.2f" % (was, now))
    # AND THE TOLERANCE IS RELATIVE, because "equal to its own ring" is not
    # reachable: the sky a figure is drawn through is not the sky 20 px away —
    # constellation lines connect bright stars, so they run through the crowded
    # parts by construction. What is checkable is that the figure's own contrast
    # is GONE: at +33.27 it was a wire, and the residual must be a small fraction
    # of that. 15% is where this was verified BY LOOKING at the 4k output, which
    # is the other half of this check and was used: at -4.16 (12.5%) the figures
    # are not findable on the dark sky and the faintest trace remains only over
    # the galaxy's brightest band; the earlier -7.50 (16%) was still legible.
    if abs(now) > max(GHOST_TOL, abs(was) * GHOST_FRAC):
        print("strip_constellations: %s — the figures are still legible as a %s wire "
              "(%.2f luma, tolerance %.2f)"
              % ("writing anyway (--force)" if force else "REFUSING",
                 "bright" if now > 0 else "dark", now, GHOST_TOL))
        if not force:
            return 1

    os.makedirs(os.path.dirname(DST), exist_ok=True)
    Image.fromarray(out.astype(np.uint8)).save(DST, quality=94, subsampling=0)
    print("strip_constellations: wrote %s (%.1f MB)" % (DST, os.path.getsize(DST) / 1e6))
    return 0


if __name__ == "__main__":
    sys.exit(main())
