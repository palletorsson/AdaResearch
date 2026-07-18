# Eye shot — ForcesArena

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **6 overlaps, 18 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] hits_reset_display         <-> health_display             gap +1.00m (centers 2.00m)`
- `[tight  ] queer_cylinder_target:-90:2 <-> proximity_spawner#type:miura_crawler gap +0.41m (centers 1.41m)`
- `[tight  ] queer_cylinder_target:-90:2 <-> vector_drone               gap +0.74m (centers 2.00m)`
- `[tight  ] proximity_spawner#type:miura_crawler <-> vector_drone               gap +0.15m (centers 1.41m)`
- `[tight  ] human_catapult             <-> VectorThrowing             gap +1.01m (centers 3.16m)`
- `[OVERLAP] destructibles_test_scene   <-> VectorThrowing             gap -0.46m (centers 5.00m)`
- `[OVERLAP] destructibles_test_scene   <-> catalyst_target#shape:cube gap -2.07m (centers 2.24m)`
- `[tight  ] destructibles_test_scene   <-> catalyst_target#shape:cube gap +1.08m (centers 5.39m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=-0.041
      walkability improved: 0/1  mean Δ=-0.233

no sibling kept — the move did not beat the ride (overlaps 6→6, tight 18→18). Note-only.

## The voice (qfep)
14 of 20 cast members carry a theory-claim; 6 mute.
- **VectorAddition** — F-composition — two deterministic forces combine into one deterministic result. Superposition is linearity mad
- **VectorBasics** — Pure F-decomposition — breaking a single quantity into orthogonal components. The vector IS its components, an
- **VectorCrossProduct** — F-perpendicularity — the cross product extracts the component of interaction that is orthogonal to both inputs
- **VectorSubtraction** — negative_b — the negated vector rendered in parallel shows why a-b ≠ b-a; switching which is negated flips the
- mute: grab_sphere_point, health_display, hits_reset_display, proximity_spawner, queer_cylinder_target, throw_ball

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
