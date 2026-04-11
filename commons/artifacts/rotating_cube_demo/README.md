# Rotating Cube Demo

A continuously spinning cube that demonstrates the simplest form of rotational motion: constant angular velocity. Teaches the core update formula for rotation, where angle increases by angular velocity multiplied by delta time each frame.

## How It Works

Each frame, the current angle is incremented by the rotation speed (omega) times delta time, implementing the formula theta += omega * dt. The cube rotates around the Y axis, and a direction indicator arrow on the ground plane tracks the current angle. A ground-plane circle shows the rotation path. The real-time angle in degrees, angular velocity in radians per second, and frame delta are displayed alongside the formula label. A subtle color pulse on the cube wireframe shader varies with the rotation angle.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `cube_size` | float | `0.3` |
| `rotation_speed` | float | `1.5` |
| `cube_color` | Color | `Color(0.9, 0.6, 0.2)` |
| `show_labels` | bool | `true` |
| `show_trail` | bool | `true` |

## Features

- Constant angular velocity rotation with real-time angle display
- Ground-plane circle and direction arrow showing the rotation path
- Formula label displaying theta += omega * dt
- Wireframe cube shader with color pulse tied to rotation angle
- Public API for setting speed, getting angle, and resetting

## Files

- `rotating_cube_demo.gd` -- Main script
- `rotating_cube_demo.tscn` -- Scene file
