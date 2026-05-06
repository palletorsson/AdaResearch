# Fabrics

A collection of GPU shaders that teach **procedural texture generation** -- specifically noise-based patterns that mimic real-world surfaces like textiles, stone, terrain, and organic cellular structures. Each shader runs entirely on the GPU and can be applied to any mesh (planes, spheres, boxes, tori) as demonstrated in the accompanying scene.

## How It Works

Four shaders explore different procedural techniques:

### Wallpaper (Textile)
Uses **simplex noise turbulence** to create fabric-like patterns. UV coordinates are mirrored at the midpoint (a wallpaper-group symmetry operation), then turbulence displaces them to produce an organic weave. Six octaves of absolute-value simplex noise are summed for the turbulence function. Three color layers (base, mid, dark) are blended using turbulence at different frequencies.

### Normal Stone
Generates a **height-field normal map** from multi-octave simplex noise (up to 8 octaves). The `level()` function sums noise at increasing frequencies with decreasing amplitude (standard fBm). The normal is computed by finite-difference sampling of the height field at neighboring UV offsets, then packed into 0--1 range for the normal map output. Optional vertex displacement pushes geometry along normals proportional to the height.

### Terrain
Builds a **biome-aware terrain** from the same simplex fBm height field. Elevation is classified into water, beach, land, and mountain zones using configurable thresholds. Each zone has its own albedo color, roughness, and metallic values. A foam effect appears near the shoreline using high-frequency noise. Vertex displacement creates actual 3D relief.

### Displacement (Cellular)
Implements **Voronoi / cellular noise** where each cell contains a random point that can be animated over time. Three displaced copies of the cellular pattern (shifted horizontally and vertically) are combined into RGB channels, creating a pulsing, amoeba-like surface. Optional vertex displacement and pattern-driven alpha transparency add depth.

## Parameters

### Wallpaper
| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `pattern_scale` | float | 5.0 | Tile repetition count |
| `turbulence_strength` | float | 0.5 | X-axis UV distortion |
| `turbulence_offset` | float | 0.2 | Y-axis UV distortion |
| `base_color` | vec3 | green | Primary color layer |
| `mid_color` | vec3 | orange | Mid-frequency color |
| `dark_color` | vec3 | dark red | Low-frequency color |
| `animate` | bool | true | Enable time-based animation |

### Normal Stone
| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `noise_scale` | float | 1.0 | Frequency multiplier |
| `height_scale` | float | 1.0 | Normal map intensity |
| `octaves` | int | 7 | Number of noise octaves |
| `displacement_strength` | float | 0.1 | Vertex push amount |

### Terrain
| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `water_level` | float | 0.4 | Elevation threshold for water |
| `terrain_height` | float | 1.0 | Overall height scale |
| `mountain_threshold` | float | 0.7 | Elevation where mountains begin |
| `beach_threshold` | float | 0.05 | Width of beach transition zone |
| `foam_intensity` | float | 0.3 | Shoreline foam brightness |
| `vertex_displacement` | float | 0.3 | Geometry relief strength |

### Displacement
| Uniform | Type | Default | Description |
|---------|------|---------|-------------|
| `cell_scale` | float | 5.0 | Cellular pattern density |
| `displacement_strength` | float | 0.5 | RGB channel offset |
| `animation_speed` | float | 1.0 | Cell point animation speed |
| `vertex_displacement` | float | 0.1 | Geometry push amount |
| `base_alpha` | float | 0.5 | Base transparency |

## Features

- Pure GPU -- all patterns are computed in shaders with zero CPU overhead.
- Simplex noise implementation (Ashima Arts) ported to Godot 4 spatial shaders.
- Voronoi / cellular noise with animated cell points.
- Multi-octave fractal Brownian motion (fBm) for natural terrain.
- Height-to-normal conversion via finite differences.
- Vertex displacement for true 3D surface relief.
- Biome classification with smooth transitions (water, beach, land, mountain).
- Edge-fade alpha and pattern-driven transparency in the displacement shader.
- Scene file demonstrates each shader on planes, boxes, spheres, and a torus.

## Files

| File | Purpose |
|------|---------|
| `wallpaper.gdshader` | Textile / wallpaper pattern using mirrored turbulence |
| `normalstone.gdshader` | fBm height field with computed normal map |
| `terrain.gdshader` | Biome-classified terrain with water, beach, land, mountain |
| `displacement.gdshader` | Animated cellular noise with RGB channel displacement |
| `fabrics.tscn` | Demo scene showing all shaders on various mesh shapes |
