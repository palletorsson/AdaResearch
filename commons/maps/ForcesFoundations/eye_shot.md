# Eye shot — ForcesFoundations

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 7 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] friction_ramp:0:0:1        <-> newtons_laws:0:0:1         gap +0.41m (centers 1.41m)`
- `[tight  ] proximity_spawner:0:0:1#type:kresling_spire <-> example_2_3_gravity_scaled_by_mass_vr:0:0:1 gap +0.00m (centers 1.00m)`
- `[tight  ] proximity_spawner:0:0:1#type:kresling_spire <-> example_2_5_fluid_resistance_vr:0:0:1 gap +0.41m (centers 1.41m)`
- `[tight  ] newtons_laws:0:0:1         <-> VectorBasics:0:0:1         gap +1.00m (centers 2.00m)`
- `[tight  ] VectorBasics:0:0:1         <-> basis_vectors_rig:180:-0.500:1 gap +0.00m (centers 1.00m)`
- `[tight  ] example_2_3_gravity_scaled_by_mass_vr:0:0:1 <-> example_2_5_fluid_resistance_vr:0:0:1 gap +0.00m (centers 1.00m)`
- `[tight  ] example_2_5_fluid_resistance_vr:0:0:1 <-> example_2_1_forces_vr:0:0:1 gap +1.00m (centers 2.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.008
      walkability improved: 0/1  mean Δ=-0.206

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 7→7). Note-only.

## The voice (qfep)
10 of 10 cast members carry a theory-claim; 0 mute.
- **VectorBasics** — Pure F-decomposition — breaking a single quantity into orthogonal components. The vector IS its components, an
- **basis_vectors_rig** — Basis as frame of reference - the coordinate system from which we measure all positions target_point — the Vec
- **bouncing_ball** — Pure F — gravity pulls, floor reflects. The simplest possible physics: one force, one constraint. The bounce c
- **catalyst_target** — Transformation here is discrete state change: intact, flashing, destroyed, respawned. Identity persists while 

## The text vs the space
walked.md exists — the writing names 7/10 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: VectorBasics, basis_vectors_rig, friction_ramp, newtons_laws, proximity_spawner sit in clearance violations — the text promises what the floor obstructs.
- space without text: example_2_1_forces_vr, example_2_3_gravity_scaled_by_mass_vr, example_2_5_fluid_resistance_vr — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
