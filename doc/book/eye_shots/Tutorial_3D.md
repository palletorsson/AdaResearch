# Eye shot — Tutorial_3D

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **1 overlaps, 5 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] grid_3d_4x4x4              <-> dark_sphere                gap -0.76m (centers 1.41m)`
- `[tight  ] grid_3d_4x4x4              <-> bar_array:0:-0.5           gap +0.58m (centers 2.83m)`
- `[tight  ] dark_sphere                <-> bar_array:0:-0.5           gap +0.49m (centers 1.41m)`
- `[tight  ] bar_array:0:-0.5           <-> grid3d:0:-0.5              gap +0.00m (centers 1.00m)`
- `[tight  ] bar_array:0:-0.5           <-> bar_array_bubble_sort:0:-0.5 gap +1.00m (centers 2.00m)`
- `[tight  ] grid3d:0:-0.5              <-> bar_array_bubble_sort:0:-0.5 gap +0.00m (centers 1.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.047
      walkability improved: 0/1  mean Δ=-0.125

no sibling kept — the move did not beat the ride (overlaps 1→1, tight 5→5). Note-only.

## The voice (qfep)
3 of 6 cast members carry a theory-claim; 3 mute.
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **grid_3d_4x4x4** — spacing — at 1.0m the cubes form a compact volume you can reach into; increasing spacing makes the array a spa
- **sorting_algorithm_race** — step_speed — controls ticks per second; at low speed you see every comparison, at high speed you see the emerg
- mute: bar_array, bar_array_bubble_sort, grid3d

## The text vs the space
walked.md exists — the writing names 1/6 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: dark_sphere sit in clearance violations — the text promises what the floor obstructs.
- space without text: bar_array, bar_array_bubble_sort, grid3d, grid_3d_4x4x4, sorting_algorithm_race — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
