# Sixteen-Cell Net Space

A spatial arrangement generator that fills 3D space with repeating units of the 16-cell polytope net -- the 4D analogue of the octahedron, unfolded into clusters of 16 tetrahedra. This artifact teaches how higher-dimensional polytopes can be decomposed into familiar 3D building blocks, and how those blocks can tile space to create architectural structures with hollows, spirals, and symmetry patterns.

## How It Works

1. **Net generation**: Each 16-cell net consists of 16 tetrahedra arranged according to one of four patterns:
   - **Octahedral Core** -- tetrahedra placed at the 8 face centers plus 6 axis-aligned positions of an octahedron, plus center and corner
   - **Double Pyramid** -- 4 tetrahedra in a bottom ring, 8 in a middle ring, 4 in a top ring (stacked square pyramids)
   - **Tetrahedral Star** -- 4 tetrahedra along each of the 4 tetrahedral symmetry axes
   - **Compact Cluster** -- 8 corner-packed tetrahedra plus 8 axis-aligned extensions
2. **Space filling**: Nets are placed on a 3D grid (`space_size`) with configurable spacing. Optional offset patterns stagger nets for interlocking arrangements.
3. **Hollow center**: Nets within `hollow_radius` of the center are omitted, creating walkable interior voids. An optional spiral arrangement makes the hollow follow a helical path.
4. **Rotation variety**: Nets are rotated based on their grid position for visual diversity.
5. **Tetrahedra rendering**: Each tetrahedron is built from 4 triangular faces using `SurfaceTool`, with per-face normals. An optional wireframe overlay shows the 6 edges using `ImmediateMesh`.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `net_pattern` | NetPattern | OCTAHEDRAL_CORE | Arrangement of tetrahedra within each net |
| `space_size` | Vector3i | (5,3,5) | Grid dimensions for net placement |
| `tetrahedron_size` | float | 0.8 | Scale of individual tetrahedra |
| `spacing` | float | 0.2 | Gap between adjacent nets |
| `create_hollow_center` | bool | true | Omit nets near the center for a hollow interior |
| `hollow_radius` | float | 2.0 | Radius of the hollow region |
| `rotation_variety` | bool | true | Rotate nets based on grid position |
| `offset_pattern` | bool | true | Stagger nets for interlocking |
| `spiral_arrangement` | bool | false | Make the hollow follow a spiral path |
| `base_color` | Color | cyan | Base tetrahedron color |
| `use_rainbow_gradient` | bool | false | Color tetrahedra by position/index |
| `emission_strength` | float | 0.5 | Glow intensity |
| `show_edges` | bool | true | Show wireframe edge overlays |
| `transparency` | float | 0.3 | Tetrahedron face transparency |

## Features

- **Four net arrangement patterns** -- each demonstrates a different symmetry decomposition of the 16-cell
- **Hollow architectural spaces** -- the hollow center creates walkable/viewable interior voids
- **Spiral tunnels** -- optional helical hollow path for a more dynamic interior
- **Double-sided rendering** -- `CULL_DISABLED` so tetrahedra are visible from both sides
- **Demo controller** -- full UI with pattern selector, size/spacing sliders, color picker, randomize button, keyboard shortcuts (1-4 for patterns, R to regenerate, Space to randomize)
- **VR UI** (SixteenCellUI.gd) -- simplified control panel for VR interaction

## Files

- `sixteen_cell_net_space.gd` -- Core generator: net patterns, tetrahedron mesh construction, space filling, hollow carving
- `sixteen_cell_demo_controller.gd` -- Interactive demo with full UI panel, camera orbit, randomization, keyboard/mouse controls
- `SixteenCellUI.gd` -- Simplified VR control panel
- `sixteen_cell_net_space.tscn` -- Standalone artifact scene
- `sixteen_cell_net_space_demo.tscn` -- Interactive demo scene
- `sixteen_cell_net_space_showcase.tscn` -- Showcase scene
