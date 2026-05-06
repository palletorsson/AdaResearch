# Sphere Colors

A 3D geometry that maps color spaces onto its surface, cycling through seven visualization modes to teach how colors are organized in mathematical spaces like RGB, HSV, and additive mixing.

## How It Works

The script generates various 3D shapes (icosphere, cube, cylinder, torus) via procedural mesh construction and maps colors onto vertices or scattered dot particles. An automatic slideshow cycles through seven color modes: Rainbow maps hue to angular position, HSV Sweep maps hue to vertical height, RGB Cube maps XYZ position to red-green-blue channels, Gradient blends two colors by distance, Random assigns noise colors, Pixel Grid places RGB sub-pixel triplets in a 3D lattice, and Additive Mixing shows three overlapping red-green-blue sphere clusters. Each mode uses a MultiMesh of small spheres for dot visualization or per-face color plates for solid geometry. The shape slowly rotates and pulses while color wave animations ripple across the surface.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `geometry_type` | String | "Icosphere" |
| `geometry_resolution` | int | 3 |
| `geometry_scale` | float | 0.5 |
| `use_dots` | bool | true |
| `dot_count` | int | 2000 |
| `dot_size` | float | 0.03 |
| `color_mode` | String | "Rainbow" |
| `color_intensity` | float | 1.0 |
| `rotation_speed` | Vector3 | (0.2, 0.3, 0.1) |
| `slideshow_enabled` | bool | true |
| `slide_duration` | float | 8.0 |
| `emission_strength` | float | 0.3 |

## Features

- Seven color mapping modes with automatic slideshow
- Procedural icosphere, cube, cylinder, and torus generation
- Dot mode (MultiMesh particles) and plate mode (per-face geometry)
- Additive RGB mixing and pixel sub-pixel grid visualizations
- Animated rotation, pulsing scale, and color wave effects

## Files

- `spherecolors.gd` -- Main script
- `spherecolors.tscn` -- Scene file
