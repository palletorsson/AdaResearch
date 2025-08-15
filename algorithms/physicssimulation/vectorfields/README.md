# Vector Fields Visualization

## Overview
This scene demonstrates various types of vector fields and their effects on particle motion. It provides an interactive 3D environment to explore different field types including radial, vortex, uniform, and sinusoidal fields.

## Features
- **Multiple Field Types**: Switch between different vector field configurations
- **Interactive Particle**: Blue test particle that responds to field forces
- **Visual Field Representation**: Red arrows showing field direction and magnitude
- **Particle Trail**: Green trail showing particle's path through the field
- **Grid System**: Visual reference grid for spatial orientation

## Field Types
1. **Radial Field**: Forces point outward from origin (repulsive)
2. **Vortex Field**: Forces create circular motion around origin
3. **Uniform Field**: Constant force in one direction
4. **Sinusoidal Field**: Varying force based on position

## Physics Implementation
- **Field Calculation**: Real-time computation of force vectors at each grid point
- **Particle Motion**: Integration of field forces to update particle position
- **Trail Rendering**: Dynamic trail system showing particle history
- **Field Visualization**: Color-coded arrows indicating force magnitude

## Controls
- **Switch Field Type**: Cycles through different field configurations
- **Reset Particle**: Returns particle to starting position
- **Toggle Trail**: Shows/hides particle path visualization

## Technical Details
- **Engine**: Godot 4
- **Language**: GDScript
- **Scene Type**: 3D Visualization
- **Field Resolution**: Configurable grid density
- **Trail System**: Dynamic line rendering with fade effect

## Files
- `vectorfields.tscn` - Main scene file
- `VectorFields.gd` - Field generation and particle simulation script
- `VectorFieldArrow.gd` - Individual field vector visualization script

## Usage
1. Open the scene in Godot 4
2. Run the scene to see the vector field visualization
3. Use the UI controls to switch field types and reset the particle
4. Observe how the particle moves differently in each field type
5. Toggle the trail to see the particle's path

## Educational Value
This visualization helps understand:
- How vector fields influence particle motion
- Different types of force fields and their characteristics
- The relationship between field strength and particle behavior
- Real-time field visualization and simulation concepts
