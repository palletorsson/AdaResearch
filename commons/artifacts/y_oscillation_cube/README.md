# Y Oscillation Cube

Demonstrates simple harmonic motion by oscillating a cube up and down along the Y axis according to y = A * sin(omega * t). Teaches how the sine function maps continuous time to periodic vertical displacement, forming the basis of wave and oscillation concepts.

## How It Works

Each frame, the elapsed time is fed into the formula y = A * sin(2 * pi * f * t), where A is the amplitude and f is the frequency. The cube's Y position is offset from its base rest height by this value, producing smooth up-and-down oscillation. A vertical rail with colored markers shows the amplitude bounds. Ghost trail cubes rendered with the Grid shader track recent positions to visualize the motion history. The cube's wireframe color shifts dynamically based on the current sine value -- greener at the top, bluer at the bottom -- providing immediate visual feedback of the oscillation phase.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `cube_size` | float | 0.15 |
| `amplitude` | float | 0.2 |
| `frequency` | float | 1.0 |
| `cube_color` | Color | Teal green (0.2, 0.8, 0.5) |
| `show_rail` | bool | true |
| `show_trail` | bool | true |
| `trail_count` | int | 5 |

## Features

- Real-time sinusoidal oscillation with configurable amplitude and frequency
- Grid shader wireframe rendering on the cube and ghost trails
- Vertical rail with top (green) and bottom (red) amplitude markers
- Ghost trail cubes showing recent position history with fading transparency
- Live labels displaying time, sin(omega*t), and current Y offset
- Formula label showing y = A * sin(omega*t)
- Dynamic color feedback: wireframe and emission intensity vary with sine phase
- Public API: `set_amplitude()`, `set_frequency()`, `get_current_y()`, `get_sin_value()`, `reset()`

## Files

- `y_oscillation_cube.gd` -- Main script
- `y_oscillation_cube.tscn` -- Scene file
