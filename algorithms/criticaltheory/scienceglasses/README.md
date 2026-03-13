# Science Glasses -- Procedural Laboratory Glassware

A collection of procedurally generated laboratory glass tubes demonstrating **parametric helix generation**, **Perlin noise displacement**, **tube extrusion along curves**, and **Frenet frame computation**. The artifact creates four distinct glass apparatus: a spiral condenser coil, a noise-displaced wobbly tube, a DNA-style double helix, and a complete condenser assembly.

## Concept Taught

**Parametric curves and tube extrusion.** This artifact teaches how to generate geometry along mathematical curves by computing a local coordinate frame (tangent, normal, binormal -- the Frenet-Serret frame) at each point, then placing a ring of vertices in that frame to form a tube cross-section. It also demonstrates how Perlin noise can add organic irregularity to procedural shapes, and how combining multiple parametric primitives produces complex scientific apparatus.

## How It Works

1. **Spiral Tube**: A helix path is defined parametrically as `(cos(angle) * radius, t * height, sin(angle) * radius)`. At each point, the tangent vector is computed analytically, and a Frenet frame (tangent, normal, binormal) is derived to orient a ring of vertices that form the tube cross-section. Adjacent rings are connected with triangle pairs.
2. **Wobbly Tube**: A straight vertical tube path is displaced laterally by a sine wave (`wobbly_amplitude * sin(t * TAU * wobbly_frequency)`) plus Perlin noise from `FastNoiseLite`. The tube cross-section is a simple horizontal ring extruded along the Y axis.
3. **Double Helix**: Two helix strands are generated with a phase offset of PI, creating intertwined spirals. Connecting "rungs" are placed between the two strands at regular intervals using cylinder meshes oriented via `look_at`.
4. **Condenser Assembly**: A complete lab apparatus combining a straight outer jacket tube, an inner spiral condenser coil (scaled narrower), and horizontal inlet/outlet tubes.
5. All glass uses a transparent `StandardMaterial3D` with optional refraction. An inner liquid mesh (70% tube radius) is generated with emissive material when `show_liquid` is enabled.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `spiral_radius` | float | 0.3 | Helix coil radius |
| `spiral_height` | float | 1.0 | Total helix height |
| `spiral_turns` | int | 5 | Number of helix revolutions |
| `spiral_tube_radius` | float | 0.02 | Glass tube cross-section radius |
| `spiral_resolution` | int | 32 | Vertices per helix turn |
| `spiral_tube_sides` | int | 12 | Cross-section polygon sides |
| `wobbly_length` | float | 1.0 | Wobbly tube total length |
| `wobbly_tube_radius` | float | 0.025 | Wobbly tube cross-section radius |
| `wobbly_amplitude` | float | 0.1 | Sine wave displacement magnitude |
| `wobbly_frequency` | float | 3.0 | Sine wave oscillation count |
| `wobbly_resolution` | int | 64 | Vertices along wobbly tube length |
| `wobbly_noise_seed` | int | 0 | Perlin noise seed |
| `glass_color` | Color | pale blue (0.3 alpha) | Glass material color |
| `glass_roughness` | float | 0.0 | Glass surface roughness |
| `use_refraction` | bool | true | Enable glass refraction |
| `inner_liquid_color` | Color | green (0.6 alpha) | Liquid fill color |
| `show_liquid` | bool | true | Show inner liquid meshes |

## Features

- Frenet-Serret frame computation for proper tube orientation along curves
- Analytical tangent vectors for helix paths
- Perlin noise displacement via FastNoiseLite for organic tube wobble
- Double helix with connecting rungs (DNA-style)
- Condenser assembly combining multiple tube primitives
- Transparent glass material with optional refraction
- Inner liquid meshes at 70% tube radius with emissive glow
- Double-sided rendering for glass visibility from all angles
- All geometry generated via SurfaceTool with computed normals

## Files

- `science_glasses.gd` -- Parametric tube generator with four glass apparatus types
- `science_glasses.tscn` -- Scene file
