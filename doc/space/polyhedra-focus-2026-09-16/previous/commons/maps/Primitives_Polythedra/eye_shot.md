# Eye shot — Primitives_Polythedra

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 11 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] grab_trihedron:90:0:0.1    <-> path_game_controller       gap +1.00m (centers 2.00m)`
- `[tight  ] path_game_controller       <-> path_watchdog              gap +0.00m (centers 1.00m)`
- `[tight  ] cube_scene:0:0:0.90#group:fillhole <-> becoming_catalyst          gap +0.45m (centers 1.00m)`
- `[tight  ] cube_scene:0:0:0.90#group:fillhole <-> interactive_point_origin_force:0:1#mode:transformation gap +1.00m (centers 2.00m)`
- `[tight  ] cube_scene:0:0:0.90#group:fillhole <-> pyramid_edit:0:0:0.4       gap +0.00m (centers 1.00m)`
- `[tight  ] cube_scene:0:0:0.90#group:fillhole <-> tentacle_placer:0:0#place_positions:-1.5,0,0;0,0,0;1.5,0,0#sky_height:7.0#travel_speed:0.6#dwell_seconds:1.5#pyramid_size:1.0#pyramid_height:-0.5#debug_log:true gap +0.41m (centers 1.41m)`
- `[tight  ] becoming_catalyst          <-> interactive_point_origin_force:0:1#mode:transformation gap +0.45m (centers 1.00m)`
- `[tight  ] becoming_catalyst          <-> pyramid_edit:0:0:0.4       gap +0.87m (centers 1.41m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.001
      walkability improved: 1/1  mean Δ=+0.009

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 11→11). Note-only.

## The voice (qfep)
9 of 9 cast members carry a theory-claim; 0 mute.
- **becoming_catalyst** — Embodies the full QFEP trajectory: from order (primitives) through entropy (randomness) to the edge of chaos (
- **cube_scene** — Transformation changes S while the cube serves as the invariant reference body. Because the base form is so le
- **grab_trihedron** — The wedge as 3D primitive — 4 vertices, three triangular faces on a quad base. The catalyst bracelet's walkabl
- **interactive_point_origin_force** — F_force: the origin point that becomes a force field in the hand — picked up, its surface morphs to a pulsing 

## The text vs the space
walked.md exists — the writing names 7/9 of the cast; dwells declared for 1.
- **the writing's subjects are blocked in space**: becoming_catalyst, cube_scene, grab_trihedron, interactive_point_origin_force, path_game_controller, pyramid_edit, tentacle_placer sit in clearance violations — the text promises what the floor obstructs.
- space without text: lab_room, path_watchdog — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
