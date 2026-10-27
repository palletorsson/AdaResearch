# Boolean Surfaces â†’ Void transfer: HANDOFF

Owner: Claude Opus. Written 2026-10-21. Batch: `doc/void-transfer/2026-10-21-batch-04/`.
Stage: **placed**. Native-tested: no. Headset-tested: no. Curated: no. No Godot run.
`python tools/audit_void_transfer.py boolean_surfaces` passes 132 / 132.

All 29 placements are placed, including every configured gallery duplicate. **No adapter
and no catalog override is required.** The eight artifacts read their config from the
metadata the Void stamps before `add_child`. None binds to museum-only ancestors, groups
or world heights.

## Files (all in `commons/void/trials/boolean_surfaces/`)

| file | what |
|---|---|
| `rooms.json` | 4 + 25 placements; 16 one-metre cubes for Verbs' raised bays; 39 provenance captions |
| `layout.json` | text only (status, floor roles, route note); frame, six-metre storeys and pads unchanged |
| `source-inventory.json` | each placement `placed` with its `void` record and any exception note; `transfer` block |
| `catalog-additions.json` | no required entries; two optional footprint corrections |
| `transfer-status.json`, `HANDOFF.md` | this package |

Untouched: shared files, source maps and texts, scenes, scripts, earlier trial folders, the
main tower. No git operations.

## Placement

Each floor is its source grid turned 180Â° about a chosen centre, 1 cell = 1 m:
`void_x = cx - cell_x`, `void_z = cz - cell_z`, `facing = token_rotation + 180`.
Verbs uses cx 6, cz 12; Gallery uses cx 8, cz 11. The entrance column lands on x 0 and
the entrance row beside the shared spawn (0, 12), so the source aisle stays the walking
aisle. Heights follow the museum plan rows (all 0) except where listed.

**Boolean_Verbs, floor 1.** Union (0, 8), intersection (0, 0) at 0.5 m with `forfeit:numeral`
and facing 0, difference (0, -7), the argument of solids (2, -10). The two raised bays
(structure 2 at rows 9 and 16, cols 1-4 and 8-11) are 1 m construction cubes at z 3 and
z -4, leaving the 3 m central passage. The whole hall stays between x -6 and 6, clear of
both shafts.

**Boolean_Gallery, floor 2.** Six rows of four, two each side of the aisle at x 0, in
source order east to west: x 6, 3, -3, -6.

| row | z | family | east to west |
|---|---|---|---|
| 3 | 8 | `csg_difference_demo#workings` | outcome, trace, operands, expression |
| 7 | 4 | `csg_union_demo#fusion` | lobed, distinct, necked, single |
| 11 | 0 | `csg_intersection_demo#consensus` | broad, unanimous, narrow, token |
| 15 | -4 | `subtraction_suite#breach` | pierced 6, opened **2.1**, severed **-2.1**, husk -6 |
| 19 | -8 | `coincident_face#separation` (height **0.35**) | coincident, clear, hairline, inverted |
| 23 | -12 | `removal_room#subtraction` | cross **9.3**, gasket **3.3**, third **-3.3**, figure **-9.3** |

The film `film_boolean_overlap` (`plinth:0`, `pin:true`) stands at **(15, -8)**, facing 270.

## Exceptions to the rigid turn (each in the inventory notes)

1. **Subtraction row spread.** Each suite is 2.88 m wide. In the source, opened and
   severed stood 2 m apart and interpenetrated by 0.88 m. They move from x Â±1 to Â±2.1,
   leaving a 1.3 m aisle.
2. **Removal row spread.** Each room is 5.41 m wide. The source put four of them 2 m
   apart, so they overlapped heavily. They move to x Â±3.3 and Â±9.3, keeping row, side and
   order. The row is at z -12, clear of the shafts and 1 m from the columns at z -14.
3. **Film relocated.** The rigid position (7, -18) is 2 m beyond the slab. The film moves
   to (15, -8), east of the gallery, still facing west into it.
4. **Coincident faces at 0.35 m.** The diagram is centred on its origin, with its lowest
   point at -0.31 m, so at height 0 the amber/blue band would sit at deck level. The grid
   lane auto-grounded it; the museum lane did not.
5. **Provenance captions** (`route`): 7 on Verbs, 32 on Gallery (the schema maximum).
   Removable.

## Not transferred

Perimeter walls; spawn and teleporter utilities; the `3t` text displays (Verbs col 1
rows 3, 11, 18; Gallery col 1 rows 2-22, all without a message); lighting, sky and
`nature_layer`.

## Controls to test

- **Every artifact except the film is observation only.** None has buttons, sliders,
  pickables or input handlers. Test that each copy builds its configured variant, that
  the CSG bodies rotate, and that the intersection readouts show three volumes. The
  `forfeit:numeral` plate is on Verbs.
- **The film** (`concept_monitor`) has PAUSE / REPLAY / STEP / ROUTE buttons and a private
  viewport. It activates on gaze within 14 m, with its sight raycast on mask 1.
- **The CSG bodies have no collision**, which `final.md` relies on ("You can pass through
  a surface"). Confirm the Void does not add any. The plinths, benches and shells of the
  argument, suites and removal rooms may carry their own collision; I did not verify this.

## Fit risks

- **Gallery outer copies.** These stand 0.5 to 0.65 m from a shaft hole on their outer
  flank: union `single` at x -6.96 (z 3.5-4.6), intersection `broad` and `token` at
  Â±6.85 (z -0.95..0.55), and subtraction `pierced` and `husk` at Â±7.44 (z -4.5..-3.5).
  Viewing is along z, so no viewing position is on that flank. Widening the gallery is
  a curation choice.
- **Floor 2 A landing.** The landing at (-8.3, -1.9) opens east onto a 2.5 m corridor
  between the `token` and `husk` copies.
- **Removal rooms.** The spread row spans x -12 to 12. Its fronts face south (-z), as in
  the source, so the visitor views them from z about -13.
- **Unmeasured extents.** The removal room AABB is computed, not measured (its registry
  says so). The intersection plates and gauge, the subtraction suite's trays, and the
  argument's bench ends are estimates. Read `measure` before trusting the gaps above.

## Commands

```bash
python tools/audit_void_transfer.py boolean_surfaces
```
```bash
python tools/export_void_trial.py boolean_surfaces
```

Editor: `http://localhost:3003/lab-editor?mode=void&trial=boolean_surfaces&floor=2`.
Every copy is its own entry, so copy, move and turn act on one variant.

**Test scope.** This package was checked statically: the schema, transforms against the
inventory, clearances from predicted extents, and the source audit. Loading, variant
appearance, collision, residency and editor saves are untested and are yours to run.

## Coordinator acceptance — Codex, 21 October 2026

The delivery above was independently reviewed after Claude froze it. All 29
placements and configured duplicates match their source inventory. Native Mobile
testing passed 355 checks across desktop and synthetic tracked XR. Every live
variant property, generated geometry, non-colliding CSG body and floor height was
checked. The intersection retains its three-volume numeral plate. Film gaze,
pause, step, view turn, replay and moved/rotated input work. Shaft landing, upper
floor sleep, return/resume and retry passed. No physical headset was used.

Measured geometry confirms the optional footprint corrections: removal rooms
5.41 × 1.64 × 1.145 m; argument bench 5.073 × 1.77 × 2.599 m. All native bounds
fit the slabs, with no sampled pairwise or shaft AABB overlap. The actual solids,
benches and room shells have no PhysicsBody3D colliders; the film has its own case
and stand. Measurements are in evidence/measured-bounds.json. The broad union
catalog footprint still warns near an approach; native geometry is clear and the
landing test passes. Final circulation is a curation task.

All 29 placements exported as real native geometry. The editor passed 32 checks:
independent copy/move/rotation for every artifact, save/reload to the native layout
and Desktop mirror, stale-save rejection and unchanged source maps/chapters.
The four images are native screenshots from the trial. Chapter texts and the
main curated tower were not changed.
