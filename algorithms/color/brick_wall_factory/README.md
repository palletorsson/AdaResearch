# Brick Wall Factory

## Purpose
Procedurally builds a colored brick wall from the shared color palette resource.

## Key Files
- `res://algorithms/color/brick_wall_factory/brick_wall_factory.tscn`
- `res://algorithms/color/brick_wall_factory/brick_wall_factory.gd`

## VR Notes
- Runtime generation happens once in `_ready()`.
- Keep wall dimensions moderate on Quest to avoid high mesh/material count.

## Used In
- `res://commons/maps/Color_Nails/map_data.json`
