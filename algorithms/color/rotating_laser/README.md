# Rotating Laser

A concert-style laser rig that arranges beams in a configurable rows-by-columns array on overhead truss bars, demonstrating how array indexing drives synchronized animation patterns across many elements.

## How It Works

The script builds a grid of laser beams using a MultiMesh for high-performance instanced rendering. Each beam is a tapered cylinder mounted on a visible rig bar at a configurable height. Six animation patterns sweep the beams using each beam's normalized row/column position as input to trigonometric functions: Wave creates a traveling sine across the array, Focus converges all beams onto a moving floor point, Spread fans them outward, Scanning sweeps in synchronized phase, Chaos gives each beam independent motion, and SkyWalker produces a gentle sway. The beam color cycles through a green-white-pink sequence at a configurable interval. This teaches how a single mathematical function applied with different per-element parameters produces coordinated group behavior -- the core idea behind array-driven animation.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `array_rows` | int | 3 |
| `array_cols` | int | 12 |
| `array_spacing_x` | float | 1.2 |
| `array_spacing_z` | float | 3.0 |
| `rig_height` | float | 8.0 |
| `beam_length` | float | 15.0 |
| `beam_thickness` | float | 0.04 |
| `pattern_speed` | float | 1.0 |
| `pattern_amplitude` | float | 55.0 |
| `pattern_type` | enum | Wave (0) |
| `color_change_interval` | float | 10.0 |

## Features

- Six distinct beam animation patterns
- MultiMesh instanced rendering for performance
- Visible overhead rig bar geometry
- Cycling color sequence with configurable interval
- Tool mode support for in-editor preview

## Files

- `RotatingLaser.gd` -- Main script
- `RotatingLaser.tscn` -- Scene file
