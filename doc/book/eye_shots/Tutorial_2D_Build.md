# Eye shot — Tutorial_2D_Build

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 3 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] pick_up_cube               <-> row_3_x                    gap +0.24m (centers 2.24m)`
- `[tight  ] row_3_x                    <-> column_3_z                 gap +0.97m (centers 4.47m)`
- `[tight  ] dark_sphere                <-> grid_2d_4x4                gap +1.08m (centers 4.12m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.035
      walkability improved: 1/1  mean Δ=+0.031

no sibling kept — the move did not beat the ride (overlaps 0→4, tight 3→0). Note-only.

## The voice (qfep)
6 of 8 cast members carry a theory-claim; 2 mute.
- **column_3_z** — spacing — at 1.0 the cubes are adjacent and the array feels compact; at 2.0 they feel like separate objects; t
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **grid_2d_4x4** — show_binary_table — when true, a BinaryTableDisplay appears beside the grid showing the same 4×4 structure as 
- **pick_up_cube** — Pure S as carried displacement: the cube stays itself while its coordinates change. The artifact isolates tran
- mute: gridagent, xyz_coordinates

## The text vs the space
walked.md exists — the writing names 1/8 of the cast; dwells declared for 0.
- space without text: column_3_z, dark_sphere, grid_2d_4x4, gridagent, pick_up_cube, pulsar_visualizer — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
