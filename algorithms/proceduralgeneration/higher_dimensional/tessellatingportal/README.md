# Tessellating Portal

A portal structure generator that builds arch-and-pillar doorways from space-filling polyhedra -- shapes that tile 3D space without gaps. This artifact teaches the concept of **space-filling tessellation**: which 3D shapes can pack together to fill all of space, and how those shapes can be arranged into architectural forms like portals, arches, and rings.

## How It Works

1. **Shape selection**: Six polyhedra are available, each with different tessellation properties:
   - **Cube** -- the simplest space-filler, used to build a classic brick-arch portal with pillars
   - **Truncated Octahedron** -- the Voronoi cell of the BCC lattice, arranged in a honeycomb ring with arch
   - **Rhombic Dodecahedron** -- the Voronoi cell of the FCC lattice, stacked in rings with a dome cap
   - **Triangular Prism** -- arranged radially pointing outward in a ring
   - **Hexagonal Prism** -- concentric rings of hexagons for a honeycomb portal
   - **Gyrobifastigium** -- paired twisted triangular prisms in a ring
2. **Portal construction**: Each portal type arranges its blocks in a characteristic pattern -- arches, rings, domes, or radial fans. Transforms (position, rotation, scale) are stored in an array.
3. **Efficient rendering**: All blocks are rendered via a single `MultiMeshInstance3D` with the selected polyhedron mesh, using instanced transforms for high performance.
4. **Grid VR mode**: The `tessellating_portal_grid_vr.gd` script generates a 10x10 grid of all portal types with varying parameters for comparative viewing in VR.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `portal_type` | PortalType | CUBE | Which space-filling polyhedron to use |
| `portal_radius` | float | 3.0 | Radius of the portal arch/ring |
| `portal_thickness` | float | 1.5 | Depth of the portal structure |
| `block_size` | float | 0.5 | Scale of each tessellating block |
| `auto_generate` | bool | true | Generate on scene load |
| `portal_color` | Color | blue | Block color |
| `emission_strength` | float | 1.5 | Glow intensity |
| `animate_rotation` | bool | true | Slowly rotate the portal |
| `rotation_speed` | float | 0.5 | Rotation speed |

## Features

- **Six space-filling polyhedra** -- demonstrates which shapes tile 3D space and how they differ visually
- **MultiMesh instancing** -- all blocks rendered in one draw call for VR performance
- **Custom mesh generation** -- triangular prism, hexagonal prism, and approximations of truncated octahedron/rhombic dodecahedron built procedurally via SurfaceTool
- **VR grid display** -- 100-portal grid with per-portal color variation and type labels for comparative study
- **Demo controller** -- full UI with portal type selector, radius/thickness/block size sliders, color picker, randomize button

## Files

- `tessellating_portal.gd` -- Core generator: portal construction for 6 polyhedra types, mesh creation, MultiMesh rendering
- `portal_demo_controller.gd` -- Interactive demo with UI panel, camera orbit, randomization
- `tessellating_portal_grid_vr.gd` -- 10x10 grid generator for VR comparative viewing
- `tessellating_portal.tscn` -- Standalone artifact scene
- `tessellating_portal_demo.tscn` -- Interactive demo scene
- `tessellating_portal_grid_vr.tscn` -- VR grid scene
- `portal_showcase.tscn` -- Showcase scene
