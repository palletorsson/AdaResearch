# Strange Attractors Visualization

## Overview
This implementation visualizes several classic strange attractors from chaos theory, including the Lorenz, Clifford, De Jong, Bedhead, Svensson, and Ikeda attractors. These mathematical objects demonstrate how deterministic systems can produce complex, seemingly random behavior while remaining bounded in phase space.

## Algorithm Description
Strange attractors are sets in phase space toward which dynamical systems evolve over time. Despite their chaotic nature, they have fractal structure and represent the long-term behavior of nonlinear dynamical systems.

### Implemented Attractors

#### Lorenz Attractor
- Parameters: σ=10.0, ρ=28.0, β=8/3
- Famous "butterfly" attractor from weather modeling
- Demonstrates sensitive dependence on initial conditions

#### Clifford Attractor  
- 2D attractor with parameters a=-1.4, b=1.6, c=1.0, d=0.7
- Creates intricate fern-like patterns

#### De Jong Attractor
- 2D system with parameters a=-2.0, b=-2.0, c=-1.2, d=2.0
- Produces beautiful symmetric patterns

#### Others
- Bedhead, Svensson, and Ikeda attractors with unique characteristics

### Algorithm Flow
1. Initialize system with starting position
2. Iterate through attractor equations
3. Plot trajectory points in real-time
4. Maintain trail of recent points for visualization

## Files Structure
- `strange_attractors.gd`: Main implementation with all attractor types
- `strange_attractors.tscn`: 2D visualization scene
- `2d_to_3d_strange_attractors.tscn`: 3D projection scene

## Parameters
- Max points: 10,000 trail length
- Iterations per frame: 10 for smooth animation
- Scale factor: 100.0 for proper display
- Customizable colors and line properties

## Theoretical Foundation
Strange attractors are fundamental to:
- Chaos theory and nonlinear dynamics
- Fractal geometry
- Ergodic theory
- Complex systems analysis

## Applications
- Weather prediction modeling
- Population dynamics
- Economic modeling
- Cryptography and random number generation
- Art and visualization

## Usage
Run the scene to watch attractors evolve in real-time. Switch between different attractor types to explore various chaotic behaviors and pattern formations.