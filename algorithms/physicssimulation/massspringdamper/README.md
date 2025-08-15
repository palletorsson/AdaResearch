# Mass-Spring-Damper Algorithm

## Overview
This algorithm demonstrates detailed elasticity models using interconnected masses, springs, and dampers. It shows three different structural configurations: a grid structure, a chain structure, and a cloth structure, each responding to various forces.

## Visualization Features
- **Three Structural Types**: Grid, Chain, and Cloth configurations
- **Mass-Point Visualization**: Individual mass points with distinct colors
- **Spring Connections**: Visual representation of spring connections between masses
- **Real-time Physics**: Continuous simulation of forces and motion
- **Force Source Animation**: Animated representation of applied forces

## Technical Implementation
- **Mass Class**: Handles position, velocity, and force accumulation
- **Spring Class**: Implements Hooke's law and damping forces
- **Grid Structure**: 2D grid of interconnected masses
- **Chain Structure**: Linear chain of masses with sequential connections
- **Cloth Structure**: 2D cloth with structural, shear, and bending springs

## Parameters
- `grid_size`: Size of the grid structure (default: 5x5)
- `chain_length`: Number of masses in the chain (default: 8)
- `cloth_size`: Size of the cloth structure (default: 6x6)
- `spring_constant`: Spring stiffness coefficient (default: 50.0)
- `damping_coefficient`: Damping force coefficient (default: 2.0)
- `mass_value`: Mass of each point (default: 1.0)
- `gravity_strength`: Gravitational acceleration (default: 9.8)
- `wind_strength`: Wind force magnitude (default: 2.0)

## Physics Concepts Demonstrated
- **Hooke's Law**: Spring force proportional to displacement
- **Damping Forces**: Velocity-dependent resistive forces
- **Newton's Second Law**: Force equals mass times acceleration
- **Structural Dynamics**: How forces propagate through connected systems

## Spring Types in Cloth
- **Structural Springs**: Connect adjacent masses horizontally and vertically
- **Shear Springs**: Diagonal connections that resist shearing deformation
- **Bending Springs**: Help maintain cloth shape and prevent folding

## Force Applications
- **Gravity**: Constant downward force on all masses
- **Wind**: Time-varying force on cloth structure
- **External Force**: Oscillating force on chain structure

## VR Integration Notes
- Optimized for VR viewing with emissive materials
- Clear visual separation between different structures
- Spring lines show connectivity clearly
- Force sources are visually distinct
- Ready for XR world integration
