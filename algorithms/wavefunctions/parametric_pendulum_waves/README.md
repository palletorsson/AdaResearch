# Parametric Pendulum Waves

A physics simulation of the classic "pendulum wave" or "pendulum snake" demonstration that teaches **simple harmonic motion**, the relationship between **pendulum length and period**, and how **phase differences** create emergent wave patterns from independent oscillators.

## How It Works

An array of pendulums hangs from a horizontal bar, each with a carefully chosen length so that their natural periods form an arithmetic sequence. When all pendulums are released simultaneously from the same angle, they initially swing in unison but gradually fall out of phase, producing serpentine, diagonal, and chaotic-looking patterns before eventually returning to synchrony.

The period of each pendulum follows the formula `T = 2 * pi * sqrt(L / g)`. The system inverts this to calculate lengths: given a target recurrence time of 60 seconds and a range of oscillation counts (51 to 51 + N), each pendulum's length is computed as `L = (T / (2 * pi))^2 * g`. This guarantees that the fastest pendulum completes exactly N more oscillations than the slowest over the full cycle.

Physics integration uses Euler's method with the nonlinear equation `theta'' = -(g/L) * sin(theta)` (not the small-angle approximation), plus a configurable damping factor applied to angular velocity each step.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `num_pendulums` | int | 15 | Number of pendulums in the array |
| `pendulum_spacing` | float | 0.3 | Horizontal distance between pivot points |
| `base_height` | float | 2.5 | Height of the pivot bar above ground |
| `shortest_length` | float | 0.8 | Minimum allowed pendulum length |
| `longest_length` | float | 1.5 | Maximum allowed pendulum length |
| `length_profile` | String | "Linear" | Distribution curve for lengths |
| `gravity` | float | 9.8 | Gravitational acceleration |
| `damping` | float | 0.998 | Per-frame velocity damping (1.0 = no damping) |
| `bob_radius` | float | 0.08 | Radius of each pendulum bob |
| `rod_thickness` | float | 0.02 | Thickness of the pendulum rod |
| `trail_length` | int | 100 | Number of stored trail positions per bob |
| `color_by_index` | bool | true | Assign rainbow hues based on pendulum index |
| `auto_release` | bool | true | Release all pendulums on scene start |
| `release_angle` | float | 0.5 | Initial displacement angle in radians (~29 degrees) |

## Features

- Parametric length calculation from period-oscillation relationships
- Nonlinear pendulum physics (full `sin(theta)`, not small-angle)
- Rainbow-hued bobs with emissive glow
- Position trail history for visualizing sweep patterns
- `@tool` support for editor preview
- Public API: `reset()`, `get_bob_position(index)`, `get_wave_phase()`

## Files

| File | Description |
|------|-------------|
| `parametric_pendulum_waves.gd` | Complete pendulum wave simulation -- physics, visualization, and parametric length calculation |
