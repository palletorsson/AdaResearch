# Strobe Lasers

A nightclub-style laser scanner that fans beams in a configurable arc with rapid strobe on/off cycling, teaching the relationship between frequency, timing, and persistence of vision.

## How It Works

The system distributes laser beams in a fan pattern around the Y axis using MultiMesh instanced rendering. Each beam is a cylinder rotated to point outward at evenly spaced angles within the configurable spread. A strobe timer toggles beam visibility at the set frequency (in Hz), creating the characteristic on/off flashing effect. The entire rig rotates continuously at a configurable speed. Rainbow mode cycles the beam hue over time using HSV color space, and an optional pulse speed modulates beam length via Z-axis scaling. A custom `laser_smoke.gdshader` with a noise texture adds volumetric atmosphere to the beams.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `beam_count` | int | 16 |
| `beam_length` | float | 20.0 |
| `beam_thickness` | float | 0.05 |
| `spread_angle_deg` | float | 120.0 |
| `rotation_speed` | float | 2.0 |
| `strobe_frequency` | float | 12.0 |
| `pulse_speed` | float | 0.0 |
| `laser_color` | Color | Green |
| `rainbow_mode` | bool | false |
| `rainbow_speed` | float | 0.5 |

## Features

- Configurable beam fan with adjustable spread angle
- Strobe frequency control in Hz
- Rainbow color cycling via HSV
- Custom shader with noise-based volumetric smoke effect
- MultiMesh rendering for performance
- Tool mode support for in-editor preview

## Files

- `strobe_lasers.gd` -- Main script
- `strobe_lasers.tscn` -- Scene file
- `laser_smoke.gdshader` -- Volumetric beam shader
