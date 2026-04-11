# Color Spaces Floors

Two shader-driven floor scenes that display tiled color patterns, teaching how color checker charts and Truchet tile algorithms generate structured color grids.

## How It Works

Each scene creates a large box mesh with a collision body, textured by a custom shader. The **ColorCheckerFloor** uses the `ColorCheckerFloor.gdshader` to render a grid of calibration-style color swatches with configurable grout lines and tile rotation. The **ColorTruchetFloor** uses the `TruchetFloor.gdshader` to generate Truchet tiling patterns -- quarter-circle arc tiles that produce maze-like or woven designs depending on the mode. Both shaders compute color per-pixel on the GPU, so the patterns remain sharp at any viewing distance.

## Parameters

Shader parameters (ColorCheckerFloor):

| Parameter | Type | Default |
|-----------|------|---------|
| `tile_size` | float | 0.6 |
| `grout` | float | 0.06 |
| `preset` | int | 0 |
| `metallic` | float | 0.757 |
| `roughness` | float | 0.45 |

Shader parameters (ColorTruchetFloor):

| Parameter | Type | Default |
|-----------|------|---------|
| `tile_size` | float | 1.219 |
| `grout` | float | 0.085 |
| `truchet_mode` | int | 0 |
| `preset` | int | 0 |
| `metallic` | float | 0.97 |
| `roughness` | float | 0.45 |

## Features

- GPU-computed tiled patterns with no runtime GDScript
- Collision-enabled floors suitable for VR walkthroughs
- Configurable grout width, tile size, and color presets
- Two distinct pattern algorithms in separate scenes

## Files

- `colorcheckerfloor.tscn` -- Color checker floor scene (references `ColorCheckerFloor.gdshader`)
- `colortruchetfloor.tscn` -- Truchet tiling floor scene (references `TruchetFloor.gdshader`)
