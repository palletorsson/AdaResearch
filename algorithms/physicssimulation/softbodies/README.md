# SoftBodies Algorithm

## Overview
This algorithm demonstrates advanced soft body physics simulation with three different deformable objects: a jelly cube, a blob sphere, and a deformable cylinder. Each object features realistic deformation, pressure forces, volume preservation, and collision handling.

## Visualization Features
- **Three Soft Body Types**: Jelly Cube, Blob Sphere, and Deformable Cylinder
- **Real-time Deformation**: Objects deform based on forces and collisions
- **Pressure System**: Dynamic pressure fields that influence object shape
- **Volume Preservation**: Objects maintain their volume during deformation
- **Collision Detection**: Interaction with ground plane and obstacles
- **Tetrahedral Mesh**: Wireframe visualization of internal structure

## Technical Implementation
- **SoftBodyNode Class**: Handles individual node physics and rendering
- **SoftBody Class**: Manages soft body mesh, springs, and tetrahedra
- **Pressure Forces**: Distance-based pressure influence on nodes
- **Volume Calculation**: Tetrahedral-based volume computation
- **Spring Constraints**: Maintains object shape and connectivity

## Parameters
- `node_resolution`: Number of nodes per dimension (default: 6)
- `stiffness`: Spring stiffness coefficient (default: 100.0)
- `damping`: Damping force coefficient (default: 5.0)
- `pressure_strength`: Pressure force magnitude (default: 50.0)
- `gravity_strength`: Gravitational acceleration (default: 9.8)
- `volume_preservation`: Volume preservation strength (default: 0.8)

## Soft Body Types

### Jelly Cube
- **Shape**: Cubic soft body with uniform node distribution
- **Behavior**: Deforms under pressure and collision forces
- **Material**: Soft, jelly-like properties
- **Visualization**: Yellow spring connections, orange tetrahedra

### Blob Sphere
- **Shape**: Spherical soft body with radial node distribution
- **Behavior**: Maintains spherical shape while deforming
- **Material**: Blob-like, fluid-like properties
- **Visualization**: Cyan spring connections, green tetrahedra

### Deformable Cylinder
- **Shape**: Cylindrical soft body with axial node distribution
- **Behavior**: Deforms while maintaining cylindrical structure
- **Material**: Flexible, rubber-like properties
- **Visualization**: Magenta spring connections, purple tetrahedra

## Physics System
- **Mass-Spring System**: Nodes connected by springs for shape maintenance
- **Pressure Forces**: External pressure fields influence deformation
- **Volume Preservation**: Forces maintain object volume during deformation
- **Collision Response**: Realistic collision handling with obstacles
- **Gravity**: Constant downward acceleration

## Volume Preservation
- **Tetrahedral Elements**: Internal structure for volume calculation
- **Rest Volume**: Initial volume stored for comparison
- **Volume Correction**: Forces applied to maintain volume
- **Pressure Restoration**: Outward forces when volume decreases
- **Adaptive Forces**: Dynamic force application based on volume changes

## Pressure System
- **Multiple Sources**: Three animated pressure fields
- **Distance-Based Influence**: Pressure strength decreases with distance
- **Dynamic Fields**: Pressure sources move and scale over time
- **Force Application**: Pressure forces applied to all nodes
- **Visual Feedback**: Pressure sources animate to show activity

## Collision System
- **Ground Collision**: Soft bodies interact with ground plane
- **Obstacle Collision**: Spherical obstacles provide collision surfaces
- **Penetration Prevention**: Nodes pushed away from collision surfaces
- **Energy Loss**: Collisions reduce node velocity
- **Realistic Bouncing**: Objects bounce off surfaces naturally

## Mesh Deformation
- **Center of Mass**: Mesh position follows node center of mass
- **Deformation Scaling**: Mesh scale changes based on node deformation
- **Visual Consistency**: Mesh appearance matches node positions
- **Smooth Transitions**: Gradual deformation over time
- **Shape Preservation**: Overall object shape maintained

## Spring System
- **Structural Springs**: Connect nearby nodes for shape maintenance
- **Rest Lengths**: Springs maintain original distances
- **Constraint Satisfaction**: Forces applied to satisfy spring constraints
- **Visual Representation**: Spring lines show connectivity
- **Dynamic Updates**: Springs update based on node movement

## Performance Features
- **Efficient Node Management**: Optimized node creation and updates
- **Selective Connections**: Only nearby nodes are connected
- **Volume Optimization**: Efficient tetrahedral volume calculation
- **Collision Optimization**: Spatial partitioning for collision detection
- **Memory Management**: Efficient storage of node and spring data

## VR Integration Notes
- Optimized for VR viewing with emissive materials
- Clear visual separation between different soft body types
- Spring lines and tetrahedra show internal structure clearly
- Volume indicators provide real-time feedback
- Pressure sources are visually distinct and animated
- Collision objects are clearly defined
- Ready for XR world integration
