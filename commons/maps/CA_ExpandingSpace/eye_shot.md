# Eye shot — CA_ExpandingSpace

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **8 overlaps, 2 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] ca_chair_test              <-> dark_sphere                gap +0.49m (centers 1.41m)`
- `[tight  ] ca_chair_test              <-> cellular_automata_3d_tree  gap +0.43m (centers 2.00m)`
- `[OVERLAP] ca_chair_test              <-> crossway_ca                gap -2.42m (centers 6.08m)`
- `[OVERLAP] ca_chair_test              <-> decaying_bridge            gap -9.15m (centers 6.32m)`
- `[OVERLAP] dark_sphere                <-> cellular_automata_3d_tree  gap -0.08m (centers 1.41m)`
- `[OVERLAP] dark_sphere                <-> crossway_ca                gap -3.42m (centers 5.00m)`
- `[OVERLAP] dark_sphere                <-> decaying_bridge            gap -9.56m (centers 5.83m)`
- `[OVERLAP] cellular_automata_3d_tree  <-> crossway_ca                gap -4.95m (centers 4.12m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.039
      walkability improved: 0/1  mean Δ=-0.074

no sibling kept — the move did not beat the ride (overlaps 8→8, tight 2→2). Note-only.

## The voice (qfep)
2 of 5 cast members carry a theory-claim; 3 mute.
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **decaying_bridge** — decay_speed vs regrow_speed — the ratio determines whether the bridge survives your crossing Architecture that
- mute: ca_chair_test, cellular_automata_3d_tree, crossway_ca

## The text vs the space
**no walked.md** — the space stands unwritten; this note is the first text this map has.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
