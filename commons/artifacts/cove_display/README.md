# Cove Display

Cyclorama/infinity cove surface that accepts any shader. A flat floor transitions through a smooth curved cove into a vertical back wall, eliminating hard edges so shaders tile seamlessly across the entire surface.

## How It Works

The mesh is built with SurfaceTool in three continuous zones: a horizontal floor strip, a quarter-circle curved cove, and a vertical wall strip. UV coordinates are continuous from the floor front edge through the curve to the wall top, ensuring seamless shader tiling. The `apply_grid_config` method accepts a shader name (resolved from `commons/resourses/shaders/`) and passes all extra config keys as shader parameters. For the `wallpaper_tile` shader, a procedural domain texture is generated automatically.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| cove_width | float | 2.0 |
| floor_depth | float | 1.5 |
| wall_height | float | 2.0 |
| cove_radius | float | 0.4 |
| curve_segments | int | 12 |

## Features

- Generic display form that accepts any shader via config
- Seamless UV mapping across floor, curve, and wall
- Automatic domain texture generation for wallpaper_tile shader with 8 neon palettes
- Smart shader parameter type parsing (int, float, Vector3, string)
- Fallback to plain StandardMaterial3D with optional color
- Spot light automatically added for shader visibility
- Config syntax: `cove_display#shader:wallpaper_tile#tile_scale:6#wallpaper_group:5`

## Files

- `cove_display.gd` -- Cove mesh builder with shader integration and grid config support
- `cove_display.tscn` -- Scene file
