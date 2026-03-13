# Tile Patterns

A procedural tile pattern generator that creates grids of symmetrical, colorful designs through random path generation and mirror/rotational symmetry. Patterns evolve over time: rows shift downward like a scrolling display, and a genetic "mating" system breeds neighboring patterns together to produce emergent visual variety.

## Concept Taught

**Symmetry, procedural generation, and genetic algorithms.** This artifact teaches how complex visual patterns emerge from simple rules applied with symmetry transformations. A random walk on a small inner grid produces a path. That path is then reflected or rotated into four quadrants, creating a tile with bilateral or rotational symmetry -- the same principle that governs wallpaper groups, Islamic tessellations, and crystal structures. The mating system adds a genetic algorithm dimension: patterns inherit structure from one parent and colors from another, with occasional mutations. Students see how selection, crossover, and mutation produce evolving populations of designs.

## How It Works

1. A grid of tiles (default 5x5 or 8x8) is generated. Each tile runs an independent random walk:
   - Starting from a point on an inner grid (default 3x3), the walker picks a random valid direction (up, down, left, right).
   - Each step adds a new point and assigns a random color from the palette.
   - Periodically the path breaks and restarts from a random position, creating multiple disconnected strokes per tile.
   - The walk is limited by maximum edges and maximum attempts.
2. Each tile's path is drawn four times using symmetry:
   - **Reflect mode**: original, vertical mirror, horizontal mirror, and diagonal mirror.
   - **Rotate mode**: original, 90-degree, 180-degree, and 270-degree rotations.
3. The result is a grid of symmetric, colorful line drawings on a dark background.
4. A timer periodically shifts all patterns down by one row, generating a new top row.
5. The `tilemate.gd` variant adds genetic mating: each tile can crossbreed with a random neighbor. One parent contributes the path structure, the other contributes colors. A 10% mutation chance randomly changes individual colors, and a 30% chance toggles whether new rows are added or the grid recombines in place.

## Parameters

Both scripts use a configuration dictionary `P` with these fields:

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| `tiles` | int | 5 or 8 | Grid dimension (tiles x tiles) |
| `padding` | float | 0.2 | Padding fraction between tiles |
| `edgesMax` | int | 15 | Maximum edges per tile path |
| `edgesAttempts` | int | 20 | Maximum walk attempts |
| `edgesBreak` | int | 4 | Steps between path breaks |
| `innerGrid` | int | 3 | Inner grid resolution for the walk |
| `startPoint` | Vector2 | (1, 1) | Starting position of the walk |
| `symmetry` | String | "reflect" | Symmetry mode: "reflect" or "rotate" |
| `colors` | Array[Color] | 9 colors | Palette: red, green, blue, yellow, magenta, cyan, orange, purple, teal |

## Features

- Two symmetry modes: reflective (bilateral) and rotational (4-fold)
- Random walk path generation with configurable grid, edge count, and break frequency
- Nine-color palette with per-segment random color assignment
- Scrolling animation shifts patterns downward on a timer
- Genetic mating system (tilemate.gd) crossbreeds neighboring tiles
- Crossover: structure from one parent, colors from another
- Mutation: 10% chance to randomize individual segment colors
- Toggle between adding fresh rows and recombining existing patterns
- Click to regenerate the entire grid instantly
- Responsive to window resize

## Files

| File | Purpose |
|------|---------|
| `tilepattern.gd` | Base tile pattern generator with symmetry, scrolling, and per-tile random walks |
| `tilemate.gd` | Extended version adding genetic crossover and mutation between neighboring patterns |
