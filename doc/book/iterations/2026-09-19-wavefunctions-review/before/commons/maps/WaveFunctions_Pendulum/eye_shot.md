# Eye shot — WaveFunctions_Pendulum

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **1 overlaps, 7 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] foucault_pendulum          <-> WavePaintings:180:1:0.2    gap -1.30m (centers 3.00m)`
- `[tight  ] draw_dot_time_domain       <-> BigPipeSystem:0:1#path:straight,straight,corner_right,straight,straight gap +0.25m (centers 1.00m)`
- `[tight  ] draw_dot_time_domain       <-> lab_table                  gap +0.15m (centers 1.00m)`
- `[tight  ] BigPipeSystem:0:1#path:straight,straight,corner_right,straight,straight <-> lab_table                  gap +0.31m (centers 1.41m)`
- `[tight  ] BigPipeSystem:0:1#path:straight,straight,corner_right,straight,straight <-> PendulumWave:90            gap +1.00m (centers 2.00m)`
- `[tight  ] lab_table                  <-> PendulumWave:90            gap +0.31m (centers 1.41m)`
- `[tight  ] seismograph                <-> dark_sphere                gap +0.98m (centers 2.00m)`
- `[tight  ] dark_sphere                <-> GlassRack:0:0.6#config:reflux_apparatus gap +0.49m (centers 1.41m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.048
      walkability improved: 0/1  mean Δ=-0.115

no sibling kept — the move did not beat the ride (overlaps 1→1, tight 7→7). Note-only.

## The voice (qfep)
10 of 10 cast members carry a theory-claim; 0 mute.
- **BigPipeSystem** — oscillation: the organ's logic at room scale — pipes whose lengths ARE their pitches; geometry as tuning, the 
- **GlassRack** — oscillation: the glass rack chassis — the eurorack made walkable; modules at body height, patching as architec
- **PendulumWave** — length — determines natural frequency via sqrt(g/L) Gravity and a string are sufficient to generate periodic m
- **VRAudioMonitor** — the monitor — level meters for the inhabited mix; it marks what is sounding without asserting content.

## The text vs the space
walked.md exists — the writing names 10/10 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: BigPipeSystem, GlassRack, PendulumWave, WavePaintings, dark_sphere, draw_dot_time_domain, foucault_pendulum, lab_table, seismograph sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
