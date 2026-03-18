# Grid Eye

Player position visualization snapped to a configurable grid.

## Key Files
- `the_grid_point.gd` — Extends Node3D; shows player position (from XROrigin3D) snapped to grid with configurable `grid_spacing` (0.2); outputs coordinates to Label3D nodes; generates grid texture via `_create_grid_texture()`
- `the_grid_point.tscn` — Node3D with 3x Label3D position displays, Camera3D, GrabCube2, HighlightRing, PlanGrid plane mesh
