# Eye shot — ForcesChaos

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **12 overlaps, 4 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] library_rack:0:0#collection:physics_simulation#layout:rack_layout.json <-> spring_system              gap -0.25m (centers 5.39m)`
- `[OVERLAP] three_body_problem         <-> spring_system              gap -2.63m (centers 3.00m)`
- `[tight  ] chaos_attractor            <-> spring_system              gap +0.58m (centers 6.08m)`
- `[OVERLAP] nbody_simulation           <-> spring_system              gap -4.04m (centers 1.41m)`
- `[tight  ] nbody_simulation           <-> forcedirected3d            gap +1.06m (centers 10.20m)`
- `[tight  ] spring_system              <-> dark_sphere                gap +0.10m (centers 5.66m)`
- `[tight  ] spring_system              <-> particle_systems           gap +0.27m (centers 11.40m)`
- `[OVERLAP] spring_system              <-> forcedirected3d            gap -4.90m (centers 9.06m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=-0.018
      walkability improved: 1/1  mean Δ=+0.010

no sibling kept — the move did not beat the ride (overlaps 12→12, tight 4→4). Note-only.

## The voice (qfep)
13 of 13 cast members carry a theory-claim; 0 mute.
- **catalyst_target** — Transformation here is discrete state change: intact, flashing, destroyed, respawned. Identity persists while 
- **chaos_attractor** — lambda_edge: strange attractors traced live — deterministic rules whose futures diverge from any measurable pr
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **example_2_8_two_body_attraction_vr** — gravitational_constant and initial tangential velocity — together they decide circular, elliptical, parabolic,

## The text vs the space
walked.md exists — the writing names 11/13 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: chaos_attractor, dark_sphere, forcedirected3d, library_rack, nbody_simulation, particle_systems, spring_system, three_body_problem sit in clearance violations — the text promises what the floor obstructs.
- space without text: example_2_8_two_body_attraction_vr, example_2_9_n_body_attraction_vr — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
