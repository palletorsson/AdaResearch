# Sine Space Explanation

A 3D wave surface demonstrating the topology of sine space, where the height at each point is computed as y = A * sin(f*x) * cos(f*z). Teaches how combining perpendicular sinusoidal functions creates a 2D wave terrain with peaks and valleys.

## How It Works

The surface is built using SurfaceTool by evaluating the function y = A * sin(f*x + phase) * cos(f*z + phase*0.7) over a regular grid. Triangles are generated for each grid cell with vertex colors mapped from the computed height -- blue in the troughs, the surface color at midpoints, and white at peaks. A wireframe overlay rendered as line primitives sits slightly above the solid surface for visual clarity. When animation is enabled, a time-varying phase parameter shifts the wave pattern continuously, and both the solid surface and wireframe are regenerated each frame.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | 1.0 |
| `grid_resolution` | int | 24 |
| `amplitude` | float | 0.12 |
| `frequency` | float | 1.5 |
| `wave_speed` | float | 0.3 |
| `animate` | bool | false |
| `surface_color` | Color | (0.2, 0.5, 0.8) |
| `wireframe_color` | Color | (0.4, 0.8, 1.0) |

## Features

- Procedural wave surface with height-based vertex coloring
- Wireframe overlay for seeing the mesh topology
- Optional real-time animation with time-varying phase
- Labeled X, Y, Z axes with formula display
- Public API: `set_amplitude()`, `set_frequency()`, `set_wave_speed()`

## Files

- `sine_space_explanation.gd` -- Main script
- `sine_space_explanation.tscn` -- Scene file
