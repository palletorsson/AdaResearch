# Eye shot — WaveFunctions_Effect_Sound

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **11 overlaps, 55 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] BigPipeSystem:0:-0.5       <-> pick_up_cube               gap +0.66m (centers 1.41m)`
- `[tight  ] pick_up_cube               <-> AudioContr:-90#preset:basic_mono gap +0.25m (centers 1.00m)`
- `[tight  ] pick_up_cube               <-> pick_up_cube               gap +0.50m (centers 1.00m)`
- `[tight  ] pick_up_cube               <-> AudioContr:-90#config:mario_rack gap +0.66m (centers 1.41m)`
- `[tight  ] AudioContr:-90#preset:basic_mono <-> pick_up_cube               gap +0.66m (centers 1.41m)`
- `[tight  ] AudioContr:-90#preset:basic_mono <-> AudioContr:-90#config:mario_rack gap +0.00m (centers 1.00m)`
- `[tight  ] pick_up_cube               <-> RackSineBasic:0:1          gap +0.25m (centers 1.00m)`
- `[tight  ] pick_up_cube               <-> GlassRack#config:simple_tube gap +0.25m (centers 1.00m)`

## The move
        new_placements = fn(room, artifacts, rng)
      File "C:\Users\palle\Documents\GitHub\AdaResearch_46\tools\placement_research.py", line 1283, in strategy_humanoid_walker
        for r in range(room.depth - d + 1):
    TypeError: 'float' object cannot be interpreted as an integer

no sibling kept — the move did not beat the ride (overlaps 11→11, tight 55→55). Note-only.

## The voice (qfep)
19 of 22 cast members carry a theory-claim; 3 mute.
- **AudioContr** — the audio controller — the room's mixing desk; infrastructure that routes the chapter's voices, never dominant
- **BigPipeSystem** — oscillation: the organ's logic at room scale — pipes whose lengths ARE their pitches; geometry as tuning, the 
- **DualBallFMController** — mod_index — controls harmonic richness from pure tone to metallic chaos All timbral complexity is phase modula
- **GlassRack** — oscillation: the glass rack chassis — the eurorack made walkable; modules at body height, patching as architec
- mute: audio_catalog_tablet, interactable_demo, mario_test_sound_ui

## The text vs the space
walked.md exists — the writing names 14/22 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: AudioContr, BigPipeSystem, GlassRack, RackSineBasic sit in clearance violations — the text promises what the floor obstructs.
- space without text: dark_sphere, harmonic_distance_table, interactable_demo, lab_table, mario_test_sound_ui, pick_up_cube — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
