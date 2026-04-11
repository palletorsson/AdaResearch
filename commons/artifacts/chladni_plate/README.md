# Chladni Plate

Simulates a vibrating metal plate with sand particles that migrate to nodal lines, reproducing the classic Chladni figure experiment. Teaches standing wave modes and how eigenfrequencies create characteristic geometric patterns on 2D surfaces.

## How It Works

Particles are scattered across a square plate and driven by the Chladni equation: `cos(n*pi*x)*cos(m*pi*y) - cos(m*pi*x)*cos(n*pi*y)`. Each particle computes the local amplitude gradient and moves toward nodal lines where the amplitude is zero. Random jitter proportional to local amplitude simulates the vibration that shakes particles off anti-nodes. The mode pair (n, m) can auto-cycle through ten preset combinations that produce visually distinct patterns.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `plate_size` | float | `0.3` |
| `plate_thickness` | float | `0.005` |
| `num_particles` | int | `400` |
| `particle_size` | float | `0.003` |
| `particle_speed` | float | `0.5` |
| `particle_color` | Color | `(0.9, 0.85, 0.7)` |
| `mode_n` | int | `2` |
| `mode_m` | int | `3` |
| `vibration_frequency` | float | `1.0` |
| `vibration_amplitude` | float | `0.002` |
| `auto_cycle_modes` | bool | `true` |
| `mode_cycle_time` | float | `8.0` |
| `base_color` | Color | `(0.15, 0.15, 0.18)` |
| `plate_color` | Color | `(0.7, 0.7, 0.75)` |

## Features

- Real-time particle simulation of sand on a vibrating plate
- Classic Chladni equation with configurable (n, m) mode pairs
- Auto-cycling through ten preset modes with distinct nodal patterns
- MultiMesh rendering for efficient particle display
- Visible plate vibration animation synchronized to the frequency

## Files

- `chladni_plate.gd` -- Main script
- `chladni_plate.tscn` -- Scene file
