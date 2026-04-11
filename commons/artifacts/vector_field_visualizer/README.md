# Vector Field Visualizer

Displays a 3D vector field as a grid of arrow glyphs, where each arrow's direction and length represent the field value at that point. Supports four field modes -- vortex, source, sink, and dipole -- to illustrate how vector fields describe flow, divergence, and curl in physical systems.

## How It Works

A 3D grid of sample points is evaluated against one of four analytical field functions. At each point, the field vector is computed, and an arrow glyph is drawn using ImmediateMesh line primitives (shaft plus two arrowhead lines). Arrow length is proportional to field magnitude (clamped to prevent overlap), and color maps from blue (slow) through cyan, green, and yellow to red (fast) based on magnitude. The entire field is rebuilt as a single mesh for efficient rendering.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `grid_x` | int | 8 |
| `grid_y` | int | 4 |
| `grid_z` | int | 8 |
| `grid_spacing` | float | 0.12 |
| `arrow_scale` | float | 0.04 |
| `field_mode` | int | 0 (Vortex) |

## Features

- 4 field modes: Vortex (tangential flow), Source (radial outward), Sink (radial inward), Dipole (two opposite charges)
- Magnitude-to-color mapping across a blue-cyan-green-yellow-red spectrum
- Analytical field equations displayed as labels
- Grid config integration for field_mode, grid_spacing, and arrow_scale
- Single ImmediateMesh draw call for the entire arrow grid

## Files

- `vector_field_visualizer.gd` -- Main script
- `vector_field_visualizer.tscn` -- Scene file
