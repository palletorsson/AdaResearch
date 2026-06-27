# Curation — Fractal_CantorSet ("Existence Without Extension")

## The argument
The map's lesson (from `intent.md` + `cantor_bench` @identity): the Cantor set is **defined entirely by
what is removed** — remove the middle third, recurse forever; what survives has *length zero* yet
*uncountably many points*; `D = log 2 / log 3 ≈ 0.63`, the first fractal with a computable
between-integers dimension. So the wall is staged as the **construction walked left→right**: first the
rule, then the rule made legible, then the worlds the rule builds, then the proof that the dust
outnumbers any list. Curation here is the argument that *erasure is a generative act* — you read a
thing into being by reading what it lost.

## Reading order (left → right, +X)
1. **THE RULE** (panel) → `example_8_4_cantor_set_vr` on a slim 1×1 plinth, raised high (top 1.3 m),
   set forward (z 0.7). The radial demo: the linear middle-third rule wrapped onto concentric rings —
   the smallest, most "held" object, so it gets the tall-narrow podium. *"What you raise high and
   narrow, you call precious."*
2. **EXISTENCE WITHOUT EXTENSION** (panel, the map's own title + the D beat) → **`cantor_bench`**, the
   focal point, on a low broad 2×2 plinth set FORWARD of everything else (z 0.5). This is the rule laid
   out generation-by-generation — the truest single object in the room.
3. **THE DUST IT LEAVES** (panel) → `cantor_set` (13×14 m, world_scale) on a 4×4 `station_stage`, set
   DEEP (z 2.4). The big "world" the rule carves — low and broad, set back as a backdrop mass.
4. **DELETION BECOMES ARCHITECTURE** (panel) → `example_8_4_cantor_pagoda_vr` (9×13 m) on a second 4×4
   stage, also deep (z 2.2). Each pagoda tier = one Cantor cut; the 1D deletion raised into 3D.
5. **UNCOUNTABLY MANY** (panel) → `cantor_diagonal_workbench` on a low 2×2 plinth, forward (z 0.9). The
   applied coda: the diagonal argument proves the dust outnumbers every list — closes "zero length, yet
   as many points as the line."

## Focal point
**`cantor_bench`** (centre, x≈6). It is set forward (smallest z, 0.5) and flanked by the panel carrying
the map title and the `D = log 2 / log 3` beat. Everything else reads off it: the rule (left of it), the
worlds it builds (the two deep stages, right and back), the proof (far right).

## The 3D composition (rewards orbiting)
Not a flat line — `z` runs 0.5 → 0.7 → 0.9 in the **foreground band** (the held/legible/proof objects)
and jumps to 2.2 → 2.4 for the **background mass** (the two world_scale stages set back). Base heights
stagger 0.0 / 0.18 / 0.95 / 1.3, so the silhouette steps from a tall narrow podium (left) down through
the low focal bench, back to the broad deep stages. From the front iso it reads as a clean left→right
ladder; orbiting reveals the two big worlds standing behind a forward row of three smaller, higher,
hand-scale pieces. Generous spacing (cell gaps of 4–6 m between clusters) keeps it walkable.

## Why each prop (footprint-fit)
- `example_8_4_cantor_set_vr` — measured [1.0, 3.0, 3.0] (room_scale, 1 cell wide, 3 m TALL). 1-cell
  footprint → **station_plinth 1×1, top 1.3, cap_inset 0.3** (the brief's slim high-narrow podium). It
  is *not* genuinely sub-1 m (it's 3 m tall), so a micropod would under-base a tall object — the slim
  1×1 plinth is the correct "one precious specimen" call.
- `cantor_bench` — `footprint_cells` 4 (designed 2×2) → **station_plinth 2×2, top 0.95**, low and broad
  per the 2–4 cell rule, presented at working height as the centerpiece.
- `cantor_set` — measured [13.0, 4.0, 14.0] (world_scale, >> 9 cells) → **station_stage 4×4** capped at
  4×4 per the ">9 → stage capped ~4×4" rule; `step_height` 0.18, low. `hazard_edge` marks the lip of a
  big walk-up mass.
- `example_8_4_cantor_pagoda_vr` — measured [9.0, 3.0, 13.0] (world_scale) → second **station_stage
  4×4**, low. Applied-tier architecture, given its own deep bay.
- `cantor_diagonal_workbench` — [2,3,2], `footprint_cells` 4 → **station_plinth 2×2, top 0.95**, low, a
  hand-cranked instrument at working height.

## Labels (requirement #2 — every artifact gets a 2D-in-3D plate)
- Plinths/micropods → `caption_text` = display name: "Cantor Set (radial)", "Cantor Bench", "Cantor
  Diagonal Workbench".
- Stages → `name_plate` (NOT caption_text, per the brief): "Cantor Set", "Cantor Pagoda". The two big
  artifacts on stages keep their surface-pinned plate — no fallback to a low-broad plinth just for the
  label.
- Five `station_panel` wall headers carry the map's truth-beats (THE RULE / EXISTENCE WITHOUT EXTENSION
  / THE DUST IT LEAVES / DELETION BECOMES ARCHITECTURE / UNCOUNTABLY MANY), so the only free-standing
  text is the editor-hidden Label3D's replacement: these plates.

## What changed from the baseline (`spine_walls.json`)
The old entry: (a) put **everything on one flat z = 0.8** — no 3D read; (b) gave the plinths/stage **no
caption/name_plate** — unlabeled bases; (c) staged **`dark_sphere` on a station_plinth** (it is the
void/sky backdrop, not a display artifact) and **`stochastic_tree_separated`** (a tree carried from
Fractals_2, off the Cantor concept) on a plinth; (d) under-based the large `cantor_set` on a **9×1
sliver stage** instead of a 4×4. This curation drops dark_sphere and the tree, labels every base,
caps both world_scale artifacts on real 4×4 stages, and stages a genuine foreground/background
composition around the bench.

## Tier coverage
small 1 (`example_8_4_cantor_set_vr`) · medium 1 (`cantor_bench`) · large 1 (`cantor_set`) ·
applied 2 (`example_8_4_cantor_pagoda_vr`, `cantor_diagonal_workbench`). Full small→medium→large→applied
ladder, each tier present exactly where the concept map places it (`doc/fractal_concept_map.json` →
"Cantor set").

## Decisions & gaps flagged
- **No `station_micropod` used — deliberate.** Per requirement #1 the micropod is for *genuinely
  sub-1 m* things (AABB ≲ 0.7 m). Every Cantor artifact here is room_scale or larger (smallest is
  1 m × 3 m tall). Forcing a micropod would under-base a tall object; the slim 1×1 plinth is the honest
  footprint fit. If a true held Cantor toy is ever authored, the small-tier slot should migrate to a
  micropod.
- **Duplicate scene skipped:** `fractal_cantor_set` (concept-map small) points to the *same scene* as
  `example_8_4_cantor_set_vr`. I staged only `example_8_4_cantor_set_vr` (the one the map itself uses)
  to avoid two identical objects on the wall.
- **Prop gap — none blocking.** The station kit covered every footprint band cleanly (1×1, 2×2, 4×4
  stage). The only content gap is the one `intent.md` already names: a **tunable dimension calculator**
  (vary the removal fraction, watch `D = log N / log S` change) — that artifact does not yet exist, so
  the wall makes D legible via the `cantor_bench` plate + the EXISTENCE panel rather than a live meter.
- **What to try next:** if VR review wants the worlds to dominate less, pull the two deep stages back
  another ~0.4 m (z 2.6/2.8) and/or drop their `step_height` so the bench reads as the unambiguous hero;
  if the bench should sit even more forward, add a short `station_barrier` in front of the two stages to
  cue "stand back, these are the big ones."
