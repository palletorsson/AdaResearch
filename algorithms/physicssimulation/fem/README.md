# Finite Element Method (FEM) Algorithm

## Overview
This algorithm demonstrates the Finite Element Method for simulating deformable body physics in 3D space. It shows how complex objects can be broken down into discrete elements and how forces affect their deformation.

## Visualization Features
- **Three Deformable Objects**: Beam, Membrane, and Sphere
- **FEM Grid Visualization**: Shows the discretization of objects into finite elements
- **Real-time Deformation**: Objects deform based on applied forces
- **Force Point Animation**: Visual representation of applied forces
- **Grid Lines**: Wireframe representation of element boundaries

## Technical Implementation
- **Beam Deformation**: Simple beam theory with quadratic deflection
- **Membrane Deformation**: Wave equation-based surface deformation
- **Sphere Deformation**: Radial wave deformation patterns
- **Grid Generation**: Procedural creation of finite element meshes
- **Material System**: Distinct colors for each object type

## Parameters
- `deformation_strength`: Maximum deformation amount (default: 0.5)
- `grid_resolution`: Number of elements per dimension (default: 8)
- `animation_speed`: Speed of force oscillation (default: 2.0)

## Physics Concepts Demonstrated
- **Finite Element Discretization**: Breaking continuous objects into discrete elements
- **Structural Deformation**: How forces cause objects to bend and deform
- **Wave Propagation**: How disturbances travel through materials
- **Stress Visualization**: Visual representation of internal forces

## FEM Principles Shown
- **Mesh Generation**: Creating computational grids
- **Node Definition**: Defining points where forces are calculated
- **Element Connectivity**: How nodes are connected to form elements
- **Deformation Calculation**: Computing displacement at each node

## VR Integration Notes
- Optimized for VR viewing with emissive materials
- Grid lines provide clear structural understanding
- Force points show applied loads clearly
- Ready for XR world integration
