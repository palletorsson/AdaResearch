# Agnes Grid

2D grid visualization context object, available in both 2D and grabbable 3D forms.

## Key Files
- `agnes_grid.gd` — Extends Node2D; draws a configurable 2D grid (grid_size, cell_size, grid_color, background_color, line_width)
- `agnes_grid.tscn` — Basic 2D grid scene
- `agnes_grid_3d.tscn` — 3D variant: SubViewport renders the 2D grid onto a Sprite3D via ViewportTexture, with GrabCube and HighlightRing
- `grabable_agnes.tscn` — Grabbable VR version wrapping the 3D variant
