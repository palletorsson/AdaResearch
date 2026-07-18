# Eye shot — Trans_Rotation

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 4 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] dark_sphere                <-> spin:180:1                 gap +0.08m (centers 1.00m)`
- `[tight  ] dark_sphere                <-> spin:0:1                   gap +1.08m (centers 2.00m)`
- `[tight  ] spin:180:1                 <-> spin:0:1                   gap +0.00m (centers 1.00m)`
- `[tight  ] pick_up_cube:0:1           <-> pickup_gate#pickups:7      gap +0.00m (centers 1.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=-0.028
      walkability improved: 0/1  mean Δ=-0.083

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 4→4). Note-only.

## The voice (qfep)
6 of 6 cast members carry a theory-claim; 0 mute.
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **pick_up_cube** — Pure S as carried displacement: the cube stays itself while its coordinates change. The artifact isolates tran
- **pickup_gate** — Transformation here is thresholded state change. Repeated object translations alter the count until the gate p
- **rotate_grid_cubes** — Transformation modifies orientation across S while the grid itself remains stable. Patterned rotation makes st

## The text vs the space
walked.md exists — the writing names 6/6 of the cast; dwells declared for 2.
- **the writing's subjects are blocked in space**: dark_sphere, pick_up_cube, pickup_gate, spin sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
