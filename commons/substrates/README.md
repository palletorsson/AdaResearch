# Substrates

Swappable algorithm visualization platforms. Each substrate is a physical object (bar chart, grid, graph, paper, oscilloscope) that runs interchangeable algorithm cartridges. One object, many algorithms.

## How It Works

Every substrate follows the same pattern: a renderer (MultiMesh or ImmediateMesh), a manager script (play/pause/step lifecycle), and a base cartridge class that algorithm-specific cartridges extend. Cartridges implement `initialize()` and `step()` to drive the visualization. Substrates are placed in maps via the artifact registry and configured with `apply_grid_config()`.

## Directories

- `bar_array/` -- 1D array visualization (sorting, sequences, histograms). 9 cartridges.
- `grid2d/` -- 2D cell grid (cellular automata, pathfinding, mazes). 8 cartridges.
- `grid3d/` -- 3D graph visualization (traversal, MST, shortest path). 8 cartridges.
- `living_paper/` -- Grabbable VR paper that draws 2D algorithms (fractals, noise, CA). 22 cartridges.
- `profile/` -- 1D continuous curve renderer (waveforms, noise, oscillations). 16 cartridges.
- `substrate_vector/` -- Vector field visualization.
