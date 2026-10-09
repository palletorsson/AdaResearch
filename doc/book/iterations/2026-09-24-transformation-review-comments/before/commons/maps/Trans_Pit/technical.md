# The Moving Boundary — technical companion

Current museum configuration, 23 September 2026. Canonical map ID: `Trans_Pit`. The display title describes timed boundaries on level ground. The historical technical draft described a lethal pit course and included illustrative implementations that do not match these artifacts; its complete text is retained in the [before snapshot](/book-review/doc/book/iterations/2026-09-23-moving-boundary/before/commons/maps/Trans_Pit/technical.md).

## Three timed studies

The map retains an optional route around the first lanes and room to observe the other studies. Its legacy fire tokens are disarmed by the embedded museum. The final manuscript therefore makes no claim that failure kills the visitor or that every obstacle must be crossed.

| Encounter | Current placement and rule | Source |
| --- | --- | --- |
| Translation | Three 0.98 m pushers at source cells (3,3), (7,3), (5,5), centred 0.49 m above the deck. Each travels 2 m; axes +Z, +Z, −Z; speeds 1.5, 2, 1.8 m/s; endpoint pauses 1.5, 1, 1.2 s. | `commons/hazards/transformation_blocks/pusher_block.gd` |
| Rotation | Two `rc` utilities turn 90° about Y and reverse, with 4 s and 3 s endpoint pauses. Their wall profiles offer broad faces and narrow edges to the route. Four ball launchers add independent timing in this zone. | `commons/scenes/mapobjects/rotation_cube.gd`; see tutorial.md for the exact configuration. |
| Scale | Three growers at (3,21), (7,21), (11,21): side length 0.3–3.5 m, rate 0.15 cycles/s, `anchor:floor`. No visitor distance enters this size calculation. | `commons/hazards/transformation_blocks/grower_block.gd` |

The [tutorial](tutorial.md) follows the actual pusher interpolation, reversing turn and growth code. The grower advances its phase by `delta * grow_speed * TAU`; the floor-anchored cosine starts small and completes a cycle in about 6.67 s. Mesh and collision dimensions change together. Their centres remain half a side length above the fixed floor reference. The legacy centre-anchored mode is a different configuration.

These object invariants do not determine a body's usable route. Translation preserves dimensions; rotation preserves internal distances; positive uniform scale preserves proportions. Available clearance also depends on placement, timing and the collision body attempting passage.

## The final door

`commons/artifacts/transformation_airlock/transformation_airlock.gd` is placed at (7,29), beyond the timed studies. It deliberately returns to proximity as input. The next sequence, Array, returns to the pickup cube and asks what changes when it has indexed copies.

The frame has a nominal 3 m wide by 2.8 m high opening. Two leaves translate outward and upward, turn in the frame's plane, then shrink to 34 percent of their initial dimensions. The three intervals overlap. They share an opening fraction driven toward one over 4.8 seconds while a qualifying visitor occupies the sensor; after three empty seconds it runs back toward zero. Approach from either side can open it. No pickup count or player relocation is involved.

The sensor is an 8.8 × 4.6 × 9 m box, centred 2 m above the root. It accepts the configured player collision layers, then checks for CharacterBody3D or the player/walker groups. This is a programmed recognition of the body, not a universal definition of presence.

Physical leaf bodies retain unit scale. Each leaf's convex shape is resized with the visible armour and shares the leaf's translated/rotated transform. The opening can admit the museum body before all three operations finish: the mechanism demonstrates composition, not three individually necessary locks. It holds while a qualifying body remains in its clearance area; vacancy, rather than successful collection, allows it to close.

## Shared book figures and current checks

Both figures are native Godot renders of this hall with its current artifact placements, geometry and materials. `tools/probes/moving_boundary_illustrations.gd` runs through `tools/run_encounter_probe.py`, which isolates museum output paths. No live bake or save is replaced.

- **The room keeps time:** one fixed camera, 2 m above the grower floor reference, at the small and large extremes. The probe freezes phase at 0 and π for photography; a separate ordinary-clock check confirms all three grow while the player remains parked away. This is a view down one lane, not an overhead comparison of all three cubes.
- **Make room:** one fixed camera at 1.7 m above the door's floor reference. Selected opening fractions 0, 0.52 and 1 show the closed, turning and reduced poses. These are supplied photographic poses. The subsequent interaction check restores the ordinary proximity controller.
- **Current interaction evidence:** the actual museum body (0.64 m wide, 1.5 m high) receives walking input to approach, cross and return. The door opens, holds with the body waiting, and closes after the body is parked outside its sensor. The probe also compares visible/physical leaf sizes and the growers' fixed bases and matching geometry.

All 46 focused checks pass, exit 0. [Runtime report and source manifest](/book-review/doc/book/iterations/2026-09-23-moving-boundary/index.html#evidence). This pass does not repeat the entire pusher/rotation course, demonstrate contact forces for every player rig, or establish headset comfort or learner understanding. Historical endpoint and full-cycle studies remain documented in `commons/testing/probe_transformation_pit.gd`; earlier airlock mechanics and placement evidence are in `doc/space/transformation-airlock-2026-09-17/`.
