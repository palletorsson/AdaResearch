# Stigmergy Grid

A real-time ant pheromone simulation where agents deposit chemical trails on a grid, trails evaporate and diffuse over time, and ants steer toward the strongest pheromone signal. Teaches stigmergy -- indirect communication through environmental modification, a key mechanism behind swarm intelligence.

## How It Works

Ants move on a 2D grid, sensing pheromone concentrations at three positions ahead (left, center, right) and turning toward the strongest signal. Each ant deposits pheromone at its current cell, capped at a maximum concentration. After all ants move, pheromone values are processed through a diffusion step (3x3 blur kernel averaging neighbors) followed by multiplicative evaporation. The resulting pheromone grid is rendered as a texture on a floor-lying quad, with concentrations mapped to a color ramp from black through green, yellow, to white. Ants wrap around at grid boundaries, creating a toroidal environment.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `grid_size` | int | 64 |
| `world_size` | float | 0.8 |
| `num_ants` | int | 15 |
| `evaporation_rate` | float | 0.99 |
| `diffusion_rate` | float | 0.05 |
| `deposit_amount` | float | 1.0 |
| `sensor_distance` | float | 3.0 |
| `sensor_angle` | float | PI/6 (30 degrees) |
| `ant_speed` | float | 1.0 |
| `turn_speed` | float | 0.5 |

## Features

- Agent-based pheromone trail simulation at 30 fps
- Three-sensor steering model (left, ahead, right)
- Double-buffered diffusion with 3x3 blur kernel and evaporation decay
- Real-time pheromone-to-color texture rendering (black -> green -> yellow -> white)
- Toroidal grid boundaries with wrapping
- Configurable via grid config for ant count, evaporation, and sensor parameters

## Files

- `stigmergy_grid.gd` -- Main script
- `stigmergy_grid.tscn` -- Scene file
