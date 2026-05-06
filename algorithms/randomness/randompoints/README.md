# Random Points

A multi-distribution point cloud artifact that generates 3D point sets using three different sampling strategies: Uniform, Gaussian (normal), and Blue Noise (Poisson disk). Each distribution produces visually distinct point arrangements, teaching learners how the same number of random points can look completely different depending on the underlying sampling algorithm.

## Concept Taught

Not all random point distributions are equal. Uniform sampling produces clusters and gaps (clumping). Gaussian sampling concentrates points near a center with sparse outliers. Blue noise (Poisson disk) sampling enforces a minimum distance between points, producing an even spread without visible patterns. This artifact teaches these three fundamental sampling strategies side by side, connecting to applications in Monte Carlo integration (uniform), statistical modeling (Gaussian), and anti-aliased rendering and texture synthesis (blue noise). The directory contains three scene variants -- one per distribution -- plus a combined script that auto-detects which distribution to use from the scene node name.

## How It Works

### Combined Script (`randompoints.gd`)

1. **Auto-detection** -- On `_ready()`, the script checks the node's name for keywords ("gaussian", "uniform", "blue", or the default "randompoints") to determine which distribution to use. This allows a single script to power all three scene variants.
2. **Point instantiation** -- The shared `grab_sphere_point_color_with_text.tscn` scene is used for each point, providing colored, labeled, grabbable spheres.
3. **Distribution implementations**:
   - **Uniform** (`_generate_uniform`) -- Each coordinate is drawn independently from `randf_range(-extent, extent)`, producing uncorrelated positions.
   - **Gaussian** (`_generate_gaussian`) -- Uses the Box-Muller transform: `z = sqrt(-2 * ln(u1)) * cos(2*pi*u2)` to generate normally distributed values. Each coordinate is scaled by `gaussian_std_fraction * extent` and clamped to bounds.
   - **Blue Noise** (`_generate_blue_noise`) -- Implements dart throwing: random candidates are tested against all existing points, and only accepted if the nearest neighbor is at least `blue_noise_min_dist` away. Each point gets up to 100 attempts; failed placements are silently dropped, which is characteristic of Poisson disk sampling at packing limits.

### Uniform-Only Script (`randompoints_uniform.gd`)

A simplified variant that only generates uniform points, with no distribution selection logic. It serves as the most basic point cloud generator.

## Parameters

### Combined script (`randompoints.gd`)

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `distribution_type` | DistributionType | BLUE_NOISE | Which sampling algorithm to use |
| `num_points` | int | 30 | Number of points to generate |
| `area_size` | Vector3 | (1, 1, 1) | Size of the sampling volume |
| `gaussian_std_fraction` | float | 0.25 | Standard deviation as fraction of extent (Gaussian only) |
| `blue_noise_min_dist` | float | 0.25 | Minimum distance between points (Blue Noise only) |

### Uniform-only script (`randompoints_uniform.gd`)

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `num_points` | int | 30 | Number of points to generate |
| `area_size` | Vector3 | (1, 1, 1) | Size of the sampling volume |

## Features

- Three distribution modes: Uniform, Gaussian, and Blue Noise (Poisson disk)
- Auto-detection of distribution type from scene node name
- Box-Muller transform for Gaussian sampling
- Dart throwing algorithm for Blue Noise with configurable minimum distance
- Points use the shared grabbable sphere primitive with color and text
- Separate simplified script for uniform-only use cases
- Three `.tscn` scene variants for direct comparison

## Files

| File | Description |
|------|-------------|
| `randompoints.gd` | Combined script with Uniform, Gaussian, and Blue Noise generation |
| `randompoints_uniform.gd` | Simplified script for uniform-only point generation |
| `randompoints.tscn` | Blue Noise (default) scene variant |
| `randompoints_gaussian.tscn` | Gaussian distribution scene variant |
| `randompoints_uniform.tscn` | Uniform distribution scene variant |
