# Cellular Automata Bridge

This directory contains a generator for a "bridge" structure created by stacking 1D cellular automata generations along the Z-axis.

## Concept

- **1D Cellular Automata**: Uses Wolfram's elementary rules (like Rule 30, 90, 110).
- **Time as Space**: Each generation of the CA is placed at a new Z-coordinate, creating a 2D pattern on the ground (or a bridge).
- **Instantiated Cubes**: Uses `res://commons/primitives/cubes/cube_scene.tscn` for each cell, scaled to 50%.

## Files

- `ca_bridge.gd`: The main script logic.
- `ca_bridge.tscn`: The scene file.

## Usage

1. Open `ca_bridge.tscn`.
2. Select the `CABridge` node.
3. Adjust parameters in the Inspector:
    - **Width**: Number of cells across the bridge.
    - **Length**: How long the bridge grows (generations).
    - **Rule**: The Wolfram rule number (0-255).
    - **Cell Size**: Spacing and scale of cubes (default 0.5).
    - **Generation Speed**: How fast it builds.

## Interesting Rules

- **Rule 30**: Chaotic, organic.
- **Rule 90**: Sierpinski triangle (fractal).
- **Rule 110**: Complex, Turing complete behavior.
- **Rule 184**: Traffic flow simulation (diagonal lines).
