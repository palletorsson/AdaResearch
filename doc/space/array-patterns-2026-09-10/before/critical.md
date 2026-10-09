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
