# Shader Noise Space -- Animated Noise Room

An immersive room-scale environment where walls and a central sphere are covered in animated procedural noise shaders. The artifact teaches how **shader parameters can be driven from GDScript** to create living, breathing visual spaces -- time scale, cloud density, and color channels all cycle independently.

## How It Works

The script finds ShaderMaterial references on a room sphere (`RoomContainer/MainRoomBody/RoomShape`) and wall panels (`WallsContainer/FrontWall`), stores their original parameter values, and then continuously modulates them in `_process()`.

Three independent animation clocks drive the system:
- **base_time** -- advances at `animation_speed`, fed directly to the shader's `time` uniform and used to modulate `time_scale` via sine waves.
- **color_cycle_time** -- shifts `base_pink`, `deep_pink`, and `pink_intensity` through sinusoidal color cycling on each RGB channel independently.
- **density_cycle_time** -- oscillates `cloud_density` to make the noise patterns swell and contract.

Walls animate at 70% of the room sphere speed and use cosine offsets instead of sine to keep them visually distinct.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `animation_enabled` | bool | true | Master on/off toggle |
| `animation_speed` | float | 1.0 | Global time multiplier |
| `time_scale_variation` | float | 0.5 | How much `time_scale` oscillates |
| `color_cycling` | bool | true | Enable hue shifting |
| `color_cycle_speed` | float | 0.3 | Speed of color cycling |
| `cloud_density_animation` | bool | true | Enable density pulsing |
| `density_variation` | float | 0.5 | Amplitude of density oscillation |

## Features

- Dual-material animation system (room sphere + walls) with independent timing
- Per-channel RGB color cycling with clamped output
- Runtime toggling via keyboard (Space to pause, Escape to reset)
- Original parameter snapshot and restoration
- Public API: `set_animation_speed()`, `set_color_cycling()`, `get_animation_info()`

## Files

- `noiseroom.gd` -- Animation controller for shader parameters
