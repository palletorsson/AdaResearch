# Drawingboard Context

## Purpose
Shared painting/drawing components used by map-level color demos.

## Key Files
- `res://commons/context/drawingboard/ball_painting_demo_v2.tscn`
- `res://commons/context/drawingboard/ball_spawner.gd`
- `res://commons/context/drawingboard/paper_draw_surface.gd`

## VR Notes
- Input and paint updates are event-driven; rendering is shader/viewport based.
- Keep spawned paint projectiles and texture update frequency balanced for Quest.

## Used In
- `res://commons/maps/Color_Paint/map_data.json`
