# Sound Box

An interactive VR sound pad that teaches **audio triggering** and **collection-based sound design** by presenting a grid of coloured buttons that play sounds from a JSON-defined collection. Designed for hands-on exploration of synthesised audio in VR.

## How It Works

**SoundBox** loads a JSON collection file that defines a set of sounds with IDs, labels, and colours. It spawns a grid of `SoundTriggerButton` instances positioned in 3D space according to configurable column layout and spacing. Each button is wired to trigger its associated sound through the global `SoundBank` autoload.

**SoundTriggerButton** is a VR-interactive button built on `StaticBody3D`. When a VR controller pointer hovers over the button, a progress timer fills (configurable dwell time, default 0.2s for fast jamming). On completion, the button emits a `triggered` signal with its sound ID. The button provides haptic feedback on hover and trigger, visual scaling animations, and a shader-based progress indicator.

The SoundBox supports 12+ collection shorthands (synthetic, retro, sci-fi, drums, sacred, noir, etc.) mapped to JSON files in the audio collections folder. It also accepts direct configuration from the map JSON grid system via the `configure()` method.

## Parameters

### SoundBox
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `collection_path` | String (file) | synthetic_suite.json | Path to the JSON sound collection |
| `button_scene` | PackedScene | SoundTriggerButton.tscn | Scene used for each button |
| `spacing` | float | 0.5 | Distance between buttons in the grid |

### SoundTriggerButton
| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `sound_id` | String | detection_sound | ID of the sound to trigger |
| `text` | String | "Sound" | Label displayed on the button |
| `color` | Color | magenta | Button colour |
| `hover_time_required` | float | 0.2 | Seconds of hover needed to trigger |

## Features

- JSON-driven sound collection loading with 12+ shorthand aliases
- VR pointer interaction with hover-to-trigger dwell time
- Haptic feedback on both hover entry and sound trigger
- Visual feedback: scale animation, colour inversion, progress indicator
- 3D spatial audio playback via `AudioStreamPlayer3D`
- Grid system integration through `configure()` method
- Support for position, rotation, and scale overrides from map data
- "Stop All" button support for clearing active sounds

## Files

| File | Description |
|------|-------------|
| `SoundBox.gd` | Collection loader, grid layout manager, and audio playback controller |
| `SoundTriggerButton.gd` | VR-interactive button with hover detection, haptics, and progress display |
