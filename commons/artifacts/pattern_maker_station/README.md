# Pattern Maker Station

An interactive design station where users paint a small domain grid on an upright panel and see the result tiled across a large floor carpet using any of the 17 wallpaper symmetry groups. Teaches crystallographic symmetry, tiling, and how local motifs generate global patterns through mathematical transformations.

## How It Works

The user paints colors onto an NxN domain grid (default 4x4) using VR touch or button controls. The domain is then tiled across a floor carpet by applying the selected wallpaper group symmetry operations (rotations, reflections, glide reflections) via `WallpaperGroups.get_symmetric_color()`. Each pixel in the carpet texture is computed by mapping its coordinates back through the symmetry group to determine which domain cell it corresponds to. Cycling through all 17 wallpaper groups (p1, p2, pm, pg, cm, pmm, pmg, pgg, cmm, p4, p4m, p4g, p3, p3m1, p31m, p6, p6m) shows how the same motif produces radically different global patterns.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `tile_size` | int | 4 |
| `cell_size` | float | 0.06 |
| `panel_width` | float | 1.2 |
| `panel_height` | float | 0.9 |
| `carpet_world_size` | float | 4.0 |
| `carpet_repeats` | int | 10 |

## Features

- All 17 wallpaper symmetry groups with one-button cycling
- VR touch painting on the domain grid panel
- 8-color Italian textile palette
- Mirror X, Mirror Y, and Rotate CW domain transformation buttons
- Clear button to reset the domain
- Real-time carpet texture regeneration on every edit
- Procedural floor carpet tiled from the domain using symmetry operations

## Files

- `pattern_maker_station.gd` — Main script
- `pattern_maker_station.tscn` — Scene file
