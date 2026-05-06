# Homogeneous Coordinates

A visual explainer showing why 4x4 matrices are used for 3D transforms. Displays a color-coded matrix with its four functional regions -- rotation/scale, translation, projection, and the homogeneous w=1 scalar -- alongside an interactive 3D coordinate frame.

## How It Works

The artifact renders a 4x4 matrix with each region color-coded: the upper-left 3x3 block (blue) encodes rotation and scale, the rightmost column (green) holds translation, the bottom row (red) represents projection, and the bottom-right element (gray) is the homogeneous scalar w=1. A 3D coordinate frame with labeled axes and a translation arrow demonstrates the transform in action. A VR slider adjusts the frame scale to explore how transforms affect geometry.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `color_panel` | Color | (0.06, 0.06, 0.1) |
| `color_rotation` | Color | (0.3, 0.5, 1.0) |
| `color_translation` | Color | (0.3, 1.0, 0.5) |
| `color_projection` | Color | (1.0, 0.35, 0.35) |
| `color_homogeneous` | Color | (0.55, 0.55, 0.6) |
| `color_title` | Color | (0.92, 0.92, 0.97) |

## Features

- Color-coded 4x4 matrix with bracket notation and divider lines
- Point transform demonstration: [x, y, z, 1] -> M -> [x', y', z', 1]
- Interactive 3D coordinate frame with X, Y, Z axis labels
- Translation vector arrow visualization
- Four-item color legend explaining each matrix region
- VR slider for adjusting coordinate frame scale
- Insight label explaining why translation requires the fourth dimension

## Files

- `homogeneous_coordinates.gd` -- Main script
- `homogeneous_coordinates.tscn` -- Scene file
