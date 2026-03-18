# Wall Cove

Curved floor-to-wall transition artifact built with SurfaceTool. Creates a quarter-circle cove that blends from the floor plane up into the vertical wall surface, with continuous UVs so shaders tile seamlessly across the curve.

## How It Works

The mesh is built in three segments: a small floor lip, a high-resolution quarter-circle curve, and an optional vertical wall extension. UVs are continuous from floor front through the curve to wall top, allowing the `wallpaper_tile` shader (or any spatial shader) to tile without seams. When configured with the wallpaper_tile shader, a procedural 8x8 domain texture is generated from a seed-based palette system with six pattern types (blocks, stripes, diagonal, concentric, checker, cross).

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `cove_width` | float | 1.0 |
| `cove_radius` | float | 0.3 |
| `curve_segments` | int | 24 |
| `wall_extend` | float | 0.0 |

## Features

- SurfaceTool-built mesh with continuous UVs across the curved surface
- Supports arbitrary GPU shaders via grid config `shader` key
- Procedural domain texture generation with 8 neon color palettes
- Automatic shader parameter forwarding from grid config
- Fallback to StandardMaterial3D with color support
- Adds a SpotLight3D for shader visibility
- Tool script compatible for in-editor preview

## Files

- `wall_cove.gd` -- Cove mesh builder with shader and domain texture support
- `wall_cove.tscn` -- Scene file
