# Array Carpet

A decorative floor carpet that displays the player's tiled pattern from the arrays lesson, demonstrating how repetition and symmetry transforms turn a small tile into rich ornamental art. If no player pattern exists, a handmade default rug motif is shown.

## How It Works

The carpet reads a saved pattern from the TraceData singleton (written by PatternTilePuzzle) and tiles it across a floor-lying quad mesh using one of ten repeat modes: simple, mirror X/Y/XY, rotate 90/180, brick X/Y, herringbone, or diamond. Each mode applies different symmetry operations to map pixel coordinates back into the source tile. The resulting tiled image is rendered as a nearest-neighbor texture on a flat quad. Live-updates when the player edits their pattern in the puzzle.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `carpet_world_size` | Vector2 | `Vector2(0.8, 0.8)` |
| `carpet_repeats` | Vector2i | `Vector2i(6, 6)` |
| `default_tile_size` | int | `4` |
| `default_repeat_mode` | int | `3` (MIRROR_XY) |

## Features

- Ten tiling repeat modes with full symmetry math (mirror, rotation, brick, herringbone, diamond)
- Live-updates from TraceData when the player saves a new pattern
- Default 4x4 tile with an 8-color traditional rug palette
- Nearest-neighbor texture filtering for crisp pixel art look
- Grid configuration support for tile_size, repeat_mode, and carpet_repeats

## Files

- `array_carpet.gd` -- Main script
- `array_carpet.tscn` -- Scene file
