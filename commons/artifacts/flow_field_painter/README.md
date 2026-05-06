# Flow Field Painter

A Perlin noise flow-field particle system where hundreds of particles follow noise-derived gradients and leave colored trails, creating organic paint-like patterns that teach how structured randomness produces emergent visual order.

## How It Works

A FastNoiseLite Perlin noise field maps each 2D position (plus time) to a flow angle. Each frame, every particle samples the noise at its location, moves in the resulting direction, and appends its position to a trail buffer. Trails are rendered as colored line segments via ImmediateMesh, with optional alpha fading from oldest to newest. The noise field evolves continuously over time, producing ever-changing flow structures. Particles wrap around the canvas edges to maintain coverage.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `canvas_size` | Vector2 | `Vector2(0.6, 0.4)` |
| `num_particles` | int | `500` |
| `particle_speed` | float | `0.1` |
| `trail_length` | int | `50` |
| `trail_fade` | bool | `true` |
| `noise_scale` | float | `3.0` |
| `noise_speed` | float | `0.1` |
| `palette` | Array[Color] | 5-color palette (red, orange, cyan, green, purple) |

## Features

- Perlin noise flow field with configurable frequency and time evolution
- Hundreds of color-coded particles with fading trail histories
- VR sliders for noise scale and particle speed
- Push buttons to reset particles and generate a new noise seed
- Dark canvas with subtle frame edges (MultiMesh-based)
- Keyboard shortcuts for desktop use (R=reset, N=new seed, Up/Down=scale)
- Wrap-around particle boundaries for continuous coverage
- Grid system integration for all major parameters

## Files

- `flow_field_painter.gd` — Main script
- `flow_field_painter.tscn` — Scene file
