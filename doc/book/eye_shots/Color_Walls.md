# Eye shot — Color_Walls

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 3 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] subpixel_display:0:-0.5    <-> color_constellation_office:0:-1:2 gap +0.00m (centers 1.00m)`
- `[tight  ] subpixel_display:0:-0.5    <-> gradient_interpolator:0:-0.5 gap +1.00m (centers 2.00m)`
- `[tight  ] rainbow_hallway:180:1.0    <-> dark_sphere                gap +0.08m (centers 1.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.055
      walkability improved: 0/1  mean Δ=-0.025

sibling **Trial_eye_Color_Walls** kept: overlaps 0→0, tight 3→0, pathfinder OK.

## The voice (qfep)
6 of 7 cast members carry a theory-claim; 1 mute.
- **color_constellation_office** — transparency — controls how much light passes through each wall; at 0.4 the mixing is visible but walls remain
- **color_space_navigator** — cube_size (0.7m default) — scales the entire color space; sample_count controls point density; show_hsl_cylind
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **gradient_interpolator** — interpolation mode — RGB walks a straight line in a cube, HSV walks an arc on a cylinder Interpolation is not 
- mute: rainbow_hallway

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The floor was fighting the walk — bodies inside each other's clearance. The mover found a better seating; the ride confirms it in text. The voice column above says what the room is FOR; the next writing pass should say it in the walked page.
