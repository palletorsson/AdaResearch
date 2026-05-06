# Distribution Sampler

An interactive probability distribution visualizer that draws samples from Uniform, Gaussian, Poisson, or Exponential distributions and displays them as a falling-particle histogram with a theoretical PDF overlay, teaching the concept that randomness has structured shape.

## How It Works

Samples are drawn from the selected distribution using standard algorithms: direct `randf()` for uniform, Box-Muller transform for Gaussian, inverse transform for Poisson, and inverse CDF for exponential. Each sample spawns as a glowing sphere that falls from above the display and lands in its corresponding histogram bin. The bins are rendered efficiently as a MultiMesh, and a theoretical PDF curve is drawn via ImmediateMesh for comparison. Live statistics (sample count, mean, standard deviation) update each frame.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_width` | float | `0.6` |
| `display_height` | float | `0.4` |
| `num_bins` | int | `30` |
| `max_samples` | int | `1000` |
| `distribution` | DistType | `GAUSSIAN` |
| `gaussian_mean` | float | `0.5` |
| `gaussian_std` | float | `0.15` |
| `poisson_lambda` | float | `5.0` |
| `exponential_rate` | float | `3.0` |
| `samples_per_second` | float | `50.0` |
| `auto_sample` | bool | `true` |
| `color_bar` | Color | `Color(0.3, 0.7, 1.0)` |
| `color_theory` | Color | `Color(1.0, 0.5, 0.3, 0.6)` |
| `color_sample` | Color | `Color(1.0, 0.9, 0.3)` |

## Features

- Four distribution types: Uniform, Gaussian, Poisson, Exponential
- Animated falling-particle sampling with glowing markers
- GPU-instanced histogram bars via MultiMesh
- Theoretical PDF curve overlay for visual comparison
- VR push buttons for switching distributions and clearing data
- Live statistics display (n, mean, standard deviation)
- Keyboard shortcuts for desktop use (1-4 for distributions, Space to toggle, C to clear)

## Files

- `distribution_sampler.gd` — Main script
- `distribution_sampler.tscn` — Scene file
