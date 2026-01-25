# Array Primitives - Pattern & Tile Systems

> "The loom was the first computer. Every carpet is an algorithm."

## Overview

Array primitives explore the relationship between **2D data structures** and **visual patterns**. From textile traditions to pixel art, these tools make array indexing tangible.

## Components

### PatternTilePuzzle

Interactive tile-based pattern editor with physical drag-and-drop interaction.

**Features:**
- Editable grid (4×4 to 16×16)
- 8-color palette (textile-inspired)
- **Grabbable color cubes** - drag and drop to place on grid
- Cubes snap and freeze in place when dropped on cells
- 10 repeat modes (simple, mirror, rotate, brick, herringbone, diamond)
- Live preview showing tiled result
- Carpet spawning (physical output)

**Interaction:**
1. **Grab** a color cube from the spawner pedestals on the right
2. **Move** the cube over the grid
3. **Release** - cube snaps to nearest cell and freezes in place
4. Grid cell updates, preview regenerates with new pattern
5. New cube automatically spawns at the pedestal

**Repeat Modes:**

| Mode | Effect |
|------|--------|
| Simple | Basic XY tiling |
| Mirror X | Horizontal reflection |
| Mirror Y | Vertical reflection |
| Mirror XY | Kaleidoscope |
| Rotate 90° | Quarter-turn symmetry |
| Rotate 180° | Half-turn symmetry |
| Brick X | Half-offset rows |
| Brick Y | Half-offset columns |
| Herringbone | Diagonal weave |
| Diamond | 45° rotation |

### WallpaperGroups

Mathematical implementation of the 17 wallpaper groups—ALL possible ways to tile a 2D plane.

**Groups by lattice:**

- **Oblique**: p1, p2
- **Rectangular**: pm, pg, pmm, pmg, pgg
- **Rhombic**: cm, cmm
- **Square**: p4, p4m, p4g
- **Hexagonal**: p3, p3m1, p31m, p6, p6m

## Usage

### In Artifact Registry

```json
{
  "pattern_tile_puzzle": {
    "scene": "res://commons/primitives/arrays/pattern_tile_puzzle.tscn"
  },
  "pattern_tile_mirror": {
    "scene": "res://commons/primitives/arrays/pattern_tile_puzzle.tscn",
    "config": {
      "tile_size": 4,
      "repeat_mode": 3
    }
  }
}
```

### In Map Data

```
"pattern_tile_4x4:0:-0.5"
```

### Programmatic

```gdscript
var puzzle = pattern_tile_puzzle.instantiate()
puzzle.tile_size = 8
puzzle.repeat_mode = PatternTilePuzzle.RepeatMode.MIRROR_XY
puzzle.set_cell(0, 0, 1)  # Set top-left to color 1
puzzle.select_color(2)     # Select color 2 for painting
puzzle.next_repeat_mode()  # Cycle to next mode
```

## Signals

| Signal | Description |
|--------|-------------|
| `cell_changed(x, y, color_idx)` | Cell was painted |
| `pattern_complete()` | Pattern matches target (if any) |
| `repeat_mode_changed(mode)` | Tiling mode changed |
| `color_selected(color_idx)` | Palette selection changed |

## Configuration

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `tile_size` | int | 4 | Grid dimensions (NxN) |
| `preview_repeats` | Vector2i | (4,4) | How many times to tile in preview |
| `cell_size` | float | 0.05 | Size of each cell in meters |
| `repeat_mode` | enum | SIMPLE | Tiling algorithm |
| `palette` | Color[] | [8 colors] | Available colors |
| `selected_color` | int | 1 | Currently selected color |
| `preview_offset` | Vector3 | (0,0,-0.8) | Position of preview relative to editor |
| `cube_size_ratio` | float | 0.8 | Cube size relative to cell size |
| `spawner_offset` | Vector3 | (0.25,0,0) | Position of cube spawners relative to grid |

## Mathematical Background

### The 17 Wallpaper Groups

Discovered in the 19th century, these represent a complete classification of 2D plane symmetries:

1. **Symmetry operations**: translation, rotation (2,3,4,6-fold), reflection, glide reflection
2. **Lattice types**: oblique, rectangular, rhombic, square, hexagonal
3. **Impossibilities**: 5-fold symmetry doesn't tile (see Penrose tilings for quasi-crystals)

### Why This Matters

- **Textiles**: Every woven pattern is a wallpaper group
- **Architecture**: Floor tiles, brick patterns, mosaics
- **Digital**: Shader textures, procedural generation, game tiles
- **Nature**: Crystal structures, molecular patterns

The same mathematical structures underlie Persian carpets and pixel art.

## Cultural Connections

- **Kilim rugs** (Anatolia) - geometric abstraction
- **Ikat** (Indonesia) - warp-dyed patterns
- **Kente** (Ghana) - symbolic color combinations
- **Islamic geometry** - infinite patterns from finite rules
- **Celtic knots** - interlacing without ends

## Files

- `pattern_tile_puzzle.gd` - Main puzzle script with grid, preview, and spawners
- `pattern_tile_puzzle.tscn` - Default scene
- `pattern_tile_cube.gd` - Grabbable color cube (extends XRToolsPickable)
- `pattern_tile_cube.tscn` - Cube scene with collision and mesh
- `wallpaper_groups.gd` - Mathematical symmetry implementation
