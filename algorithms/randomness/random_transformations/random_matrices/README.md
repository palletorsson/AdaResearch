# Random Matrices

A 3D visualization that demonstrates random matrix concepts by rendering a 4x4 grid of bars whose heights and colors are determined by random values, with a pulsing sphere representing the matrix determinant. Random matrix theory is a branch of mathematics with deep connections to physics, statistics, and number theory.

## Concept Taught

Random matrices are matrices whose entries are random variables. They appear throughout mathematics and science -- in quantum physics (energy level spacing), wireless communications (channel capacity), machine learning (covariance estimation), and financial modeling (correlation structure). This artifact makes the abstract concept tangible by mapping matrix element values to physical bar heights and colors, letting learners see how a random matrix "looks" and how its structure changes over time.

## How It Works

This scene uses the shared `RandomTransformations.gd` script, which manages four sub-visualizations via named child nodes. This scene provides the `RandomMatrices` child node.

1. **Matrix element visualization** -- A 4x4 grid of `CSGBox3D` bars is created, each representing one matrix element. Each element receives a random value in [-1, 1].
2. **Height encoding** -- Bar height is `abs(value) * 2.0 + 0.1`, making magnitude visually obvious. The bar's Y position equals the raw value, so positive elements rise above the grid plane and negative elements sink below.
3. **Color coding** -- Positive values are colored green with green emission proportional to their magnitude. Negative values are colored red with red emission proportional to their absolute value. This binary color scheme provides immediate visual feedback on the sign structure of the matrix.
4. **Determinant indicator** -- A yellow emissive sphere floats above the matrix grid, pulsing in size via `0.5 + sin(time * 2) * 0.2`. It represents the matrix determinant concept -- the single scalar that captures key properties of the entire matrix.
5. **Per-frame regeneration** -- The entire visualization is rebuilt each frame with new random values, showing the inherent variability of random matrices.

## Parameters

The script uses internal variables rather than exports. The matrix is always 4x4, with element values drawn uniformly from [-1, 1].

## Features

- 4x4 grid of bars representing random matrix elements
- Height and position encode element magnitude and sign
- Green/red color scheme distinguishes positive from negative entries
- Emissive materials for visual clarity
- Pulsing determinant indicator sphere
- Per-frame random regeneration shows matrix variability
- Spatial layout on XZ plane with Y-axis representing value

## Files

| File | Description |
|------|-------------|
| `random_matrices.tscn` | Scene file with camera, directional light, and `RandomMatrices` child node |
| `../RandomTransformations.gd` | Shared script managing all four random transformation sub-demos |
