# Eye shot — Noise_Voxel

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **3 overlaps, 0 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] perlin_terrain_sculptor:180:0.5:1#mount:shelf <-> voxelnoise                 gap -15.50m (centers 1.00m)`
- `[OVERLAP] science_screen:180:1.5#mode:field <-> voxelnoise                 gap -6.45m (centers 10.05m)`
- `[OVERLAP] voxelnoise                 <-> dark_sphere                gap -10.76m (centers 5.66m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.079
      walkability improved: 1/1  mean Δ=+0.324

no sibling kept — the move did not beat the ride (overlaps 3→3, tight 0→1). Note-only.

## The voice (qfep)
3 of 4 cast members carry a theory-claim; 1 mute.
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **science_screen** — Transformation here is projection: a 3D state is re-expressed in 2D while preserving selected structural relat
- **voxelnoise** — iso_level — the decision boundary between solid and void; small changes cause avalanches of appearing/disappea
- mute: shelf

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
