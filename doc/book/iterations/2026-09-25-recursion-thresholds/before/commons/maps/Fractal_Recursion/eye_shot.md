# Eye shot — Fractal_Recursion

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **2 overlaps, 11 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] fractal_recursion_2:-90:2  <-> recursive_table:0:-0.5:0.2 gap +1.00m (centers 2.00m)`
- `[tight  ] fractal_recursion_2:-90:2  <-> science_screen:180:1.5#mode:bars gap +0.41m (centers 1.41m)`
- `[tight  ] fractal_recursion_2:-90:2  <-> fibonacci_pagoda           gap +0.73m (centers 3.16m)`
- `[tight  ] fractal_recursion_2:-90:2  <-> example_8_3_recursion_circles_vr gap +1.11m (centers 3.61m)`
- `[tight  ] recursive_table:0:-0.5:0.2 <-> example_8_3_recursion_circles_vr gap +0.50m (centers 3.00m)`
- `[OVERLAP] science_screen:180:1.5#mode:bars <-> fibonacci_pagoda           gap -0.44m (centers 2.00m)`
- `[tight  ] science_screen:180:1.5#mode:bars <-> example_8_3_recursion_circles_vr gap +1.11m (centers 3.61m)`
- `[OVERLAP] fibonacci_pagoda           <-> example_8_3_recursion_circles_vr gap -0.94m (centers 3.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=+0.000
      walkability improved: 0/1  mean Δ=-0.009

no sibling kept — the move did not beat the ride (overlaps 2→2, tight 11→11). Note-only.

## The voice (qfep)
9 of 9 cast members carry a theory-claim; 0 mute.
- **cube_staircase** — step_count — determines granularity of the subdivision, how many slices the cube yields A staircase is a cube 
- **cube_subdivision** — random_corner — when true, every subdivision picks a different child, creating unpredictable growth; when fals
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **example_8_3_recursion_circles_vr** — max_depth — at 3 it's a simple pattern, at 5 the circles overlap and interfere, creating moire-like density Re

## The text vs the space
walked.md exists — the writing names 5/9 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: fibonacci_pagoda, recursive_table sit in clearance violations — the text promises what the floor obstructs.
- space without text: dark_sphere, example_8_3_recursion_circles_vr, fractal_recursion_2, science_screen — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
