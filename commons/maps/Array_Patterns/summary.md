# Array_Patterns - Tile-Based Pattern Creation

## Overview

This map explores **arrays as pattern generators**. Small tile grids become carpets, floor tiles, and textiles. The connection between handmade craft traditions and computational pattern-making.

## Layout

- **11×11 platform** with gallery of pattern stations
- Four pattern editors at different complexity levels
- Central dark sphere for ambient lighting
- Teleporter to continue the sequence

## Key Elements

| Element | Purpose |
|---------|---------|
| `pattern_tile_4x4` | Basic 4×4 tile, simple XY repeat |
| `pattern_tile_mirror` | 4×4 with kaleidoscope symmetry |
| `pattern_tile_brick` | Half-offset rows (brick/masonry) |
| `pattern_tile_herringbone` | Alternating diagonal weave |

## Interaction

### Editing
1. **Click** cells in the small grid to paint with selected color
2. **Click** palette balls to select colors
3. Press **Tab** or VR button to cycle repeat modes
4. Press **1-8** to quick-select palette colors

### Preview
- The large rectangle shows how your tile repeats
- Different modes create different symmetries
- Pixel-art aesthetic (nearest-neighbor filtering)

### Spawning
- Some stations can spawn a physical carpet object
- The carpet has your pattern applied as texture

## Repeat Modes

| Mode | Description |
|------|-------------|
| Simple | Basic XY tiling |
| Mirror X | Horizontal reflection |
| Mirror Y | Vertical reflection |
| Mirror XY | Kaleidoscope (both axes) |
| Rotate 90° | Quarter-turn symmetry |
| Rotate 180° | Half-turn symmetry |
| Brick X | Half-offset rows |
| Brick Y | Half-offset columns |
| Herringbone | Diagonal weave |
| Diamond | 45° rotated tiling |

## Learning Objectives

- 2D array indexing (`grid[y][x]`)
- Pattern repetition and tiling
- Symmetry operations (reflection, rotation)
- The mathematics of wallpaper groups
- Pixel/tile-based design thinking

## Design Philosophy

> "Every carpet is an algorithm. Every algorithm can be a carpet."

The traditions of textile craft—kilim, ikat, jacquard—encode algorithms in thread. This map makes that encoding visible and interactive. The same operations that generate a Persian rug generate pixel art, cellular automata, and shader patterns.

The 17 wallpaper groups (discovered in the 19th century) are ALL possible ways to tile a 2D plane. This map provides a hands-on exploration of that mathematical truth.
