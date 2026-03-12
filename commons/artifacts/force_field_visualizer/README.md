# Force Field Visualizer

Visualizes vector force fields as a grid of directional arrows, teaching how invisible fields like gravity and electrostatic forces have structure, magnitude, and direction at every point in space.

## How It Works

The artifact computes a field vector at each point on a 2D grid using one of four equations: uniform gravity, inverse-square point charge (Coulomb's law), dipole (superposition of two opposing charges), or vortex (tangential curl field). Each vector is rendered as a scaled, colored arrow via MultiMesh instancing. Arrow length encodes magnitude, orientation shows direction, and color indicates whether the field points outward (red) or inward (blue) relative to the source.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `field_size` | float | `0.8` |
| `grid_resolution` | int | `8` |
| `field_type` | FieldType enum | `POINT_CHARGE` |
| `field_strength` | float | `1.0` |
| `source_position` | Vector3 | `(0, 0, 0)` |
| `color_positive` | Color | `(1.0, 0.3, 0.3)` |
| `color_negative` | Color | `(0.3, 0.5, 1.0)` |
| `color_source` | Color | `(1.0, 0.8, 0.3)` |

## Features

- Four field types: gravity, point charge, dipole, and vortex
- VR control panel with type-selection buttons and a strength slider
- Arrows scale and recolor dynamically as parameters change
- Source markers glow at charge/vortex centers
- Keyboard shortcuts for quick field switching (1-4, Up/Down)

## Files

- `force_field_visualizer.gd` -- Main script
- `force_field_visualizer.tscn` -- Scene file
