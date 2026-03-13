# Random Bell Curve

A 3D terrain artifact that builds a walkable surface shaped by the Gaussian (bell curve) distribution. A 20x20 quad grid is deformed so that vertex heights follow `h * exp(-distance^2 / sigma^2)`, creating a smooth mound that rises at the center and falls off symmetrically. Optional noise adds subtle surface variation, and the terrain can periodically regenerate with randomized parameters.

## Concept Taught

The Gaussian (normal) distribution is the most important probability distribution in statistics, appearing everywhere from measurement error to population heights to thermal fluctuations. Its characteristic bell shape -- peaked at the mean, falling off symmetrically, with most values within a few standard deviations -- defines the concept of "typical" variation. This artifact makes the bell curve physically tangible: learners can walk on it in VR and feel how the terrain rises steeply near the center and flattens at the edges, building spatial intuition for the shape that underlies so much of probability theory.

## How It Works

1. **Flat grid construction** -- On `_ready()`, a `(quads_x+1) x (quads_z+1)` vertex grid is built on the XZ plane, centered at the origin. UV coordinates are computed for texturing.
2. **Bell curve deformation** -- Each vertex's Y coordinate is set to `h * exp(-(dx^2 + dz^2) / s^2)`, where:
   - `h` = `height_scale * randf_range(0.8, 1.2)` -- randomized peak height
   - `s` = `spread * randf_range(0.8, 1.2)` -- randomized width
   - `dx`, `dz` = distance from center on each axis
3. **Optional noise** -- When `add_noise` is enabled, a small random offset (`noise_strength`, default 0.05) is added to the Z coordinate of each vertex, creating subtle surface irregularity.
4. **Mesh commit** -- A `SurfaceTool` builds the triangle mesh from the deformed vertices with auto-generated normals, and a `SimpleGrid` shader material is applied.
5. **Collision** -- A `HeightMapShape3D` is generated from the vertex heights and attached to a `StaticBody3D`, making the terrain walkable in VR with a slight downward offset for safe footing.
6. **Optional regeneration** -- When `randomize_on_ready` is true, the bell curve is regenerated every `update_interval` seconds with new random height and spread parameters, showing how the same distribution shape persists despite parameter variation.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `quads_x` | int | 20 | Number of quads along the X axis |
| `quads_z` | int | 20 | Number of quads along the Z axis |
| `cell_size` | float | 1.0 | Size of each grid cell |
| `height_scale` | float | 5.0 | Peak height of the bell curve (Y axis) |
| `spread` | float | 2.0 | Width parameter of the Gaussian |
| `randomize_on_ready` | bool | false | Whether to periodically regenerate |
| `update_interval` | float | 2.0 | Seconds between regenerations (if enabled) |
| `add_noise` | bool | true | Whether to add surface noise |
| `noise_strength` | float | 0.05 | Amplitude of surface noise |

## Features

- Walkable 3D terrain shaped by the Gaussian distribution
- HeightMapShape3D collision for VR traversal
- Randomized peak height and spread within +/- 20% of base values
- Optional subtle Z-axis surface noise for realism
- SimpleGrid shader material for visual grid lines
- Auto-generated normals for proper lighting
- Optional periodic regeneration to show distribution shape persistence
- Original vertex positions preserved for clean regeneration (no drift)

## Files

| File | Description |
|------|-------------|
| `RandomBellCurve.gd` | Main script -- grid construction, Gaussian deformation, collision, regeneration |
| `random_bell_curve.tscn` | Scene file |
