# Eye shot — Tutorial_Pattern

> one pass: ride (gaze), move (place --only-improve), gate (pathfinder), voice (qfep). Field note, not a ruling.

## The ride (before)
clearance violations: **0 overlaps, 9 tight** — the law wants ≥1.2m to walk between.
- `[tight  ] grid_model:180:-0.8        <-> pattern_tile_plate:180:-0.49#p4m gap +1.00m (centers 2.00m)`
- `[tight  ] pattern_studio_plate:0:-0.45 <-> pattern_tile_plate:180:-0.49#p4m gap +0.41m (centers 1.41m)`
- `[tight  ] pattern_tile_plate:180:-0.49#p4m <-> pattern_tile_plate:180:-0.49#p4m gap +1.00m (centers 2.00m)`
- `[tight  ] pattern_tile_plate:180:-0.49#p4m <-> pattern_tile_plate:180:-0.49#p4m gap +1.00m (centers 2.00m)`
- `[tight  ] pattern_tile_plate:180:-0.49#p4m <-> dark_sphere                gap +0.08m (centers 1.00m)`
- `[tight  ] pattern_tile_plate:180:-0.49#p4m <-> pattern_tile_mirror:0:-0.5 gap +1.00m (centers 2.00m)`
- `[tight  ] dark_sphere                <-> pattern_tile_mirror:0:-0.5 gap +0.08m (centers 1.00m)`
- `[tight  ] pattern_tile_mirror:0:-0.5 <-> pattern_tile_puzzle:0:-0.5 gap +0.41m (centers 1.41m)`

## The move
    logged 1 entries to ada_run\placement_log.json
    summary: 1 maps processed
      constraint improved: 1/1  mean Δ=+0.102
      walkability improved: 1/1  mean Δ=+0.003

sibling **Trial_eye_Tutorial_Pattern** kept: overlaps 0→0, tight 9→6, pathfinder OK.

## The voice (qfep)
5 of 10 cast members carry a theory-claim; 5 mute.
- **dark_sphere** — Transformation often needs an invariant reference to be legible. The sphere stays simple so surrounding change
- **grid_model** — max_model_size — the model dynamically scales so any map fits within this bounding dimension (default 1.0m); a
- **panel_bridge_loom** — The oldest L-system in human hands: threading, tie-up, treadling — a weaving draft is a grammar, and the drawd
- **pattern_maker_station** — wallpaper_group — the symmetry operator that transforms a 4x4 domain into a universe; 17 groups, exactly 17, a
- mute: pattern_studio_plate, pattern_tile_mirror, pattern_tile_plate, pattern_tile_puzzle, script_runner

## The text vs the space
walked.md exists — the writing names 0/10 of the cast; dwells declared for 0.
- space without text: dark_sphere, grid_model, panel_bridge_loom, pattern_maker_station, pattern_studio_plate, pattern_tile_mirror — standing in the room, absent from the walk.

## The heuristic understanding
The floor was fighting the walk — bodies inside each other's clearance. The mover found a better seating; the ride confirms it in text. The voice column above says what the room is FOR; the next writing pass should say it in the walked page.
