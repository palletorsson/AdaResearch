# Noise Voxel — metre cells, flying body

Author request: each cube in the large voxel work should be one metre, with a fly box around the space.

## Built

- Large receiver: 24 × 24 × 24 addresses, one-metre cell spacing. Same seed 31415, sampler, bias and occupied set. Bench remains at 4 cm: the physical ratio is now 25:1.
- Physical glass flight cube: 28 m per side, two metres around the field horizontally and four metres above. Human-scale ground doors stay 3 m wide × 2.6 m high. Floor, walls and roof collide; occupied voxel surfaces still collide.
- Existing museum flight controls: desktop look/WASD, Space up, Ctrl down; XR tilted left controller and left stick. Neutral input hovers, speed capped at 2.4 m/s, normal gravity resumes outside.
- A construction-time edge_length parameter extends the existing flight box. Menger and Array retain their default 12 m enclosure. The XR provider and museum movement code are unchanged.
- Hall expands from 15 × 16 to 33 × 44 cells, with open roof. Interior recovered structure/utility tokens shift +9 in x. Side/end boundaries expand. The bench and screen shift with the grid, the volume moves to (16,24), the orb to (5,8), safely outside the enclosure. No authored artifact is removed. Roles and sequence order are unchanged.
- Stage, caption, yellow section and selected-address marker scale from cell spacing. Field and CELL changes preserve the flight zone. The metadata route is opt-in: existing stand:volume placements keep 0.20 m unless cell_size is supplied.

## Book

Corrected the physical ratio, selected-layer heights, photograph and approach. Added one flight encounter: support below the feet is no longer required, but clearance still matters. Earlier threshold/CUT, occupancy, component-count, material and critical arguments remain. Current companion documents now use the new scale; dated earlier reports remain available.

## Native evidence

69 final checks pass, with three floor rays. Synthetic keys drive the actual museum controller through a ground door, up the front margin, into an interior void and back, above the volume, down to the far door and out. A discrete search nominated a route with two vertically empty cells; the physical museum capsule then validated all 15 inward and 15 outward segments. Deepest reached address: (12,11,12), feet near 11 m. Neither search nor flight implies that every empty cell is reachable.

The real XRTools body with synthetic tracking ascends using a tilted left controller and stick, hovers on neutral input, yields to other providers and releases outside the 28 m box. Repeated installation leaves one adapter. This is not a headset test.

Four additional checks cover settling at the museum arrival and walking to the bench, around its corner and to the flight entrance. A further native view looks up from cell (12,16,12), on the verified route. The original deep-pocket photograph looks directly at a nearby wall; it is retained rather than presented as a panoramic space.

## Diagnostic record and limits

The first route kept the old heading because the probe detached the view-smoother reference without stopping that node. Corrected the probe, not production locomotion. The XR fixture initially forced its script to compile before XRToolsUserSettings existed; deferred that load to runtime. A stage caption used unsupported %g formatting; production caption corrected to %s. Failed logs remain under first-heading-check/ and xr-fixture-check/.

The direct bench-to-door test clipped the bench corner; its failed report is retained under first-arrival-check/. The accepted approach walks around the corner. No obstacle or collision was removed to pass a test.

Final native runs exit zero, without script/formatting errors. Existing UID, renderer, empty-registry and occasional decoration-build warnings remain in logs. Tests use private museum files, controlled input and paused independent camera smoothing. No headset reach, tracking quality, comfort, learner acceptance or Quest performance claim. The live museum bake/save and frozen book exports are untouched. Reload/rebuild Noise_Voxel for its enlarged source placement.
