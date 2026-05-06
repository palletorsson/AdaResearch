<<<ADA_BUNDLE>>>
sequence: array_tutorial
file: critical.md
maps: 8
skipped_passing: 0
created: 2026-04-23T22:38:12
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
# Array_Patterns - Critical Notes

## The Loom as Computer

> "The Jacquard loom is the ancestor of the computer. Punch cards encoded patterns before they encoded programs."

The textile arts are among humanity's oldest forms of computation:

- **Warp and weft** as binary states (over/under)
- **Pattern cards** as stored programs
- **The weaver** as processor, following instructions
- **The cloth** as output, materialized algorithm

When Ada Lovelace saw the Analytical Engine, she recognized it because she knew looms.

## The 17 Wallpaper Groups

In the 19th century, mathematicians proved that there are exactly **17 distinct ways** to tile a 2D plane with a repeating pattern. No more, no less.

These groups are defined by their symmetry operations:
- **Translation** (shift the pattern)
- **Rotation** (2-fold, 3-fold, 4-fold, 6-fold)
- **Reflection** (mirror)
- **Glide reflection** (mirror + half-shift)

Every tiled bathroom floor, every Persian carpet, every pixel art texture falls into one of these 17 groups.

### The Groups

| Name | Symmetry | Example |
|------|----------|---------|
| p1 | Translation only | Brick wall |
| p2 | 180° rotation | Herringbone |
| pm | Parallel mirrors | Striped fabric |
| pg | Glide reflection | Footprints in sand |
| cm | Mirror + glide | Zigzag pattern |
| pmm | Double mirror | Checkerboard |
| pmg | Mirror + glide + rotation | Complex tiles |
| pgg | Double glide | Celtic knots |
| cmm | Centered double mirror | Diamond lattice |
| p4 | 90° rotation | Square tiles |
| p4m | Square + diagonal mirrors | Islamic geometry |
| p4g | Square + off-center mirrors | Pinwheel |
| p3 | 120° rotation | Triangular |
| p3m1 | Triangle + mirrors (type 1) | Honeycomb |
| p31m | Triangle + mirrors (type 2) | Mercedes logo tiled |
| p6 | 60° rotation | Hexagonal |
| p6m | Hex + all mirrors | Highest symmetry |

## Handmade ↔ Digital

The pattern tile puzzle reveals a profound equivalence:

**Handmade traditions:**
- Kilim rugs (Anatolia)
- Ikat textiles (Indonesia)
- Kente cloth (Ghana)
- Navajo blankets
- Celtic manuscripts

**Digital patterns:**
- Pixel art
- Shader textures
- Cellular automata
- Procedural generation
- Tile-based games

The **operations** are identical:
- Repeat
- Mirror
- Rotate
- Offset
- Combine

The only difference is the substrate: thread vs. pixel, loom vs. GPU.

## The Array as Canvas

In programming, a 2D array is just a grid of values:

```
grid[y][x] = color
```

In textiles, the same structure:

```
warp[row] × weft[col] = color
```

The pattern tile puzzle makes this equivalence tactile. You paint pixels. They become fabric.

## QFEP and Pattern

The Queer Feminist Energy Principle asks: where is the agency?

In prescribed patterns (follow the chart), the weaver executes.
In emergent patterns (cellular automata), the rules create.
In improvisational patterns (jazz quilts), the maker negotiates.

The pattern tile puzzle offers all three:
- **Prescribed**: match a target pattern
- **Emergent**: change the repeat mode, watch new forms appear
- **Improvisational**: paint freely, discover what tiles well

## Questions for Reflection

1. Why do all cultures develop geometric patterns? What about our perception makes tiling satisfying?

2. If there are only 17 wallpaper groups, have we "exhausted" 2D pattern space? Or is the space infinite within each group?

3. When you paint a 4×4 tile and see it repeat 16 times, where is "your" pattern? In the tile or in the repetition?

4. The Jacquard loom was automated weaving. Is the pattern tile puzzle automated art? Or a tool for making art?

5. What patterns are impossible? (Hint: 5-fold rotational symmetry doesn't tile the plane. Why not?)

## The Infinite in the Finite

A 4×4 grid with 8 colors has 8^16 = 281 trillion possible patterns.

Even this tiny tile contains more patterns than any human could paint in a lifetime.

The array is finite. The possibilities are effectively infinite. This is the paradox of computational creativity—constraint enabling rather than limiting expression.

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
# INTENT: Concept: No catalyst mode — the lesson is observation and arrangement rather than projection. The learner places obstacles and the grid agent adapts, so the chamber's teaching is about state and responsiveness rather than about firing. | Sequence role: Catalyst chamber for the Array Tutorial sequence, the last map before returning to the Lab. The sequence taught array addressing across one, two, and three dimensions and closed with the dance-floor grid; this chamber converts the array from a data structure the learner reads into a data structure the learner composes for another agent to read. | Te | [... truncated ...]
# BLURB: No new weapon. Instead you watch the grid agent traverse, copy, pattern. You place obstacles. The agent adapts.  This is the catalyst chamber for the Array Tutorial sequence — the only chamber without a projection mode. …
[empty — file does not yet exist]
