# Bouncing Ball Physics Visualization

## Overview
This scene demonstrates realistic bouncing ball physics with multiple balls, obstacles, and collision detection. It showcases momentum conservation, energy loss, and complex collision interactions in a 3D environment.

## Features
- **Multiple Balls**: Three balls with different initial conditions and colors
- **Environment**: Ground plane, walls, and obstacles for collision testing
- **Realistic Physics**: Gravity, air resistance, and collision response
- **Collision Detection**: Ball-to-ball and ball-to-environment interactions
- **Visual Trails**: Path visualization for each ball

## Physics Implementation
- **Gravity**: Constant downward acceleration (9.8 m/s²)
- **Air Resistance**: Velocity damping for realistic motion
- **Collision Detection**: AABB-based collision detection system
- **Impulse Response**: Momentum-conserving collision resolution
- **Energy Loss**: Realistic bouncing with energy dissipation

## Controls
- **Reset Balls**: Restores all balls to initial positions
- **Pause/Resume**: Toggles physics simulation on/off

## Technical Details
- **Engine**: Godot 4
- **Language**: GDScript
- **Scene Type**: 3D Visualization
- **Physics**: Custom collision detection and response
- **Collision System**: Broad-phase and narrow-phase detection

## Files
- `bouncingball.tscn` - Main scene file
- `BouncingBall.gd` - Physics simulation and collision handling script
- `Ball.gd` - Individual ball physics and trail rendering script

## Usage
1. Open the scene in Godot 4
2. Run the scene to see the bouncing ball simulation
3. Use the UI controls to reset or pause the simulation
4. Observe how balls interact with each other and the environment
5. Watch the collision patterns and energy transfer between objects

## Educational Value
This visualization helps understand:
- Momentum conservation in collisions
- Energy loss through friction and air resistance
- Complex collision detection algorithms
- Real-time physics simulation concepts
- The relationship between initial conditions and final outcomes
