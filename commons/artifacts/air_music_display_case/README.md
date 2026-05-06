# Air Music Display Case

A miniature glass museum display case with dark walnut wood frame containing the Air Music spatial audio system. Inspired by Scandinavian minimalist design, it presents generative FM synthesis music as a curated gallery object.

## How It Works

The display case uses a cube_lines frame scaled to 0.5m with a wooden platform base. Inside, a scaled-down Air Music system generates ambient FM piano notes triggered by spatial proximity. The audio is attenuated and the intensity cycle slowed for a subtle ambient effect. A VR volume slider below the case lets the user adjust loudness from -40 dB to 0 dB.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `case_scale` | float | `0.5` |
| `frame_color` | Color | `Color(0.25, 0.15, 0.08)` |
| `frame_thickness` | float | `0.02` |
| `base_height` | float | `0.04` |
| `audio_volume_db` | float | `-12.0` |
| `inner_scale` | float | `0.35` |

## Features

- Dark walnut wood frame with configurable thickness and color
- Wooden base platform with slight overhang for display pedestal look
- Embedded Air Music generative audio system scaled to fit inside
- VR volume slider for real-time audio level control
- Auto-removal of internal labels and cameras for clean display presentation
- Grid configuration support via `apply_grid_config()`

## Files

- `air_music_display_case.gd` -- Main script
- `air_music_display_case.tscn` -- Scene file
