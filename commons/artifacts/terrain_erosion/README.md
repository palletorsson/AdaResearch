# Terrain Erosion

Simulates hydraulic erosion on a procedural heightmap, teaching how water flow shapes landscapes over time. The artifact generates island-like terrain using layered sine waves, then runs hundreds of virtual water droplets that carve valleys and deposit sediment along their paths.

## How It Works

A heightmap is generated using six octaves of layered sine and cosine waves with an edge falloff to create an island shape. Hydraulic erosion simulates individual water droplets that flow downhill following the terrain gradient (computed via bilinear interpolation). Each droplet picks up sediment when moving fast downhill (erosion) and deposits sediment when slowing down or moving uphill. The final terrain is rendered as an ImmediateMesh colored by altitude bands: water, beach, grass, forest, rock, and snow.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `terrain_size` | float | 0.8 |
| `grid_res` | int | 48 |
| `height_scale` | float | 0.25 |
| `droplet_count` | int | 800 |
| `droplet_lifetime` | int | 64 |
| `erosion_rate` | float | 0.3 |
| `deposition_rate` | float | 0.3 |
| `evaporation_rate` | float | 0.02 |
| `min_sediment_capacity` | float | 0.01 |
| `sediment_capacity_factor` | float | 4.0 |
| `inertia` | float | 0.3 |
| `gravity` | float | 4.0 |

## Features

- Procedural island heightmap using multi-octave sine-wave noise with radial falloff
- Particle-based hydraulic erosion with bilinear gradient sampling
- Altitude-band coloring: water (deep/shallow), beach, grass, forest, rock, snow
- Grid config integration for droplet_count, erosion_rate, and height_scale

## Files

- `terrain_erosion.gd` -- Main script
- `terrain_erosion.tscn` -- Scene file
