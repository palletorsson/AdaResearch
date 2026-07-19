# Eye shot — Array_Patterns

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 8 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] pattern_tile_4x4:0:-0.5    <-> vr_tile_editor_mirror:0:-0.5 gap +1.00m (centers 2.00m)`
- `[tight  ] pattern_tile_4x4:0:-0.5    <-> tiling_demo:180:-1.6       gap +1.00m (centers 2.00m)`
- `[tight  ] vr_tile_editor_mirror:0:-0.5 <-> pattern_tile_mirror:0:-0.5 gap +1.00m (centers 2.00m)`
- `[tight  ] pattern_tile_mirror:0:-0.5 <-> science_screen:180:1.5#mode:grid gap +1.00m (centers 2.00m)`
- `[tight  ] dark_sphere                <-> pattern_tile_plate:0:-0.49#p4m gap +1.08m (centers 2.00m)`
- `[tight  ] dark_sphere                <-> grid_model                 gap +1.08m (centers 2.00m)`
- `[tight  ] pattern_tunnel_machine:0:0#tunnel_length:6 <-> panel_bridge_loom          gap +0.19m (centers 1.41m)`
- `[tight  ] panel_bridge_loom          <-> grid_model                 gap +0.78m (centers 2.00m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.115
      walkability improved: 1/1  mean Δ=+0.094

no sibling kept — the move did not beat the ride (overlaps 0→1, tight 8→6). Note-only.

## The voice (qfep)
5 of 13 cast members carry a theory-claim; 8 mute.
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **grid_model** — max_model_size — the model dynamically scales so any map fits within this bounding dimension (default 1.0m); a
- **panel_bridge_loom** — The oldest L-system in human hands: threading, tie-up, treadling — a weaving draft is a grammar, and the drawd
- **pattern_tunnel_machine** — f_order: the tunnel that paints itself — a subway-tiled walkway laid tile by tile from a pattern console at it
- mute: facade_grammar_demo, pattern_tile_4x4, pattern_tile_brick, pattern_tile_herringbone, pattern_tile_mirror, pattern_tile_plate, tiling_demo, vr_tile_editor_mirror

## The text vs the space
walked.md exists — the writing names 0/13 of the cast; dwells declared for 0.
- space without text: dark_sphere, facade_grammar_demo, grid_model, panel_bridge_loom, pattern_tile_4x4, pattern_tile_brick — standing in the room, absent from the walk.

## The heuristic understanding
The violations are real but mechanical moving does not fix them — they are placement DECISIONS (which body yields?), not placement errors. This is verdict material, not tooling material.
