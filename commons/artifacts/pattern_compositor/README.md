# Pattern Compositor

Renders a SpatialComposition as a grid of tiles, each with its own wallpaper group shader material. Zones receive distinct wallpaper groups, color palettes, and weathering/aging effects. Supports both rectangular and non-rectangular tilings.

## How It Works

The compositor builds a SpatialComposition from named presets (carpet, facade, mosaic, quilt, tunnel, or any art history preset) and renders each cell as a mesh with a unique `wallpaper_tile` ShaderMaterial. Each zone maps to specific wallpaper group, palette, seed, and tile scale settings defined in `ZONE_DEFAULTS`. For non-rectangular tilings (hex, polar, truchet, voronoi), it delegates mesh creation to the coordinate system. Web editor overrides from the Ada Encyclopedia can replace the domain, palette, group, and weathering parameters.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| preset_name | String | "carpet" |
| grid_width | int | 20 |
| grid_height | int | 20 |
| tile_size | float | 0.5 |
| surface | String | "floor" |
| emission_strength | float | 0.8 |
| tiling | String | "rect" |

## Features

- Multiple composition presets: carpet, facade, mosaic, quilt, tunnel, plus all art history presets
- All 17 wallpaper groups with 10 neon color palettes
- 8 procedural domain pattern generators (blocks, stripes, diagonal, cross, concentric, checker, scatter, stairs)
- Floor or wall surface orientation
- Non-rectangular tilings: hex, polar, truchet, voronoi
- Weathering effects: wear, dust, fade, cracks, stains, chipping
- Web editor integration with domain, palette, and group overrides from Ada Encyclopedia
- Automatic lighting scaled to grid extent

## Files

- `pattern_compositor.gd` -- Composition renderer with zone-based shader material assignment
- `pattern_compositor.tscn` -- Scene file
