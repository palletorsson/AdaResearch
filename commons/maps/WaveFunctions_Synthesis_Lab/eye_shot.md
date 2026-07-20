# Eye shot — WaveFunctions_Synthesis_Lab

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **3 overlaps, 28 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] dna_specimen:0:0.4         <-> holographicdisplay:0:1     gap +0.00m (centers 1.00m)`
- `[tight  ] dna_specimen:0:0.4         <-> electronicscales:0:1       gap +1.00m (centers 2.00m)`
- `[tight  ] dna_specimen:0:0.4         <-> air_music_display_case:0:1 gap +0.41m (centers 1.41m)`
- `[tight  ] holographicdisplay:0:1     <-> electronicscales:0:1       gap +0.00m (centers 1.00m)`
- `[tight  ] electronicscales:0:1       <-> lissajous_curves:0:1:0.1   gap +0.41m (centers 1.41m)`
- `[tight  ] electronicscales:0:1       <-> seismograph                gap +1.14m (centers 2.24m)`
- `[OVERLAP] lissajous_curves:0:1:0.1   <-> seismograph                gap -0.10m (centers 1.00m)`
- `[tight  ] lissajous_curves:0:1:0.1   <-> dark_sphere                gap +1.08m (centers 2.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=-0.002
      walkability improved: 0/1  mean Δ=+0.000

no sibling kept — the move did not beat the ride (overlaps 3→3, tight 28→28). Note-only.

## The voice (qfep)
24 of 24 cast members carry a theory-claim; 0 mute.
- **GlassRack** — oscillation: the glass rack chassis — the eurorack made walkable; modules at body height, patching as architec
- **SoundscapeRadioRack** — Lambda as tuning — the wheel angle IS lambda, sweeping through a spectrum of possible sounds. Between stations
- **UnitCircleTrig** — rotation_speed — controls how fast the angle sweeps and waves extend Rotation is the generator of all oscillat
- **additive_wave_demo** — harmonic_amplitudes[] — each slider adds one frequency component Any periodic function is a sum of sines; comp

## The text vs the space
walked.md exists — the writing names 14/24 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: air_music_display_case, dark_sphere, dna_specimen, electronicscales sit in clearance violations — the text promises what the floor obstructs.
- space without text: hallway_scene, holographicdisplay, lissajous_curves, microscope, multimeter, oscilloscope — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
