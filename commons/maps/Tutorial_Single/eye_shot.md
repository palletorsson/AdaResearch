# Eye shot — Tutorial_Single

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 4 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] science_screen:180:1.5#mode:point <-> xyz_coordinates            gap +1.13m (centers 2.24m)`
- `[tight  ] pick_up_cube               <-> dark_sphere                gap +0.74m (centers 1.41m)`
- `[tight  ] pick_up_cube               <-> xyz_coordinates            gap +0.55m (centers 1.41m)`
- `[tight  ] dark_sphere                <-> xyz_coordinates            gap +0.97m (centers 2.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=-0.071
      walkability improved: 1/1  mean Δ=+0.067

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 4→4). Note-only.

## The voice (qfep)
3 of 4 cast members carry a theory-claim; 1 mute.
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **pick_up_cube** — Pure S as carried displacement: the cube stays itself while its coordinates change. The artifact isolates tran
- **science_screen** — Transformation here is projection: a 3D state is re-expressed in 2D while preserving selected structural relat
- mute: xyz_coordinates

## The text vs the space
walked.md exists — the writing names 0/4 of the cast; dwells declared for 0.
- space without text: dark_sphere, pick_up_cube, science_screen, xyz_coordinates — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
