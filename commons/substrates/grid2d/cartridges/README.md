# Grid2D Cartridges

Algorithm cartridges for the Grid2D substrate. Each extends `Grid2DCartridge` and implements `initialize()`, `step()`, `get_state_color()`, and `get_state_emission()` to drive a 2D cell grid visualization.

## How It Works

A cartridge operates on a `PackedInt32Array` representing cell states in a flat width-by-height grid. Each step returns a new state array. The renderer maps states to colors and emission values via the cartridge. Most cartridges use toroidal wrapping at grid edges.

## Files

- `cartridge_game_of_life.gd` -- Conway's Game of Life (B3/S23). Warm amber cells on dark background with dying-cell trails.
- `cartridge_brians_brain.gd` -- Brian's Brain. Three-state CA: on/dying/off. Produces chaotic self-sustaining patterns.
- `cartridge_seeds.gd` -- Seeds CA. Born with exactly 2 neighbors, always dies next step. Explosive growth.
- `cartridge_rule_1d.gd` -- Elementary 1D cellular automaton. Draws Wolfram rules row by row (default: Rule 30).
- `cartridge_langtons_ant.gd` -- Langton's Ant. Simple 2-state Turing machine that builds emergent highways.
- `cartridge_wireworld.gd` -- Wireworld. 4-state CA for simulating digital circuits with electron pulses on copper wire.
- `cartridge_bfs.gd` -- Breadth-first search on a 2D grid. Flood-fill wavefront from source to goal.
- `cartridge_dfs_maze.gd` -- DFS maze generation. Recursive backtracker carving corridors through the grid.
