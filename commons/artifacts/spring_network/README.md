# Spring Network

A mass-spring lattice where a grid of point masses is connected by springs to horizontal, vertical, and diagonal neighbors, simulated with Verlet integration and position-based dynamics (PBD). Teaches how local spring constraints produce emergent elastic behavior across a deformable mesh.

## How It Works

An NxN grid of masses is created with uniform spacing, and corner masses are fixed as anchors. Each mass connects to its immediate neighbors (horizontal, vertical, and both diagonals) with springs whose rest lengths match the initial distances. Each frame runs three substeps of PBD constraint solving: for each spring, the positional error (current length minus rest length) is split equally between the two connected masses as a correction vector. Verlet integration then advances positions using the implicit velocity (current minus previous position) scaled by a damping factor. Spring lines are colored by strain -- blue for compression, red for stretching, and neutral gray at rest.

## Parameters

| Export | Type | Default |
|--------|------|---------|
| `grid_size` | int | 6 |
| `spacing` | float | 0.1 |
| `stiffness` | float | 80.0 |
| `damping` | float | 0.97 |
| `mass_radius` | float | 0.008 |

## Features

- Verlet integration with PBD constraint solving for stable oscillation
- MultiMesh GPU instancing for mass point rendering
- Strain-based spring coloring: blue (compressed), gray (rest), red (stretched)
- Corner masses anchored as fixed points
- VR sliders for stiffness and damping control
- Random initial perturbation to kick the network into motion

## Files

- `spring_network.gd` -- Main script
- `spring_network.tscn` -- Scene file
