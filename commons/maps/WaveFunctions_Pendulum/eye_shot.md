# Eye shot — WaveFunctions_Pendulum

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **2 overlaps, 1 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] foucault_pendulum          <-> BigPipeSystem:0:1#path:straight,straight,corner_right,straight,straight gap -0.18m (centers 4.12m)`
- `[OVERLAP] foucault_pendulum          <-> dark_sphere                gap -0.10m (centers 4.12m)`
- `[tight  ] BigPipeSystem:0:1#path:straight,straight,corner_right,straight,straight <-> dark_sphere                gap +1.08m (centers 2.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.010
      walkability improved: 0/1  mean Δ=-0.010

no sibling kept — the move did not beat the ride (overlaps 2→2, tight 1→1). Note-only.

## The voice (qfep)
10 of 10 cast members carry a theory-claim; 0 mute.
- **BigPipeSystem** — oscillation: the organ's logic at room scale — pipes whose lengths ARE their pitches; geometry as tuning, the 
- **GlassRack** — oscillation: the glass rack chassis — the eurorack made walkable; modules at body height, patching as architec
- **PendulumWave** — length — determines natural frequency via sqrt(g/L) Gravity and a string are sufficient to generate periodic m
- **VRAudioMonitor** — the monitor — level meters for the inhabited mix; it marks what is sounding without asserting content.

## The text vs the space
walked.md exists — the writing names 10/10 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: BigPipeSystem, dark_sphere, foucault_pendulum sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
