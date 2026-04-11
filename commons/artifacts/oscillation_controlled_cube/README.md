# Oscillation Controlled Cube

A cube whose position, rotation, and scale are driven in real-time by pendulum oscillation data, demonstrating how periodic signals can be mapped to visual transformations. Teaches the concept of signal mapping between oscillation parameters and spatial properties.

## How It Works

The cube connects to a ControlPendulum node and receives three oscillation parameters via the `oscillation_updated` signal: vertical offset, angular velocity, and amplitude. These are mapped to three independent cube transformations: the Y offset controls vertical translation, angular velocity drives continuous rotation speed, and amplitude modulates scale pulsing. Visual guide elements (a vertical rail, rotation arc, and mapping breakdown panel) show the live parameter-to-property mappings. When no pendulum is connected, a fallback sine-based animation demonstrates the behavior autonomously.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `cube_size` | float | 0.3 |
| `translation_scale` | float | 0.2 |
| `rotation_scale` | float | 2.0 |
| `scale_range` | Vector2 | (0.8, 1.2) |
| `show_guides` | bool | true |
| `cube_color` | Color | (0.2, 0.6, 0.9) |
| `pendulum_path` | NodePath | |

## Features

- Three-channel signal mapping: Y offset, angular velocity, and amplitude
- Visual guide overlays: vertical rail with markers, rotation arc, and mapping panel
- Real-time label showing current Y position, spin angle, and scale factor
- Color feedback that shifts hue based on oscillation intensity
- Automatic ControlPendulum discovery in parent node
- Fallback autonomous oscillation when no pendulum is connected

## Files

- `oscillation_controlled_cube.gd` — Main script
- `oscillation_controlled_cube.tscn` — Scene file
