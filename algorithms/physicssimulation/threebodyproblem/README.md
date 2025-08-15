# Three-Body Problem Visualization

## Overview
This scene demonstrates the famous Three-Body Problem from celestial mechanics, showing how three gravitational bodies interact in a complex orbital dance. The simulation reveals the chaotic nature of multi-body gravitational systems.

## Features
- **Three Celestial Bodies**: Different colored spheres representing celestial objects
- **Gravitational Interaction**: Realistic gravitational forces between all bodies
- **Orbital Trails**: Visual paths showing the complex orbital patterns
- **Mass Adjustment**: Interactive control over body masses
- **Star Field Background**: Immersive space environment

## Physics Implementation
- **Gravitational Force**: F = G * m1 * m2 / r² calculation
- **Multi-Body Dynamics**: All bodies affect each other simultaneously
- **Trail System**: Dynamic trail rendering showing orbital history
- **Mass Scaling**: Adjustable mass values affecting gravitational strength
- **Real-time Integration**: Continuous physics updates

## Controls
- **Reset Simulation**: Restores all bodies to initial positions
- **Pause/Resume**: Toggles physics simulation on/off
- **Mass Adjustment**: Modify individual body masses

## Technical Details
- **Engine**: Godot 4
- **Language**: GDScript
- **Scene Type**: 3D Visualization
- **Physics**: Custom gravitational force implementation
- **Trail System**: Dynamic line rendering with fade effect

## Files
- `threebodyproblem.tscn` - Main scene file
- `ThreeBodyProblem.gd` - Gravitational simulation script
- `CelestialBody.gd` - Individual body physics script

## Usage
1. Open the scene in Godot 4
2. Run the scene to see the three-body gravitational dance
3. Use the UI controls to reset, pause, or adjust masses
4. Observe the complex and often chaotic orbital patterns
5. Experiment with different mass configurations

## Educational Value
This visualization helps understand:
- The complexity of multi-body gravitational systems
- Why the three-body problem has no general analytical solution
- How small changes in initial conditions lead to vastly different outcomes
- The chaotic nature of certain physical systems
- Real-world applications in astronomy and space navigation
