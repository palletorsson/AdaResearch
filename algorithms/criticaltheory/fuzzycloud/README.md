# Fuzzy Cloud -- Hairy Blob Sculpture

A procedural sculpture generator that creates clusters of sphere-shaped blobs covered in radiating hair strands, displayed in a gallery environment. The artifact demonstrates **point distribution on spheres**, **ImmediateMesh line rendering**, and **MultiMesh instancing** for high-density procedural geometry.

## Concept Taught

**Procedural sculpture and surface distribution algorithms.** The artifact teaches how to distribute thousands of points uniformly across a sphere using spherical coordinates (theta/phi parameterization), how to generate outward-radiating geometry from surface normals, and how different rendering strategies (ImmediateMesh lines, MultiMesh cylinders, GPU particles) trade off between visual quality and performance. The gallery setting connects computational geometry to contemporary art installation.

## How It Works

1. A cluster of `num_blobs` hairy blobs is generated within an ellipsoidal volume, with position validation to prevent overlap.
2. Each blob consists of a **core sphere** (`SphereMesh`) and a **hair layer**.
3. Hair strands are distributed uniformly on the sphere surface using uniform spherical sampling: `theta = randf() * TAU`, `phi = acos(2 * randf() - 1)`.
4. Each hair strand is a line from the sphere surface outward along the surface normal, with slight random endpoint perturbation.
5. Three alternative hair rendering methods are implemented:
   - **ImmediateMesh lines** (default) -- line primitives drawn directly
   - **MultiMesh cylinders** -- instanced thin cylinders oriented outward via computed Basis transforms
   - **GPU particles** -- particle system with sphere emission and high damping
6. A gallery room is constructed with floor, walls, ceiling, spotlights, and a `WorldEnvironment` with fog, SSAO, and filmic tonemapping.
7. The sculpture slowly rotates via a looping Tween for VR viewing interest.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `num_blobs` | int | 15 | Number of hairy blobs in the cluster |
| `blob_size_min` | float | 1.0 | Minimum blob sphere size |
| `blob_size_max` | float | 2.5 | Maximum blob sphere size |
| `hair_density` | int | 3000 | Hair strands per blob (multiplied by size) |
| `hair_length_min` | float | 0.3 | Minimum hair strand length |
| `hair_length_max` | float | 0.5 | Maximum hair strand length |
| `generate_on_ready` | bool | true | Auto-generate on scene load |
| `blob_color` | Color | off-white/cream | Core sphere color |
| `hair_color` | Color | slightly different cream | Hair strand color |
| `randomize_colors` | bool | true | Apply per-blob color variation |
| `color_variation` | float | 0.05 | Maximum color channel deviation |

## Features

- Uniform spherical point distribution for even hair coverage
- Three hair rendering implementations: ImmediateMesh, MultiMesh, GPU particles
- Gallery environment with spotlights, SSAO, fog, and filmic tonemapping
- Cluster position validation to prevent blob overlap
- Per-blob color randomization within configurable bounds
- VR-optimized material settings: double-sided rendering, depth draw always, subtle emission
- Slow rotation tween for dynamic viewing
- Scalable architecture -- hair density scales with blob size

## Files

- `fuzzy_cloud.gd` -- Sculpture generator with blob clustering, hair systems, gallery environment, and VR optimization
- `fuzzy_cloud.tscn` -- Scene file
