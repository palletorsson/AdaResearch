# Tesseract Net Space

A space-filling structure built from repeating tesseract nets -- the 3D unfoldings of a 4D hypercube (tesseract). Just as a cube can be unfolded into a cross of 6 squares, a tesseract unfolds into a cross of 8 cubes. This artifact teaches the concept of **polytope nets** -- how higher-dimensional objects are represented by lower-dimensional unfoldings, and how those unfoldings can tile space to create architectural environments.

## How It Works

1. **Net types**: Four different tesseract net configurations are available:
   - **Dali Cross** -- the classic cruciform net (inspired by Dali's "Corpus Hypercubus"): a center cube with 6 face-attached cubes and 1 extension, totaling 8 cubes
   - **Linear Chain** -- 8 cubes in a straight line
   - **Folded Chain** -- 8 cubes arranged in a zigzag path through 3D space
   - **Double Cross** -- two perpendicular crosses sharing a center cube
2. **Space filling**: Nets are placed on a 3D grid with configurable spacing. Offset patterns stagger every other net for interlocking. Rotation variety rotates nets by 90-degree increments based on grid position.
3. **Hollow center**: Nets within a configurable distance of the grid center are omitted, creating a walkable interior void.
4. **Cube rendering**: Each cube is a slightly-undersized `BoxMesh` (95% size for visible gaps). Optional wireframe overlays show all 12 edges using `ImmediateMesh`.
5. **VR grid mode**: The `tesseract_net_space_grid_vr.gd` script generates a 4x4 grid showing all 4 net types in 4 parameter variations each (small, hollow, offset, complex).

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `net_type` | NetType | DALI_CROSS | Which tesseract net unfolding to use |
| `space_size` | Vector3i | (5,3,5) | Grid dimensions for net placement |
| `cube_size` | float | 1.0 | Size of each cube in the net |
| `spacing` | float | 0.1 | Gap between adjacent nets |
| `create_hollow_center` | bool | true | Omit nets near center for hollow interior |
| `rotation_variety` | bool | true | Rotate nets based on grid position |
| `offset_pattern` | bool | true | Stagger nets for interlocking |
| `base_color` | Color | red | Base cube color |
| `color_variation` | bool | true | Lighten cubes progressively within each net |
| `emission_strength` | float | 0.3 | Glow intensity |
| `show_wireframe` | bool | true | Show edge wireframe overlays |

## Features

- **Four tesseract net types** -- each demonstrates a different valid unfolding of the 4D hypercube into 3D
- **Dali Cross reference** -- the most recognizable net, connecting 4D geometry to art history
- **Wireframe overlays** -- 12-edge cube wireframes rendered via ImmediateMesh for clarity
- **Hollow architecture** -- walkable interior spaces carved from the grid
- **VR grid comparison** -- 16-instance grid showing all net types and parameter variations with labels
- **Demo controller** -- full UI with net type selector, size/spacing sliders, color picker, randomize button, keyboard shortcuts (1-4 for types, R to regenerate)
- **VR UI** (TesseractNetUI.gd) -- simplified panel for VR interaction

## Files

- `tesseract_net_space.gd` -- Core generator: net definitions, space filling, cube/wireframe rendering, hollow carving
- `net_space_demo_controller.gd` -- Interactive demo with full UI panel, camera orbit, randomization
- `TesseractNetUI.gd` -- Simplified VR control panel
- `tesseract_net_space_grid_vr.gd` -- 4x4 grid generator for VR comparative viewing
- `tesseract_net_space.tscn` -- Standalone artifact scene
- `tesseract_net_space_demo.tscn` -- Interactive demo scene
- `tesseract_net_space_grid_vr.tscn` -- VR grid scene
- `tesseract_net_space_showcase.tscn` -- Showcase scene
