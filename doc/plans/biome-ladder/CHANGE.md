# B20/B21 — a pattern becomes a direction

13 October 2026. Palle approved fixing Tiling, then building Change. There are now six playable ladder stages. Tutorial/final.md and canonical museum order are unchanged.

## Tiling

The desktop walker and XRTools PlayerBody walk the continuous backing. Their collision exceptions exclude the 4 cm paint tiles; catalyst and skull projectiles still meet those exact transformed tile colliders. Exceptions are removed before a stage's bodies are freed. This avoids the turned edge that previously stopped the walker short of RESET, COLOUR and MENU.

A catalyst hit starts one 1.15-second white outline pulse on all 18 matching tiles in the same frame. The highlight fades; the underlying colour, scale and turn stay. Other motif addresses do not flash. RESET clears the highlight and tile state. The in-world explanation now sits on the entrance refuge, above the hand glow.

The native probe first reproduces the old obstruction with only the walking exceptions removed. With the fix, the same body walks from arrival to all 14 controls, including the new Change selector. Tile ray and projectile collision remain intact.

## Change

Play **Game menu → Biome Ladder → 6 CHANGE**, or NEXT STAGE from Tiling. The museum entry is in **Flow_Field**; MUSEUM continues to **Forces / Vectors_Act1_WhatAVectorIs**.

The floor retains scaling, rotation, colour and repeated impacts. Each tile now carries an arrow. A shot rotates the tile and its arrow together; the sampler reads that same rotation at the ball's current cell. A direction applies over its addressed cell, including gaps left by a smaller tile. Outside the floor, the forward direction is used.

The centre column introduces the new shot. It follows those arrows for 1.4 seconds at 1.8 m/s. It then samples the current target once, holds still and draws a white line for 0.9 seconds, and commits to that straight direction. Move after the signal and it continues toward the remembered position. No further homing occurs. The outer columns retain the stored zigzag paths. Row/column scheduling, falling vacancies, growing balls, cover and pickups remain.

This is prescribed motion: direction × speed × elapsed seconds updates position. Velocity is not accumulated from a force. Acceleration, mass and gravity remain for Forces. The player's catalyst edits the field through floor impacts; its own projectile retains the earlier flight behaviour.

START restores the encounter and starts volleys. REST clears shots while retaining floor edits. RESET restores the field as well as the earlier state. Stage changes still reset exact floor edits; inherited abilities remain available.

## Checks

| Runtime check | Passed |
|---|---|
| Tiling access and simultaneous feedback | [25/25](feedback-checks.json) |
| Change input, field, turn and collision | [36/36](change-checks.json) |
| Six-stage behaviour | [80/80](change-stages-checks.json) |
| Arrays regression | [140/140](change-arrays-checks.json) |
| Tiling impacts regression | [33/33](change-tiling-checks.json) |
| Desktop input through all stages | [61/61](change-desktop-checks.json) |
| Controlled XR input and falling skulls | [127/127](change-xr-checks.json) |

The Change probe uses actual desktop input to select the stage and paint the floor. It checks the arrow/sampler reference frame, constant speed, one interval versus two half-intervals, target sampling, warning duration, committed direction, normal engine-driven flight, swept cover/player collision, REST/RESET, defeat and return to Tiling. The first phase-test failure was a test fixture: the elevated observer body still occupied the projectile path. Returning it to arrival and waiting for physics synchronization corrected the probe; the ball had correctly collided with it.

All standalone checks exit 0; existing ObjectDB cleanup warnings remain. The real museum-entry probe passes 8/8 and exits 0, but Flow_Field's older `algorithms/steering/noc_ch05/noc_5_04_flow_field_vr.gd` emits freed-label/vehicle errors during probe cleanup. This is recorded as an open museum cleanup issue, not a clean teardown. Physical headset comfort, difficulty and performance are untested.

## Claude handoff

Claude's review and probe files are untouched. Independently review whether all matching tiles are perceived as one event, whether the arrows predict the centre-column flight, and whether the one-turn cue permits a readable dodge. Update the older route probe's intentional three-head/five-stage assumptions before rerunning it. Source hashes are in [change-evidence.json](change-evidence.json). Preserve Palle's editable changes in SCAFFOLD.json. Forces is next; do not silently add acceleration to this field sampler.
