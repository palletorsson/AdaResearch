# Cloth Simulation Algorithm

## Overview
This algorithm demonstrates realistic cloth simulation with self-collision detection, wind interaction, and constraint handling. It shows three different cloth configurations: hanging cloth, floating cloth, and draped cloth, each responding to various environmental forces.

## Visualization Features
- **Three Cloth Types**: Hanging, Floating, and Draped configurations
- **Real-time Deformation**: Cloth responds to gravity, wind, and collisions
- **Wind System**: Multiple wind sources with animated wind streams
- **Collision Detection**: Cloth interacts with collision spheres
- **Spring Visualization**: Wireframe representation of cloth structure
- **Fixed Point Constraints**: Some nodes are anchored to create realistic behavior

## Technical Implementation
- **ClothNode Class**: Handles individual cloth node physics
- **ClothPiece Class**: Manages cloth mesh and spring connections
- **Spring System**: Structural, shear, and diagonal springs
- **Collision Detection**: Sphere-cloth and self-collision handling
- **Wind Forces**: Distance-based wind influence on cloth nodes

## Parameters
- `cloth_resolution`: Number of nodes per dimension (default: 8)
- `cloth_stiffness`: Spring stiffness coefficient (default: 100.0)
- `cloth_damping`: Damping force coefficient (default: 5.0)
- `wind_strength`: Wind force magnitude (default: 3.0)
- `gravity_strength`: Gravitational acceleration (default: 9.8)
- `collision_strength`: Collision response strength (default: 50.0)

## Physics Concepts Demonstrated
- **Mass-Spring System**: Cloth modeled as interconnected masses and springs
- **Constraint Satisfaction**: Spring constraints maintain cloth shape
- **Collision Response**: Realistic collision handling with external objects
- **Wind Interaction**: Dynamic wind forces affecting cloth movement
- **Self-Collision**: Cloth nodes avoiding penetration with each other

## Cloth Types
- **Hanging Cloth**: Fixed at top corners, responds to gravity and wind
- **Floating Cloth**: Free-floating cloth affected by wind currents
- **Draped Cloth**: Cloth draped over collision objects

## Spring Types
- **Structural Springs**: Connect adjacent nodes horizontally and vertically
- **Shear Springs**: Diagonal connections that resist shearing deformation
- **Bending Springs**: Help maintain cloth shape and prevent folding

## Wind System
- **Multiple Wind Sources**: Three animated wind fields
- **Wind Streams**: Visual particles showing wind direction
- **Distance-Based Influence**: Wind strength decreases with distance
- **Animated Sources**: Wind sources move and scale dynamically

## Collision System
- **Sphere Collisions**: Cloth interacts with spherical collision objects
- **Penetration Prevention**: Cloth nodes are pushed away from collision surfaces
- **Collision Forces**: Forces applied to prevent cloth from passing through objects
- **Self-Collision**: Cloth nodes avoid penetrating each other

## VR Integration Notes
- Optimized for VR viewing with emissive materials
- Clear visual separation between different cloth types
- Spring lines show cloth structure clearly
- Wind streams provide visual feedback
- Collision objects are visually distinct
- Ready for XR world integration
