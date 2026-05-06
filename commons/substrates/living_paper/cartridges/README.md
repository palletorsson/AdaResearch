# Living Paper Cartridges

Algorithm cartridges for the Living Paper substrate. Each extends `PaperAlgorithm` and implements `initialize()` and `step()` to draw into an Image pixel buffer on a grabbable VR paper sheet.

## How It Works

A cartridge receives an Image and draws into it step by step. Each step returns true when complete. The paper texture updates live as the algorithm progresses, producing animated drawings of fractals, noise fields, cellular automata, and more. Cartridges define their own background and primary colors.

## Files

### Cellular Automata and Simulation
- `paper_ca_1d.gd` -- 1D elementary cellular automaton (Wolfram rules), drawn row by row.
- `paper_ca_2d.gd` -- 2D cellular automaton (Game of Life variant) on the paper surface.
- `paper_reaction_diffusion.gd` -- Gray-Scott reaction-diffusion producing organic spotted/striped patterns.
- `paper_heat_diffusion.gd` -- Heat equation diffusion. Color encodes temperature spreading from hot spots.

### Pathfinding and Graph
- `paper_bfs.gd` -- Breadth-first search flood fill on a 2D grid drawn onto paper.
- `paper_dfs_maze.gd` -- DFS recursive backtracker maze generation.
- `paper_quadtree.gd` -- Quadtree spatial subdivision of scattered points.

### Fractals and L-Systems
- `paper_mandelbrot.gd` -- Mandelbrot set computed scanline by scanline.
- `paper_julia_set.gd` -- Julia set fractal with configurable constant.
- `paper_sierpinski.gd` -- Sierpinski triangle via chaos game.
- `paper_koch_curve.gd` -- Koch snowflake curve drawn iteratively.
- `paper_lsystem.gd` -- L-system string rewriting with turtle graphics rendering.

### Noise and Randomness
- `paper_perlin_noise.gd` -- Perlin noise field rendered as a grayscale heightmap.
- `paper_noise_octaves.gd` -- Layered noise octaves (fBm) with increasing detail.
- `paper_random_walk.gd` -- Random walk trace accumulating on the paper surface.
- `paper_dla.gd` -- Diffusion-limited aggregation. Particles stick to a growing crystal.

### Waves and Functions
- `paper_sine_wave.gd` -- Animated sine wave drawn across the paper.
- `paper_fourier.gd` -- Fourier series approximation built term by term.
- `paper_lissajous.gd` -- Lissajous curve traced parametrically.

### Data and Clustering
- `paper_sorting.gd` -- Sorting algorithm visualized as colored columns on paper.
- `paper_voronoi.gd` -- Voronoi diagram from random seed points.
- `paper_kmeans.gd` -- K-means clustering with iterating centroids and colored regions.
