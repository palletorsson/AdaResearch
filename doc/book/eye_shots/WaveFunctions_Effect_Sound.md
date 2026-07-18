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
10 of 22 cast members carry a theory-claim; 12 mute.
- **DualBallFMController** — mod_index — controls harmonic richness from pure tone to metallic chaos All timbral complexity is phase modula
- **MarioSoundController** — mode — switches between Mario jump, coin, laser, explosion, powerup generators Every game sound is a parametri
- **MelodyChaser3D** — beat_interval — sets the tempo that drives the melodic sequence A melody is a path through pitch-space travers
- **cable_builder** — control_point_count — determines degrees of freedom for curve shaping A hanging cable finds the shape that min
- mute: AudioContr, BigPipeSystem, GlassRack, Rack303Acid, RackDX7Piano, RackMoogBass, RackSineBasic, VRAudioMonitor

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
