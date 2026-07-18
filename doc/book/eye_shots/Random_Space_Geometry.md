# Eye shot — Random_Space_Geometry

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **2 overlaps, 1 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] dark_sphere                <-> env_one:0:4:0.5            gap +0.08m (centers 1.00m)`
- `[OVERLAP] curl_noise_particles:0:-0.5 <-> sculpt_one                 gap -0.65m (centers 2.00m)`
- `[OVERLAP] sculpt_one                 <-> perlin_noise_bridge:0:-0.5 gap -1.65m (centers 1.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.012
      walkability improved: 1/1  mean Δ=+0.157

sibling **Trial_eye_Random_Space_Geometry** kept: overlaps 2→1, tight 1→2, pathfinder OK.

## The voice (qfep)
3 of 6 cast members carry a theory-claim; 3 mute.
- **curl_noise_particles** — flow_speed — at 0.1 particles drift in wide lazy loops; at 0.5 they spiral tight; the range shows how the same
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **perlin_noise_bridge** — frequency — controls the scale of coherent features; low = rolling hills, high = jagged peaks Coherence is not
- mute: env_one, random_transformations_geometric, sculpt_one

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The floor was fighting the walk — bodies inside each other's clearance. The mover found a better seating; the ride confirms it in text. The voice column above says what the room is FOR; the next writing pass should say it in the walked page.
