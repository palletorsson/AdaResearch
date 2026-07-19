# Eye shot — Random_Gaussian

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **7 overlaps, 1 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] GaussianPaintSplatter:180:1.5 <-> random_bell_curve          gap -2.30m (centers 8.25m)`
- `[OVERLAP] GaussianBlurCircle:0:-0.5  <-> random_bell_curve          gap -4.47m (centers 6.08m)`
- `[OVERLAP] dark_sphere                <-> random_bell_curve          gap -5.47m (centers 5.00m)`
- `[OVERLAP] random_bell_curve          <-> distribution_comparator:0:-0.5 gap -4.15m (centers 6.40m)`
- `[OVERLAP] random_bell_curve          <-> gaussian_random            gap -6.55m (centers 4.00m)`
- `[OVERLAP] random_bell_curve          <-> distribution_sampler:180:0.5:1 gap -5.45m (centers 5.10m)`
- `[OVERLAP] random_bell_curve          <-> galton_board:180:1:4       gap -4.23m (centers 6.32m)`
- `[tight  ] gaussian_random            <-> distribution_sampler:180:0.5:1 gap +0.41m (centers 1.41m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=-0.031
      walkability improved: 1/1  mean Δ=+0.031

no sibling kept — the move did not beat the ride (overlaps 7→7, tight 1→1). Note-only.

## The voice (qfep)
9 of 9 cast members carry a theory-claim; 0 mute.
- **GaussianBlurCircle** — The bell curve applied to sight: a circle dissolving under gaussian blur, each pixel averaged with its neighbo
- **GaussianBlurShader** — max_blur_radius — controlled to 40 here vs 8 on CPU; GPU permits a wider kernel without lag The kernel is the 
- **GaussianPaintSplatter** — stddev — the standard deviation that controls splatter spread vs concentration A bell curve drawn in the air, 
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change

## The text vs the space
walked.md exists — the writing names 9/9 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: GaussianBlurCircle, GaussianPaintSplatter, dark_sphere, distribution_comparator, distribution_sampler, galton_board, gaussian_random, random_bell_curve sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
