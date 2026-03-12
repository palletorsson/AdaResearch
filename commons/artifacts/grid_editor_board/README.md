# Grid Editor Board

Interactive grid layout editor for designing control board configurations in VR, serving as a Godot-native mirror of the web-based grid editor with a Black Mesa-inspired industrial aesthetic.

## How It Works

The artifact presents an upright XY back-panel with a configurable cell grid (default 24x14). A 2D boolean occupancy array tracks which cells are filled. Each element has a width and height in grid cells; placement checks the occupancy array for collisions before stamping the element's instance ID into the occupied region. Elements are rendered as category-colored quads with name labels on the grid surface. Grid lines use MultiMesh instancing for GPU efficiency. A category-organized palette sidebar shows available elements, and preset buttons load predefined board layouts (Mission Control, Server, Communications, or empty).

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `panel_width` | float | `2.8` |
| `panel_height` | float | `1.4` |
| `cell_size` | float | `0.06` |
| `grid_margin_left` | float | `0.08` |
| `default_grid_w` | int | `24` |
| `default_grid_h` | int | `14` |

## Features

- 2D occupancy-grid placement with collision detection
- Category-colored element palette organized by type
- Preset board layouts loadable via buttons (Mission Control, Server, Communications)
- Touch-based VR interaction via Area3D overlap detection
- Selection highlighting with delete and clear tools
- GPU-instanced grid lines via MultiMesh
- Built-in capture camera for screenshots

## Files

- `grid_editor_board.gd` -- Main script
- `grid_editor_board.tscn` -- Scene file
- `grid_editor_board_3d.tscn` -- 3D variant scene
- `control_board_subset.gd` -- Element and preset data definitions
- `control_board_element_factory.gd` -- Element construction helpers
