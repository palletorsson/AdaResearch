# Eye shot — CA_BeyondBinary

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **5 overlaps, 4 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] science_screen:180:1.5#mode:grid <-> ca_growth_network          gap +0.51m (centers 2.00m)`
- `[tight  ] science_screen:180:1.5#mode:grid <-> mold_network               gap +1.05m (centers 2.24m)`
- `[OVERLAP] science_screen:180:1.5#mode:grid <-> hexagon_ca_vr              gap -13.91m (centers 4.12m)`
- `[tight  ] ca_growth_network          <-> mold_network               gap +0.56m (centers 2.24m)`
- `[OVERLAP] ca_growth_network          <-> hexagon_ca_vr              gap -14.40m (centers 4.12m)`
- `[tight  ] mold_network               <-> game_of_life_petri:0:0.5:1 gap +1.05m (centers 2.24m)`
- `[OVERLAP] mold_network               <-> hexagon_ca_vr              gap -16.23m (centers 2.00m)`
- `[OVERLAP] game_of_life_petri:0:0.5:1 <-> hexagon_ca_vr              gap -15.80m (centers 2.24m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=+0.000
      walkability improved: 0/1  mean Δ=+0.000

no sibling kept — the move did not beat the ride (overlaps 5→5, tight 4→4). Note-only.

## The voice (qfep)
6 of 6 cast members carry a theory-claim; 0 mute.
- **ca_growth_network** — attractor_strength — how powerfully distant goals bend the growth direction Growth toward a goal, with noise, 
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **game_of_life_petri** — Game of Life operates at the edge of chaos â€” simple enough to be deterministic, complex enough to be unpredi
- **hexagon_ca_vr** — f_order: the same game on six neighbors — a hexagonal lattice showing that 'neighborhood' is a choice, and the

## The text vs the space
walked.md exists — the writing names 6/6 of the cast; dwells declared for 1.
- **the writing's subjects are blocked in space**: ca_growth_network, game_of_life_petri, hexagon_ca_vr, mold_network, science_screen sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
