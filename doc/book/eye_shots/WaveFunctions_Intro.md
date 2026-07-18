# Eye shot — WaveFunctions_Intro

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 22 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] rotatescalecubes:0:15      <-> pickup_cube_static         gap +0.25m (centers 1.00m)`
- `[tight  ] cube_scene:0:0:0.2         <-> transformation_cube:0:0:0.2 gap +0.00m (centers 1.00m)`
- `[tight  ] cube_scene:0:0:0.2         <-> y_oscillation_cube:180:0.5 gap +0.41m (centers 1.41m)`
- `[tight  ] transformation_cube:0:0:0.2 <-> rotating_cube:0:0:0.2      gap +1.00m (centers 2.00m)`
- `[tight  ] transformation_cube:0:0:0.2 <-> y_oscillation_cube:180:0.5 gap +0.00m (centers 1.00m)`
- `[tight  ] rotating_cube:0:0:0.2      <-> rotating_cube_demo:180:0.5 gap +0.00m (centers 1.00m)`
- `[tight  ] y_oscillation_cube:180:0.5 <-> rotating_cube_demo:180:0.5 gap +1.00m (centers 2.00m)`
- `[tight  ] rotating_cube_demo:180:0.5 <-> science_screen:180:1.5#mode:wave gap +1.00m (centers 2.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.003
      walkability improved: 0/1  mean Δ=-0.208

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 22→22). Note-only.

## The voice (qfep)
16 of 16 cast members carry a theory-claim; 0 mute.
- **SphericalHarmonics** — Spherical harmonics are the F-basis for any function on a sphere — the most compressed representation of spher
- **control_pendulum** — pendulum_length — determines the natural frequency via sqrt(g/L) A pendulum is gravity's metronome — length al
- **cube_scene** — Transformation changes S while the cube serves as the invariant reference body. Because the base form is so le
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change

## The text vs the space
walked.md exists — the writing names 9/16 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: cube_scene, rotatescalecubes, rotating_cube, science_screen sit in clearance violations — the text promises what the floor obstructs.
- space without text: pick_up_cube, pickup_cube_rotating, pickup_cube_static, pickup_cube_transforming, rotating_cube_demo, transformation_cube — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
