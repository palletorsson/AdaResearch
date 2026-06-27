# Curation Notes — VFM_02_Operations (sequence: forces)

> *"Curation is an argument made with placement."* This hall stages the moment **vectors start
> computing things**: the two products and their consequences. The wall is built so a player can
> *walk the argument* dot → cross → projection, not just file the objects.

## The argument (what the wall says)

The map's own lesson (from `tutorial.md` / `intent.md`): **dot answers *how aligned* (one scalar),
cross answers *which way is perpendicular* (a vector), and projection is the shadow that keeps
coming back wearing a physics costume** (work is the dot, torque is the cross, normal force is
projection again). I composed the wall as **three reading bays along +X**, each a self-contained
claim with its own headline panel, its monumental walk-inside station set *back* as the bay's
backdrop, and its small/applied consequences brought *forward* toward the viewer:

1. **DOT — how aligned** (x ≈ 0.5–5): `vector_dot_product_xl` (large, walk-inside) is the deep
   backdrop on a 4×3 stage; `VectorWorkbench` (medium) is the hinge at mid-depth where "you take the
   dot at the bench"; `dot_aligner` (applied) and the small `agreement_gauge` + `work_energy_demo`
   crowd forward — agreement and work are what the dot *gives you*.
2. **CROSS — the perpendicular** (x ≈ 8–11): `vector_cross_product_xl` (large) backs the bay;
   `torque_crank` (applied — "the cross product with a handle") sits forward at hand height, with
   the small `torque_demo` beside it.
3. **PROJECTION / REFLECTION — the shadow that returns** (x ≈ 12–18): the synthesis bay.
   `vector_projection_reflection_xl` (large) is the **focal centerpiece** — set deepest (z = 2.6),
   lifted highest (step 0.2 + a lit toe-groove), and **framed by its own pair of tall lit pillars**
   so it reads as the place the lesson lands. `projection_shadow` (applied) sits forward; the small
   `normal_force_demo` ("projection wearing a physics costume") and the closing
   `exercise_5_9_angle_between` ("measure the angle without a protractor") form the coda before the
   teleporter to Motion.

A bookend pillar stencilled **OPERATIONS** opens the run at x = −0.5; a pillar stencilled
**TO MOTION →** closes it at x = 18.8, pointing at the map's actual teleporter exit (`t:VFM_03_Motion`).

## Reading order & focal point

- **Left → right (front iso):** OPERATIONS ▸ DOT bay ▸ CROSS bay ▸ PROJECTION bay (focal) ▸ MOTION.
- **Focal point:** `vector_projection_reflection_xl` — deepest z, highest lift, the only artifact
  given a framing pillar pair and a lit-edge stage. It is the synthesis the whole tutorial circles
  back to (projection recurs as reflection *and* as normal force), so it earns the architectural
  emphasis. The two product XL stations (dot, cross) flank it as equals one step back in emphasis.
- **Reward for orbiting (free-cam):** each bay is a genuine alcove — large station deep, medium at
  mid-depth, applied + small things staggered forward across z = 0.5–1.9. Walking *around* a bay you
  see the consequence-pieces in front of their parent operation, which is the point: the small demos
  are literally downstream of the big idea behind them.

## Why each prop (chosen for meaning, per the @identity reads)

- **`station_stage` (3×) for the walk-inside XL stations** (footprint 9 / room_scale). The plinth's
  truth is "size IS the argument — what you set low and broad, you call a world." These are 5×3 m
  walk-*inside* spaces, so they get a low broad **stage** ("the smallest honest pedestal — height
  enough to mean *look*, low enough to step onto"), named via `name_plate`, not a tall podium.
- **`station_plinth` 3×1 @ top 0.9 for `VectorWorkbench`** (footprint 3) — a long thing laid across
  the grid, presented at working height as the bay's hinge.
- **`station_plinth` 2×1 @ top 1.0 for the applied trio** (`dot_aligner`, `torque_crank`,
  `projection_shadow`, footprint 2) — hand-height benches you operate.
- **Slim `station_plinth` 1×1 @ top 1.15–1.35, cap_inset 0.3 for the five small demos** — "a tall
  narrow podium for a small precious thing… the lift always says *this one, here, by itself*."
  Heights are varied per-piece (1.15 / 1.2 / 1.3 / 1.35) so the small row is not a flat fence.
- **`station_panel` (3×, wall) as bay headers** — the only floating-free text on the wall, each
  carrying the map's own truth-beat (`a·b = |a||b|cosθ`, `a×b ⊥ both`, `(a·n̂)n̂`). The editor hides
  every artifact's Label3D, so these plates + the plinth captions are the entire legend.
- **`station_pillar` (6×)** — bookend signage posts (OPERATIONS / TO MOTION →), inter-bay dividers
  that turn open floor into three rooms, and the focal centerpiece's framing pair. "One upright,
  repeated, makes a room out of an open floor."

Every artifact's base prop carries `caption_text` (or `name_plate`) = its **registry display name**,
rendered as a framed 2D-in-3D plate (requirement 2, satisfied 12/12).

## Prop gaps flagged

- **`agreement_gauge` is sub-1 m** (registry `size_group: small`, no measured footprint). I used the
  slim 1×1 plinth as instructed, but even a 1×1 foot reads a touch oversized under a tiny gauge.
  **Gap: a future micro-pedestal** (≈0.4–0.6 m foot, a true specimen stand) for genuinely
  hand-sized instruments. Same note applies more mildly to `work_energy_demo` / `torque_demo` /
  `exercise_5_9_angle_between` (1-cell tabletop demos) — they sit fine on the slim plinth but would
  benefit from the same micro-stand so the foot doesn't crowd a 1 m cell.
- No registry footprint exists for `agreement_gauge` or `exercise_5_9_angle_between` (used
  `size_group` / 1-cell `grid_cells` fallbacks per brief §3). Worth a `sync_footprints` pass so
  future auto-placers measure real AABBs.

## What changed vs. the baseline (and what to try next)

The current `spine_walls.json` entry is **flat** — every piece at z = 0.8 in one straight line — and
it **drops all three walk-inside XL stations** (counts large = 0), so the small→applied pieces float
with no parent idea behind them. This curation: (a) **restores the full ladder** (large = 3, the
three XL "walk-inside" products as the backbone), (b) **stages a real 3D composition** across 11 z-
planes with three alcove bays and a framed focal centerpiece, and (c) gives every bay a **truth-beat
header** so the lesson is legible without any floating labels.

**Next to try:** walk it in VR / capture `--mode=map --target=VFM_02_Operations` to confirm the
4×3 stages clear the XL stations' 2 m front/back clearance without overlapping the forward applied
benches; if the projection bay feels tight, nudge `projection_shadow`/`normal_force_demo` ±0.4 in X.
Then build the micro-pedestal prop and re-seat the four 1-cell demos onto it.
