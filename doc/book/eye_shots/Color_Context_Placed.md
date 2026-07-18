# Eye shot — Color_Context_Placed

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **5 overlaps, 5 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] constraint_sculptor        <-> crackpropagation_ca        gap +0.55m (centers 3.61m)`
- `[OVERLAP] dna_color_furniture_furniture_lamp_warm_glow <-> crackpropagation_ca        gap -1.06m (centers 2.00m)`
- `[tight  ] crackpropagation_ca        <-> mill_memphis_p3            gap +1.06m (centers 4.12m)`
- `[OVERLAP] crackpropagation_ca        <-> dna_color_furniture_furniture_coco_pendant_warm gap -1.06m (centers 2.00m)`
- `[tight  ] dna_color_stacks_stack_value_steps_warm <-> 2d_in_3d_point_vis         gap +1.14m (centers 3.16m)`
- `[OVERLAP] dna_color_stacks_stack_value_steps_warm <-> pattern_tunnel_machine     gap -0.11m (centers 5.39m)`
- `[tight  ] 2d_in_3d_point_vis         <-> csg_architecture_cavity    gap +0.21m (centers 2.24m)`
- `[OVERLAP] 2d_in_3d_point_vis         <-> pattern_tunnel_machine     gap -0.12m (centers 6.40m)`

## The move
        if not try_place_at(a, target_r, target_c):
      File "C:\Users\palle\Documents\GitHub\AdaResearch_46\tools\placement_research.py", line 1578, in try_place_at
        for radius in range(0, max(room.depth, room.width)):
    TypeError: 'float' object cannot be interpreted as an integer

no sibling kept — the move did not beat the ride (overlaps 5→5, tight 5→5). Note-only.

## The voice (qfep)
23 of 26 cast members carry a theory-claim; 3 mute.
- **crackpropagation_ca** — Edge of chaos — the crack threshold is the critical lambda where order (intact material) meets entropy (shatte
- **csg_architecture_cavity** — wall_size against the opening sizes — the ratio of solid to void. Too little solid and the wall stops reading 
- **dna_color_furniture_furniture_becker_utensilo_bauhaus** — F_order: a curated finding given a name in the registry.
- **dna_color_furniture_furniture_coco_pendant_warm** — F_order: a curated finding given a name in the registry.
- mute: 2d_in_3d_point_vis, constraint_sculptor, pattern_tunnel_machine

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
