# Poincare Disk

A visualization of the Poincare disk model of hyperbolic geometry. Demonstrates how parallel lines diverge and triangles have angle sums less than 180 degrees in negatively curved space.

## How It Works

The artifact renders a flat disk whose boundary circle represents infinity in hyperbolic space. Geodesics (the hyperbolic equivalent of straight lines) are drawn as circular arcs that meet the boundary at right angles. A hyperbolic triangle is overlaid to show that its interior angles sum to less than 180 degrees, a defining property of hyperbolic geometry. Geodesic lines pulse with animated opacity to draw attention to the curvature effects.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `disk_radius` | float | `0.4` |
| `line_count` | int | `8` |
| `show_triangle` | bool | `true` |
| `animate_geodesics` | bool | `true` |

## Features

- Boundary circle rendered as a glowing torus representing the "infinity" of hyperbolic space
- Configurable number of geodesic arcs drawn as circular arc line strips
- Hyperbolic triangle with curved geodesic edges and angle-sum annotation
- Animated opacity pulsing on geodesic lines
- Labels showing the model name and triangle angle deficiency

## Files

- `poincare_disk.gd` -- Main script
- `poincare_disk.tscn` -- Scene file
