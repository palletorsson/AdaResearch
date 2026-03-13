# Water Flowers

A physics-driven scene that floats procedurally generated flowers on a Gerstner-wave water surface. Each flower is a `RigidBody3D` subject to spring-based buoyancy, wave-alignment torque, and drift currents -- creating a realistic floating behavior.

## Concept Taught

**Gerstner waves and buoyancy physics** -- how Gerstner wave functions produce more realistic water surfaces than simple sine waves (sharper crests, flatter troughs), and how floating objects can be coupled to a wave surface using spring-damper buoyancy and torque alignment. The GDScript water state function mirrors the shader math exactly, ensuring the CPU-side physics and GPU-side rendering agree on surface height and normal.

## How It Works

1. **Water Surface**: A subdivided `PlaneMesh` with a GLSL shader that sums four Gerstner wave components. Each wave has direction, frequency, amplitude, speed, and steepness parameters. The vertex shader calculates tangent and bitangent vectors for correct normals.

2. **Flower Generation**: 50 flowers (configurable) are created as `RigidBody3D` nodes with procedural `ArrayMesh` geometry. Six flower types are supported -- lotus, lily, rose, daisy, cherry blossom, and water lily -- each built from triangle fans with `SurfaceTool`.

3. **Buoyancy Physics** (in `_physics_process`):
   - `get_water_state_at_position()` replicates the shader's Gerstner math on CPU to get the exact water height and normal at any point.
   - A damped spring force (`F = -k * displacement - d * velocity`) pushes flowers toward the surface.
   - Torque aligns each flower's up vector to the local wave normal.
   - Drift currents give flowers a gentle circular motion with random perturbation.
   - Boundary forces keep flowers within the water area.

4. **Flower Shader**: A separate spatial shader adds gentle swaying motion and petal-shaped alpha masking with radial segments.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `flower_count` | int | 50 | Number of floating flowers |
| `water_size` | float | 30.0 | Side length of the water surface |
| `wave_strength` | float | 0.8 | Global amplitude multiplier for waves |
| `animation_speed` | float | 1.0 | Speed multiplier for wave animation |
| `flower_drift_speed` | float | 0.5 | Strength of lateral drift currents |

## Features

- Four-component Gerstner wave system with steepness control
- CPU-side wave state function matching GPU shader exactly
- Spring-damper buoyancy with configurable stiffness (25.0) and damping (3.0)
- Wave-normal alignment torque for realistic tilting
- Circular drift currents with random perturbation
- Six procedural flower mesh types built with SurfaceTool
- Emissive flower materials for visibility
- Procedural sky environment with warm sunlight
- Boundary containment forces

## Files

| File | Description |
|------|-------------|
| `waterflowers.gd` | Complete scene -- water shader, Gerstner math, flower meshes, buoyancy physics, and environment |
