# Rigid Body Dynamics Visualization

## Overview
This scene demonstrates rigid body physics with multiple blocks that can stack, tumble, and interact through realistic collision detection and response. It showcases advanced physics concepts including angular momentum and complex collision resolution.

## Features
- **Multiple Rigid Blocks**: Various sized blocks with different properties
- **Realistic Stacking**: Blocks can stack and form stable structures
- **Angular Motion**: Rotation and tumbling behavior
- **Collision Response**: Impulse-based collision resolution
- **Dynamic Addition**: Button to add random blocks during simulation

## Physics Implementation
- **Positional Dynamics**: Linear velocity and acceleration
- **Angular Dynamics**: Angular velocity and rotational motion
- **Collision Detection**: AABB-based broad-phase detection
- **Collision Response**: Impulse-based velocity and angular velocity updates
- **Separation**: Automatic collision separation to prevent overlap

## Controls
- **Add Random Block**: Creates a new block with random properties
- **Reset Simulation**: Restores all blocks to initial positions

## Technical Details
- **Engine**: Godot 4
- **Language**: GDScript
- **Scene Type**: 3D Visualization
- **Physics**: Custom rigid body dynamics implementation
- **Visualization**: Wireframe rendering for block edges

## Files
- `rigidbody.tscn` - Main scene file
- `RigidBodyDynamics.gd` - Physics simulation and collision handling script
- `RigidBlock.gd` - Individual block physics and visualization script

## Usage
1. Open the scene in Godot 4
2. Run the scene to see the rigid body simulation
3. Use the "Add Random Block" button to create new objects
4. Observe how blocks interact, stack, and tumble
5. Watch the complex collision patterns and momentum transfer

## Educational Value
This visualization helps understand:
- Rigid body dynamics and angular momentum
- Complex collision detection and response systems
- Stacking and stability in physics simulations
- The relationship between mass, velocity, and collision outcomes
- Real-time physics simulation with multiple interacting objects
