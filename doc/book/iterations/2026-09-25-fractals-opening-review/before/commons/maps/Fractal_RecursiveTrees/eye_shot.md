# Eye shot — Fractal_RecursiveTrees

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **3 overlaps, 8 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] inverted_tree_cloud        <-> recursive_tree:0:0:0.7     gap -3.66m (centers 4.12m)`
- `[OVERLAP] inverted_tree_cloud        <-> fractal_scene              gap -2.78m (centers 5.00m)`
- `[OVERLAP] inverted_tree_cloud        <-> dark_sphere                gap -1.30m (centers 6.40m)`
- `[tight  ] inverted_tree_cloud        <-> recursive_tree_2           gap +0.33m (centers 7.81m)`
- `[tight  ] fractal_scene              <-> dark_sphere                gap +0.49m (centers 1.41m)`
- `[tight  ] dark_sphere                <-> recursive_tree_2           gap +0.79m (centers 1.41m)`
- `[tight  ] small_subdivision_cube     <-> cube_desk                  gap +0.86m (centers 1.41m)`
- `[tight  ] recursive_tree_2           <-> living_paper:180#algorithm:mandelbrot gap +0.71m (centers 1.41m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=-0.004
      walkability improved: 0/1  mean Δ=-0.256

no sibling kept — the move did not beat the ride (overlaps 3→3, tight 8→8). Note-only.

## The voice (qfep)
10 of 10 cast members carry a theory-claim; 0 mute.
- **cube_desk** — drawer_rows * drawer_cols — the grid resolution of the drawer unit determines storage granularity A desk is a 
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **fractal_lsystem_tree** — The bridge to the next chapter grown early: a tree written as grammar, branches as rewrite rules. Standing amo
- **fractal_scene** — A composed fractal tableau — the chapter's specimens arranged as one scene, self-similarity as scenography. re

## The text vs the space
walked.md exists — the writing names 6/10 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: inverted_tree_cloud, living_paper, recursive_tree, recursive_tree_2 sit in clearance violations — the text promises what the floor obstructs.
- space without text: cube_desk, dark_sphere, fractal_scene, small_subdivision_cube — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
