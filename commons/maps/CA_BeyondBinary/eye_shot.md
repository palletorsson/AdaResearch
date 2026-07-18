# Eye shot — CA_BeyondBinary

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **5 overlaps, 3 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] mold_network               <-> hexagon_ca_vr              gap -13.98m (centers 4.24m)`
- `[tight  ] game_of_life_petri:0:0.5:1 <-> science_screen:180:1.5#mode:grid gap +1.00m (centers 2.00m)`
- `[tight  ] game_of_life_petri:0:0.5:1 <-> dark_sphere                gap +0.08m (centers 1.00m)`
- `[OVERLAP] game_of_life_petri:0:0.5:1 <-> hexagon_ca_vr              gap -16.04m (centers 2.00m)`
- `[OVERLAP] science_screen:180:1.5#mode:grid <-> hexagon_ca_vr              gap -15.21m (centers 2.83m)`
- `[OVERLAP] dark_sphere                <-> hexagon_ca_vr              gap -16.96m (centers 1.00m)`
- `[tight  ] dark_sphere                <-> ca_growth_network          gap +0.83m (centers 2.24m)`
- `[OVERLAP] hexagon_ca_vr              <-> ca_growth_network          gap -17.11m (centers 1.41m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.204
      walkability improved: 0/1  mean Δ=-0.196

no sibling kept — the move did not beat the ride (overlaps 5→5, tight 3→4). Note-only.

## The voice (qfep)
4 of 6 cast members carry a theory-claim; 2 mute.
- **ca_growth_network** — attractor_strength — how powerfully distant goals bend the growth direction Growth toward a goal, with noise, 
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **game_of_life_petri** — Game of Life operates at the edge of chaos â€” simple enough to be deterministic, complex enough to be unpredi
- **science_screen** — Transformation here is projection: a 3D state is re-expressed in 2D while preserving selected structural relat
- mute: hexagon_ca_vr, mold_network

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
