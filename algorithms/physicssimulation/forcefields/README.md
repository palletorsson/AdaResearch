# Force Fields Algorithm

## Overview
This algorithm demonstrates three different types of force fields in 3D space:
- **Gravity Field**: Radial force field that attracts particles toward a central point
- **Magnetic Field**: Dipole field that creates circular motion patterns
- **Fluid Drag Field**: Field with turbulence that simulates fluid resistance

## Visualization Features
- **Three Force Field Centers**: Each with distinct colors (Blue, Red, Green)
- **Particle Systems**: 50 particles per field that respond to forces
- **Field Lines**: Visual representation of force field direction and strength
- **Real-time Physics**: Particles continuously update based on force calculations

## Technical Implementation
- **Force Calculation**: Uses inverse square law for field strength
- **Particle Physics**: Simple velocity-based movement with force application
- **Field Line Generation**: Procedural creation of directional indicators
- **Material System**: Emissive materials for better visibility in VR

## Parameters
- `particle_count`: Number of particles per field (default: 50)
- `field_strength`: Strength of the force fields (default: 10.0)
- `particle_speed`: Movement speed multiplier (default: 2.0)

## Physics Concepts Demonstrated
- **Inverse Square Law**: Force strength decreases with distance squared
- **Vector Fields**: Directional forces in 3D space
- **Particle Dynamics**: Massless particle movement under forces
- **Field Visualization**: How to represent abstract forces visually

## VR Integration Notes
- Optimized for VR viewing with emissive materials
- Camera positioned for optimal 3D perspective
- No UI elements - pure 3D visualization
- Ready for XR world integration
