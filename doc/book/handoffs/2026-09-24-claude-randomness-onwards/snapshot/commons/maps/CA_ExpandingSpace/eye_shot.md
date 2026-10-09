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
5 of 5 cast members carry a theory-claim; 0 mute.
- **ca_chair_test** — f_order: the chair grown by rule — furniture as the output of a cellular process, sat-on proof that local rule
- **cellular_automata_3d_tree** — f_order: growth as computation — a tree-form accreted by 3D CA steps, branching where the rule permits. The or
- **crossway_ca** — f_order: automata at the crossing — lanes of cells negotiating an intersection by neighborhood rule alone; tra
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change

## The text vs the space
walked.md exists — the writing names 5/5 of the cast; dwells declared for 0.
- **the writing's subjects are blocked in space**: ca_chair_test, cellular_automata_3d_tree, crossway_ca, dark_sphere, decaying_bridge sit in clearance violations — the text promises what the floor obstructs.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
