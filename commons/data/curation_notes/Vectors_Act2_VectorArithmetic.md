# Curation — Vectors_Act2_VectorArithmetic (sequence: forces)

## The argument
The map's own thesis is that *arithmetic is what vectors do to each other*, compressed in its
closing reflection to three verbs: **to add is to walk; to dot is to agree; to cross is to turn.**
The wall stages that ladder as a walkable left-to-right sentence — the foundational moves
(add / subtract), then the centerpiece where addition becomes a room you step into, then the three
*products* (agree / shadow / turn) lifted high as precious objects. Placement is the argument: what
is set low and broad is "a world you stand in," what is raised high and narrow is "precious."

## Reading order (+X, left to right)
1. **Scaling** — `example_2_3_gravity_scaled_by_mass_vr` (tier *small*) — the warm-up: a scalar is a
   volume knob for a direction.
2. **Addition** — `vector_add` (tier *medium*) — a + b is where you arrive.
3. **Subtraction** — `vector_sub` (tier *medium*) — a - b is the gap between. (Set deeper, z=1.3,
   so the add/sub pair reads as two depths of one idea, not a flat row.)
4. **CENTERPIECE — `vector_addition_walk`** (tier *large*) — the one walk-in that is genuinely a
   staged pedestal exhibit (registry: `platform: pedestal`, `player_position: front`). Set **forward**
   (z=2.4) on a low broad 4x4 stage, flanked by two `station_pillar` corners so the bay reads as
   architecture. This is the focal point: "TO ADD IS TO WALK."
5. **The products** (tier *applied*) — `dot_aligner` (agree), `projection_shadow` (shadow),
   `torque_crank` (turn) — three slim high-narrow plinths staggered in depth (z 0.7 / 1.3 / 0.9),
   an alcove cluster that closes the wall on the three things vectors make.

## Focal point
`vector_addition_walk` on its forward 4x4 stage. It is the only artifact pushed out to z=2.4, the only
one on a broad low stage, the only one framed by paired pillars, and the only one with a full-width
wall panel directly behind it carrying the act's headline verb. Everything else reads as approach.

## Why each prop
- **Slim 1x1 plinths, top 1.15-1.25** for the three applied toys (dot/projection/torque): per the
  plinth's "size IS the argument," these compact gadgets are raised high and narrow to read as
  *precious products*, lifted above the foundational consoles.
- **Fitted 2x1 plinths, top 0.9** for `vector_add` / `vector_sub` (3-cell consoles): sized to the
  console footprint, presented at lip/reach height where the two-pad surface is used.
- **1x2 plinth, top 0.85** for the scaling demo (1x2 footprint): low and modest, the warm-up.
- **`station_stage` 4x4, step 0.18** for the large walk-in: big thing goes low and broad; the step
  is the smallest honest pedestal for a room you step onto. `name_plate` is its label.
- **`station_panel` x3 (wall, 2D-in-3D)** carry the map's actual truth-beats as tier-group headers
  ("ADD / SUBTRACT", "TO ADD IS TO WALK", "THE PRODUCTS — agree / shadow / turn") — the only floating
  text the editor keeps; artifact Label3D is hidden.
- **`station_pillar` x2** frame the centerpiece bay (readout_face on) so the large exhibit is
  architecture, not furniture in a void.
- **`caption_text` on every artifact plinth** = the display name, rendered as a framed surface-pinned
  plate (requirement 2). The stage uses `name_plate` for the same purpose.

## 3D composition (requirement 3)
Nothing sits on one flat z. Depth runs 0.7 -> 1.3 across the toy ladder, jumps to **2.4 forward** for
the centerpiece, then steps 0.7 / 1.3 / 0.9 across the applied cluster. Height staggers: 0.85 (small)
-> 0.9 (medium consoles) -> 0.18 broad (large stage) -> 1.15-1.25 high-narrow (applied). Read from the
front it is a clean left-to-right ladder; orbited in free-cam it is a foreground stage, a mid-depth
console pair, and a high back-and-forth alcove of products — bays, a thing set forward, backing wall
behind. Walkable gaps (~1.5-2.5 m) between every cluster; deliberate negative space east of the
centerpiece pillars before the products.

## What this beats (baseline)
The current `spine_walls.json` entry stages the same 7 artifacts but **flat**: every plinth at
top_height 0.9, every piece at z=0.8, the products at the same low height as the consoles. It reads as
a shelf. This version (a) honors the concept-map tiers (small/medium/applied/large) as *height*, (b)
lifts the three products high-and-narrow as precious, (c) pushes the centerpiece forward into its own
depth with a framed bay, and (d) staggers depth across every cluster so the free-cam is rewarded.

## Tiers (source: doc/vector_forces_concept_map.json concept_meta)
small 1 (Scaling) · medium 2 (Addition, Subtraction) · applied 3 (Dot, Projection, Cross) ·
large 1 (Addition Walk). Counts: {small:1, medium:2, large:1, applied:3} = 7 staged.

## Prop gaps flagged
- **Micro-pedestal gap (the main one).** `dot_aligner`, `projection_shadow`, `torque_crank` each
  measure **2 footprint cells** but read as small precious toys. To lift them high-and-narrow I used
  slim **1x1** plinths (per the brief's "precious small things go high+narrow"), which means a 1x1
  foot is a slight under-fit vs their 2-cell measurement. A true sub-1 m **micro-pedestal** prop
  (a 0.5 m narrow column) would seat these gadgets without any base overhang. Future addition.
- **The three pure walk-inside XL twins are intentionally NOT on the wall.** `vector_dot_product_xl`,
  `vector_cross_product_xl`, `vector_projection_reflection_xl` are `delegate_to` room-scale exhibits
  (`player_position: inside`, ~5x5 m) — rooms you stand *inside*, not objects you shelve. Staging them
  on a plinth would contradict their nature, so (like the baseline) they live in the open map, not on
  the curated wall. Only `vector_addition_walk` (a `platform: pedestal`, `player_position: front`
  exhibit) earns a stage. This is a deliberate curatorial limit, not a missing prop.

## What to try next
- Add the micro-pedestal prop and re-seat the three products on it (remove the 1x1 under-fit note).
- Consider a fourth wall panel naming the dot product's FOE->FRIEND beat ("agreement is mercy") above
  the Dot-Aligner — the intent.md flags this as an un-named strong beat.
- A capture pass (`--mode=map --target=Vectors_Act2_VectorArithmetic`) to confirm the high-narrow
  products don't collide with the wall panel behind them and the forward stage reads as focal.
