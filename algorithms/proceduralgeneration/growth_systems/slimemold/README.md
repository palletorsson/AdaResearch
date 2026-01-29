# Slime Mold Simulation (Dave Stewart Style)

## Overview
This implementation creates a viscous, organic slime mold simulation inspired by Dave Stewart's artistic style. The algorithm generates dynamic, tubular slime structures with pooling effects, drips, and organic movement patterns using procedural generation and noise-based animation.

## Algorithm Description
The slime mold algorithm simulates the growth patterns and movement of slime organisms through procedural generation of interconnected tubes and pools. The system uses noise functions to create organic deformation and realistic viscous behavior.

### Key Components
1. **Pool Generation**: Creates initial slime pools with varying sizes
2. **Tube Network**: Connects pools with organic tubular structures
3. **Viscosity Simulation**: Models fluid-like behavior and surface tension
4. **Drip System**: Generates realistic dripping effects
5. **Bubble Formation**: Adds organic bubbles within the slime
6. **Noise-Based Animation**: Creates organic pulsing and movement

### Visual Features
- **Glossy Materials**: Realistic slime surface with high glossiness (0.9)
- **Color Gradients**: Primary, secondary, and highlight colors for depth
- **Dynamic Deformation**: Real-time organic shape changes
- **Particle Effects**: Bubbles and drips for enhanced realism

## Algorithm Flow
1. **Initialization**: Set up noise generators and material properties
2. **Pool Placement**: Generate initial slime pools at random locations
3. **Tube Generation**: Create connecting tubes between pools
4. **Surface Creation**: Generate 3D meshes for pools and tubes
5. **Animation Loop**: Apply noise-based deformation and movement
6. **Drip Generation**: Create and animate falling drips
7. **Bubble Management**: Add and remove bubbles dynamically

## Files Structure
- `dave-stewart-slime-tubes.gd`: Main slime simulation with 3D generation
- `slime.tscn`: Scene setup with camera and lighting

## Parameters
- **Structure**: 5 pools, 3 tube segments per pool
- **Sizes**: Pool size (2.0-6.0), tube thickness (0.3-1.2)
- **Materials**: Viscosity (0.7), glossiness (0.9)
- **Colors**: Primary (dark teal), secondary (green), highlight (light green)
- **Animation**: Speed (0.2), drip amount (1.5), bubble amount (0.6)

## Theoretical Foundation
Based on:
- **Physarum Polycephalum**: Real slime mold behavior and growth patterns
- **Fluid Dynamics**: Viscous flow and surface tension effects
- **Procedural Generation**: Noise-based organic structure creation
- **Cellular Automata**: Growth and path-finding behaviors

## Applications
- Procedural organic modeling for games
- Scientific visualization of slime molds
- Artistic installations and generative art
- Fluid simulation prototyping
- Biomimetic algorithm research

## Visual Features
- Real-time 3D organic deformation
- Physically-based slime materials
- Dynamic dripping and pooling effects
- Procedural bubble generation
- Organic color gradients

## Usage
Run the simulation to observe the slime mold's organic growth and movement. The slime will continuously deform, create new connections, and exhibit realistic viscous behavior. Watch for emerging patterns and natural-looking organic structures.