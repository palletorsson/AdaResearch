# Static Reference Cube

A motionless cube that serves as a baseline reference for an oscillation progression sequence. Teaches the concept that stillness provides the perceptual anchor needed to recognize and understand motion -- "without stillness, we cannot perceive motion."

## How It Works

The artifact instantiates a standard cube primitive scene and positions it above a translucent ground marker. The cube remains completely stationary (y = 0 at all times), providing a visual constant that contrasts with animated oscillating cubes in the same sequence. The formula label "y = 0" reinforces that position is unchanging. The cube's shader material can be color-customized via wireframe, emission, and model color parameters.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `cube_size` | float | 0.3 |
| `cube_color` | Color | (0.3, 0.5, 0.8) |
| `show_ground_marker` | bool | true |
| `show_label` | bool | true |

## Features

- Stationary reference point for motion perception sequences
- Translucent cylindrical ground marker for spatial grounding
- Customizable cube color via shader parameters
- Public API: `get_position_value()` always returns 0.0

## Files

- `static_reference_cube.gd` -- Main script
- `static_reference_cube.tscn` -- Scene file
