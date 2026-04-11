# Cave Generator

Generates procedural cave maps using cellular automaton smoothing and flood-fill connectivity analysis. Teaches the classic roguelike cave generation pipeline: random initialization, iterative smoothing, region detection, and entrance/exit placement.

## How It Works

The grid is initialized with roughly 45% walls at random. Multiple cellular automaton smoothing passes apply a neighbor-count threshold (the 4-5 rule) to organically shape cave walls. A flood-fill algorithm then identifies all connected floor regions, keeps only the largest one, and fills the rest with walls to guarantee reachability. The entrance (green) and exit (red) are placed at opposite extremes of the surviving region. The result is rendered to an image texture displayed on a horizontal quad.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | `0.8` |
| `grid_size` | int | `64` |
| `seed_value` | int | `42` |
| `wall_chance` | float | `0.45` |
| `smooth_passes` | int | `5` |
| `wall_threshold` | int | `5` |

## Features

- Cellular automaton cave generation with configurable wall density and smoothing
- Flood-fill connectivity analysis to guarantee a single traversable region
- Automatic entrance and exit placement at region extremes
- Nearest-neighbor texture filtering for crisp pixel-art rendering
- Grid config integration for dynamic reconfiguration from map data

## Files

- `cave_generator.gd` -- Main script
- `cave_generator.tscn` -- Scene file
