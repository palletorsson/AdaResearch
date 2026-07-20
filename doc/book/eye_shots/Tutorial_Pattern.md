# Eye shot — Tutorial_Pattern

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 6 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] panel_bridge_loom:0:-0-49#shafts:8 <-> script_runner:0:-0.5       gap +0.00m (centers 1.00m)`
- `[tight  ] panel_bridge_loom:0:-0-49#shafts:8 <-> pattern_tile_plate:180:-0.49#p4m gap +1.00m (centers 2.00m)`
- `[tight  ] dark_sphere                <-> pattern_tile_mirror:0:-0.5 gap +0.08m (centers 1.00m)`
- `[tight  ] dark_sphere                <-> pattern_tile_puzzle:0:-0.5 gap +1.08m (centers 2.00m)`
- `[tight  ] pattern_tile_mirror:0:-0.5 <-> pattern_tile_puzzle:0:-0.5 gap +0.00m (centers 1.00m)`
- `[tight  ] grid_model:180:-0.8        <-> pulsar_compact:0:-0.5      gap +0.00m (centers 1.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 0/1  mean Δ=+0.000
      walkability improved: 1/1  mean Δ=+0.008

no sibling kept — the move did not beat the ride (overlaps 0→0, tight 6→6). Note-only.

## The voice (qfep)
10 of 10 cast members carry a theory-claim; 0 mute.
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **grid_model** — max_model_size — the model dynamically scales so any map fits within this bounding dimension (default 1.0m); a
- **panel_bridge_loom** — The oldest L-system in human hands: threading, tie-up, treadling — a weaving draft is a grammar, and the drawd
- **pattern_maker_station** — wallpaper_group — the symmetry operator that transforms a 4x4 domain into a universe; 17 groups, exactly 17, a

## The text vs the space
walked.md exists — the writing names 0/10 of the cast; dwells declared for 0.
- space without text: dark_sphere, grid_model, panel_bridge_loom, pattern_maker_station, pattern_studio_plate, pattern_tile_mirror — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
