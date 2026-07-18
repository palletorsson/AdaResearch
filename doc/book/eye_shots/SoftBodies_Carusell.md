# Eye shot — SoftBodies_Carusell

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **2 overlaps, 4 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] pick_up_cube               <-> grab_long_stick            gap -0.12m (centers 1.00m)`
- `[OVERLAP] grab_long_stick            <-> pick_up_cube               gap -0.12m (centers 1.00m)`
- `[tight  ] grab_long_stick            <-> grab_long_stick:180        gap +0.63m (centers 2.00m)`
- `[tight  ] pick_up_cube               <-> grab_long_stick:180        gap +0.25m (centers 1.00m)`
- `[tight  ] grab_long_stick:180        <-> pick_up_cube               gap +0.25m (centers 1.00m)`
- `[tight  ] cloth_straps:0:-0.5        <-> cloth_straps:0:-0.5        gap +1.00m (centers 2.00m)`

## The move
        new_placements = fn(room, artifacts, rng)
      File "C:\Users\palle\Documents\GitHub\AdaResearch_46\tools\placement_research.py", line 1283, in strategy_humanoid_walker
        for r in range(room.depth - d + 1):
    TypeError: 'float' object cannot be interpreted as an integer

no sibling kept — the move did not beat the ride (overlaps 2→2, tight 4→4). Note-only.

## The voice (qfep)
5 of 5 cast members carry a theory-claim; 0 mute.
- **cloth_straps** — strap_count — more straps create a denser curtain with more inter-strap collision, fewer straps let each one s
- **grab_long_stick** — F_force: the probe — a graspable stick trailing a long cloth ribbon. It is how the hand asks a soft world ques
- **pick_up_cube** — Pure S as carried displacement: the cube stays itself while its coordinates change. The artifact isolates tran
- **revolving_joy_ride** — ride_speed — slow rotation lets soft bodies dangle and sway, fast rotation stretches them into elongated teard

## The text vs the space
walked.md exists — the writing names 1/5 of the cast; dwells declared for 0.
- space without text: cloth_straps, grab_long_stick, pick_up_cube, revolving_joy_ride — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
