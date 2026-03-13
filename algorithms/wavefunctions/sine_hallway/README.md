# Sine Hallway

An immersive walkthrough environment that teaches **sinusoidal wave functions** and **phase relationships** by filling a hallway with animated 3D tubes whose positions are governed by sine equations. Each tube traces a different sine curve through space, creating a dynamic tunnel of interlocking wave patterns.

## How It Works

The system creates a configurable number of tubes, each composed of many cylinder segments placed along the Z axis using `MultiMesh` for efficient instancing. Each tube's X and Y positions are calculated from sine functions:

- X position: `sin(z * frequency + phase)` scaled by the wave amplitude
- Y position: `sin(z * frequency * 0.7 + phase)` scaled by half amplitude, offset to hallway center

The `phase` for each tube is derived from its index (`i * 0.6`) plus a time-varying rotation offset, causing the tubes to appear to rotate and weave through one another as time progresses. The cylinder segments are oriented horizontally (rotated 90 degrees around X) and placed at each sample point along the Z axis.

A dark environment with glow post-processing makes the metallic, emissive tubes visually striking in VR.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `hallway_length` | float | 60.0 | Length of the hallway space |
| `hallway_width` | float | 12.0 | Width of the hallway |
| `hallway_height` | float | 12.0 | Height of the hallway |
| `tube_count` | int | 8 | Number of sine-wave tubes |
| `tube_length` | float | 80.0 | Z-axis span of each tube |
| `wave_amplitude` | float | 2.5 | Maximum lateral displacement |
| `wave_frequency` | float | 0.3 | Spatial frequency of the sine wave |
| `tube_radius` | float | 0.4 | Radius of each tube segment |
| `segment_spacing` | float | 1.0 | Distance between segment samples |
| `animate_tubes` | bool | true | Enable continuous animation |
| `rotation_speed` | float | 0.35 | Speed of phase rotation |
| `color_variants` | Array | 8 colors | Color palette for the tubes |

## Features

- Efficient `MultiMesh` instancing for hundreds of cylinder segments per tube
- Per-tube phase offset creating interlocking wave patterns
- Metallic materials with emission glow
- Dark environment with HDR glow post-processing
- Continuous animation driven by elapsed time

## Files

| File | Description |
|------|-------------|
| `hallway_scene.gd` | Complete sine hallway -- environment setup, MultiMesh tube generation, and animated updates |
