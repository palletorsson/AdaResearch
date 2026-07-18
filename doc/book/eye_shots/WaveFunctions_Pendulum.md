# Eye shot — WaveFunctions_Pendulum

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **2 overlaps, 11 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] PendulumWave:90            <-> PendulumWave:90            gap +0.41m (centers 1.41m)`
- `[tight  ] PendulumWave:90            <-> PendulumWave:90            gap +1.00m (centers 2.00m)`
- `[tight  ] PendulumWave:90            <-> PendulumWave:90            gap +0.41m (centers 1.41m)`
- `[tight  ] WavePaintings:180:1:0.2    <-> foucault_pendulum          gap +0.70m (centers 5.00m)`
- `[OVERLAP] GlassRack:0:0.6#config:reflux_apparatus <-> lab_table                  gap -0.10m (centers 1.00m)`
- `[tight  ] GlassRack:0:0.6#config:reflux_apparatus <-> foucault_pendulum          gap +0.70m (centers 5.00m)`
- `[OVERLAP] GlassRack:0:0.6#config:spiral_condenser <-> lab_table                  gap -0.10m (centers 1.00m)`
- `[tight  ] GlassRack:0:0.6#config:spiral_condenser <-> foucault_pendulum          gap +0.70m (centers 5.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.066
      walkability improved: 1/1  mean Δ=+0.029

sibling **Trial_eye_WaveFunctions_Pendulum** kept: overlaps 2→2, tight 11→1, pathfinder OK.

## The voice (qfep)
5 of 10 cast members carry a theory-claim; 5 mute.
- **PendulumWave** — length — determines natural frequency via sqrt(g/L) Gravity and a string are sufficient to generate periodic m
- **WavePaintings** — Oscillation as the fundamental pattern of non-rest — perpetual movement between poles. The simplest E(S) that 
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **foucault_pendulum** — The pendulum maintains its F (swing plane) while the frame rotates beneath it. Inertia as F-preservation — the
- mute: BigPipeSystem, GlassRack, VRAudioMonitor, draw_dot_time_domain, lab_table

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The floor was fighting the walk — bodies inside each other's clearance. The mover found a better seating; the ride confirms it in text. The voice column above says what the room is FOR; the next writing pass should say it in the walked page.
