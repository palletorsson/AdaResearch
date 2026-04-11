# Flocking Controls

An interactive boid flocking simulation with VR sliders for separation, alignment, cohesion, speed, and perception radius, teaching emergent swarm behavior from simple local rules.

## How It Works

Each boid evaluates three steering forces based on nearby neighbors within a perception radius: separation (steer away from close neighbors, inversely proportional to distance squared), alignment (match average neighbor velocity), and cohesion (steer toward average neighbor position). These weighted forces are summed into an acceleration that updates velocity each frame. Boids wrap around the boundaries for an open-air feel. One boid is highlighted with a torus ring and has its three force vectors drawn as colored arrows (red=separation, blue=alignment, green=cohesion), letting learners see exactly what drives each agent.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `boid_count` | int | `30` |
| `bounds` | Vector3 | `Vector3(0.8, 0.6, 0.8)` |
| `separation_weight` | float | `1.5` |
| `alignment_weight` | float | `1.0` |
| `cohesion_weight` | float | `1.5` |
| `max_speed` | float | `0.5` |
| `perception_radius` | float | `0.2` |

## Features

- GPU-instanced boids via MultiMesh with per-instance coloring
- Five VR sliders controlling separation, alignment, cohesion, speed, and perception radius
- Highlighted boid with visible force vectors (separation, alignment, cohesion)
- Wrap-around boundaries with wireframe box visualization
- Reset button to respawn all boids
- Live info label showing all current parameter values
- Minimum speed enforcement to prevent boid stalling
- Grid system integration for all flocking parameters

## Files

- `flocking_controls.gd` — Main script
- `flocking_controls.tscn` — Scene file
