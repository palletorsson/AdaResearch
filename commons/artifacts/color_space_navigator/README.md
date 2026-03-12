# Color Space Navigator

Displays a 3D RGB color cube alongside an optional HSV cylinder, letting users explore color as a navigable three-dimensional space. Teaches how different color models (RGB vs HSV) organize the same set of colors into fundamentally different geometric structures.

## How It Works

The RGB cube maps red, green, and blue channels to X, Y, and Z axes respectively. Eight corner spheres mark the primary and secondary colors (black, red, green, blue, yellow, cyan, magenta, white), wireframe edges outline the cube, and 500 random sample points fill the interior via MultiMesh. When `show_hsl_cylinder` is enabled, a companion HSV cylinder is drawn to the right, with hue mapped to angle, saturation to radius, and value to height. Both displays use unshaded vertex-colored materials with emission for vibrant visibility in VR.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `cube_size` | float | `0.7` |
| `sample_count` | int | `500` |
| `corner_radius` | float | `0.018` |
| `sample_radius` | float | `0.006` |
| `show_hsl_cylinder` | bool | `true` |

## Features

- 3D RGB cube with wireframe edges, labeled axes (R, G, B), and corner spheres
- 500 randomly sampled color points rendered via MultiMesh with emission glow
- Optional HSV cylinder with hue rings, vertical value stacks, and sample points
- Axis labels and title labels for both color models
- Grid config integration for dynamic resizing and toggling the HSV display

## Files

- `color_space_navigator.gd` -- Main script
- `color_space_navigator.tscn` -- Scene file
