# Cellular Automata Columns

This directory contains a generator for 3D structures created by stacking 2D cellular automata generations.
Each layer in the 3D structure represents a single time step of a 2D cellular automaton.

## Files

- `ca_columns.gd`: The main script generating the structure.
- `ca_columns.tscn`: A ready-to-use scene.

## Usage

1. Open `ca_columns.tscn`.
2. Select the `CAColumns` node.
3. Adjust parameters in the Inspector:
    - **Grid Size**: Width/Depth of the base grid.
    - **Max Height**: Number of generations to stack.
    - **Rule Born/Survive**: The CA rule (default is Game of Life B3/S23).
    - **Initial Density**: Probability of a cell being alive in the first layer.
    - **Colors**: Gradient colors for the column height.

## Interesting Rules

Try these B/S (Born/Survive) combinations for different structures:

- **Game of Life (B3/S23)**: Chaotic, often forms gliders and stable structures.
- **HighLife (B36/S23)**: Similar to Life but with a replicator.
- **Day & Night (B3678/S34678)**: Very rich structures.
- **Seeds (B2/S)**: Explosive growth, good for sparse, crystalline shapes.
- **Maze (B3/S12345)**: Creates maze-like walls that extend upwards.
- **Coral (B3/S45678)**: Organic, coral-like growth.
- **Walled Cities (B45678/S2345)**: Solid blocky structures.

## Performance

The script uses `MultiMeshInstance3D` to render thousands of cubes efficiently. However, very large grids (>100x100) with high max height (>200) may still impact performance during generation.
