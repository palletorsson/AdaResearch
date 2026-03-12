# Sine Wall Explanation

A 3D wall whose surface is displaced by a sine function, demonstrating how x = A * sin(f*z + t) creates wave-shaped geometry along a corridor. Teaches sinusoidal displacement as a building block for procedural level geometry.

## How It Works

The wall is constructed segment-by-segment using SurfaceTool. Each segment's x-position is offset by amplitude * sin(frequency * TAU * t + phase), where t is the normalized position along the wall length. Vertex colors vary by displacement intensity, brightening where the wave peaks. A sine curve line strip is drawn above the wall to show the mathematical function driving the shape. MultiMesh marker spheres at sample points display the current sine value, and an interactive VR slider lets learners adjust the frequency in real time to see how wave density changes the geometry.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `display_size` | float | 1.0 |
| `wall_height` | float | 0.5 |
| `wall_length` | float | 0.9 |
| `amplitude` | float | 0.12 |
| `frequency` | float | 2.0 |
| `wave_speed` | float | 0.4 |
| `animate` | bool | false |
| `wall_color` | Color | (0.8, 0.2, 0.3) |
| `value_color` | Color | (1.0, 1.0, 0.4) |
| `frequency_min` | float | 0.5 |
| `frequency_max` | float | 6.0 |

## Features

- Procedurally displaced wall surface with intensity-based coloring
- Sine curve overlay showing the mathematical function
- Value markers displaying the sine output at sample points
- VR frequency slider for interactive exploration
- Reference plane at x=0 showing the undisplaced centerline
- Optional animation with time-varying phase

## Files

- `sine_wall_explanation.gd` -- Main script
- `sine_wall_explanation.tscn` -- Scene file
