<<<ADA_BUNDLE>>>
sequence: array_tutorial
file: summary.md
maps: 8
skipped_passing: 0
created: 2026-04-23T19:21:13
only_failing: false
diff_mode: false
with_context: true
<<</ADA_BUNDLE>>>

<<<MAP: Tutorial_Pattern>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Patterns as equations the eye solves — checkerboards from (x+y)%2, waves from sin(x), and the learner places colors on tiles to discover that arrays hold data but patterns are data that rhymes. | Sequence role: Sixth map in Array Tutorial; transitions from structural navigation (maps 2–5) to computational pattern recognition. The learner now uses the grid not just for addressing but for generating visual structure from mathematical rules. Connects forward to Array_Patterns' symmetry groups and back to the dimensional foundation; follows Tutorial_3D; leads to Tutorial_Disco. | Technical an | [... truncated ...]
# BLURB: Arrays hold data. Patterns are data that rhymes. A checkerboard — two values alternating: `grid[y][x] = (x + y) % 2`. A wave — one function swept across indices. Every pattern is an equation the eye solves before the min…
[empty — file does not yet exist]

<<<MAP: Array_Patterns>>>
# INTENT: Concept: Pattern-making through arrays — small tiles repeated by symmetry operations produce carpets, mosaics, and wallpaper groups. The loom as first computer; textiles as algorithms. | Sequence role: First map in Array Tutorial; establishes that arrays are not just data containers but pattern generators. The 17 wallpaper groups appear as the complete set of planar symmetries. Connects back to Color_Grid_Pallet's grid-as-canvas, but now the grid has mathematical structure (symmetry operations, not just color assignment); leads to Tutorial_Single. | Technical angle: 2D array indexing as tile addre | [... truncated ...]
# BLURB: Every carpet is an algorithm. Every algorithm can be a carpet.  Paint a small tile. Watch it repeat. Discover the 17 wallpaper groups—all possible ways to tile a plane.  The loom was the first computer. Punch cards encod…
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

<<<MAP: Tutorial_Single>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The absolute minimum interaction — one cube, one exit. The entire system reduced to grab-and-go, teaching VR hand tracking before any data structure concepts enter. | Sequence role: Second map in Array Tutorial; the zero-index map (absolute_beginner). Before arrays, before patterns, the learner must know how to pick up an object in VR. This is the control tutorial — establishing the interface contract that all subsequent maps assume. The single cube is the scalar before the array; follows Array_Patterns; leads to Tutorial_Row. | Technical angle: VR hand tracking, grab mechanics, object in | [... truncated ...]
# BLURB: One cube. One exit. The entire system reduced to its smallest possible act.  A platform floats in space — four by three, barely enough to stand on. A single cube waits at its center. Reach out. Close your hand. Pick it u…
[empty — file does not yet exist]

<<<MAP: Tutorial_Row>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The 1D array as corridor — forward/backward movement along a single axis, where spatial traversal is equivalent to array indexing with one index. | Sequence role: Third map in Array Tutorial; introduces the first data structure as physical space. After Tutorial_Single's scalar interaction, this map adds the first dimension. Seven columns wide, nine rows deep, one lane runs forward. The column_3_z rig constrains traversal to the Z-axis — a physical 1D array; leads to Tutorial_2D_Build. | Technical angle: Y-axis (depth) navigation as array traversal, linear indexing, forward/backward moveme | [... truncated ...]
# BLURB: A corridor. Seven columns wide, nine rows deep. One lane runs forward through the center — the rest is buffer, orientation, context. Movement here is linear. Forward and back along a single axis.  The `column_3_z` rig te…
[empty — file does not yet exist]

<<<MAP: Tutorial_2D_Build>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The jump from line to grid — two indices find a point, and the 4×4 grid makes the coordinate pair tangible. Row and column helpers decompose the axes; the grid agent navigates programmatically. | Sequence role: Fourth map in Array Tutorial; the dimensional leap from 1D to 2D. After Tutorial_Row's single axis, this map adds the second. The 4×4 grid is small enough to comprehend entirely but large enough to require systematic addressing. The grid agent introduces algorithmic traversal — the first programmatic navigation; leads to Tutorial_3D. | Technical angle: 2D array indexing (row, colum | [... truncated ...]
# BLURB: One index finds a slot. Two indices find a point. The jump from line to grid is the jump from sequence to space — from knowing *where* to knowing *where in relation to what*.  Row and column helpers break the axes apart.…
[empty — file does not yet exist]

<<<MAP: Tutorial_3D>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: Three indices address a volume — the grid gains height, and what was a spreadsheet becomes a navigable space. Volumetric thinking as the payoff of dimensional progression. | Sequence role: Fifth map in Array Tutorial; completes the dimensional ladder (scalar → 1D → 2D → 3D). The 4×4×4 cube is 64 positions addressed by three indices — the full spatial data structure. Stepped platforms and lifts make vertical navigation physical. After this, the learner understands that array dimensionality maps directly to spatial dimensionality; follows Tutorial_2D_Build; leads to Tutorial_Pattern. | Tech | [... truncated ...]
# BLURB: Two dimensions flatten. Three dimensions inhabit. The grid gains a vertical axis — X, Y, and now Z. Height enters the data structure. What was a spreadsheet becomes a volume.  Stepped platforms rise along the north and w…
[empty — file does not yet exist]

<<<MAP: Tutorial_Disco>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: The array as dance floor — a 17×17 grid large enough to get lost in, where every tile is an address (row, column, state) and stepping activates response. The step sequencer makes the grid temporal. | Sequence role: Seventh and final map in Array Tutorial; the capstone that synthesizes navigation, addressing, and pattern into a single playful space. The 17×17 grid is dramatically larger than the 4×4 grids — scale changes the experience from comprehensible to immersive. The step sequencer adds time to the spatial array, connecting forward to Wavefunctions where temporal patterns dominate. | [... truncated ...]
# BLURB: A 17×17 grid stretched into a dance floor. Every tile is an address — row, column, state. Step on it, it responds. The array becomes a surface you walk across, a structure large enough to get lost in.  The step sequencer…
[empty — file does not yet exist]

<<<MAP: Chamber_Arrays>>>
# STATUS: missing (file does not exist)
# INTENT: Concept: No catalyst mode — the lesson is observation and arrangement, not projection. | Sequence role: Catalyst chamber for array_tutorial. Last map before returning to Lab. | Technical angle: Catalyst mode none, creature gridagent:copy, Science Screen grid. | Critical angle: The chamber is where mathematics becomes relationship. The catalyst transforms the player-creature boundary.
# BLURB: No new weapon. Instead you watch the grid agent traverse, copy, pattern. You place obstacles. The agent adapts.  This is the catalyst chamber for the Array Tutorial sequence — the only chamber without a projection mode. …
[empty — file does not yet exist]
