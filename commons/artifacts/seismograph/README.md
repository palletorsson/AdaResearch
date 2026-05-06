# Seismograph

A drum-type chart recorder inspired by classic scientific instruments. Simulates a rotating drum with paper and a pen arm that draws a continuous waveform trace, teaching signal recording, noise, and time-series visualization.

## How It Works

A cylindrical drum wrapped in paper rotates at a configurable speed while a pen arm draws a trace composed of a base sine wave, random noise, and occasional spike events. The trace data is stored as a scrolling array of samples: each update shifts existing data left and appends a new value. The trace line is rebuilt as a line-strip mesh on every update using a cached SurfaceTool. VR sliders allow real-time adjustment of noise intensity and wave frequency. The instrument housing includes decorative corner trim, a dark top panel, ventilation grilles, and end caps on the drum, all built procedurally.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `base_width` | float (0.2-1.5) | `0.6` |
| `base_depth` | float (0.1-1.0) | `0.4` |
| `base_height` | float (0.05-0.5) | `0.18` |
| `drum_radius` | float (0.03-0.3) | `0.12` |
| `drum_width` | float (0.05-0.4) | `0.18` |
| `base_color` | Color | `Color(0.76, 0.71, 0.63)` |
| `top_panel_color` | Color | `Color(0.15, 0.15, 0.17)` |
| `drum_color` | Color | `Color(0.25, 0.12, 0.12)` |
| `paper_color` | Color | `Color(0.95, 0.93, 0.88)` |
| `grid_color` | Color | `Color(0.6, 0.8, 0.7, 0.5)` |
| `trace_color` | Color | `Color(0.1, 0.5, 0.4)` |
| `drum_rotation_speed` | float (0.01-2.0) | `0.1` |
| `trace_frequency` | float (0.1-20.0) | `3.0` |
| `trace_amplitude` | float (0.001-0.1) | `0.02` |
| `noise_intensity` | float (0.0-2.0) | `0.5` |
| `auto_animate` | bool | `true` |

## Features

- Rotating drum with paper wrap and metallic end caps
- Pen arm assembly with housing, arm, and tapered tip
- Scrolling trace line combining sine wave, noise, and random spikes
- VR sliders for noise intensity and frequency control
- Decorative housing with corner trim cylinders and ventilation grilles
- Paper feed strip extending from the drum
- Public API for setting trace intensity and triggering seismic events
- Efficient rendering using MultiMesh for repeated geometry and cached SurfaceTool

## Files

- `seismograph.gd` -- Main script
- `seismograph.tscn` -- Scene file
