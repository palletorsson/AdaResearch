# Zelda Tilemap

Procedural tilemap generator in 2D and 3D variants, inspired by top-down RPG terrain.

## Key Files
- `zelda_tilemap.gd` — Extends Node3D; 60x60 configurable 3D tilemap with 7 terrain types (empty, sand, grass, water, rock, mountain, building); color/height mapping; map_scale 0.2 for VR
- `zelda_tilemap2d.gd` — Extends Node2D; 2D variant with same terrain types; tile_size 16.0 pixels
- `zelda_tilemap.tscn` — 3D tilemap scene
- `zelda_tilemap_2d.tscn` — 2D variant scene
- `zelda_tiles_3d.tscn` — Complex 3D tile variant (pre-baked model)
