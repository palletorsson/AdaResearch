# Wall Pattern Colorizer

Colors wall cubes in the GridSystem MultiMesh using wallpaper group symmetry patterns. Each wall cube becomes a pixel whose color is determined by tiling math based on its grid position.

## How It Works

The colorizer finds the scene's GridMultiMesh and GridStructureComponent, then iterates over all cube instances. Floor cubes (y=0) are dimmed, while wall cubes (y>0) receive colors computed by applying one of 17 wallpaper group symmetry operations to their grid coordinates, then sampling from a procedurally generated 8x8 domain texture. The domain texture is created from a seed using one of six pattern types and eight neon palettes.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `wallpaper_group` | int | 5 (PMM) |
| `tile_scale` | float | 2.0 |
| `pattern_seed` | int | 0 |
| `auto_cycle` | bool | false |
| `cycle_interval` | float | 8.0 |

## Features

- CPU implementation of all 17 wallpaper groups (P1 through P6M)
- Directly colors MultiMesh instance colors for zero GPU overhead
- Procedural domain texture generation with 8 neon palettes and 6 pattern types
- Auto-cycle mode steps through all wallpaper groups on a timer
- Adjusts GridMultiMesh material for instance color visibility
- Supports `apply_grid_config()` for map JSON configuration

## Files

- `wall_pattern_colorizer.gd` -- Wallpaper group tiling math and MultiMesh colorizer
- `wall_pattern_colorizer.tscn` -- Scene file
