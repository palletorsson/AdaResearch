# Art History Gallery

Walk-through exhibition of 20 art history composition presets rendered as floor tiles. Each composition is displayed with its own wallpaper group patterns and neon color palettes, inspired by Art to Eat installations.

## How It Works

The gallery loads composition presets from `art_history_presets.gd` and renders each one as a grid of QuadMesh tiles on the floor. Each tile receives a unique `wallpaper_tile` ShaderMaterial with a procedurally generated 8x8 domain texture. Non-rectangular tilings (hex, polar, truchet, voronoi) are supported via coordinate system meshes that are scaled to fit each composition's tile area. Labels and omni lights are added automatically.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| tile_resolution | int | 16 |
| tile_world_size | float | 4.0 |
| columns | int | 7 |
| emission_strength | float | 1.0 |

## Features

- Renders all 20 art history composition presets side by side
- Supports rectangular, hex, polar, truchet, and voronoi coordinate systems
- 10 neon color palettes with 8 procedural domain pattern generators (blocks, stripes, diagonal, cross, concentric, checker, scatter, stairs)
- Per-coordinate-system grout width tuning for visual clarity
- Numbered labels beneath each composition tile
- Configurable via `apply_grid_config` from map data

## Files

- `art_history_gallery.gd` -- Main script that builds the gallery from composition presets
- `art_history_gallery.tscn` -- Scene file
