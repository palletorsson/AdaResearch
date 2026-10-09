# Eye shot — Color_Nails

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 6 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] science_screen:180:1.5#mode:field <-> colorballs                 gap +1.00m (centers 2.00m)`
- `[tight  ] colorballs                 <-> hand_model:90:-1:3         gap +0.00m (centers 1.00m)`
- `[tight  ] hand_model:90:-1:3         <-> brick_wall_factory:90      gap +0.41m (centers 1.41m)`
- `[tight  ] nail_color_controller:180  <-> hand_color_controller:180  gap +0.00m (centers 1.00m)`
- `[tight  ] nail_color_controller:180  <-> dark_sphere                gap +0.08m (centers 1.00m)`
- `[tight  ] hand_color_controller:180  <-> dark_sphere                gap +0.49m (centers 1.41m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=-0.001
      walkability improved: 1/1  mean Δ=+0.029

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 6→6). Note-only.

## The voice (qfep)
7 of 7 cast members carry a theory-claim; 0 mute.
- **brick_wall_factory** — palette — selects from 20 named palettes (starry_night to industrial_brutalism), redefining the wall's emotion
- **colorballs** — current_palette_index — switches the entire chromatic vocabulary; same physics, different visual language a co
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **hand_color_controller** — relation: the nails' sibling mapper — the same live adjustment addressed to the whole hand; identity's palette

## The text vs the space
walked.md exists — the writing names 7/7 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: brick_wall_factory, colorballs, dark_sphere, hand_color_controller, hand_model, nail_color_controller, science_screen sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
