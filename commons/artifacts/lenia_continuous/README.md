# Lenia Continuous

A continuous cellular automaton that produces smooth, lifelike organisms on a floor-mounted display. Lenia generalizes Conway's Game of Life by replacing discrete states and neighborhoods with continuous values and smooth kernel functions, demonstrating how simple rules can generate complex emergent behavior.

## How It Works

Each cell holds a continuous state in [0, 1]. At each time step, a ring-shaped kernel (a Gaussian bell curve at a specific radius) is convolved with the grid to measure local neighborhood density. A bell-curve growth function maps this convolution result to a growth rate between -1 and +1, which is then applied with a time step dt. The grid wraps toroidally. Initial conditions are seeded as random circular blobs. The result is displayed as a color-mapped texture where black represents empty space, blue represents low activity, and cyan represents high activity.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | 0.8 |
| `grid_size` | int | 64 |
| `step_interval` | float | 0.05 |
| `dt` | float | 0.1 |
| `kernel_radius` | int | 13 |
| `ring_mu` | float | 0.5 |
| `ring_sigma` | float | 0.15 |
| `growth_mu` | float | 0.135 |
| `growth_sigma` | float | 0.015 |

## Features

- Continuous-state cellular automaton with smooth kernel convolution
- Precomputed sparse kernel for efficient simulation
- Ring-shaped neighborhood with configurable radius, peak, and width
- Bell-curve growth function for smooth population dynamics
- Animated floor texture with black-to-blue-to-cyan color mapping
- Double-buffered grid for correct simultaneous updates
- Frame-skipping for performance optimization

## Files

- `lenia_continuous.gd` -- Main script
- `lenia_continuous.tscn` -- Scene file
