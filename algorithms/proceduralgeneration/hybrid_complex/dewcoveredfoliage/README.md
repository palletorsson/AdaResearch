# Dew-Covered Foliage

A procedural garden scene generator that creates clusters of leaves with realistic water droplets, demonstrating how combining simple geometric primitives (flattened spheres, cylinders) with material properties (subsurface scattering, refraction, transparency) can produce naturalistic organic scenes. This artifact teaches procedural placement, material-driven realism, and how small details like dew droplets transform basic geometry into convincing natural environments.

## How It Works

1. **Leaf cluster placement**: `leaf_count` clusters are placed at random positions within `scene_radius`. Each cluster contains 2--4 leaves in a tight grouping.
2. **Leaf geometry**: Each leaf is a `SphereMesh` flattened to 5% of its radius in height, creating a thin disc. Size varies between `leaf_size_min` and `leaf_size_max`. Green hue is randomized per leaf for natural variation.
3. **Stems**: Each leaf gets a thin `CylinderMesh` stem positioned below it, with slight random tilt.
4. **Water droplets**: Each leaf receives 1 to `droplet_density * 10` droplets. Droplets are slightly elongated `SphereMesh` spheres (radius 0.02--0.08) positioned on the leaf surface.
5. **Materials**:
   - **Leaf material** -- green with subsurface scattering for light transmission, moderate roughness
   - **Droplet material** -- near-transparent with refraction, rim lighting, zero roughness for glassy appearance
   - **Stem material** -- dark green, high roughness
6. **Lighting**: A warm directional light simulates morning sun with shadows. An ambient green environment provides fill light.
7. **Animation**: Optional tween-based gentle swaying simulates wind effect on leaves.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `leaf_count` | int | 50 | Number of leaf clusters to generate |
| `droplet_density` | float | 0.3 | Approximate droplets per leaf (scaled x10) |
| `scene_radius` | float | 5.0 | Radius of the placement area |
| `leaf_size_min` | float | 0.5 | Minimum leaf radius |
| `leaf_size_max` | float | 1.2 | Maximum leaf radius |
| `generate_on_start` | bool | true | Auto-generate on scene load |

## Features

- **Procedural natural scene** -- demonstrates organic placement without authored assets
- **Material-driven realism** -- subsurface scattering on leaves, refraction and rim lighting on droplets
- **Cluster-based placement** -- leaves are grouped naturally rather than uniformly scattered
- **Scale variation** -- randomized leaf sizes, stem lengths, droplet counts, and color hues
- **Animated wind** -- tween-based sinusoidal rotation creates gentle swaying
- **Scene regeneration** -- press Space to regenerate with new random parameters
- **Public API** -- `set_leaf_count()`, `set_droplet_density()`, `set_scene_size()` for runtime adjustment

## Files

- `dewcoveredfoliage.gd` -- Complete scene generator: leaf/stem/droplet creation, material setup, lighting, animation
- `dewcoveredfoliage.tscn` -- Scene file
