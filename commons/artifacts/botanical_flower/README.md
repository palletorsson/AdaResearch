# Botanical Flower

Grid-system wrapper for the BotanicalFlower procedural flower generator. Instances the core botanical flower scene and exposes grid config for map-driven parameter control.

## How It Works

On ready, the artifact instantiates the `botanical_flower.tscn` scene from `commons/flora/`. When `apply_grid_config` is called, it translates grid config keys (petal count, length, width, curve, stem height, color hue, leaf count, symmetry, preset) into a configuration dictionary and forwards it to `BotanicalFlower.configure()` followed by `rebuild()`.

## Features

- Wraps the standalone BotanicalFlower generator for grid system placement
- Supports petal count, length, width, and curve parameters
- Stem height and leaf count control
- Color hue mapped to HSV color wheel
- Radial or bilateral symmetry selection
- Named preset support via BotanicalFlower's built-in species presets

## Files

- `botanical_flower.gd` -- Grid wrapper that forwards config to the BotanicalFlower generator
- `botanical_flower.tscn` -- Scene file
