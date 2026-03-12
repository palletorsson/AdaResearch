# Doppler Effect Demo

A real-time visualization of the Doppler effect where a moving wave source emits expanding ring wavefronts, demonstrating how motion compresses wavelengths ahead (blue shift) and stretches them behind (red shift).

## How It Works

A glowing source oscillates back and forth along the X axis, periodically emitting circular wave rings. Each ring stores its emission position and birth time, then expands outward at a constant wave speed from that fixed origin point. This naturally produces wavefront compression ahead of the source and stretching behind it. Ring segments are colored from blue (ahead/compressed) to red (behind/stretched) based on their angular direction. A stationary green observer marker displays the calculated observed frequency ratio using the Doppler formula.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `arena_size` | float | `0.8` |
| `source_speed` | float | `0.15` |
| `emit_interval` | float | `0.18` |
| `wave_expand_speed` | float | `0.25` |
| `max_rings` | int | `30` |
| `circle_segments` | int | `48` |
| `ring_max_radius` | float | `0.6` |
| `color_blue_shift` | Color | `Color(0.3, 0.5, 1.0)` |
| `color_neutral` | Color | `Color(0.8, 0.8, 0.8)` |
| `color_red_shift` | Color | `Color(1.0, 0.3, 0.2)` |
| `color_source` | Color | `Color(1.0, 0.8, 0.2)` |

## Features

- Oscillating wave source with expanding ring wavefronts
- Per-segment ring coloring showing blue/red shift based on direction
- Stationary observer with live frequency ratio display
- Automatic ring culling when radius exceeds maximum
- Labeled source and observer markers with billboard text
- Grid system integration for source speed, emit interval, and wave speed

## Files

- `doppler_effect_demo.gd` — Main script
- `doppler_effect_demo.tscn` — Scene file
