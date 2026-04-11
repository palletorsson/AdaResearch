# Long Cave -- Queer Marching Cubes Cave Generator

A procedural cave generator that uses the **marching cubes algorithm** to extract an isosurface from a layered 3D noise field, producing organic, bulgy cave geometry with a queer-coded color palette. The artifact teaches how marching cubes converts a scalar density field into triangle mesh geometry -- for each cube of 8 density samples, a lookup table maps the inside/outside classification (256 cases) to a set of triangles that approximate the isosurface.

## How It Works

### Density Field Generation
Four independent `FastNoiseLite` generators define the cave's scalar field:
- **Primary noise** (Simplex, low frequency) -- overall cave structure
- **Secondary noise** (Perlin, higher frequency) -- surface detail
- **Bulge noise** (Cellular/Voronoi) -- large-scale organic distortion that warps the sample positions before re-querying primary noise, creating bulgy protrusions
- **Cave carving noise** (Simplex, very low frequency) -- subtractive carving for passage variation

These are combined with a vertical bias (favoring horizontal passages), a distance-from-center boundary (keeping the cave contained), and the `bulginess` parameter that amplifies the cellular noise warp.

### Marching Cubes
The density field is sampled on a 3D grid at `resolution` spacing. For each cube:
1. An 8-bit `cube_index` is computed from the sign of (density - iso_level) at each corner.
2. The `edge_table` (256 entries of 12-bit masks) identifies which edges are intersected.
3. Edge intersection points are linearly interpolated between corner positions.
4. The `triangle_table` (256 entries) provides the triangle configurations.

### Coloring
Vertices are colored with a queer palette mixing pink, purple, and cyan based on noise variation, height ratio, and a white sparkle from the bulge noise. The cave mesh animates its emission energy and hue in `_process()`.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `cave_size` | Vector3 | (10, 6, 10) | Cave bounds in meters |
| `resolution` | float | 0.5 | Grid cell size in meters |
| `iso_level` | float | 0.0 | Isosurface threshold |
| `primary_noise_scale` | float | 0.15 | Primary noise frequency |
| `secondary_noise_scale` | float | 0.4 | Detail noise frequency |
| `bulginess` | float | 1.5 | Cellular distortion strength |
| `cave_density` | float | 0.3 | Cave carving noise weight |
| `vertical_bias` | float | 0.2 | Height-dependent density shift |
| `color_shift_speed` | float | 0.5 | Color animation speed |
| `pulse_intensity` | float | 0.3 | Emission pulse amplitude |

## Features

- Full marching cubes implementation with 256-entry edge and triangle lookup tables
- Four-layer noise field: primary structure, detail, cellular bulge warp, cave carving
- Queer color palette (pink/purple/cyan) with sparkle highlights
- Concave polygon collision shape for VR walkability
- Real-time emission pulsing and hue shifting animation
- Runtime parameter adjustment via `set_cave_parameters()` and `regenerate_cave()`
- Cave statistics via `get_cave_info()` (vertex count, triangle count, parameters)

## Files

- `QueerMarchingCave.gd` -- Complete marching cubes cave generator (class_name QueerMarchingCave)
