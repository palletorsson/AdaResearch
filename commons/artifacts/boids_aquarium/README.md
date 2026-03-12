# Boids Aquarium

A flocking simulation inside a glass tank, demonstrating Craig Reynolds' Boids algorithm where complex group behavior emerges from three simple local rules: separation (avoid crowding), alignment (match neighbors' heading), and cohesion (steer toward flock center).

## How It Works

Each boid updates its velocity every frame by querying nearby neighbors within a perception radius using a spatial hash grid for efficient O(n) lookup. Three steering forces are computed -- separation pushes away from close neighbors, alignment averages neighbors' velocities, and cohesion steers toward the local center of mass. These weighted forces combine to produce naturalistic schooling behavior. Boids bounce off tank walls and orient their elongated mesh to face their velocity direction. A MultiMesh renders all boids in a single draw call with per-instance coloring.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `tank_size` | Vector3 | `Vector3(1.0, 1.0, 1.0)` |
| `boid_count` | int | `30` |
| `separation_weight` | float | `1.5` |
| `alignment_weight` | float | `1.0` |
| `cohesion_weight` | float | `1.5` |
| `max_speed` | float | `0.5` |
| `perception_radius` | float | `0.15` |
| `boid_size` | Vector3 | `Vector3(0.008, 0.008, 0.025)` |
| `boid_transparency` | float | `0.7` |
| `tank_transparency` | float | `0.15` |

## Features

- Spatial hash grid for efficient neighbor queries (3x3x3 cell neighborhood)
- VR sliders for separation, alignment, and cohesion weights
- Reset button to respawn boids with new random positions
- Glass tank with semi-transparent panels and metallic frame edges
- 8-color palette with per-boid hue variation
- Velocity-oriented elongated boid meshes
- Keyboard controls for parameter adjustment and reset

## Files

- `boids_aquarium.gd` -- Main script
- `boids_aquarium.tscn` -- Scene file
