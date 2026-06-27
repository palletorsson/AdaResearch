# Curated Wall — VFM_01_Foundations (sequence: forces)

> *"Curation is an argument made with placement."* This wall turns the museum's front-door
> lesson — **what a vector actually is** — into a walkable argument, read left→right (+X),
> rewarded by orbiting.

## The argument (reading order, left → right)

The wall retells the map's own tutorial spine as five bays, each headed by a `station_panel`
truth-beat (2D-in-3D, the only floating-free text — artifact Label3Ds are hidden by the editor):

1. **I — A WHERE** (x 0–5). The focal bay. Before a vector, a *where*: three axes and an agreed
   origin. **CoordinateSystem3M** is the centerpiece, raised on its own 4×4 `station_stage` and
   **set forward** into the room (z = 1.5) inside a pair of cool-blue `station_pillar`s. You are
   meant to stand *inside* it (its own `@identity`: "learner stands inside the coordinate system").
2. **II — WHAT A VECTOR IS** (x 11–15). The two halves. **VectorBasics** (the definition), then
   **Magnitude** and **Normalization** as a depth-staggered pair — *how far* set forward, *which way*
   set behind it — because normalization is "magnitude forgotten, direction kept."
3. **III — ARITHMETIC ON THE IDEA** (x 18–30). Everything else is arithmetic on that idea: **Scaling**
   leads, then the **Addition** and **Subtraction** consoles as a front/back mirror (a+b is "where you
   arrive if you walk a then b"; a−b is "where b's tip must reach to land on a"), then the **Basis
   Vectors Rig** and **Translation**.
4. **IV — THE VECTOR BENCH** (x 33–39). The **applied** tier — the same ideas made *playable* hand
   instruments: **The Adder's Drafting Board**, the **Length Lantern**, the **Stretch Bench**. Its own
   framed bay (two pillars + backing panel), the three machines in a low foreground row.
5. **V — TOWARD FORCES** (x 41–43). The doorway. **Newton's Laws** and **Forces (2.1)** hang here,
   ahead of the forces halls, because "every law is a sentence about vectors." Forces (2.1) is set
   back — receding toward the teleporter to VFM_02_Operations.

## Focal point

**CoordinateSystem3M** — large tier, footprint 9 (5×4). The single clear focus: alone on a broad
low stage, pushed forward off the wall, framed by two blue pillars and backed by the opening
truth-panel. Big and broad = "a world," exactly as the plinth/stage `@identity` prescribes; the frame
is the one thing the whole hall is arithmetic *upon*, so it earns the isolation and the depth.

## Why each prop (footprint-fit)

| Tier | Artifact | Footprint | Base prop chosen |
|------|----------|-----------|------------------|
| large | CoordinateSystem3M | 9 (5×4) | `station_stage` 4×4 (capped), low + broad — a world to stand in |
| medium | vector_add / vector_sub | 3 each | `station_plinth` 3×1, mid height 0.95 |
| medium | basis_vectors_rig | 4 (2×2) | `station_plinth` 2×2, height 0.9 |
| medium | vector_translation_demo | 3 (3×1) | `station_plinth` 3×1, height 0.95 |
| small | VectorBasics | 2 (2×1) | `station_plinth` 2×1, height 1.0 |
| small | magnitude / normalize / multiplication | 1 each | **slim 1×1** plinth, `cap_inset 0.3`, tall (1.3–1.4) — precious = high+narrow |
| small | Forces (2.1) | 2 | `station_plinth` 2×1, height 1.0 |
| small | Newton's Laws | [1,2] (sub-1m read) | **slim 1×1** plinth, tall 1.35 |
| applied | adder_board / length_lantern / stretch_bench | [1,2] each | `station_plinth` 1×2, low 0.85–0.9 — bench-shaped |

Each plinth carries the artifact's **display name** as its `caption_text` (renders as a framed,
surface-pinned plate). The centerpiece carries its name on the stage `name_plate`. No 1 m default base
was used for any 1-cell artifact — every small thing sits on a slim high-narrow podium.

## Using the 3D space (not a flat line)

The baseline (`spine_walls.json`) put **all 19 artifacts on a single flat z = 0.8**, x = 0→55 — a
conga line. This wall keeps the left→right read but composes in depth:

- **13 distinct depth values** (z 0.5 → 2.4) and **9 distinct base heights**.
- Pairs are staggered front/back so orbiting reveals the relation: magnitude (z 0.5) vs normalize
  (z 1.95); addition (z 1.3) vs its mirror subtraction (z 2.3).
- The centerpiece gets its **own forward depth** (z 1.5) with a backing wall behind and pillars
  beside — a genuine alcove, one clear focal point.
- The applied bench is a **foreground row**; concept tiers recede behind their panels. Deliberate
  negative space sits between bays (x 5→11, 30→33) so each argument-beat reads as its own bay.

## Prop gaps flagged

- **Newton's Laws** (footprint [1,2,1], a thin upright readout) reads clearly **sub-1 m** in plan.
  Even the slim 1×1 plinth foot is a touch broad for it. **Future micro-pedestal** — a ~0.5×0.5 m
  high-narrow post — would seat thin upright "law/readout" artifacts honestly. Used the slim 1×1 here
  as the closest fit.
- The three **Vector Bench** machines (adder_board / length_lantern / stretch_bench) carry no
  `measurements.grid_cells` in the registry — only `footprint [1,2,1]` + `size_group: small`. Sized
  their plinths 1×2 from the footprint; if their true measured AABB differs, run `sync_footprints.py`
  and re-fit. They are also kin (`artifact_neighbors.json`) — they belong together, which the bench
  bay honours.

## What to try next

- **Excluded by design:** the two **XL** demos (`vector_addition_xl` room_scale 9, `vector_subtraction_demo`
  xlarge 9) and the standalone info-demos (`script_runner`, `graphics_monitor`, `2d_in_3d_vectors_vis`)
  are floor / wall-info **installations in the map proper**, not curated-wall objects. They live on the
  open floor in `map_data.json`; the wall curates the legible interactable vocabulary. If a walk-in XL
  bay is wanted on the wall, give `vector_addition_xl` its own deep alcove east of bay III with a low
  `station_stage` 4×4 and a "WALK INSIDE" panel.
- `coordinate_system_switcher` (small) was **dropped** from the wall: its lesson ("switch the basis,
  watch nothing move") is already carried by the centerpiece frame + the III header. Re-add as a slim
  1×1 beside CoordinateSystem3M if the switch interaction should be reachable from the wall.
- Capture to verify height re-seating: `capture_multi_angle.gd --mode=artifact` per plinth+artifact
  pair, then a `--mode=map` orbit to confirm the depth composition reads from the free-cam.
- Consider pulling `agreement_gauge` (the Vector Bench's shared dot/alignment kin) into a transitional
  beat before bay V — but it arguably belongs to the *next* hall (dot product / alignment), so it is
  left out here to keep this hall's argument clean.
