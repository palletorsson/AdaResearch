# Flow Field Painter

A Perlin noise flow-field particle system where particles follow noise-derived directions and leave colored trails, making repeated local sampling visible.

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
- `shared_field_lesson.gd` — Opt-in shared sampler lesson with field/arrow controls
- `wall_monitor.gd` — Independent wall display and standing controls

## Museum wall monitor

The Flow_Field hall uses `#lesson:shared_field#display:wall_monitor`. Its west-wall placement is cell (1,5), yaw 90 degrees, root height zero and scale one. A 4.8 × 3.2 metre screen replaces the tabletop in this placement. The local canvas, trails and arrows share one display transform; their sampling positions, update rule, 80 lesson particles and trail capacity are unchanged.

The screen spans heights 0.6–3.8 metres. A separate console keeps SCALE, SPEED, RESET, SEED, ARROWS and FIELD TIME around waist height. The original tabletop lesson remains available when the display metadata is absent. The canvas’s second coordinate maps down the wall screen after its display rotation; it is not a new simulation axis or a change to the field.
