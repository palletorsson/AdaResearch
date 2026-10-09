# Eye shot — Noise_Perlin_Simplex

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **5 overlaps, 1 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] simplex_noise              <-> perlin_noise               gap -5.00m (centers 5.00m)`
- `[OVERLAP] simplex_noise              <-> noise_terrain              gap -1.26m (centers 4.24m)`
- `[OVERLAP] simplex_noise              <-> dark_sphere                gap -0.42m (centers 5.00m)`
- `[OVERLAP] perlin_noise               <-> noise_terrain              gap -1.89m (centers 3.61m)`
- `[OVERLAP] perlin_noise               <-> dark_sphere                gap -0.95m (centers 4.47m)`
- `[tight  ] noise_terrain              <-> dark_sphere                gap +0.08m (centers 1.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=-0.053
      walkability improved: 0/1  mean Δ=-0.037

no sibling kept — the move did not beat the ride (overlaps 5→5, tight 1→1). Note-only.

## The voice (qfep)
6 of 6 cast members carry a theory-claim; 0 mute.
- **configurable_portal** — The door as parameter: size, rotation, destination all data. Passage itself made configurable — the humblest a
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **noise_terrain** — Noise cashed out as landscape: height mapped from the field, terrain without a designer. The first honest answ
- **perlin_noise** — Perlin's gift to graphics: gradients on a lattice, interpolated smoothly — randomness that flows instead of st

## The text vs the space
walked.md exists — the writing names 6/6 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: dark_sphere, noise_terrain, perlin_noise, simplex_noise sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
