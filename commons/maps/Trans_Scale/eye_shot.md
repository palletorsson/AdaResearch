# Eye shot — Trans_Scale

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 14 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] chair_assembly_puzzle:180:-0.5#furniture_type:chair <-> clipboard#vr_scale_controls:180:0:0.5 gap +0.00m (centers 1.00m)`
- `[tight  ] clipboard#vr_scale_controls:180:0:0.5 <-> science_screen:180:1.5#mode:bars gap +1.00m (centers 2.00m)`
- `[tight  ] scale_me:0:1               <-> cube_scene:45:0.2:0.6      gap +1.00m (centers 2.00m)`
- `[tight  ] prism_block:90             <-> prism_block:90             gap +0.00m (centers 1.00m)`
- `[tight  ] prism_block:90             <-> cube_scene:45:0.2:0.6      gap +1.00m (centers 2.00m)`
- `[tight  ] prism_block:90             <-> cube_scene:45:0.2:0.6      gap +0.00m (centers 1.00m)`
- `[tight  ] prism_block:90             <-> cube_scene:45:0.2:0.6      gap +1.00m (centers 2.00m)`
- `[tight  ] cube_scene:45:0.2:0.6      <-> cube_scene:45:0.2:0.6      gap +0.00m (centers 1.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=-0.029
      walkability improved: 0/1  mean Δ=-0.090

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 14→14). Note-only.

## The voice (qfep)
7 of 7 cast members carry a theory-claim; 0 mute.
- **chair_assembly_puzzle** — Transformation modifies S while the cube remains the invariant unit. Furniture appears when repeated primitive
- **clipboard** — Transformation changes the clipboard's state, page, and content while preserving a continuous reading object. 
- **cube_scene** — Transformation changes S while the cube serves as the invariant reference body. Because the base form is so le
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change

## The text vs the space
walked.md exists — the writing names 7/7 of the cast; dwells declared for 1.
- **the writing's subjects are blocked in space**: chair_assembly_puzzle, clipboard, cube_scene, prism_block, scale_me, science_screen sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
