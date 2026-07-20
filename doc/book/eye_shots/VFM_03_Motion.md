# Eye shot — VFM_03_Motion

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **14 overlaps, 32 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] bouncing_ball              <-> example_3_3_pointing_in_the_direction_of_motion_vr gap -1.27m (centers 3.16m)`
- `[OVERLAP] bouncing_ball              <-> example_3_2_forces_with_arbitrary_angular_motion_vr gap -0.46m (centers 4.12m)`
- `[tight  ] bouncing_ball              <-> flocking_controls          gap +0.56m (centers 5.10m)`
- `[OVERLAP] bouncing_ball              <-> exercise_1_5_solution_accelerate_and_decelerate_vr gap -1.99m (centers 2.24m)`
- `[OVERLAP] bouncing_ball              <-> VectorForces               gap -1.17m (centers 3.61m)`
- `[tight  ] bouncing_ball              <-> ForceMagnitudeDemo         gap +0.01m (centers 4.47m)`
- `[tight  ] bouncing_ball              <-> VectorMotion               gap +0.88m (centers 5.39m)`
- `[OVERLAP] bouncing_ball              <-> combined_forces_demo       gap -1.21m (centers 3.16m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.111
      walkability improved: 0/1  mean Δ=-0.039

sibling **Trial_eye_VFM_03_Motion** kept: overlaps 14→2, tight 32→5, pathfinder OK.

## The voice (qfep)
15 of 15 cast members carry a theory-claim; 0 mute.
- **ForceMagnitudeDemo** — Classical F — force as deterministic law. Drag the arrow, the ball obeys. No randomness, no emergence. Pure Ne
- **VectorForces** — DRAG_COEFFICIENT (0.8) — too high and the ball stops immediately; zero and it goes parabolic; the visible drag
- **VectorMotion** — acceleration — it is the only thing directly driven; velocity is its running sum and position is velocity's su
- **bouncing_ball** — Pure F — gravity pulls, floor reflects. The simplest possible physics: one force, one constraint. The bounce c

## The text vs the space
walked.md exists — the writing names 10/15 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: ForceMagnitudeDemo, VectorForces, VectorMotion, bouncing_ball, combined_forces_demo, flocking_controls sit in clearance violations — the text promises what the floor obstructs.
- space without text: example_2_5_fluid_resistance_vr, example_3_2_forces_with_arbitrary_angular_motion_vr, example_3_3_pointing_in_the_direction_of_motion_vr, exercise_1_3_solution_3_d_bouncing_ball_vr, exercise_1_5_solution_accelerate_and_decelerate_vr — standing in the room, absent from the walk.

## The heuristic understanding
The floor was fighting the walk — bodies inside each other's clearance. The mover found a better seating; the ride confirms it in text. The voice column above says what the room is FOR; the next writing pass should say it in the walked page.
