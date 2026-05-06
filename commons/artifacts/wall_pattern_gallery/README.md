# Wall Pattern Gallery

Overlays wallpaper group shader patterns on grid wall cubes in clusters, creating a tunnel-like gallery where each section showcases a different wallpaper group using GPU shaders.

## How It Works

The gallery finds GridSystem wall cubes and groups them by Z position. Each cluster of Z-rows is assigned a different wallpaper group from all 17 types. Thin BoxMesh overlays are placed on all six faces of each cube with the `wallpaper_tile` shader configured for that cluster's group. Ceiling cubes and patterned floor tiles are also generated to close the tunnel, and OmniLight3D nodes are placed at intervals for illumination.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `cluster_size` | int | 3 |
| `tile_scale` | float | 4.0 |
| `emission_strength` | float | 0.8 |
| `grout_width` | float | 0.02 |

## Features

- Showcases all 17 wallpaper groups in sequential clusters along the Z axis
- GPU shader-based patterns using the `wallpaper_tile` shader
- Per-cluster procedural domain textures with 8 neon palettes
- Overlays on all visible cube faces (front, back, left, right, top)
- Auto-generated ceiling and patterned floor tiles
- Interior tunnel lighting with spaced OmniLight3D nodes
- Supports `apply_grid_config()` for map JSON configuration

## Files

- `wall_pattern_gallery.gd` -- Gallery builder with shader material and tunnel generation
- `wall_pattern_gallery.tscn` -- Scene file
