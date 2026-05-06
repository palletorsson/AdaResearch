# Sequencer

Tile-based animation sequencer running light patterns on a 3D tile grid.

## Key Files
- `seqencer.gd` — Extends Node3D; runs 6 animation patterns on a tile array: running light, block light, random tiles, rows and columns, checkerboard, diagonal sweep; configurable pattern_duration and selected_patterns list
- `seqencer.tscn` — Complex scene with pre-baked ArrayMesh tile grid geometry (Blender export)
