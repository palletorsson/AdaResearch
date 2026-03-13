# Water One

A realistic water surface simulation using a custom GLSL shader with multi-directional sine waves, Fresnel reflections, foam generation, and a real-time planar reflection system via SubViewport.

## Concept Taught

**Wave superposition and Fresnel reflections** -- how multiple sine waves with different directions, frequencies, and amplitudes combine to create a convincing water surface. The shader demonstrates the Fresnel effect (surfaces reflect more light at grazing angles), normal calculation via finite differences, and how a planar reflection camera mirrors the scene across the water plane.

## How It Works

1. A large `PlaneMesh` (default 50x50 units) is subdivided into a 150x150 grid for smooth vertex displacement.
2. The custom spatial shader displaces vertices using three layered sine waves, each with its own direction vector, amplitude, and speed. Normals are recalculated per-vertex using finite differences.
3. The fragment shader mixes shallow and deep water colors based on depth, applies a Fresnel-powered reflection blend, and adds foam on wave peaks using a threshold on the surface normal.
4. A `SubViewport` with a mirrored `Camera3D` renders the scene from below the water plane, producing a real-time reflection texture sampled in the shader.
5. The environment includes a procedural sky (for reflection content), directional sunlight with shadows, and subtle fog for atmosphere.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `water_size` | float | 50.0 | Side length of the water plane |
| `wave_height` | float | 1.2 | Maximum wave amplitude |
| `wave_speed` | float | 1.0 | Speed multiplier for wave animation |
| `reflection_quality` | float | 0.5 | Strength of reflection blending |
| `water_clarity` | float | 0.8 | Overall water transparency |

## Features

- Custom GLSL spatial shader with multi-wave vertex displacement
- Fresnel-based reflection with configurable power
- Dynamic foam on wave crests via normal-based threshold
- Real-time planar reflection using SubViewport and mirrored camera
- Procedural sky environment for reflection content
- Directional sunlight with shadows
- Subtle fog for atmospheric depth
- Optional environment objects (floating platforms, tall pillars) for reflection interest

## Files

| File | Description |
|------|-------------|
| `waterone.gd` | Water surface setup with shader, reflection system, sky, lighting, and environment objects |
