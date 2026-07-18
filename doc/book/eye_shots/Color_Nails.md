# Eye shot — Color_Nails

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 13 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] dark_sphere                <-> nail_color_controller:180  gap +0.49m (centers 1.41m)`
- `[tight  ] dark_sphere                <-> hand_model:90:-1:3         gap +0.08m (centers 1.00m)`
- `[tight  ] dark_sphere                <-> hand_color_controller:180  gap +0.49m (centers 1.41m)`
- `[tight  ] nail_color_controller:180  <-> hand_model:90:-1:3         gap +0.00m (centers 1.00m)`
- `[tight  ] nail_color_controller:180  <-> hand_color_controller:180  gap +1.00m (centers 2.00m)`
- `[tight  ] hand_model:90:-1:3         <-> hand_color_controller:180  gap +0.00m (centers 1.00m)`
- `[tight  ] hand_model:90:-1:3         <-> dark_side_prism:0:1.5      gap +1.00m (centers 2.00m)`
- `[tight  ] dark_side_prism:0:1.5      <-> colorballs                 gap +0.41m (centers 1.41m)`

## The move
        r = apply_to_map(m, engine=args.engine, in_place=args.in_place,
      File "C:\Users\palle\Documents\GitHub\AdaResearch_46\tools\place.py", line 222, in apply_to_map
        new_inter[r][c] = name_to_token.get(p.artifact.lookup_name,
    TypeError: list indices must be integers or slices, not float

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 13→13). Note-only.

## The voice (qfep)
5 of 9 cast members carry a theory-claim; 4 mute.
- **brick_wall_factory** — palette — selects from 20 named palettes (starry_night to industrial_brutalism), redefining the wall's emotion
- **colorballs** — current_palette_index — switches the entire chromatic vocabulary; same physics, different visual language a co
- **dark_side_prism** — fan_length — controls how far the spectrum spreads, making refraction feel gentle or dramatic white light is n
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- mute: grab_stick_scanner, hand_color_controller, hand_model, nail_color_controller

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
