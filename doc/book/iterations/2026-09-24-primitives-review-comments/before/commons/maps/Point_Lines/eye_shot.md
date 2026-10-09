# Eye shot — Point_Lines

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 27 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] perspective_lines:0:2:1    <-> line_builder_3d:0:0:0.500  gap +1.00m (centers 2.00m)`
- `[tight  ] perspective_lines:0:2:1    <-> lab_room:0:0:1#mounted_lab_json:res://commons/labs/point_line.lab.json gap +1.00m (centers 2.00m)`
- `[tight  ] fontana_puncture:0:0:1     <-> laser_sword:0:0:1          gap +0.00m (centers 1.00m)`
- `[tight  ] fontana_puncture:0:0:1     <-> klee_walking_point:0:0:1   gap +1.00m (centers 2.00m)`
- `[tight  ] laser_sword:0:0:1          <-> klee_walking_point:0:0:1   gap +0.00m (centers 1.00m)`
- `[tight  ] laser_sword:0:0:1          <-> grabbable_line:0:1:1       gap +0.41m (centers 1.41m)`
- `[tight  ] klee_walking_point:0:0:1   <-> grabbable_line:0:1:1       gap +0.00m (centers 1.00m)`
- `[tight  ] klee_walking_point:0:0:1   <-> lightrod:90:0:1#config:4   gap +1.00m (centers 2.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=-0.120
      walkability improved: 0/1  mean Δ=-0.017

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 27→27). Note-only.

## The voice (qfep)
20 of 20 cast members carry a theory-claim; 0 mute.
- **cube_scene** — Transformation changes S while the cube serves as the invariant reference body. Because the base form is so le
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **dgrid** — Dürer's perspective frame standing in the room — the drafting instrument that taught the Renaissance to projec
- **floating_sphere_field** — The void was never empty, only under-rendered. Replacing the lattice with a drift trades the comfort of fixed 

## The text vs the space
walked.md exists — the writing names 12/20 of the cast; dwells declared for 2.
- **the writing's subjects are blocked in space**: fontana_puncture, grabbable_line, klee_walking_point, line_builder_3d, perspective_lines sit in clearance violations — the text promises what the floor obstructs.
- space without text: cube_scene, dark_sphere, floating_sphere_field, lab_room, laser_exploding_sphere, laser_sword — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
