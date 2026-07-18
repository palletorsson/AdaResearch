# Eye shot — ForcesFoundations

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 4 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] VectorBasics:0:0:1         <-> friction_ramp:0:0:1        gap +0.00m (centers 1.00m)`
- `[tight  ] example_2_1_forces_vr:0:0:1 <-> catalyst_target:0:0:1#shape:cube gap +1.00m (centers 2.00m)`
- `[tight  ] catalyst_target:0:0:1#shape:cube <-> example_2_3_gravity_scaled_by_mass_vr:0:0:1 gap +0.41m (centers 1.41m)`
- `[tight  ] catalyst_target:0:0:1#shape:cube#hits:3 <-> catalyst_target:0:0:1#shape:cube gap +1.00m (centers 2.00m)`

## The move
        r = apply_to_map(m, engine=args.engine, in_place=args.in_place,
      File "C:\Users\palle\Documents\GitHub\AdaResearch_46\tools\place.py", line 222, in apply_to_map
        new_inter[r][c] = name_to_token.get(p.artifact.lookup_name,
    TypeError: list indices must be integers or slices, not float

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 4→4). Note-only.

## The voice (qfep)
10 of 10 cast members carry a theory-claim; 0 mute.
- **VectorBasics** — Pure F-decomposition — breaking a single quantity into orthogonal components. The vector IS its components, an
- **basis_vectors_rig** — Basis as frame of reference - the coordinate system from which we measure all positions target_point — the Vec
- **bouncing_ball** — Pure F — gravity pulls, floor reflects. The simplest possible physics: one force, one constraint. The bounce c
- **catalyst_target** — Transformation here is discrete state change: intact, flashing, destroyed, respawned. Identity persists while 

## The text vs the space
walked.md exists — the writing names 7/10 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: VectorBasics, catalyst_target, friction_ramp sit in clearance violations — the text promises what the floor obstructs.
- space without text: example_2_1_forces_vr, example_2_3_gravity_scaled_by_mass_vr, example_2_5_fluid_resistance_vr — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
