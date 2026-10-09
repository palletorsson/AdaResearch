# Eye shot — Array_Patterns

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **1 overlaps, 6 tight** — the law wants ≥1.2m to walk between.
- `[OVERLAP] panel_bridge_loom          <-> tiling_demo:180:-1.6       gap -0.22m (centers 1.00m)`
- `[tight  ] panel_bridge_loom          <-> science_screen:180:1.5#mode:grid gap +0.19m (centers 1.41m)`
- `[tight  ] dark_sphere                <-> pattern_tile_mirror:0:-0.5 gap +0.08m (centers 1.00m)`
- `[tight  ] pattern_tile_4x4:0:-0.5    <-> grid_model                 gap +0.00m (centers 1.00m)`
- `[tight  ] pattern_tile_4x4:0:-0.5    <-> pattern_tile_brick:0:-0.5  gap +1.00m (centers 2.00m)`
- `[tight  ] grid_model                 <-> pattern_tile_herringbone:0:-0.5 gap +1.00m (centers 2.00m)`
- `[tight  ] pattern_tile_brick:0:-0.5  <-> pattern_tile_herringbone:0:-0.5 gap +0.00m (centers 1.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=+0.000
      walkability improved: 0/1  mean Δ=+0.000

no sibling kept — the move did not beat the ride (overlaps 1→1, tight 6→6). Note-only.

## The voice (qfep)
13 of 13 cast members carry a theory-claim; 0 mute.
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **facade_grammar_demo** — Architecture as array: Italian facades — Villa San Michele, the Certosa — read as grids of repeating elements,
- **grid_model** — max_model_size — the model dynamically scales so any map fits within this bounding dimension (default 1.0m); a
- **panel_bridge_loom** — The oldest L-system in human hands: threading, tie-up, treadling — a weaving draft is a grammar, and the drawd

## The text vs the space
walked.md exists — the writing names 0/13 of the cast; dwells declared for 0.
- space without text: dark_sphere, facade_grammar_demo, grid_model, panel_bridge_loom, pattern_tile_4x4, pattern_tile_brick — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
