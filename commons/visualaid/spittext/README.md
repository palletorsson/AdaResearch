# Spit Text 3D

A typewriter-style text display that reveals multiline text character by character with fade-in animations. Toggled on and off by a VR button press.

## How It Works

When triggered (via the configurable VR action or `_unhandled_input`), the script splits the exported `text` into lines and spawns each line as a Label3D with a staggered delay. Each line fades in over `fade_in_duration` while characters appear one at a time at `character_delay` intervals. Pressing the trigger again fades all lines out and frees them. The A button (`vr_button_a`) is also polled in `_process` for direct input detection.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `text` | String (multiline) | Three sample lines |
| `line_delay` | float | `1.0` |
| `character_delay` | float | `0.05` |
| `fade_in_duration` | float | `0.5` |
| `line_spacing` | float | `1.0` |
| `font_size` | int | `120` |
| `pixel_size` | float | `0.01` |
| `trigger_action` | StringName | `"vr_button_a"` |

## Features

- Character-by-character typewriter reveal per line
- Staggered line appearance with configurable delays
- Fade-in and fade-out animations via tweens
- Toggle on/off with VR button input
- Configurable font size, pixel size, and line spacing

## Files

- `spit_text_3d.gd` -- Typewriter animation logic with VR input handling
- `spit_text_3d.tscn` -- Scene with a base Label3D node
