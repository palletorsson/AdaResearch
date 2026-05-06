# Elliptic Surface

A dome-shaped surface demonstrating positive Gaussian curvature (K > 0), used alongside other curvature artifacts to teach the classification of geometric surfaces in non-Euclidean geometry.

## How It Works

A sphere mesh is positioned so that its upper hemisphere is prominently visible, simulating an elliptic surface where parallel lines converge. The sphere is offset downward by 30% of its radius to emphasize the dome shape above the ground plane. A label beneath the surface identifies it as having positive curvature (K > 0).

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `radius` | float | `0.4` |
| `resolution` | int | `24` |

## Features

- Sphere mesh presenting the upper hemisphere as a positively curved surface
- Configurable radius and mesh resolution
- Descriptive label identifying curvature type and sign
- Warm-toned material with slight metallic sheen

## Files

- `elliptic_surface.gd` — Main script
- `elliptic_surface.tscn` — Scene file
