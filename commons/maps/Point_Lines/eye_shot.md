# Eye shot — Point_Lines

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 42 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] dark_sphere:0:-0.500:1     <-> lab_room:0:0:1#mounted_lab_json:res://commons/labs/point_line.lab.json gap +0.00m (centers 1.00m)`
- `[tight  ] line:0:1.500:2             <-> modulor_man_demo:0:-0.500:1 gap +0.41m (centers 1.41m)`
- `[tight  ] plus_line_puzzle:0:1.200:0#plusfillhole:remove <-> parallel_line_puzzle:0:1.200:0#fillhole:remove gap +1.00m (centers 2.00m)`
- `[tight  ] plus_line_puzzle:0:1.200:0#plusfillhole:remove <-> cube_scene:0:0:0.900#group:plusfillhole gap +0.00m (centers 1.00m)`
- `[tight  ] parallel_line_puzzle:0:1.200:0#fillhole:remove <-> cube_scene:0:0:0.900#group:fillhole gap +0.00m (centers 1.00m)`
- `[tight  ] cube_scene:0:0:0.900#group:plusfillhole <-> cube_scene:0:0:0.900#group:fillhole gap +1.00m (centers 2.00m)`
- `[tight  ] cube_scene:0:0:0.900#group:fillhole <-> laser_measure:0:1:1        gap +1.00m (centers 2.00m)`
- `[tight  ] cube_scene:0:1:0.600       <-> cube_scene:0:1:0.400       gap +0.00m (centers 1.00m)`

## The move
        if not try_place_at(a, target_r, target_c):
      File "C:\Users\palle\Documents\GitHub\AdaResearch_46\tools\placement_research.py", line 1578, in try_place_at
        for radius in range(0, max(room.depth, room.width)):
    TypeError: 'float' object cannot be interpreted as an integer

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 42→42). Note-only.

## The voice (qfep)
9 of 20 cast members carry a theory-claim; 11 mute.
- **cube_scene** — Transformation changes S while the cube serves as the invariant reference body. Because the base form is so le
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **floating_sphere_field** — The void was never empty, only under-rendered. Replacing the lattice with a drift trades the comfort of fixed 
- **fontana_puncture** — The point given a radius and aimed at solid matter becomes the absence that defines the form. Subtraction as m
- mute: dgrid, laser_exploding_sphere, laser_measure, lightrod, line, line_builder_3d, modulor_man_demo, parallel_line_puzzle

## The text vs the space
walked.md exists — the writing names 12/20 of the cast; dwells declared for 2.
- **the writing's subjects are blocked in space**: laser_measure, line, modulor_man_demo, parallel_line_puzzle, plus_line_puzzle sit in clearance violations — the text promises what the floor obstructs.
- space without text: cube_scene, dark_sphere, floating_sphere_field, lab_room, laser_exploding_sphere, laser_sword — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
