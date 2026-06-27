# Curation Notes — Fractal_KochSierpinski

*Sequence: fractals · 10th spine (lambda_edge) · map title "Infinite Perimeter, Fractal Dimension"*

## The argument

The map's lesson is a single paradox: **a boundary can refuse to be measured** — infinite
perimeter around finite area (Koch, D≈1.262), infinite structure around zero area (Sierpinski,
D≈1.585). The wall makes that paradox walkable by laddering it: first the *tool that names the
paradox* (box-counting D), then the *hero edge* (Koch), then the *same edge in 3D*, then the
*same hole* twice over (Sierpinski triangle + its 3D preview of the next map), and finally the
*payoff* — recurse a strut and the abstraction becomes a place to live (the cube furniture, Act VI).

Three sentences: **(1)** The Koch curve is the centerpiece because the map is named for it and it
is the cleanest statement of the whole sequence's thesis — the edge that never resolves — so it
stands alone, forward, tall and lit, where the eye lands first. **(2)** Box-counting dimension is
placed *before* it, on a micro-pedestal, because you cannot feel "D between integers" as a paradox
until you have the instrument that measures it — the tool earns the hero. **(3)** The two large
Sierpinski walk-ins sit low and broad on a back plane behind the focal, so the room reads as
foreground-statement / background-mass, and the applied cube furniture closes the loop by turning
the pathology into architecture.

## Reading order (left → right, +X)

| x | piece | role | base | tier |
|---|-------|------|------|------|
| 1.0 | **INFINITE PERIMETER** panel | truth-beat header | wall | — |
| 1.0 | Box Counting Dimension | the measuring instrument (entry) | station_micropod | small |
| 4.0 | **Koch Curve** | **FOCAL** — D≈1.262, set forward + tall + lit | station_plinth 1×1 tall | small |
| 7.0 | 3D Koch Curve | the edge logic extruded to 3D | station_stage 4×2 (long deck) | medium |
| 10.5 | **THE SAME HOLE** panel | truth-beat header | wall | — |
| 11.5 | Sierpinski Triangle | D≈1.585, the same hole at every scale | station_stage 3×3 | large |
| 15.5 | Sierpinski Pyramid | the 3D preview thread to Fractals_5 | station_stage 3×3 | large |
| 19.5 | **FRACTAL TO FORM** panel | truth-beat header | wall | — |
| 19.0 | Cube Cabin | fractal logic as architecture | station_plinth 1×1 | applied |
| 21.5 | Cube Bookshelf | recurse a strut → a shelf | station_plinth 1×1 | applied |

## Focal point

**Koch Curve** (`fractal_koch_curve`), at x 4.0, **z 2.4 (most forward of any piece)**, on a slim
1×1 plinth raised to **top_height 1.25 (the tallest base on the wall)** with the lit cap groove
wrapped on (`edge_light_wrap`) and a bracketed **signage** caption rather than a flush frame — every
device says "this one, here, by itself." It is the only exhibit pulled to the front depth plane;
everything else recedes toward the wall (z 0.7–1.35) or sits low on the back plane (the 3×3 stages
at z 2.4 but only 0.18 m tall), so the tall lit Koch plinth pops out of a low, broad backing mass.

## Why each prop (footprint-first, per the brief)

Footprints are the **measured** `measurements.grid_cells` [w,d], not the ladder tier:

- **Box Counting Dimension → `station_micropod`** (`base_meters` 0.6, top 1.15). It is a held,
  interactive calculator with *no declared footprint* — genuinely sub-1 m. The micropod is the home
  for the tiny precious instrument; a full 1 m plinth would over-claim the cell. Caption plate carries
  the display name.
- **Koch Curve → `station_plinth` 1×1, top 1.25.** Measured footprint capped at 1 cell (a flat
  snowflake plate). Per the plinth's own "size IS the argument," a precious small thing goes
  **high + narrow** — so it is raised and lit as the focal, with `cap_inset` 0.3 for the slim podium read.
- **3D Koch Curve → `station_stage` 4×2.** Measured [4,2] = 8 cells, a *long* low object. A 4×2 stage
  fits its true long footprint and reads "walk along me," matching how the extruded curve runs.
- **Sierpinski Triangle & Sierpinski Pyramid → `station_stage` 3×3 each.** Both measure 9 cells
  (capped) — genuine big walk-ins. Big things go **low + broad**: a low step-deck (0.18 m) presents
  the mass without lifting it out of reach. Each stage's `name_plate` (NOT caption_text) is the plate.
- **Cube Cabin & Cube Bookshelf → `station_plinth` 1×1, top 1.0 / 1.15.** Both measure 1 cell
  (compact). Slim single-cell podiums at slightly different heights give the applied coda a quiet
  rhythm against the wall without competing with the focal.

## Truth-beats on the wall

Three `station_panel` headers carry the map's own language (2D-in-3D, the only floating-free text;
the editor hides each artifact's own Label3D):
- **INFINITE PERIMETER** — "A line that wants to be a plane · D 1.26" (Koch's paradox).
- **THE SAME HOLE** — "Zero area, infinite structure · D 1.585" (Sierpinski's, lifted from the bench identity).
- **FRACTAL TO FORM** — "Recurse a strut and you get a place to live" (Act VI, the furniture payoff).

## 3D composition

- **Foreground:** the Koch focal plinth (z 2.4, tall, lit) — one clear forward statement.
- **Mid plane (z 0.7–1.35):** the micropod and the two cube plinths near the wall, plus the long
  3D-Koch deck (z 1.0) bridging out — varied `top_height` (1.0 / 1.15 / 1.25) staggers the skyline.
- **Back plane (z 2.4, low):** the two 3×3 Sierpinski stages form a broad, low mass behind the focal.
- Reads cleanly left→right from the iso front, and rewards orbiting: the tall lit Koch plinth
  detaches from the low back stages, and the long 3D-Koch deck shows its run only when you walk the side.
- Deliberate negative space between the Sierpinski back plane (ends x 17) and the applied coda
  (begins x 19) lets the "FRACTAL TO FORM" panel act as a threshold into the payoff bay.

## Excluded from base-mounting (deliberately)

- **`dark_sphere`** — the void/sky backdrop, per the brief: not a display artifact, gets no base.
- **`science_screen`** (`#mode:trace`) — a generic "compare 3D vs its 2D projection" observation
  *screen*, already 2D-in-3D and on no fractal tier ladder. Like the backdrop, it is staging/UI, not
  an exhibit, so it is not given a plinth. (If a future pass wants it, it belongs flat on the wall
  beside the Koch focal, captioning the projection idea — not on the floor.)

## Prop gaps flagged

- **No "ruler / coastline length" prop.** `intent.md` names the map's one real gap: a ruler-length
  slider that measures the Koch boundary at shrinking scales to make length-divergence visceral
  (Richardson's coastline). No such artifact exists in the fractals registry; box-counting is the
  nearest stand-in but measures *dimension*, not *divergence*. Worth authoring.
- **No fractal-specific signage glyph.** Panels carry the truth in text only; a small etched
  Koch/Sierpinski motif on `station_panel` (or a `station_wall` relief) would let the *shape* caption
  the bay, not just the words. Restyle, not new system.
- Otherwise the station kit covers this wall fully: micropod (tiny), slim plinth (1-cell), sized
  stage (walk-ins), panel (headers). No lighting or vertical-circulation gap here.

## What to try next

1. Capture the wall (`capture_multi_angle.gd --mode=map`) and check the Koch plinth genuinely reads as
   the lone forward focal against the low Sierpinski back plane from the iso angle.
2. If the two 3×3 stages crowd at x 11.5 / 15.5, push the pyramid to x 16.0 for a wider gap.
3. Consider a 4th panel or a `station_pillar` at the far right (x ≈ 23) to cap the applied bay and stop
   the wall ending on open air.
