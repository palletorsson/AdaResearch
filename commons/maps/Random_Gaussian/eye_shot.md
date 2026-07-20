# Eye shot — Random_Gaussian

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **8 overlaps, 5 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] gaussian_random            <-> GaussianBlurShader:180:1   gap +0.00m (centers 1.00m)`
- `[OVERLAP] gaussian_random            <-> random_bell_curve          gap -2.49m (centers 8.06m)`
- `[tight  ] GaussianBlurShader:180:1   <-> dark_sphere                gap +1.08m (centers 2.00m)`
- `[OVERLAP] GaussianBlurShader:180:1   <-> random_bell_curve          gap -2.30m (centers 8.25m)`
- `[OVERLAP] dark_sphere                <-> random_bell_curve          gap -4.15m (centers 6.32m)`
- `[tight  ] GaussianPaintSplatter:180:1.5 <-> galton_board:180:1:4       gap +1.00m (centers 2.00m)`
- `[OVERLAP] GaussianPaintSplatter:180:1.5 <-> random_bell_curve          gap -4.15m (centers 6.40m)`
- `[OVERLAP] galton_board:180:1:4       <-> random_bell_curve          gap -5.16m (centers 5.39m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.038
      walkability improved: 1/1  mean Δ=+0.003

sibling **Trial_eye_Random_Gaussian** kept: overlaps 8→6, tight 5→4, pathfinder OK.

## The voice (qfep)
9 of 9 cast members carry a theory-claim; 0 mute.
- **GaussianBlurCircle** — The bell curve applied to sight: a circle dissolving under gaussian blur, each pixel averaged with its neighbo
- **GaussianBlurShader** — max_blur_radius — controlled to 40 here vs 8 on CPU; GPU permits a wider kernel without lag The kernel is the 
- **GaussianPaintSplatter** — stddev — the standard deviation that controls splatter spread vs concentration A bell curve drawn in the air, 
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change

## The text vs the space
walked.md exists — the writing names 9/9 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: GaussianBlurShader, GaussianPaintSplatter, dark_sphere, galton_board, gaussian_random, random_bell_curve sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The floor was fighting the walk — bodies inside each other's clearance. The mover found a better seating; the ride confirms it in text. The voice column above says what the room is FOR; the next writing pass should say it in the walked page.
