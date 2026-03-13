# McLeod-Inspired Procedural Compositions

Procedural 3D art compositions inspired by digital artists David McLeod and Alex McLeod. These artifacts demonstrate how randomness can be used to generate complex, visually rich scenes from simple geometric primitives -- teaching the concept that **procedural randomness applied to geometry can produce art-quality results**.

## How It Works

### mc_clould.gd -- Sphere Packing Composition

Builds a composition using **recursive sphere packing** with multiple material types (coral, chrome, glass, fur, striped). The algorithm:

1. Creates a palette of six materials -- coral, pink bubble, orange stripe, yellow fur, chrome, and glass -- each with distinct physical properties (roughness, metallic, refraction).
2. Spawns a configurable number of top-level clusters at random positions inside a bounding sphere.
3. Each cluster is assigned a random type (bubble, stripe, fur, glass, chrome) and recursively spawns sub-clusters up to a maximum recursion depth.
4. Bubble clusters fill a sphere with many small randomly sized and placed spheres. Fur objects generate thin cylinders radiating outward from a base shape. Glass and chrome objects pick random primitives (cube, sphere, cylinder) with random rotations.
5. Refractive glass panels are added throughout the composition as intersecting elements.
6. The entire composition gently rotates each frame.

Uniform distribution within a sphere is achieved using the cube-root method: `r = radius * pow(randf(), 1.0/3.0)`.

### mc_clould_2.gd -- Landscape Composition

Generates a miniature landscape with noise-displaced terrain, water, structures, and vegetation:

1. Terrain is a subdivided plane with FastNoiseLite-based vertex displacement using MeshDataTool.
2. Spiral/floral formations use capsule meshes arranged helically around a cylindrical core, with HSV-based color variation.
3. Crystal formations use PrismMesh with emissive, refractive materials.
4. Rock formations, trees (conical pine shapes), boats, a cabin with chimney/door/windows, and clouds are all placed using randomized positions and scales.
5. Fog, glow, and a physical sky material create an atmospheric, dreamlike look.

## Parameters

### mc_clould.gd

| Parameter | Default | Description |
|-----------|---------|-------------|
| `max_recursion_level` | 3 | Depth of recursive cluster generation |
| `sphere_cluster_count` | 5 | Number of top-level clusters |
| `main_composition_size` | 4.0 | Overall bounding size of the composition |
| `bubble_density` | 0.8 | Density multiplier for bubble clusters |
| `min_sphere_size` | 0.1 | Minimum sphere radius |
| `max_sphere_size` | 1.2 | Maximum sphere radius |

### mc_clould_2.gd

No exported parameters -- all values are internal constants (terrain size 50x50, 20 trees, 15 rocks, 8 clouds, 3 boats).

## Features

- Recursive procedural generation with depth-limited branching
- Six distinct material types with physically based properties (SSR, refraction, glow)
- Uniform random distribution inside a sphere (cube-root method)
- Noise-based terrain deformation using MeshDataTool
- HSV color cycling for organic variation
- Multi-light environment with directional, omni, and ambient sources

## Files

| File | Description |
|------|-------------|
| `mc_clould.gd` | Recursive sphere-packing art composition |
| `mc_clould_2.gd` | Procedural landscape with terrain, structures, and vegetation |
| `mc_clould.tscn` | Scene file for the sphere-packing composition |
| `mc_clould_2.tscn` | Scene file for the landscape composition |
