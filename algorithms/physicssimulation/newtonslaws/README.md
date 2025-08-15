# Newton's Laws Visualization

## Overview
This scene demonstrates the fundamental principles of Newton's Laws of Motion through interactive 3D visualization. Three spheres are used to illustrate different aspects of classical mechanics including gravity, applied forces, and friction.

## Features
- **Ball 1**: Demonstrates gravity-only motion (no applied force)
- **Ball 2**: Shows applied force + gravity interaction
- **Ball 3**: Illustrates applied force + gravity + friction effects
- **Force Vectors**: Visual representation of forces acting on objects
- **Interactive Controls**: Reset and pause/resume functionality

## Physics Implementation
- **Gravity**: Constant downward acceleration (9.8 m/s²)
- **Applied Forces**: Continuous horizontal forces on balls 2 and 3
- **Friction**: Air resistance simulation (98% velocity retention per frame)
- **Collision Detection**: Ground and wall boundary handling
- **Integration**: Euler method for position and velocity updates

## Controls
- **Reset Simulation**: Restores all balls to initial positions
- **Pause/Resume**: Toggles physics simulation on/off

## Technical Details
- **Engine**: Godot 4
- **Language**: GDScript
- **Scene Type**: 3D Visualization
- **Physics**: Custom implementation (not using built-in physics engine)
- **Rendering**: CSG primitives for simple geometry

## Files
- `newtonslaws.tscn` - Main scene file
- `NewtonsLaws.gd` - Primary physics simulation script
- `ForceVector.gd` - Force visualization script

## Usage
1. Open the scene in Godot 4
2. Run the scene to see the physics simulation
3. Use the UI controls to interact with the simulation
4. Observe how different forces affect the motion of each ball

## Educational Value
This visualization helps understand:
- How gravity affects all objects equally
- The relationship between force, mass, and acceleration
- The effects of friction on motion
- Real-time physics simulation concepts
