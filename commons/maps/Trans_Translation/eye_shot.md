# Eye shot — Trans_Translation

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 6 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] z_translation_cube:180:1.5:2 <-> pick_up_cube:0:1           gap +0.41m (centers 1.41m)`
- `[tight  ] z_translation_cube:180:1.5:2 <-> science_screen:180:1.5#mode:point gap +1.00m (centers 2.00m)`
- `[tight  ] pick_up_cube:0:1           <-> science_screen:180:1.5#mode:point gap +0.41m (centers 1.41m)`
- `[tight  ] y_translation_cube:180:1.5:2 <-> pick_up_cube:0:1           gap +0.41m (centers 1.41m)`
- `[tight  ] pick_up_cube:0:1           <-> pick_up_cube:0:1           gap +1.00m (centers 2.00m)`
- `[tight  ] pick_up_cube:0:1           <-> pick_up_cube               gap +0.25m (centers 1.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=-0.054
      walkability improved: 0/1  mean Δ=-0.022

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 6→6). Note-only.

## The voice (qfep)
8 of 8 cast members carry a theory-claim; 0 mute.
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **pick_up_cube** — Pure S as carried displacement: the cube stays itself while its coordinates change. The artifact isolates tran
- **pickup_gate** — Transformation here is thresholded state change. Repeated object translations alter the count until the gate p
- **player_trace** — Transformation is recorded here as a trajectory through S over time. The body changes position continuously, w

## The text vs the space
walked.md exists — the writing names 8/8 of the cast; dwells declared for 2.
- **the writing's subjects are blocked in space**: pick_up_cube, science_screen, y_translation_cube, z_translation_cube sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
