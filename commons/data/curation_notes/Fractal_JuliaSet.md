# Fractal_JuliaSet — Wall Curation Notes

**Map:** Fractal_JuliaSet — "Parameter Space Exploration" (sequence: fractals, 8th map, lambda_edge phase)
**Lesson (from intent.md):** `z = z² + c`, c fixed, z₀ varies. One c gives one Julia set; move c and the
boundary breathes between a *connected* curve and *Cantor dust*. The Julia set is the lambda_edge made
literal — the frontier between convergence and divergence. `lyapunov_fractal` is the escape-time
companion (stability coloured as a landscape). `dark_sphere` is the void/sky anchor and is deliberately
left OFF a base — it is backdrop, not exhibit.

## The argument (left → right, +X reading axis)

The map collides two concepts (Julia sets + Lyapunov/escape-time) but only stages three display
artifacts, and the native ladder is gappy: Julia has only large+applied on this map, Lyapunov only a
small. I curated the wall as a **full small→medium→large→applied ladder of the Julia concept**, with
the Lyapunov small acting as the escape-time bridge to the next map. To close the Julia ladder I pulled
two kin the tier source (`doc/fractal_concept_map.json`) already lists under "Julia sets" and that are
registry-known: `living_paper_julia` (small) and `julia_bench` (medium). Both genuinely belong to this
exact concept, so the pull strengthens rather than dilutes the lesson.

Reading order is the iteration's own story — *a card → a bench → the full field → the tool that moves c
→ the stability landscape that points forward*:

1. **living_paper_julia** (small, x=0) — a single Julia *card*, AABB 0.2×0.2×0.08, genuinely sub-1 m →
   **station_micropod** (base_meters 0.6, caption "Julia Set"). First contact: one precious held form.
2. **julia_bench** (medium, x=3) — the workbench where you operate the iteration → **station_plinth**
   2×2, low (top_height 0.9), caption "Julia Bench".
3. **julia_set** (large, x=7) — **THE CENTERPIECE.** The full escape-time field, AABB 5.84×3.44, fp 9 →
   **station_stage** 4×4 (capped), name_plate "Julia Set". Pulled FORWARD to z=0.4 on its own broad low
   deck — the one focal point everything else orbits.
4. **julia_set_explorer** (applied, x=12) — interactive c-navigation, AABB 1.2×1.35, fp 4 →
   **station_plinth** 2×2, caption "Julia Set Explorer". The tool the lesson hands you.
5. **lyapunov_fractal** (small, x=15) — flat readout, AABB 0.8×0.8 → slim high-narrow **station_plinth**
   1×1 (top_height 1.3, cap_inset 0.3), caption "Lyapunov Fractal". The escape-time bridge — its panel
   reads "NEXT: THE MANDELBROT MAP," matching the teleporter ("Next: Mandelbrot").

## Focal point

**julia_set** on its 4×4 stage at z=0.4. It is the only piece brought to the front of the bay and the
only one on a broad low deck (the stage's truth: "raise it a little and admit you are presenting it").
Everything else is staggered behind it, so from the front-iso it reads as the climax of the L→R ladder,
and from a free-cam orbit it sits alone in a forward alcove.

## Real 3D composition (not a flat line)

Five distinct floor depths: the big field forward (z=0.4); the two operating stations at mid-depth
(julia_bench z=1.2, explorer z=1.3); the two small precious things set high and back (micropod z=2.3,
lyapunov plinth z=2.4). Height echoes depth — the precious small things stand tallest (1.15–1.3 m caps)
and farthest back; the world-scale field sits lowest and nearest. This carves a forward focal alcove
plus a shallow back shelf of small instruments, rewarding the orbit while still reading cleanly L→R.

## Why each prop (chosen for meaning, per the props' own @identity)

- **station_micropod** for living_paper_julia — the plinth's truth: "what you raise high and narrow you
  call precious." A 0.2 m card on a full 1 m plinth would over-claim its cell; the micropod's 0.6 m
  sub-grid post is the home for genuinely tiny precious things.
- **station_plinth 2×2 low** for julia_bench and julia_set_explorer — fp-4 working artifacts; low+broad
  (0.9 m) says "operate me," not "venerate me."
- **station_stage 4×4** for julia_set — fp-9 walk-in; the stage is the only honest base for a big field,
  and (per brief req 2) it carries its OWN plate via `name_plate`, so the centerpiece is captioned
  without demoting it to a low-broad plinth.
- **station_plinth 1×1 slim** for lyapunov_fractal — high-narrow podium; "size IS the argument," and a
  single-cell readout deserves the precious treatment, not a sprawling base.
- **station_panel ×3** (wall, 2D-in-3D) carry the map's own truth-beats as tier headers: the Julia truth
  ("ONE c, A WHOLE SET / MOVE c — IT BREATHES"), the escape-time rule ("z = z² + c, EVERY POINT /
  BOUNDED OR GONE"), and the forward pointer ("STABILITY AS LANDSCAPE / NEXT: THE MANDELBROT MAP").

## Sieve

- **Thickens the water?** Yes — the wall turns three scattered objects into a walkable iteration story
  (card → bench → field → tool → next), and makes the gappy ladder whole so a player gets handles at
  every scale.
- **Forecloses?** It commits to the *Julia* reading and treats lyapunov_fractal as a bridge rather than
  its own ladder; a player wanting the full Lyapunov/escape-time concept won't find it here (that lives
  in the Lyapunov-led maps).
- **Dark spot?** The micropod's `living_paper_julia` is a shared-substrate cartridge (scene =
  living_paper.tscn) — it renders a Julia card but is not a bespoke artifact; acceptable as the
  small-tier stand-in, flagged below.

## Baseline beaten

Current `spine_walls.json` put **dark_sphere on a slim plinth** (treating the void backdrop as an
exhibit — the one thing the brief forbids), left julia_bench-tier slots as bare `station_pillar`
spacers, and ran every floor piece on a single flat z=0.8 line. This curation: drops dark_sphere from
the bases, fills the ladder with real Julia kin (small+medium), gives every artifact a sized base + a
2D plate, and stages five depths around one forward centerpiece.

## Prop gaps flagged

- **No bespoke small-Julia artifact.** `living_paper_julia` is a generic living-paper cartridge reused
  as the small tier. A purpose-built held Julia card would read better on the micropod.
- **The map's stated gap (intent.md):** a *connected-vs-disconnected* Julia artifact showing the set
  shattering from a curve into Cantor dust as c crosses the Mandelbrot boundary. No such artifact
  exists; if built it would be the ideal medium-tier centerpiece companion here.
- **No Lyapunov medium/large/applied on this map** — by design (those belong to the Lyapunov-led maps),
  but worth noting the escape-time concept is represented only at small tier.

## What to try next

- Capture the wall (`capture_multi_angle.gd --mode=map --target=Fractal_JuliaSet`) and confirm the
  forward stage reads as the focal point from iso and the back shelf reads on orbit.
- If a connected↔dust Julia artifact gets built, slot it between julia_bench and the stage as a second
  mid-depth station — it is the map's named missing piece.
