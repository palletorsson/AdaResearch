# Random Walk

The drunkard's path. Each step independent, direction random, yet patterns emerge.

## QFEP Connection

Random walk is **pure E(S)** — maximum local entropy (each step unpredictable) yet global patterns emerge (diffusion, return probability, scaling laws). The walk doesn't know where it's going, but mathematics knows its statistics. This is QFEP's core insight: entropy has structure.

## Core Algorithm: 7 Walk Types

The `RandomWalk` class (`scripts/random_walk.gd`) implements seven mathematically distinct random walks:

### 1. Simple Random Walk
```
← → ↑ ↓  (cardinal directions only)
```
The classic: equal probability of moving in four directions. Returns to origin with probability 1 in 2D (Pólya's theorem).

### 2. Diagonal Random Walk
```
← → ↑ ↓ ↖ ↗ ↙ ↘  (8 directions)
```
Includes diagonal moves. Faster diffusion, different statistics.

### 3. Brownian Motion
```
Any angle, continuous step sizes
```
True random motion — like pollen grains in water. Step size varies, angle is uniform random.

### 4. Fractal Walk
```
Branches recursively (30% chance)
```
Creates tree-like structures. Each step may spawn new walkers. Not a single path but a growing tree.

### 5. Fibonacci Spiral Walk
```
Steps follow Fibonacci sequence, golden angle rotation
```
Combines randomness with mathematical structure. Creates spiral patterns like sunflower seeds.

### 6. Self-Avoiding Walk
```
Never revisits a cell
```
The walker remembers where it's been. Much harder to analyze mathematically (unsolved in general). Used in polymer physics.

### 7. Lévy Flight
```
Occasional long jumps (power-law distribution)
```
Most steps are short, but occasionally very long. Models animal foraging, human travel patterns. The step distribution has infinite variance.

## Usage

```gdscript
var result = RandomWalk.perform_random_walk(
    image,           # Image to draw on
    start_pos,       # Starting position
    step_size,       # Size of each step
    width, height,   # Bounds
    RandomWalk.WalkType.LEVY_FLIGHT,  # Walk type
    {},              # Visited positions (for self-avoiding)
    Color.WHITE      # Drawing color
)
```

## Specialized Variants

This folder also contains two specialized random walk implementations:

### Crystal Random Walk
Grows crystal-like structures using branching random walks with tapering prisms.
→ See [README_CrystalRandomWalk.md](README_CrystalRandomWalk.md)

### Tessellation Lattice Walk  
Random walk that reveals space-filling tessellations (cubes, rhombic dodecahedra, truncated octahedra).
→ See [README_TessellationLatticeWalk.md](README_TessellationLatticeWalk.md)

## Mathematical Properties

| Walk Type | Return Probability (2D) | Scaling | Real-World Example |
|-----------|------------------------|---------|-------------------|
| Simple | 1 (certain) | √n | Drunk person |
| Brownian | 1 (certain) | √n | Pollen in water |
| Self-Avoiding | < 1 | n^(3/4) | Polymer chain |
| Lévy Flight | < 1 | n^(1/β) | Albatross foraging |

## Files

### Scripts
- `random_walk.gd` — Core algorithm with 7 walk types
- `random_walk_manager.gd` — Manager for multiple walks
- `crystal_random_walk.gd` — Crystal growth variant
- `crystal_demo_controller.gd` — Crystal demo UI
- `tessellation_lattice_walk.gd` — Space-filling tessellation variant
- `tessellation_demo_controller.gd` — Tessellation demo UI

### Scenes
- `random_walk.tscn` — Basic random walk visualization
- `random_walk_collection.tscn` — Multiple walk types side by side
- `random_walk_grab_paper.tscn` — Interactive paper with walk
- `crystal_random_walk.tscn` — Crystal structure
- `crystal_random_walk_demo.tscn` — Interactive crystal demo
- `tessellation_lattice_demo.tscn` — Tessellation demo
