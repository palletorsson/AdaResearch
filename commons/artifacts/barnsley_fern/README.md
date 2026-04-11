# Barnsley Fern

Renders the classic Barnsley fern fractal using an iterated function system (IFS), demonstrating how four simple affine transformations with weighted probabilities produce a self-similar natural form from pure mathematics.

## How It Works

The algorithm iterates a point through four affine transforms chosen by weighted random probability: a stem contraction (1%), the main recursive frond (85%), a left leaflet rotation (7%), and a right leaflet rotation (7%). After 50,000 iterations, the visited points are plotted onto a 256x256 image with density-based coloring -- areas where more points overlap appear brighter, shifting from deep green to a lighter tip color. The texture is displayed on a floor-lying quad with nearest-neighbor filtering.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `quad_size` | Vector2 | `Vector2(0.6, 0.8)` |
| `num_points` | int | `50000` |

## Features

- Four weighted affine transforms producing the classic fern shape
- Density accumulation buffer with sqrt gamma for visibility
- Automatic bounding box calculation and aspect-preserving fit
- Configurable point count and RNG seed via grid configuration
- Floor-lying display with nearest-neighbor texture filtering

## Files

- `barnsley_fern.gd` -- Main script
- `barnsley_fern.tscn` -- Scene file
