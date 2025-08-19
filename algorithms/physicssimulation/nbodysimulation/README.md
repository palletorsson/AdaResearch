# N-Body Gravitational Simulation

## Overview
This implementation simulates the classical N-body problem in physics, where multiple bodies interact through gravitational forces. The simulation demonstrates complex orbital mechanics, gravitational slingshots, and emergent patterns in multi-body gravitational systems.

## Algorithm Description
The N-body problem involves predicting the motion of celestial bodies under mutual gravitational attraction. Each body experiences forces from all other bodies, leading to complex dynamics that cannot be solved analytically for N>2.

### Physics Implementation
- Newton's law of universal gravitation: F = G(m₁m₂)/r²
- Numerical integration for position and velocity updates
- Real-time force calculation between all body pairs
- Energy conservation through careful integration

### Key Features
- Variable mass bodies (5.0 to 30.0 units)
- Configurable gravitational constant (G=0.5)
- Random initial velocities and positions
- Collision detection and handling

## Algorithm Flow
1. **Initialization**: Create N bodies with random masses and positions
2. **Force Calculation**: For each body, compute gravitational forces from all others
3. **Integration**: Update velocities and positions using calculated forces
4. **Collision Handling**: Merge bodies that come too close
5. **Visualization**: Render bodies with trails showing orbital paths

## Files Structure
- `nbody_problem.gd`: Main physics simulation and body management
- `nbody_problem.tscn`: 2D visualization scene
- `nbody_problem_3d.tscn`: 3D orbital mechanics scene

## Parameters
- **Bodies**: Number of gravitational bodies (default: 30)
- **Mass Range**: 5.0 to 30.0 mass units
- **G Constant**: Gravitational constant (0.5)
- **Screen Margins**: Boundary constraints (50 pixels)
- **Velocity Range**: Initial random velocity magnitude

## Theoretical Foundation
Based on:
- Newton's laws of motion and gravitation
- Classical mechanics and celestial dynamics
- Numerical integration methods
- Computational physics principles

## Applications
- Planetary orbit simulation
- Galaxy formation modeling
- Spacecraft trajectory planning
- Astrophysics research
- Game physics engines

## Visual Features
- Real-time gravitational body interaction
- Orbital trail visualization
- Dynamic body merging on collision
- Configurable visualization parameters

## Usage
Run the simulation to observe how multiple bodies interact gravitationally. Watch for stable orbits, chaotic behavior, and body mergers. Experiment with different numbers of bodies and gravitational constants.