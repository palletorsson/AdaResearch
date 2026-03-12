# Coordinate System Switcher

Displays a single 3D point simultaneously in Cartesian, cylindrical, and spherical coordinates with color-coded axes, projection lines, and angle arcs. Teaches how the same spatial position is described differently across coordinate systems and how to convert between them.

## How It Works

The artifact draws XYZ axes (RGB-colored) with arrowheads and a ground-plane grid. A glowing white sphere marks the target point. Dashed projection lines show how Cartesian coordinates decompose the point onto axis planes. A yellow radial line and vertical segment illustrate the cylindrical representation (r, theta, z). A magenta line from the origin shows the spherical representation (rho, theta, phi) with polar and azimuthal arcs. Billboard labels display the numeric values for each system, and a formula reference shows the conversion equations.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `point_cartesian` | Vector3 | `(0.25, 0.3, 0.2)` |
| `axis_length` | float | `0.45` |
| `axis_thickness` | float | `0.003` |
| `arc_segments` | int | `32` |

## Features

- Three coordinate systems displayed simultaneously for one point
- Color-coded: Cartesian = RGB, cylindrical = yellow, spherical = magenta
- Dashed projection lines and angle arcs drawn with ImmediateMesh
- Billboard labels with numeric readouts for all three representations
- Conversion formula reference and color legend
- Dynamic point update via `set_point()` or grid config

## Files

- `coordinate_system_switcher.gd` -- Main script
- `coordinate_system_switcher.tscn` -- Scene file
