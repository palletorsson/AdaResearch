# Eye shot — Point_One

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **1 overlaps, 8 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] origin                     <-> lab_room#mounted_lab_json:res://commons/labs/point_one.lab.json gap -0.01m (centers 1.00m)`
- `[tight  ] origin                     <-> folding_past:1:2           gap +0.99m (centers 2.00m)`
- `[tight  ] lab_room#mounted_lab_json:res://commons/labs/point_one.lab.json <-> folding_past:1:2           gap +0.00m (centers 1.00m)`
- `[tight  ] fontana_puncture:0:0:2#embed_artifact:interactive_point_origin_force#embed_mode:transformation <-> interactive_point_origin_force:0:1#mode:transformation gap +0.41m (centers 1.41m)`
- `[tight  ] fontana_puncture:0:0:2#embed_artifact:interactive_point_origin_force#embed_mode:transformation <-> interactive_point_origin_force:0:1#mode:chromatic gap +0.00m (centers 1.00m)`
- `[tight  ] interactive_point_origin_force:0:1#mode:transformation <-> interactive_point_origin_force:0:1#mode:chromatic gap +0.00m (centers 1.00m)`
- `[tight  ] interactive_point_origin_force:0:1#mode:chromatic <-> interactive_point_origin_force:0:1#mode:waveform gap +1.00m (centers 2.00m)`
- `[tight  ] interactive_point_origin_force:0:1#mode:waveform <-> floating_sphere_field      gap +0.41m (centers 1.41m)`

## The move
        placements = strategy_rule_based(room, list(artifacts), rng)
      File "C:\Users\palle\Documents\GitHub\AdaResearch_46\tools\placement_research.py", line 449, in strategy_rule_based
        for c in rng.sample(range(0, room.width - w + 1), room.width - w + 1):
    TypeError: 'float' object cannot be interpreted as an integer

no sibling kept — the move did not beat the ride (overlaps 1→1, tight 8→8). Note-only.

## The voice (qfep)
9 of 10 cast members carry a theory-claim; 1 mute.
- **CoordinateSystem3M** — Pure F — the coordinate system is the most fundamental structure, the frame from which all measurement begins.
- **floating_sphere_field** — The void was never empty, only under-rendered. Replacing the lattice with a drift trades the comfort of fixed 
- **folding_past** — An accordion collapsing — time made geometric, the past pleating into the present. The one primitive here that
- **fontana_puncture** — The point given a radius and aimed at solid matter becomes the absence that defines the form. Subtraction as m
- mute: 

## The text vs the space
walked.md exists — the writing names 10/10 of the cast; dwells declared for 3.
- **the writing's subjects are blocked in space**: floating_sphere_field, folding_past, fontana_puncture, interactive_point_origin_force, lab_room, origin sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
