# Color Balls

## Purpose
Spawns physics-driven color balls using palette colors for embodied color interaction.

## Key Files
- `res://algorithms/color/colorballs/colorballs.tscn`
- `res://algorithms/color/colorballs/colorballs.gd`

## VR Notes
- Uses `MultiMesh` for rendering and rigid bodies for physics.
- `multimesh_sync_rate` throttles visual transform sync to reduce CPU cost in VR.

## Used In
- `res://commons/maps/Color_Nails/map_data.json`
