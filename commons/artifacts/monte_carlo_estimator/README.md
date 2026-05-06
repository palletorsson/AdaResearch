# Monte Carlo Estimator

Estimates the value of pi using Monte Carlo integration by throwing random darts at a square dartboard with an inscribed circle. Demonstrates how randomness and the law of large numbers converge toward a precise mathematical constant.

## How It Works

Random points are placed uniformly within a unit square. Each point is tested against the inscribed unit circle: if x^2 + z^2 <= 1, it lands inside. The ratio of inside points to total points approximates pi/4, so pi is estimated as 4 * (inside / total). As more darts accumulate, the estimate converges toward the true value of pi, illustrating the law of large numbers and Monte Carlo sampling.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `board_size` | float | 0.5 |
| `darts_per_second` | float | 20.0 |
| `max_darts` | int | 2000 |
| `auto_throw` | bool | true |
| `color_inside` | Color | (0.3, 0.8, 1.0) |
| `color_outside` | Color | (1.0, 0.4, 0.3) |
| `color_circle` | Color | (0.8, 0.8, 0.8, 0.3) |

## Features

- GPU-instanced dart rendering via MultiMesh with per-instance color
- Real-time pi estimate display with accuracy-based color coding (green/yellow/red)
- VR control panel with speed slider and batch throw buttons (x1, x10, x100)
- Keyboard controls: Space (throw), C (clear), T (x10), H (x100)
- Inscribed circle overlay with translucent fill
- Grid-lined dartboard for spatial reference

## Files

- `monte_carlo_estimator.gd` — Main script
- `monte_carlo_estimator.tscn` — Scene file
