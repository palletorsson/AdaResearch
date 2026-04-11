# Instancing Scatter

A scene that scatters thousands of objects across a noise-deformed terrain using GPU-instanced `MultiMesh` rendering. Three categories of objects -- crystals, flowers, and floating particles -- are distributed by randomly sampling triangles on the terrain surface, demonstrating how noise-based terrain combined with random surface sampling creates organic, natural-looking environments.

This artifact teaches **surface scattering** -- the technique of distributing objects across a surface using random barycentric coordinate sampling. It also demonstrates how Perlin noise displacement transforms a flat plane into complex terrain, and how GPU instancing makes it feasible to render thousands of objects efficiently.

## How It Works

1. **Terrain Generation**: A `PlaneMesh` is subdivided into a 50x50 grid. Each vertex is displaced vertically by `FastNoiseLite` Perlin noise, creating hills and valleys. Normals are recalculated per-triangle for correct lighting. A `ConcavePolygonShape3D` collision shape is generated from the mesh faces.

2. **Scatter Point Sampling**: For each of the `instance_count` objects, a random triangle on the terrain is selected. Two random barycentric coordinates `r1, r2` are generated and folded into the triangle if their sum exceeds 1 (ensuring uniform distribution). The point and interpolated normal are stored.

3. **Crystal Instances**: One third of the instances are diamond-shaped crystals built from a custom `ArrayMesh` with 8 triangular faces. Crystals are placed above the terrain surface, aligned to the surface normal, with random scale (elongated vertically) and rotation. They use a glowing, semi-transparent material.

4. **Flower Instances**: Another third are procedural 5-petal flowers. Each petal is a triangulated quad fanning from the center. Flowers sit close to the terrain surface and receive random colorful materials.

5. **Particle Instances**: The final third are small glowing spheres floating above the terrain at random heights, creating a firefly-like ambient effect.

6. **Animation**: Crystals sway gently via a looping tween that applies a sinusoidal rotation. Particles float up and down with a sine wave and drift laterally, creating organic motion.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `instance_count` | int | 5000 | Total number of scattered objects (split evenly among 3 types) |
| `scatter_radius` | float | 20.0 | Half-width of the terrain plane |
| `animation_speed` | float | 1.0 | Speed multiplier for sway and float animations |
| `object_scale` | float | 0.3 | Base scale multiplier for all scattered objects |

## Features

- GPU-instanced rendering via `MultiMesh` for thousands of objects
- Perlin noise terrain displacement with per-face normal recalculation
- Uniform random surface sampling using barycentric coordinates
- Three object categories: crystals, flowers, and floating particles
- Custom `ArrayMesh` geometry for crystals (diamond shape) and flowers (5-petal)
- Animated crystal swaying and particle floating via tweens
- Terrain collision using `ConcavePolygonShape3D`
- Colored point lights (cyan, magenta, yellow, green) for atmospheric illumination
- Procedural sky material with dark background for contrast

## Files

| File | Description |
|------|-------------|
| `instancingscatter.gd` | Main script -- terrain, scatter sampling, MultiMesh instancing, animation |
| `instancingscatter.tscn` | Scene file |
