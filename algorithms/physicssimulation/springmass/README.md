# Spring-Mass Systems Visualization

## Overview
This scene demonstrates spring-mass physics systems with interconnected mass points connected by springs. It showcases Hooke's Law, damping, and how deformable objects behave under various forces.

## Features
- **Mass Points**: Individual particles with mass and position
- **Spring Connections**: Elastic connections between mass points
- **Grid Structure**: Organized spring-mass network
- **Visual Springs**: Color-coded spring visualization
- **Fixed Points**: Anchor points for stable structures

## Physics Implementation
- **Hooke's Law**: F = -kx spring force calculation
- **Damping**: Velocity reduction for realistic motion
- **Gravity**: Downward force on all mass points
- **Spring Visualization**: Color changes based on stretch/compression
- **Real-time Integration**: Continuous physics updates

## Controls
- **Reset System**: Restores all mass points to initial positions
- **Pause/Resume**: Toggles physics simulation on/off

## Technical Details
- **Engine**: Godot 4
- **Language**: GDScript
- **Scene Type**: 3D Visualization
- **Physics**: Custom spring-mass implementation
- **Visualization**: Dynamic spring coloring and mass point rendering

## Files
- `springmass.tscn` - Main scene file
- `SpringMassSystem.gd` - Spring-mass physics simulation script
- `MassPoint.gd` - Individual mass point physics script

## Usage
1. Open the scene in Godot 4
2. Run the scene to see the spring-mass system in action
3. Use the UI controls to reset or pause the simulation
4. Observe how springs stretch and compress
5. Watch the wave-like motion through the system

## Educational Value
This visualization helps understand:
- Hooke's Law and spring physics
- How interconnected systems behave
- Wave propagation through elastic materials
- Real-world applications in engineering and biology
- Deformable object simulation concepts
