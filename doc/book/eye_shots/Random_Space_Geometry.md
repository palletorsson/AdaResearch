# Eye shot — Random_Space_Geometry

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **1 overlaps, 2 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] perlin_noise_bridge:0:-0.5 <-> env_one:0:4:0.5            gap +0.41m (centers 1.41m)`
- `[tight  ] env_one:0:4:0.5            <-> sculpt_one                 gap +0.96m (centers 3.61m)`
- `[OVERLAP] random_transformations_geometric:0:1:0.2 <-> sculpt_one                 gap -1.24m (centers 1.41m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=+0.000
      walkability improved: 1/1  mean Δ=+0.100

no sibling kept — the move did not beat the ride (overlaps 1→1, tight 2→2). Note-only.

## The voice (qfep)
6 of 6 cast members carry a theory-claim; 0 mute.
- **curl_noise_particles** — flow_speed — at 0.1 particles drift in wide lazy loops; at 0.5 they spiral tight; the range shows how the same
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **env_one** — A whole environment kitbashed by draw: parts picked, placed, and joined by chance. The room-scale claim of the
- **perlin_noise_bridge** — frequency — controls the scale of coherent features; low = rolling hills, high = jagged peaks Coherence is not

## The text vs the space
walked.md exists — the writing names 6/6 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: env_one, perlin_noise_bridge, random_transformations_geometric, sculpt_one sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
