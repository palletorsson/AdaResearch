# Rejection Sampling Demo

A visual scatter plot demonstrating the accept/reject method for sampling from a target probability distribution. Teaches how uniform random proposals can be filtered to produce samples that follow an arbitrary distribution shape.

## How It Works

The artifact generates a large number of uniform random (x, y) points inside a bounding rectangle. A Gaussian bell curve is drawn as the target distribution. For each candidate point, if its y-coordinate falls below the curve at its x-position the sample is accepted (drawn green); otherwise it is rejected (drawn red). The resulting accepted points approximate the target distribution. An acceptance ratio is computed and displayed, showing the efficiency of the method. The entire plot is rendered as a procedural texture on a floor-facing quad.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `plot_size` | Vector2 | `Vector2(0.8, 0.8)` |
| `plot_resolution` | int | `256` |
| `num_samples` | int | `2000` |
| `seed_value` | int | `42` |

## Features

- Procedural 256x256 pixel plot rendered to an ImageTexture
- Gaussian target distribution curve drawn in yellow with filled area beneath
- Green accepted and red rejected sample dots
- Grid lines and axis markings for visual reference
- Acceptance ratio statistics label
- Configurable via `apply_grid_config` (sample count, seed, sigma, amplitude)

## Files

- `rejection_sampling_demo.gd` -- Main script
- `rejection_sampling_demo.tscn` -- Scene file
