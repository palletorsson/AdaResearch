# Tessellation Lattice Walk

A perfect space-filling 3D lattice revealed through random walk. This demonstrates shapes that can **perfectly tessellate 3D space** with absolutely no gaps or overlaps.

## Concept

Unlike the tetrahedral random walk which builds organically, this algorithm:

1. **Pre-computes a perfect lattice** - A grid of shapes that perfectly fill space
2. **Random walk reveals cells** - Walk through the lattice and "light up" one cell at a time
3. **No rotation, no scaling** - Forms are perfectly aligned in a space-filling grid
4. **Three tessellation types** - Each can fill 3D space with zero gaps

## The Three Space-Filling Polyhedra

### 1. Cube
- **Faces**: 6 square faces
- **Properties**: The simplest space-filling shape
- **Use case**: Clear visualization of 3D grid structure
- **Appearance**: Classic cubic grid

### 2. Rhombic Dodecahedron
- **Faces**: 12 rhombic (diamond) faces
- **Properties**: The Voronoi cell of FCC (face-centered cubic) lattice
- **Use case**: Crystalline structures, natural tessellation
- **Appearance**: Looks like 3D diamonds, more organic than cubes
- **Real world**: Found in garnet crystals and honeycomb structures

### 3. Truncated Octahedron
- **Faces**: 14 faces (6 squares + 8 hexagons)
- **Properties**: The Voronoi cell of BCC (body-centered cubic) lattice
- **Use case**: Efficient space packing, architectural structures
- **Appearance**: Like a soccer ball, beautiful hexagonal faces
- **Real world**: Used in architecture (Montreal Biosphere), foam structures

## Features

- **Perfect Tessellation**: Zero gaps between shapes
- **Random Walk Reveal**: Cells light up one at a time in random order
- **Adjustable Speed**: Control how fast cells are revealed
- **Color Gradient**: Cells transition from start color to end color over time
- **Interactive Controls**:
  - Switch between three tessellation types
  - Pause/Resume the walk
  - Reset and regenerate walk path
  - Reveal all cells instantly
  - Zoom camera with mouse wheel

## Parameters

### Lattice Properties
- `tessellation_type`: Choose CUBE, RHOMBIC_DODECAHEDRON, or TRUNCATED_OCTAHEDRON
- `grid_size`: Dimensions of the lattice (e.g., 8x8x8 = 512 cells)
- `cell_size`: Size of each cell

### Random Walk
- `walk_speed`: Cells revealed per second
- `auto_walk`: Automatically reveal cells
- `loop_walk`: Restart walk when complete

### Visual Effects
- `color_start`: Starting color (early cells)
- `color_end`: Ending color (later cells)
- `emission_strength`: Glow intensity
- `show_all_at_start`: Show all cells immediately

## Usage

```gdscript
# Create a tessellation lattice
var lattice = TessellationLatticeWalk.new()
lattice.tessellation_type = TessellationLatticeWalk.TessellationType.RHOMBIC_DODECAHEDRON
lattice.grid_size = Vector3i(10, 10, 10)
lattice.walk_speed = 15.0
add_child(lattice)

# Control the walk
lattice.pause_walk()
lattice.resume_walk()
lattice.reset_walk()
lattice.reveal_all()

# Get statistics
var stats = lattice.get_stats()
print("Revealed: ", stats.revealed_cells, " / ", stats.total_cells)
```

## Mathematical Background

### Why These Shapes?

Only 5 convex polyhedra can tessellate 3D space on their own:
1. ✅ **Cube** - Regular, all faces identical squares
2. ✅ **Rhombic Dodecahedron** - All faces identical rhombi
3. ✅ **Truncated Octahedron** - Alternating squares and hexagons
4. **Hexagonal Prism** - Not implemented (less interesting visually)
5. **Triangular Prism** - Not implemented (less interesting visually)

Regular tetrahedra and octahedra **cannot** tessellate space alone - they leave gaps!

### Space-Filling Efficiency

- **Cube**: 100% space filling (obviously)
- **Rhombic Dodecahedron**: 100% space filling, often found in nature
- **Truncated Octahedron**: 100% space filling, most faces (14) of the three

## Demo Scene

Open: `algorithms/randomness/randomwalk/scenes/tessellation_lattice_demo.tscn`

The demo includes:
- Rotating camera view
- UI panel with all controls
- Real-time statistics
- Buttons to switch between all three types

## Implementation Details

### Mesh Generation
Each polyhedron is generated procedurally with proper normals for flat shading:
- Cubes: 24 vertices (4 per face × 6 faces)
- Rhombic Dodecahedra: 48 vertices (4 per face × 12 faces)
- Truncated Octahedra: Complex hexagonal faces triangulated from center

### Lattice Structure
- Grid coordinates stored as `Vector3i`
- World transforms pre-computed
- MultiMesh for efficient rendering (hundreds of cells)

### Random Walk Algorithm
1. Generate all lattice positions
2. Create random permutation of indices (Fisher-Yates shuffle)
3. Reveal cells in random order
4. Update multimesh transforms and colors per cell

## Performance

- Efficiently handles 500+ cells using MultiMesh
- Suggested grid sizes:
  - **8×8×8 = 512 cells**: Good balance
  - **10×10×10 = 1000 cells**: More impressive
  - **12×12×12 = 1728 cells**: May slow down on older hardware

## Future Enhancements

- [ ] True random walk (neighbor-to-neighbor) instead of random reveal
- [ ] Multiple simultaneous walkers
- [ ] Tetrahedral-Octahedral honeycomb (mixed tessellation)
- [ ] Export lattice as mesh
- [ ] Animation when cells appear (fade in, scale up, etc.)
- [ ] Different color modes (height-based, distance-based, cluster-based)

## References

- [Space-Filling Polyhedra - Wikipedia](https://en.wikipedia.org/wiki/Honeycomb_(geometry))
- [Rhombic Dodecahedron - Wolfram MathWorld](https://mathworld.wolfram.com/RhombicDodecahedron.html)
- [Truncated Octahedron - Wolfram MathWorld](https://mathworld.wolfram.com/TruncatedOctahedron.html)

---

**Created**: 2025
**Algorithm**: Space-filling tessellation with random walk reveal
**Complexity**: O(n) for n cells, O(1) per frame update
