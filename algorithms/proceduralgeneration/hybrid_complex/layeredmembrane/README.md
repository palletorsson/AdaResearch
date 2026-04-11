# Layered Membrane

A generator for organic, undulating membrane structures built from dozens of nested cylindrical layers with noise-driven surface deformation. This artifact teaches how layered procedural surfaces can create complex biological forms -- similar to cell membranes, geological strata, or coral formations -- by combining sinusoidal undulation, Perlin noise displacement, and gradient coloring across concentric layers.

## How It Works

1. **Layer generation**: `num_layers` concentric membrane surfaces are created. Each layer's radius decreases from outer to inner (100% to 50% of `radius`), and its height similarly decreases.
2. **Surface construction**: Each layer is built as a triangle mesh using `SurfaceTool`. Vertices are placed on a cylindrical grid (`radial_segments` around, `height_segments` up).
3. **Undulation**: Three overlapping sinusoidal waves deform the radius at each vertex:
   - `sin(angle*3 + height*5 + phase_offset)` -- primary wave
   - `sin(angle*5 + height*3 - phase_offset)` -- secondary wave
   - Perlin noise sampled at the vertex position -- tertiary organic variation
   The phase offset is unique per layer, so adjacent layers ripple differently.
4. **Height perturbation**: The Y position also receives sinusoidal and noise-based offsets, giving each layer a wavy top/bottom edge rather than flat caps.
5. **Color gradient**: Vertex colors interpolate from `inner_color` (purple) to `outer_color` (orange) based on layer index, with additional position-based noise for local variation.
6. **Material**: Each layer uses a `StandardMaterial3D` with subsurface scattering for translucency, slight transparency (alpha=0.9), vertex color albedo, and configurable roughness/metallic/specular.
7. **Environment**: A camera, directional main light, and bluish fill light are created automatically. A `WorldEnvironment` provides ambient lighting.
8. **Animation**: An optional rotation animation slowly spins the membrane container.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `radius` | float | 3.0 | Maximum outer radius |
| `height` | float | 2.5 | Maximum layer height |
| `num_layers` | int | 50 | Number of concentric membrane layers |
| `layer_thickness` | float | 0.02 | Thickness parameter (affects visual density) |
| `undulation_amount` | float | 0.8 | Intensity of sinusoidal surface deformation |
| `radial_segments` | int | 60 | Vertices around each layer's circumference |
| `height_segments` | int | 40 | Vertices along each layer's height |
| `inner_color` | Color | purple | Color of innermost layers |
| `outer_color` | Color | orange | Color of outermost layers |
| `surface_roughness` | float | 0.5 | Material roughness |
| `metallic` | float | 0.1 | Material metallic value |
| `specular` | float | 0.5 | Metallic specular value |
| `noise_influence` | float | 0.2 | How much Perlin noise affects surface deformation |

## Features

- **Concentric layered structure** -- 50 nested surfaces create a dense, organic cross-section effect
- **Triple undulation** -- sinusoidal waves at different frequencies plus Perlin noise produce complex, non-repeating surface detail
- **Per-layer phase offset** -- adjacent layers undulate out of phase, preventing visual uniformity
- **Subsurface scattering** -- translucent material simulates light passing through biological membranes
- **Gradient coloring** -- smooth color transition from inner to outer layers with noise-based local variation
- **Regeneration** -- `regenerate()` or press Space to create a new membrane with a fresh noise seed
- **Rotation animation** -- optional slow spin via AnimationPlayer for showcase viewing

## Files

- `layered_membrane.gd` -- Complete generator: layer mesh construction, undulation math, noise displacement, material setup, lighting, animation
- `layered_membrane.tscn` -- Scene file
