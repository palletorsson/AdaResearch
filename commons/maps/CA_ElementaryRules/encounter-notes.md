# Enlarged neighbourhood — 25 September 2026

`structure_growth` remains the primary work. The map opts into `room:neighbours`; ordinary `study:states` placements remain unchanged.

`neighbour_room.gd` reads the 27 actual entries around (26, 22, 24). It shares the original solver, seed, buffers, controls and held clock. It adds no collision, sensor, rule, button or random source. Its 27 boxes are 0.52 m wide at 1.13 m spacing; empty positions remain wire outlines. Gold marks the central address. Directions between neighbours are preserved while the display spacing is enlarged. The compact specimen keeps its own scale and surface culling; the new view shows every occupied position in this neighbourhood, including ones the compact renderer can hide.

For seed 23090 under the existing 6-8/6-8/3/M rule:

| Generation | Centre | Active neighbours |
| --- | --- | --- |
| 0 | 1 — active | 11 |
| 1 | 2 — fading | 7 |
| 2 | 0 — empty | 5 |

The seven-neighbour count belongs to generation 1. It does not permit birth at that update because the central state is 2, not 0. This is a witnessed instance, not a claim that all fading cells have seven neighbours.

VIEW copies the source height-gradient mapping, using original addresses rather than the enlarged world coordinates. REPLAY restores the whole seeded volume. The fixed selected address also has a small depth-tested outline in the compact specimen; other cells can occlude it.

## Evidence and limits

49 native checks pass, with eight actual museum mouse-ray clicks and a supplied CharacterBody route through the gaps on the existing floor. Every shown state and colour, absence at state zero, shared controls, complete replay, budget, no extra collision and legacy opt-in are checked. The final process exits 0 without GDScript errors. Native images and exact diffs: `doc/book/iterations/2026-09-25-ca-lingering-cell/index.html`.

The full 125,000-cell update took 153.009 ms in the final run; the pre-change measurement was 166.710 ms. This variation is not an optimisation result. The solver is unchanged and its single-frame cost remains a VR problem. Existing missing-UID, environment, registry and renderer warnings, plus generated-art build warnings, remain in the log.

The narrow supplied desktop walking/input tests do not establish whole-route traversal, tracked-hand reach, headset comfort, Quest performance or learner acceptance. The first outside camera hid the chosen cell; later views approach it through a gap. Diagnostic captures are retained.
