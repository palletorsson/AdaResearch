# Eye shot — Random_Rotate_Random_XYZ

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **3 overlaps, 2 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] hardware_entropy_decay     <-> random_decay_multimesh     gap +0.55m (centers 11.90m)`
- `[OVERLAP] Random_Rotate_Random_XYZ   <-> random_decay_multimesh     gap -5.44m (centers 3.30m)`
- `[tight  ] Random_Rotate_Random_XYZ   <-> RotateGridCubes:0:-0.5     gap +0.10m (centers 1.10m)`
- `[OVERLAP] dark_sphere                <-> random_decay_multimesh     gap -7.56m (centers 1.10m)`
- `[OVERLAP] random_decay_multimesh     <-> RotateGridCubes:0:-0.5     gap -5.26m (centers 3.48m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=+0.000
      walkability improved: 1/1  mean Δ=+0.146

no sibling kept — the move did not beat the ride (overlaps 3→3, tight 2→2). Note-only.

## The voice (qfep)
5 of 5 cast members carry a theory-claim; 0 mute.
- **Random_Rotate_Random_XYZ** — The room's namesake engine: grid cubes spun by three independent draws, one per axis. Orientation surrendered 
- **RotateGridCubes** — PATTERN — the ordered list of (row_count, axis) bands that defines the cycle length The grid is a stack of cho
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **hardware_entropy_decay** — Entropy from embodiment — the observer's physical presence is the source of randomness that degrades order. ve

## The text vs the space
walked.md exists — the writing names 5/5 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: Random_Rotate_Random_XYZ, RotateGridCubes, dark_sphere, hardware_entropy_decay, random_decay_multimesh sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
