# Worley Noise

Generates and displays Worley (cellular) noise on a floor panel, producing Voronoi-like cell patterns. Teaches the concept of distance-based procedural noise where texture is derived from proximity to randomly scattered seed points, complementing Perlin and Simplex noise approaches.

## How It Works

A set of random seed points is scattered across a 2D domain. For every pixel, the algorithm computes the distance to the nearest seed (F1) and the second-nearest seed (F2). The rendered value is F2 - F1, which is small near cell boundaries (where two seeds are roughly equidistant) and large at cell centers (where one seed dominates). This produces the characteristic bright-edged cell structure. A square-root gamma curve is applied before color mapping to enhance the visibility of cell boundaries. The result is written to an Image texture and displayed on a floor-facing QuadMesh with nearest-neighbor filtering.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `quad_size` | Vector2 | (0.8, 0.8) |
| `num_seeds` | int | 30 |
| `seed_value` | int | 42 |

## Features

- F1/F2 distance computation for classic Worley (cellular) noise
- Square-root gamma correction for enhanced cell boundary visibility
- Configurable seed count and random seed for repeatable patterns
- Nearest-neighbor texture filtering for a crisp procedural look
- Blue-to-white color gradient from cell interiors to edges

## Files

- `worley_noise.gd` -- Main script
- `worley_noise.tscn` -- Scene file
