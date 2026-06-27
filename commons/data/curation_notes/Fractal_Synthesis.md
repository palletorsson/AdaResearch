# Curated Wall — Fractal_Synthesis (sequence: fractals)

> *"Curation is an argument made with placement."* The Edge of Chaos Gallery — the synthesis map
> where the whole fractal arc is gathered to make one claim: **D = log(N)/log(S) is a single law,
> and every fractal lives at an edge.**

## The argument (3 sentences)
The wall reads left→right as a proof in three movements: first the bare **recursive seed**
(fractal_recursion_1), then the **three classic-set types laddered by how their dimension is
built** — Cantor by *deletion*, Koch by *addition*, Sierpinski as the *hybrid* — and finally the
**organic and chaotic registers** (Fibonacci, romanesco, the strange attractor) that prove nature
runs the same math at the boundary between order and disorder. The composition pulls the chaos to
the front and the worlds to the back: the **Strange Attractors ribbon sits forward and alone on a
micro-pedestal as the focal point** — bounded chaos is the literal "edge of chaos geometry" the
map is named for — while the giant walk-ins (Cantor, romanesco, recursive tree) bank behind it and
the **fBm cloud volume floats far back as the sky**, with the neutral dark_sphere hung high as the
void anchor it was built to be. Read from the front it is a legible left-to-right ladder; orbited
in free-cam it opens into bays at five depths, so the gallery rewards walking *into* it.

## Reading order & focal point
1. **D = log N / log S** header panel (wall, left) — the governing equation, stated before any object.
2. **Fractal Recursion 1** — low broad 3×3 plinth, mid-depth: recursion itself, the seed of all of it.
3. **THREE EDGES, ONE RULE** header (wall, center) → the classic-set ladder:
   - **Cantor Set** — 4×4 stage set back (a 13×14 walk-in): deletion, measure → 0.
   - **Koch Curve** — slim 1×1 plinth, **forward & tallest (1.4 m)**: finite area, infinite edge.
   - **Sierpinski Triangle** — slim 1×1 plinth, mid: the hybrid, D ≈ 1.585, = Rule 90.
4. **Strange Attractors** — **FOCAL**: micropod set most-forward (z 0.25) at gallery centre. The
   butterfly given a fractal shape; the edge of chaos you can stand closest to.
5. **Fibonacci Sequences** — micropod, slightly back: the count that grows the spiral.
6. **NATURE COMPUTES IT** header (wall, right) → the organic/chaos register:
   - **Recursive Tree** — tall narrow 2×4 stage, set deep: geometric recursion gone biological.
   - **Romanesco** — 4×4 stage, set back (8 m walk-in): empirical proof — a vegetable does the math.
   - **Fractal Clouds (fBm)** — 4×4 grate stage, **far back (z 6.5)**: noise at every scale = the sky.
7. **dark_sphere** — hung high-right, no base: the neutral anchor that makes every other scale legible.

Focal point: **strange_attractors** (forward, isolated, lowest z, own micropod).

## Why each prop (footprint-fit — sized to the REAL measured AABB, not the concept-map fp)
- **station_micropod** ×2 — the home for genuinely sub-1 m precious things. `strange_attractors`
  is a procedural phase-space line (registry: "few" instances, ~100 verts — a held ribbon);
  `fibonacci_sequences` is a true `[1,1,1]` compact unit. A full 1 m plinth would over-claim the
  cell, so both ride the ~0.6 m post — high and narrow = "precious," per the plinth's own
  *"size IS the argument."* Caption plate carries the display name.
- **station_plinth 1×1, tall (top_height 1.3–1.4)** ×2 — `koch_curve` and `sierpinski_triangle`
  are both `[1,1,1]` compact specimens. Slim high-narrow podiums; Koch is set tallest and forward
  so the "finite/infinite edge" reads first in the classic-set run.
- **station_plinth 3×3, low (0.85)** ×1 — `fractal_recursion_1` is `room_scale` (`[1,3,3]` ≈ 3 m
  wide), too broad for a 1-cell podium but not a walk-in. Low + broad = "a world, not a specimen."
- **station_stage 4×4 / 2×4 (step 0.18)** ×4 — the world-scale walk-ins. `cantor_set` `[13,14]`,
  `fractal_clouds` `[15,15]`, and `romanesco` `[8,8]` all cap to 4×4; `recursive_tree` `[1,13]` is
  tall-and-thin so it gets a 2×4 deck. Big things go low and broad on a stepped deck; the
  `name_plate` (NOT caption_text — stages plate from name_plate) is the 2D-in-3D label.
- **station_panel** ×3 (wall) — tier-group headers carrying the map's own truth-beats
  (D = log N / log S; the three edges; nature computes it). The only standing text besides the plates.
- **station_wall** ×2 (wall) — a perforated, lit-seam backing so the bays have a back to read against.

## dark_sphere
Per its registry @identity it is a *neutral atmospheric anchor* — "because it changes very little
itself, it stabilises the viewer's sense of what other transformed objects are doing." It is the
void/sky backdrop, **not a display artifact**, so it is hung high (y 3.4) with `wall:false` and
**no base** — deliberately excluded from the tier counts. (The previous baseline wrongly shelved it
on a 1×1 plinth; that is corrected here.)

## Baseline beaten
The old `spine_walls.json` entry was the exact flat line the brief warns against: every artifact on
an identical 1×1 plinth at one depth (z 0.8), romanesco (8 m) and cantor (13 m) crammed onto 1-cell
podiums, dark_sphere on a plinth, no tier headers, no focal point. This curation fixes all five:
right-sized bases, a forward focal centerpiece, depth staggered across nine z-planes, tier-header
truth-beats, and dark_sphere freed to be the backdrop.

## Prop gaps flagged
- **The map's own noted gap is real and unmet by the kit:** intent.md asks for a *fractal-dimension
  comparison wall — every D value on one number line from 0 to 3*, to make the λ_edge spectrum read
  as a continuum. There is no station prop for a labelled number-line / spectrum readout; a
  `station_panel` can only hold a few text lines. **Gap: a `station_spectrum` / D-number-line wall
  prop** (ticks 0→3 with pinned markers at log2/log3 ≈ 0.63, 1.26, 1.585, 2.73). The closest real
  artifact is `dimension_meter` (fractals.json, "scan a shape") — a candidate kin to pull in if a
  later pass wants the comparison made by an interactable rather than a prop.
- **No dedicated tall-thin deck.** `recursive_tree` is `[1,13]` (1 m × 13 m). A 2×4 stage holds its
  footprint at the base but the kit has no long 1×N "runway" deck; a `station_stage` with a
  1-cell-wide option would seat tree-like world-scale artifacts more honestly.
- **Sky/atmosphere staging is improvised.** `fractal_clouds` (15 m volume) and `dark_sphere` are
  both really *sky*, not floor objects; they're parked on a far stage / hung in air. A
  `station_skydome` or backdrop-plane prop would stage volumetric/atmospheric artifacts properly
  instead of putting a cloud on a step-deck.

## What to try next
- Add the D-number-line wall once a spectrum prop exists (or wire `dimension_meter` in as the kin
  that *computes* the comparison live) — that single addition would land the map's stated thesis.
- VR-walk it: confirm the forward micropod (strange_attractors) reads as the focal point from the
  spawn at (0,0) and that the far cloud stage (z 6.5) doesn't fall outside the 21×19 floor in play.
- If the cloud volume swamps the gallery, drop its stage and let `fractal_clouds` render as pure
  sky behind the wall (no base), same treatment as dark_sphere.
