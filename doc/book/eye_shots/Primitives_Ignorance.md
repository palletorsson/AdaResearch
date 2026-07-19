# Eye shot — Primitives_Ignorance

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 52 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] dark_sphere:0:-0.5         <-> cube_scene:0:-0.5          gap +0.00m (centers 1.00m)`
- `[tight  ] dark_sphere:0:-0.5         <-> sphere:0:-0.5              gap +1.00m (centers 2.00m)`
- `[tight  ] cube_scene:0:-0.5          <-> sphere:0:-0.5              gap +0.00m (centers 1.00m)`
- `[tight  ] cube_scene:0:-0.5          <-> platonic_grabbables        gap +0.76m (centers 4.47m)`
- `[tight  ] sphere:0:-0.5              <-> platonic_grabbables        gap +0.41m (centers 4.12m)`
- `[tight  ] hole_with_cones:30:-0.5    <-> sphere_high                gap +1.00m (centers 2.00m)`
- `[tight  ] hole_with_cones:30:-0.5    <-> righttriangle              gap +1.00m (centers 2.00m)`
- `[tight  ] sphere_high                <-> sphere_high                gap +1.00m (centers 2.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.111
      walkability improved: 0/1  mean Δ=-0.013

no sibling kept — the move did not beat the ride (overlaps 0→3, tight 52→23). Note-only.

## The voice (qfep)
23 of 23 cast members carry a theory-claim; 0 mute.
- **capsule** — A cylinder that rounded its ends — the primitive of the *organic*, the shape a body or a pill takes when it re
- **capsule_radials_rings** — The capsule with its resolution exposed — radial segments and rings you can set. The reminder that every smoot
- **cube_scene** — Transformation changes S while the cube serves as the invariant reference body. Because the base form is so le
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change

## The text vs the space
walked.md exists — the writing names 14/23 of the cast; dwells declared for 1.
- **the writing's subjects are blocked in space**: hole_with_cones, platonic_grabbables, sphere, sphere_high sit in clearance violations — the text promises what the floor obstructs.
- space without text: cube_scene, dark_sphere, diamonds, floating_sphere_field, plus, prism_block — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
