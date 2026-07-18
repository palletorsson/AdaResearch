# Eye shot — Fractal_Synthesis

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **19 overlaps, 3 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] fractal_recursion_1        <-> koch_curve                 gap -18.81m (centers 2.00m)`
- `[OVERLAP] fractal_recursion_1        <-> cantor_set                 gap -0.96m (centers 4.00m)`
- `[OVERLAP] fractal_recursion_1        <-> recursive_tree             gap -1.72m (centers 6.71m)`
- `[OVERLAP] koch_curve                 <-> cantor_set                 gap -22.84m (centers 2.00m)`
- `[OVERLAP] koch_curve                 <-> strange_attractors         gap -14.39m (centers 6.32m)`
- `[OVERLAP] koch_curve                 <-> dark_sphere                gap -13.55m (centers 7.21m)`
- `[OVERLAP] koch_curve                 <-> recursive_tree             gap -22.22m (centers 6.08m)`
- `[OVERLAP] koch_curve                 <-> fibonacci_sequences        gap -8.32m (centers 12.53m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.132
      walkability improved: 0/1  mean Δ=-0.165

no sibling kept — the move did not beat the ride (overlaps 19→19, tight 3→3). Note-only.

## The voice (qfep)
7 of 10 cast members carry a theory-claim; 3 mute.
- **cantor_set** — max_iterations — at 5 iterations, each bar is 1/243 of the original, yet the set is still uncountably infinite
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **fractal_clouds** — density_threshold — too high makes the sky clear, too low makes the world grey fog; at 0.45 you get discrete c
- **recursive_tree** — randomness_amount (0.15) — the variance injected into every angle and length, making each tree unique A tree i
- mute: fibonacci_sequences, fractal_recursion_1, koch_curve

## The text vs the space
walked.md exists — the writing names 7/10 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: cantor_set, fibonacci_sequences, fractal_recursion_1, koch_curve, recursive_tree sit in clearance violations — the text promises what the floor obstructs.
- space without text: dark_sphere, fractal_clouds, strange_attractors — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
