# Stochastic Operations

A 3D visualization comparing four fundamental probability distributions side by side -- Uniform, Gaussian, Exponential, and Poisson. Each distribution is rendered as a column of sample spheres whose vertical positions represent sampled values, making abstract statistical concepts visually concrete.

## Concept Taught

Probability distributions are the mathematical language of randomness. Not all randomness is alike: a uniform distribution gives equal weight to all outcomes, a Gaussian (normal) distribution clusters around a mean, an exponential distribution models waiting times, and a Poisson distribution counts rare events. This artifact teaches these distinctions by letting learners compare the visual "shape" of each distribution -- how samples cluster, spread, and skew differently depending on the underlying mathematical model.

## How It Works

This scene uses the shared `RandomTransformations.gd` script, which manages four sub-visualizations via named child nodes. This scene provides the `StochasticOperations` child node.

1. **Four distribution columns** -- The visualization creates four groups, one for each distribution type: Uniform, Gaussian, Exponential, and Poisson.
2. **Sample generation** -- For each distribution, 20 samples are drawn:
   - **Uniform**: `randf()` -- values evenly distributed in [0, 1]
   - **Gaussian**: Box-Muller transform -- `sqrt(-2 * ln(u)) * sin(2 * pi * v)` produces normally distributed values
   - **Exponential**: Inverse transform -- `-ln(1 - u) / lambda` with lambda = 2.0
   - **Poisson**: Iterative multiplication -- counts random products until they fall below `exp(-lambda)` with lambda = 3.0
3. **Spatial mapping** -- Each sample becomes a `CSGSphere3D` placed at a position where X separates the distributions, Y encodes the sampled value (scaled by 4.0 and centered), and Z spreads the 20 samples front-to-back.
4. **Color coding** -- Each distribution column gets a unique hue via HSV color space (hue = column_index / 4), with emissive materials for visual clarity.
5. **Label boxes** -- Flat boxes below each column serve as visual anchors indicating the distribution type.
6. **Per-frame regeneration** -- New samples are drawn every frame, letting learners observe the characteristic patterns that each distribution produces repeatedly.

## Parameters

The script uses internal variables. Distribution parameters are hardcoded: exponential lambda = 2.0, Poisson lambda = 3.0, 20 samples per distribution.

## Features

- Four probability distributions visualized simultaneously
- Box-Muller transform for Gaussian sampling
- Inverse transform method for Exponential sampling
- Iterative algorithm for Poisson sampling
- HSV color coding distinguishes each distribution
- Vertical position encodes sample value for intuitive comparison
- Per-frame regeneration shows distribution characteristics over time
- Emissive materials for visual clarity

## Files

| File | Description |
|------|-------------|
| `stochastic_operations.tscn` | Scene file with camera, directional light, and `StochasticOperations` child node |
| `../RandomTransformations.gd` | Shared script managing all four random transformation sub-demos |
