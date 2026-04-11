# Turing Pattern Generator

Simulates Gray-Scott reaction-diffusion to produce the self-organizing patterns described by Alan Turing's morphogenesis theory. Two virtual chemicals interact and diffuse across a 2D grid, spontaneously forming spots, stripes, mazes, and other organic structures depending on the feed and kill rate parameters.

## How It Works

The Gray-Scott model tracks two concentrations (U and V) on a toroidal grid. Each simulation step computes the discrete Laplacian of both fields using a 9-point stencil, then updates concentrations: U is fed from a reservoir and consumed by the reaction U*V*V, while V is produced by the reaction and removed at the kill rate. Small random seed regions of V initiate pattern growth. The result is rendered to an Image texture using a configurable color gradient and displayed on a flat quad with emission.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | 1.0 |
| `resolution` | int | 64 |
| `pattern_type` | int (enum) | 0 (Spots) |
| `steps_per_frame` | int | 4 |
| `auto_run` | bool | true |
| `color_gradient` | Gradient | cream-to-dark |
| `Du` | float | 0.16 |
| `Dv` | float | 0.08 |
| `feed` | float | 0.055 |
| `kill` | float | 0.062 |

## Features

- 6 pattern presets: Spots, Stripes, Maze, Mitosis, Coral, Waves
- VR sliders for preset selection, feed rate, and kill rate
- Reset button to re-seed the simulation
- Real-time texture rendering with configurable color gradient
- Toroidal boundary conditions (patterns wrap around edges)
- Keyboard shortcuts for preset switching, reset, and pause

## Files

- `turing_pattern_generator.gd` -- Main script
- `turing_pattern_generator.tscn` -- Scene file
