# Water Flowers

Grid system wrapper for the WaterFlowers physics simulation, featuring floating flowers on Gerstner wave water.

## How It Works

The artifact instantiates the standalone water flowers scene from `algorithms/physicssimulation/waterflowers/waterflowers.tscn` and exposes its parameters through `apply_grid_config()`. The underlying simulation handles Gerstner wave physics and flower drift behavior.

## Features

- Wraps the WaterFlowers physics simulation for grid system placement
- Configurable flower count, water size, and wave strength
- Adjustable animation speed and flower drift speed
- Supports `apply_grid_config()` for map JSON configuration

## Files

- `water_flowers.gd` -- Grid wrapper that instantiates and configures the water flowers scene
- `water_flowers.tscn` -- Scene file
