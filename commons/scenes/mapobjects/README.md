# Map Objects

## Purpose
General-purpose interactive map objects reused across sequences.

## Key Files
- `res://commons/scenes/mapobjects/pick_up_cube.tscn`
- `res://commons/scenes/mapobjects/pick_up_cube.gd`

## VR Notes
- Pickup interactions should remain low-latency and avoid per-frame heavy logic.
- Audio feedback is generated procedurally on collection.

## Used In
- `res://commons/maps/Color_Rainbow/map_data.json`
