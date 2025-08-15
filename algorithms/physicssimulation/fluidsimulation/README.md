# Fluid Simulation (SPH) Visualization

## Overview
This scene demonstrates Smoothed Particle Hydrodynamics (SPH) fluid simulation, showing how fluid particles interact through pressure, viscosity, and boundary forces. It provides a realistic representation of fluid behavior in 3D space.

## Features
- **Fluid Particles**: Individual particles representing fluid elements
- **SPH Algorithm**: Smoothed Particle Hydrodynamics implementation
- **Pressure Forces**: Density-based pressure calculations
- **Viscosity**: Fluid internal friction simulation
- **Boundary Collisions**: Container wall interactions
- **Dynamic Visualization**: Particle size and color changes based on density

## Physics Implementation
- **SPH Core**: Density calculation using smoothing kernels
- **Pressure Forces**: F = -∇P pressure gradient forces
- **Viscosity Forces**: Velocity smoothing between particles
- **Boundary Handling**: Collision detection with container walls
- **Real-time Integration**: Continuous particle physics updates

## Controls
- **Reset Fluid**: Restores all particles to initial positions
- **Pause/Resume**: Toggles fluid simulation on/off

## Technical Details
- **Engine**: Godot 4
- **Language**: GDScript
- **Scene Type**: 3D Visualization
- **Physics**: SPH fluid dynamics implementation
- **Visualization**: Dynamic particle rendering with density-based properties

## Files
- `fluidsimulation.tscn` - Main scene file
- `FluidSimulation.gd` - SPH fluid simulation script
- `FluidParticle.gd` - Individual fluid particle script

## Usage
1. Open the scene in Godot 4
2. Run the scene to see the fluid simulation in action
3. Use the UI controls to reset or pause the simulation
4. Observe how fluid particles flow and interact
5. Watch pressure waves and fluid dynamics

## Educational Value
This visualization helps understand:
- Smoothed Particle Hydrodynamics (SPH)
- How fluid pressure and viscosity work
- Real-time fluid simulation techniques
- Applications in game physics and engineering
- Particle-based simulation concepts
