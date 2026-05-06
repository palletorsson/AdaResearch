# Spring Network

A physics simulation that teaches **Hooke's Law**, **wave propagation**, and **coupled oscillator dynamics** by constructing a 2D grid of mass nodes connected by springs. Displacing the center node sends ripples through the network, demonstrating how local forces propagate through interconnected systems.

## How It Works

The system builds a rectangular grid of point masses connected by springs to their horizontal, vertical, and diagonal neighbours. Corner nodes are fixed as anchors. Each frame, the simulation:

1. **Resets forces** on all nodes.
2. **Computes spring forces** using Hooke's Law: `F = -k * (distance - rest_length)`, applied along the direction between connected nodes. Each spring exerts equal and opposite forces on its two endpoints.
3. **Adds gravity** as a constant downward force.
4. **Integrates motion** using Euler's method: acceleration = force / mass, velocity += acceleration * dt, position += velocity * dt. Velocity is multiplied by a damping factor each step to prevent runaway oscillation.

Auto-excitation drives the center node with a sinusoidal force (`sin(t * frequency * TAU) * strength`) to continuously generate waves. The resulting motion shows how energy propagates outward from the excitation point, reflects off fixed boundaries, and creates interference patterns.

Nodes are colour-coded by velocity magnitude when `color_by_velocity` is enabled, making the wave fronts visible as colour pulses travelling across the grid.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `grid_size` | Vector2i | (10, 10) | Number of nodes in X and Y |
| `node_spacing` | float | 0.5 | Distance between adjacent nodes at rest |
| `network_height` | float | 1.5 | Vertical position of the grid |
| `spring_constant` | float | 50.0 | Stiffness of each spring (Hooke's k) |
| `damping` | float | 0.95 | Per-frame velocity damping factor |
| `mass` | float | 1.0 | Mass of each node |
| `rest_length` | float | 0.5 | Natural length of each spring |
| `excitation_strength` | float | 2.0 | Amplitude of the center excitation force |
| `excitation_frequency` | float | 1.0 | Frequency of the excitation in Hz |
| `auto_excite` | bool | true | Continuously drive the center node |
| `show_nodes` | bool | true | Render node spheres |
| `show_springs` | bool | true | Render spring connections |
| `node_radius` | float | 0.05 | Radius of each node sphere |
| `spring_thickness` | float | 0.02 | Thickness of spring lines |
| `color_by_velocity` | bool | true | Colour nodes by velocity magnitude |

## Features

- Hooke's Law spring force simulation with configurable stiffness
- Euler integration with velocity damping
- Fixed corner boundary conditions for wave reflection
- Diagonal springs for structural stability (rest length scaled by sqrt(2))
- Sinusoidal center excitation for continuous wave generation
- Velocity-based colour mapping to visualise wave fronts
- `@tool` support for editor preview
- Public API: `get_node_at_index()`, `apply_impulse()`

## Files

| File | Description |
|------|-------------|
| `spring_network.gd` | Complete spring network simulation -- grid construction, Hooke's Law physics, and velocity-coloured visualisation |
