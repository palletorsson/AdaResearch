# Collision Detection Visualization

## Overview
This scene demonstrates various collision detection algorithms including broad-phase spatial hashing and narrow-phase AABB (Axis-Aligned Bounding Box) detection. It shows how different collision detection strategies work in real-time.

## Features
- **Multiple Objects**: Various shapes (spheres, cubes) for collision testing
- **Spatial Hashing**: Broad-phase collision detection grid
- **AABB Detection**: Narrow-phase collision detection
- **Visual Grid**: Toggle-able spatial grid visualization
- **Collision Highlighting**: Visual feedback for detected collisions
- **Algorithm Switching**: Toggle between different detection methods

## Physics Implementation
- **Broad Phase**: Spatial hashing for efficient object culling
- **Narrow Phase**: AABB intersection testing
- **Collision Response**: Simple bouncing behavior
- **Grid System**: Configurable spatial partitioning
- **Real-time Detection**: Continuous collision checking

## Controls
- **Toggle Grid**: Shows/hides the spatial partitioning grid
- **Switch Algorithm**: Changes between collision detection methods
- **Reset Objects**: Restores all objects to initial positions

## Technical Details
- **Engine**: Godot 4
- **Language**: GDScript
- **Scene Type**: 3D Visualization
- **Physics**: Custom collision detection implementation
- **Visualization**: Grid system and collision highlighting

## Files
- `collisiondetection.tscn` - Main scene file
- `CollisionDetection.gd` - Collision detection and visualization script
- `CollisionObject.gd` - Individual collision object script

## Usage
1. Open the scene in Godot 4
2. Run the scene to see collision detection in action
3. Use the UI controls to toggle grid visibility and switch algorithms
4. Observe how different detection methods perform
5. Watch collision detection in real-time

## Educational Value
This visualization helps understand:
- Broad-phase vs narrow-phase collision detection
- Spatial partitioning techniques
- AABB collision detection algorithms
- Performance implications of different approaches
- Real-time collision detection concepts
