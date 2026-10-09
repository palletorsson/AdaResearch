# Transformation arenas inside the museum

9 September 2026. The source maps were inspected and copied into `before/` before modifying their museum declarations. `baseline.json` records their hashes, dimensions and prior museum settings. These are snapshots of the working grid maps, including uncommitted work, rather than reconstructed historical versions.

The museum now embeds the real GridSystem for all nine Transformation halls. Previously three halls embedded it and six used the museum's derived geometry and artifact placement. Each embedded instance keeps the source map's structure, utilities and interactables, at scale 1. Its parent offset puts the top of a standard grid floor cube at the museum's y=0. The source layers and dimensions remain unchanged in all nine JSON files.

The surrounding frame is generated separately:

- A two-metre museum walkway surrounds all four sides at y=0.
- A two-metre pit separates that walkway from the arena; its floor is 2.5 metres down.
- A one-metre apron surrounds the original grid at y=0.
- Transparent sides frame the apron; the top remains open, with slim framing posts.
- Level bridges cross the pit at opposite ends, aligned to existing source-map floor openings. Glass and rails have matching collision and leave these openings clear.
- The museum path continues around the arena, allowing observation without completing its challenges.

The complete padding is five metres on every side. No source-map wall is cut to create a door. Entrance placement selects an existing floor run on the source map's first row; the exit uses its last row. All nine maps currently have suitable openings. An isolated snapshot of a source map is a reference; the running museum continues to load the maintained map rather than a second editable copy.

Implementation: `commons/scenes/em/em_simulation_stage.gd`, called by `commons/scenes/endless_museum.gd`. The opt-in declaration is `map_info.museum.simulation` with `grid: true`, `staged: true`, `margin: 2`, `padding: 2`, `depth: 2.5`, `fire: false`. The outer pit adds no fire. Source-map hazard behaviour still meets the existing museum disarm policy.

## Verification

- `probe_simulation_stage.gd`: 45 checks passed, including source-layer preservation across nine maps, entry selection, level apron/bridge/walkway, actual glass collision, a recessed pit, and a completed real Translation grid.
- `probe_museum_simulation_stages.gd`: 81 checks passed against all nine assembled museum halls; each contains one source GridSystem, finishes building, retains its source structure and scale, uses the recorded offset, and supports the outer walk with physics.
- Source and staged Translation captures were inspected, followed by a capture from the actual endless museum.
- No script errors in the successful integration run. Engine resource/cache warnings remain in the logs; a complete headset walkthrough and gameplay parity audit have not been performed.

Evidence is in `ada_run/simulation_stage/`, including `integration-checks.json`, `integration2.log`, `Trans_Translation_source.png`, `Trans_Translation_stage.png` and the museum captures.

## What remains distinct

An embedded grid retains the museum's existing ride adaptation and exit/hazard disarming. `bare_world` omits the grid's surrounding biome/sky, and `skip_player_spawn` preserves the museum visitor. This is a spatial copy with the established museum hosting behaviour, not a claim that every desktop and VR interaction is identical to standalone play. Existing source defects, including configuration parsing and Scale targeting, are not silently corrected by this framing pass. Original source wall-height limits are preserved too.

The inner grid remains the authority for its own floor and challenges. The museum path planner advertises the frame's walking surfaces and existing adapted rides, rather than claiming that open pit is level floor. The primary-artifact roles and book prose are untouched by this pass.
