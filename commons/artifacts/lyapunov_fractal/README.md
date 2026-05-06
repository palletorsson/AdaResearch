# Lyapunov Fractal

A floor-mounted display of the Lyapunov exponent landscape for alternating logistic maps. This teaches the concept of Lyapunov exponents as a measure of chaos -- negative values indicate stable periodic orbits, positive values indicate chaotic behavior, and the boundary between them forms intricate fractal patterns.

## How It Works

For each pixel mapped to coordinates (a, b) in the parameter space [2, 4] x [2, 4], the logistic map x = r*x*(1-x) is iterated with r alternating between a and b in the pattern "AABB". After a warmup period of 50 iterations, the Lyapunov exponent is computed as the average of log|r*(1-2x)| over 200 iterations. The resulting exponent field is color-mapped: stable regions (negative exponent) appear in blue shades, chaotic regions (positive exponent) appear in yellow-to-red, and the boundary (near zero) renders as black, producing patterns that resemble alien calligraphy.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `quad_size` | Vector2 | (0.8, 0.8) |
| `seed_value` | int | 42 |

## Features

- Full Lyapunov exponent computation over a 128x128 parameter grid
- Alternating logistic map with configurable "AABB" sequence pattern
- Three-region color mapping: blue (stable), black (boundary), yellow-red (chaotic)
- 50-iteration warmup to discard transients, 200-iteration measurement
- Floor-lying quad display with nearest-neighbor texture filtering

## Files

- `lyapunov_fractal.gd` -- Main script
- `lyapunov_fractal.tscn` -- Scene file
