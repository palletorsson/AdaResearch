# Curation Notes — Fractal_GoldenSpiral (sequence: fractals)

*"Curation is an argument made with placement."* This wall stages the map's lesson —
**Fibonacci → φ → phyllotaxis** — as a walkable claim: *the most irrational number is the
one nature grows.*

## The argument (reading order, left → right along +X)

1. **Fibonacci Sequences** `small` — `station_micropod` (sub-1 m post), x=0, z=0.5, foreground.
   The recurrence F(n)=F(n−1)+F(n−2) and its ratio → φ. This is **the number**. Its AABB is
   degenerate (0,0,0 — it builds the spiral procedurally at runtime, footprint 1 cell): a thin
   upright readout, the textbook home for the micropod, which snaps to one cell without
   over-claiming it.
2. **romanesco** `small` — `station_plinth` 1×1, `top_height` 1.4, `cap_inset` 0.3, x=3, **z=0.4
   (set forward), raised high-narrow → the FOCAL POINT**. Measured AABB 1.0 × 1.5 × 1.0 (1 cell):
   per the plinth's own truth, *"what you raise high and narrow, you call precious."* romanesco is
   the map's empirical anchor — its `@identity` desire is literally *"to be stared at"* — so it gets
   the tall slim podium and the closest depth. The number (1) sits just behind-left of its living
   proof.
3. **Golden Rectangle** `large` — `station_stage` 5×4, `step_height` 0.18, x=8, z=1.1, mid-ground.
   The geometric proof φ = 1 + 1/φ — *"the only rectangle that can lose a square and remain
   itself."* AABB 5.0 × 3.09 (grid 5×4) is a wide flat board you walk up to, so it goes low + broad
   on a stage, not a podium.
4. **Fibonacci Terrain** `large` — `station_stage` 4×4 (capped from measured 8×5/40 cells),
   `step_height` 0.18, x=15, **z=1.7, the deep background finale** before the teleporter. φ applied
   to a whole landscape — *"a surface that remembers the golden ratio in every fold."* The biggest
   walk-in, set farthest back so the eye lands last on the world φ builds.

So the path reads: **meet the number → watch nature do it (focal) → see the geometry that proves it
→ stand in the world it grows.** Number and living proof in front, the two abstract/applied "proofs"
staged behind — the wall puts the body where the map's pivot is (geometric deletion → organic growth).

## Focal point
**romanesco**, x=3 — pulled forward (z=0.4) and lifted high on a slim 1.4 m plinth. Everything else
recedes in depth (z 0.5 → 1.1 → 1.7) and sits low/broad, so the one organic specimen is unmistakably
the thing the room is about.

## Using the 3D space
Depth is staggered across the full range the brief asks for (z 0.4 → 1.7) and height is layered
(1.1 / **1.4 focal** / 0.18 / 0.18). Foreground = the two small precious things (number + nature);
background = the two large walk-in proofs (geometry + world). The big terrain deck set deepest makes
a clear backing mass; romanesco set forward makes the alcove. It still reads cleanly left→right from
the iso front, but orbiting rewards you with real fore/background and one obvious focal column —
deliberately NOT a flat z-line (which is exactly what the baseline was).

## Why each prop
- **micropod** for `fibonacci_sequences`: genuinely sub-1 m, a thin readout — the micropod is the
  0.6 m post built for precisely this (it's `station_plinth.gd` with `base_meters = 0.6`).
- **slim 1×1 plinth, top 1.4** for `romanesco`: ~1-cell footprint, and the plinth's "size IS the
  argument" — high + narrow says *precious*. Promoted over a micropod because it is the map's anchor
  and deserves a full podium, not a sub-grid post.
- **station_stage** for both large artifacts: wide flat walk-ups belong low and broad; the stage's
  `name_plate` gives each its surface-pinned plate without demoting it to a low plinth (brief req 2).
- **2 × station_panel** (wall, 2D-in-3D) carry the map's own truth-beats as tier headers:
  `F(n)=F(n−1)+F(n−2) / RATIO → PHI` over the small pair, `PHI = 1 + 1/PHI / LOSE A SQUARE, STAY
  GOLDEN` over the stages — the map's two truths, in plain pinned words.

## Labels (req 2 — every artifact gets a plate)
- `fibonacci_sequences` → micropod `caption_text` = "Fibonacci Sequences"
- `romanesco` → plinth `caption_text` = "romanesco"
- `golden_rectangle` → stage `name_plate` = "Golden Rectangle"
- `fibonacci_terrain` → stage `name_plate` = "Fibonacci Terrain"
All four are the registry `entry.name`. No floating Label3D — the editor hides those; these plates
are the only text.

## dark_sphere
Deliberately **omitted from any base**. It is the void/sky backdrop / atmospheric scale reference,
not a display artifact — the baseline wrongly stood it on a plinth; this curation does not.

## Tier coverage
small ×2, medium ×0, large ×2, applied ×0 — exactly what the concept map gives this map
(all four live in *"Golden spiral & phyllotaxis"*: fibonacci_sequences/romanesco = small,
golden_rectangle/fibonacci_terrain = large). The ladder has a real gap in the **middle and the top**:
no medium step between the single number and the full landscape, and no `applied` capstone.

## Baseline beaten
The current `spine_walls.json` entry put all six pieces on **one flat z = 0.8 line**, stood
`dark_sphere` on a plinth as if it were a display object, and included a bare `station_pillar` with
nothing on it. This curation: removes dark_sphere from display, drops the empty pillar, restores true
depth/height staggering with a single forward focal point, and captions every artifact with its real
name on a plate.

## Prop gaps flagged
- **No medium tier and no applied capstone.** The map's own `intent.md` names the gap directly: a
  **phyllotaxis simulator** where the learner varies the divergence angle off 137.5° and watches
  rational angles open visible gaps while only the golden angle packs uniformly. That artifact would
  be the missing `medium` (a hands-on bridge between the number and the world) *and* the `applied`
  proof of *why* irrationality matters — the strongest single addition this wall could host.
- **Kin to try (not pulled in):** `fibonacci_pagoda` (neighbors: sim 0.905 to romanesco, 0.842 to
  golden_rectangle) is the architectural cousin and the seed this Fibonacci thread was planted with
  back in Fractals_1. It would make a clean *built* counterpoint to the *grown* romanesco and the
  *geometric* rectangle — a candidate medium/applied piece if a fourth bay is wanted. Held back here
  to keep the argument to the map's own four artifacts (the lesson is grown-not-drawn; pagoda risks
  reading as "more architecture" and muddying the pivot).

## What to try next
1. Build the phyllotaxis-angle simulator (fills medium + applied; turns the wall's claim into a knob
   the player can falsify).
2. Capture the wall (`capture_multi_angle.gd --mode=map --target=Fractal_GoldenSpiral`) and orbit-
   check that romanesco reads as the focal column and the terrain deck reads as the back wall.
3. If a fourth bay is added, slot `fibonacci_pagoda` between romanesco and the rectangle as the
   *built* tier-bridge.
