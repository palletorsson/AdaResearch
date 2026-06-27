# Fractal_Recursion — wall-hangar curation notes

**Map:** Fractal_Recursion ("Recursion Calls Itself") · sequence `fractals` · Act I — recursion & dimension
**Tier source:** `doc/fractal_concept_map.json` → concept **"Recursion (calls itself)"** (+ furniture / architecture / phyllotaxis tiers for the applied payoff).

## The argument (curation is an argument made with placement)

The map's whole job is to introduce **the function that calls itself**, and the artifacts I read tell a single
clean story across the +X reading axis:

> Recursion is *self-reference*, not repetition (`fractal_recursion_2`) → the engine is **subdivision as a
> choice** (`cube_subdivision`: *"the fractal is the history of every choice made at every scale"*) → and that
> choice is *useful*: the chair, the table, the staircase, the pagoda were **already inside the cube** —
> subdivision merely removed what was not them.

So the wall is laid out as four bays, small→medium→large→applied, each fronted by a `station_panel` carrying
the artifact's own `truth`:

1. **SEED — "A function that calls itself"** (x≈0–2.5).
   - `fractal_recursion_2` (small; AABB 1.06×1.06×**0.03** — a thin upright readout) on a **station_micropod**
     (`base_meters 0.6`, `top_height 1.15`). Genuinely sub-1 m → the micropod is its right home: high, narrow,
     precious. This is where reading starts, set slightly forward (z 0.5).
   - **FOCAL POINT — `cube_subdivision`** (medium/mechanism; fp 1, 1 m³) on a **slim 1×1 station_plinth**
     (`top_height 1.3`, `cap_inset 0.3` — the "size IS the argument" tall-narrow podium). Pushed **forward to
     z 0.2** and given its own air: this single cube splitting into eight *is* the lesson, so it gets the
     clearest, nearest, most isolated stand on the wall.

2. **PROOF — "The chair was always inside the cube"** (x≈5–8).
   - `recursive_chair` (applied furniture; fp 4, 1.5³) on a **2×2 station_plinth**, low (`top_height 0.95`),
     mid-depth (z 1.0).
   - `recursive_table` (applied furniture; fp 9, 2.5×2.0×2.5 — a walk-beside) on a **3×3 station_stage**
     (`step_height 0.18`, `name_plate`), low+broad as the brief prescribes for big things, set back at z 1.6.

3. **HOLD IT — "The first fractal you can hold"** (x≈9.5–12).
   - `example_8_3_recursion_circles_vr` (large; fp 9, AABB 4.0×3.18×4.0 — a true walk-in) on a **4×4
     station_stage**, low, pushed **deepest (z 2.4)** as the back alcove you step into.
   - `science_screen` (the map's wall data-readout, `mode:bars`; AABB depth 0.2) mounted **on the wall**
     (z 0.06, y 1.6) at the bay seam — the live readout above the walk-in, kept as a flat wall panel, never
     on the floor.

4. **PUT TO WORK — "The rule, put to work"** (x≈15.5–20).
   - `recursive_boolean_cube` (applied; fp 4) on a **2×2 plinth**, mid-depth (z 1.2).
   - `cube_staircase` (applied architecture; fp 1; *"a cube that learned to subdivide along its own
     diagonal"*) on a **slim 1×1 plinth**, set **forward (z 0.3)** so the small precious thing reads high and
     near against the deep finale behind it.
   - **FINALE — `fibonacci_pagoda`** (applied phyllotaxis; fp 9, AABB **9.43 m tall** — *"what the golden
     ratio looks like when it tries to be architecture"*) on a **4×4 station_stage**, set back (z 2.2). Its
     sheer height is the vertical exclamation mark that closes the reading axis.

## Reading order & focal point
Left→right from the iso front: **seed → mechanism (focal) → furniture proof → walk-in → applied finale.**
The one clear focal point is **`cube_subdivision`**, set forward and alone on a tall narrow plinth — the
engine the entire map turns on. The eye then travels right through progressively *larger and further-back*
stages, ending on the tall pagoda.

## Using the 3D space (not a flat line)
Depth is staggered deliberately, z 0.2 → 2.4:
- **Foreground (z 0.2–0.5):** the two small precious things on micropod/slim-plinth — `cube_subdivision`,
  `cube_staircase`, `fractal_recursion_2`. Held things come to you.
- **Mid-depth (z 1.0–1.6):** the furniture (`recursive_chair`, `recursive_table`, `recursive_boolean_cube`).
- **Background (z 2.2–2.4):** the two big walk-ins/towers on 4×4 stages — `example_8_3_recursion_circles_vr`
  and `fibonacci_pagoda` — forming the deep alcove wall.
- **Wall face (z 0.06):** four `station_wall` backings + four `station_panel` truth-headers + the
  `science_screen` readout, so each bay reads as a built alcove, not furniture in a void.
Heights also stagger: micropod cap 1.15, slim plinths 1.1–1.3, broad plinths 0.9–0.95, stages 0.18 (with the
pagoda's own 9 m rising behind). Walkable gaps (~2 m) sit between bays.

## Every artifact gets a 2D-in-3D plate (no floating text)
- Micropod & plinths: `caption_text` = display name (Fractal Recursion 2; Cube Subdivision; Recursive Chair;
  Recursive Boolean Cube; Cube Staircase).
- Stages: `name_plate` = display name (Recursive Table…; Recursion Circles…; Fibonacci Pagoda…) — a big
  artifact on a stage still gets its framed plate; it is **not** demoted to a low-broad plinth just for a label.
- `station_panel` headers carry the map's own truth-beats (self-reference / the chair was always inside /
  the first fractal you can hold / the rule put to work).

## dark_sphere
Left **off every base** by design — it is the map's void/sky backdrop (`background.type:sky`,
`color [0.15,0.2,0.4]`), not a display artifact. The baseline `spine_walls.json` entry wrongly mounted it on a
1×1 plinth next to the science_screen; this curation drops it, which also frees that plinth.

## Why these props (meaning, not just size)
- **station_micropod** — its `@identity` is literally "the home for genuinely sub-1 m precious things"; the
  3 cm-deep recursion panel is exactly that.
- **slim station_plinth (1×1, tall, cap_inset 0.3)** — the plinth's own truth: *"what you raise high and
  narrow, you call precious."* Used for the two ideas the map most wants you to fixate on (the subdivision
  engine; the diagonal-subdivided staircase).
- **station_stage (low, broad)** — its truth: *"the step is the smallest honest pedestal… low enough to step
  onto."* Used for the two walk-ins and the table you stand beside — staged, not shelved.
- **station_panel / station_wall** — *"a place that presents must also explain"*; they turn an open floor
  into built bays and put the truth-beats in plain pinned words.

## How this beats the baseline
The baseline (`spine_walls.json`) lined nearly everything on a single z≈0.8 plane — a flat shelf — and put
`dark_sphere` on a plinth as if it were a display object. This version: (a) drops the non-artifact
`dark_sphere`; (b) gives `cube_subdivision` a true forward focal stand instead of an equal slot; (c) stages
depth across z 0.2–2.4 with foreground/background and walk-in alcoves; (d) sizes every base to the artifact's
measured footprint (micropod for the 3 cm panel, slim plinths for 1-cell things, 3×3/4×4 stages for the
walk-ins and the 9 m pagoda); (e) keeps the `science_screen` on the wall where its flat readout belongs.

## Prop gaps flagged
- **No dedicated tall-finial / banner cap** for terminal artifacts: the 9 m `fibonacci_pagoda` would read even
  better as the closing exclamation with a slim vertical marker beside it (a `station_pillar` matched to ~9 m,
  or a banner prop) — current pillar tops out far below it.
- **No "specimen vitrine"** prop: the small precious held things (recursion panel, subdivision cube) sit on
  open posts; a glass-case micropod variant would reinforce "precious, isolated" without raising height.
- **station_micropod has no `.gd` of its own** (it reuses `station_plinth.gd` with `base_meters` preset in the
  scene). Works fine, but a first-class micropod identity/script would make its sub-1 m intent explicit and
  let the composer auto-pick it.

## What to try next
- Capture the wall (`capture_multi_angle.gd --mode=map`) and confirm the forward focal `cube_subdivision`
  reads as the centerpiece from the iso front, and that the pagoda/circles alcoves reward orbiting.
- Consider pulling a kin pair to thicken the "subdivision builds furniture" beat — `cube_desk` /
  `cube_bookshelf` (artifact_neighbors sim ≥0.92 to `cube_subdivision`) would extend the applied bay without
  leaving the map's own idea.
