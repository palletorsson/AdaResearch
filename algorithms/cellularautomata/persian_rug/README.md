# Persian Rug Generator

This directory contains a procedural generator for "Persian Rug" patterns using 2D Cellular Automata.

## Concept

The rug is generated using a "Generations" type cellular automaton (a variant of Game of Life with decaying states).
- **Symmetry**: The grid is forced to be symmetric (mirrored quadrants) to mimic rug designs.
- **Dual Rules**: 
    - **Border**: Uses a specific B/S (Born/Survive) rule to create a distinct frame.
    - **Inner**: Uses a different B/S rule for the central pattern.
- **Color Palette**: A "Pink Persian" palette with deep burgundy, vivid pinks, and gold.

## Files

- `persian_rug.gd`: The main script logic.
- `persian_rug.tscn`: The scene file.

## Usage

1. Open `persian_rug.tscn`.
2. Select the `PersianRug` node.
3. In the Inspector, you can adjust:
    - **Grid Size**: Width/Height of the texture.
    - **Border Size**: Thickness of the border region.
    - **Rules**: Born/Survive conditions for border and inner regions.
    - **Colors**: Customize the palette.
    - **Auto Step**: Toggle animation.

## Interesting Rules to Try

- **Maze**: B3/S12345 (Good for inner patterns)
- **Coral**: B3/S45678
- **Walled Cities**: B45678/S2345
- **Star Wars**: B2/S345/4 States (Good for borders)
