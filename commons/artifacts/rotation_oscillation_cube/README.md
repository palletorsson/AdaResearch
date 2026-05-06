# Rotation Oscillation Cube

A cube that demonstrates both oscillating and continuous rotational motion, showing the parallel between sinusoidal oscillation and constant spin. Teaches how the same sine function maps to different physical behaviors depending on context.

## How It Works

In oscillating mode, the cube's Y-axis rotation follows theta = A * sin(omega * t), swinging back and forth within a bounded angular range. In continuous mode, it switches to theta += omega * dt, producing constant spin. A ground-plane arc indicator shows the rotation range, tick marks highlight the angular limits, and a directional arrow on the cube face tracks the current rotation. Real-time labels display time, angle, and either the sin(omega*t) value or angular velocity. A VR speed slider allows interactive frequency adjustment.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `cube_size` | float (0.05-2.0) | `0.3` |
| `amplitude_degrees` | float (1-180) | `45.0` |
| `frequency` | float (0.01-5.0) | `0.8` |
| `cube_color` | Color | `Color(0.8, 0.5, 0.2)` |
| `continuous_mode` | bool | `false` |
| `show_arc` | bool | `true` |
| `show_direction_arrow` | bool | `true` |

## Features

- Two rotation modes: sinusoidal oscillation and constant spin
- Ground-plane arc indicator with tick marks at angular limits
- Directional arrow on the cube face tracking rotation
- Formula label switching between theta = A * sin(omega*t) and theta += omega * dt
- Wireframe cube with intensity-based color feedback
- VR speed slider for real-time frequency control
- Public API for mode switching, amplitude, frequency, and reset

## Files

- `rotation_oscillation_cube.gd` -- Main script
- `rotation_oscillation_cube.tscn` -- Scene file
