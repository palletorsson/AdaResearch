# Spring Network Visualizer

## Overview
A 3D visualization of wave propagation through an interconnected network of springs. Demonstrates how local spring forces create global wave patterns through mechanical coupling.

## Physics

### Hooke's Law
```
F = -k * (x - rest_length)
```
Where:
- **F** = Spring force
- **k** = Spring constant (stiffness)
- **x** = Current length
- **rest_length** = Natural length

### Network Dynamics
- Each node connected to neighbors by springs
- Forces propagate through the network
- Damping prevents infinite oscillation
- Fixed corner nodes provide boundary conditions

## Parameters

### Network Grid
- **grid_size**: Number of nodes in X and Y (default: 10x10)
- **node_spacing**: Distance between nodes (default: 0.5m)
- **network_height**: Y position of network plane (default: 1.5m)

### Spring Physics
- **spring_constant**: Stiffness (higher = stiffer springs)
- **damping**: Energy loss per frame (0.95 = 5% loss)
- **mass**: Mass of each node
- **rest_length**: Natural spring length

### Wave Excitation
- **excitation_strength**: Amplitude of driving force
- **excitation_frequency**: How fast to oscillate (Hz)
- **auto_excite**: Continuous wave generation at center

### Visualization
- **show_nodes**: Display node spheres
- **show_springs**: Display connecting lines
- **node_radius**: Size of node spheres
- **color_by_velocity**: Color nodes by speed (blue = slow, red = fast)

## Applications
- Understanding mechanical wave transmission
- Visualizing mesh physics and soft body dynamics
- Demonstrating phonon propagation in crystals
- Spring-mass system analysis

## Controls
Set `auto_excite` to false and use `apply_impulse(node_idx, impulse)` to manually excite specific nodes.
