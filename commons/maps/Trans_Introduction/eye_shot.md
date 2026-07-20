# Eye shot — Trans_Introduction

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 6 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] homogeneous_coordinates:0:-0.5 <-> rotation_gimbal:0:-0.5     gap +0.00m (centers 1.00m)`
- `[tight  ] homogeneous_coordinates:0:-0.5 <-> transform_composition:0:-0.5 gap +1.00m (centers 2.00m)`
- `[tight  ] invariants_demo:0:-0.5     <-> matrix_4x4_viewer:0:-0.5   gap +0.00m (centers 1.00m)`
- `[tight  ] rotation_gimbal:0:-0.5     <-> transform_composition:0:-0.5 gap +0.00m (centers 1.00m)`
- `[tight  ] rotation_gimbal:0:-0.5     <-> balance_puzzle:90:-0.5     gap +1.00m (centers 2.00m)`
- `[tight  ] transform_composition:0:-0.5 <-> balance_puzzle:90:-0.5     gap +0.00m (centers 1.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=+0.000
      walkability improved: 1/1  mean Δ=+0.077

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 6→6). Note-only.

## The voice (qfep)
7 of 7 cast members carry a theory-claim; 0 mute.
- **balance_puzzle** — Transformation changes S while stability acts as the invariant. The stack only counts as coherent when many lo
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **homogeneous_coordinates** — 4x4 matrices unify all affine transforms into one representation — the most compressed (F-minimal) description
- **invariants_demo** — Invariance is the core of identity under transformation — what remains when everything else changes is the ess

## The text vs the space
walked.md exists — the writing names 7/7 of the cast; dwells declared for 2.
- **the writing's subjects are blocked in space**: balance_puzzle, homogeneous_coordinates, invariants_demo, matrix_4x4_viewer, rotation_gimbal, transform_composition sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
