# Magnetic Field Simulation

## Overview
This implementation simulates magnetic field interactions and particle dynamics in electromagnetic environments. The algorithm visualizes magnetic field lines, particle trajectories, and electromagnetic forces, providing an interactive physics simulation for educational and research purposes.

## Algorithm Description
The magnetic field simulation models electromagnetic interactions using classical physics principles. It calculates magnetic field vectors, applies Lorentz forces to charged particles, and visualizes the resulting dynamics in real-time 3D space.

### Key Components
1. **Magnetic Field Generation**: Creates field sources (magnets, coils, currents)
2. **Field Line Visualization**: Renders magnetic field lines and equipotential surfaces
3. **Particle Dynamics**: Simulates charged particle motion in magnetic fields
4. **Force Calculations**: Applies electromagnetic forces (Lorentz force law)
5. **Interactive Controls**: Real-time parameter adjustment and field manipulation

### Physics Implementation
- **Magnetic Field Equations**: Uses Biot-Savart law and magnetic dipole models
- **Lorentz Force**: F = q(v × B) for particle trajectory calculation
- **Field Superposition**: Combines multiple magnetic sources
- **Energy Conservation**: Maintains physical accuracy in simulations

## Algorithm Flow
1. **Field Source Setup**: Define magnetic dipoles, current loops, or permanent magnets
2. **Field Calculation**: Compute magnetic field vectors throughout space
3. **Particle Initialization**: Place charged particles with initial velocities
4. **Force Application**: Calculate and apply electromagnetic forces
5. **Trajectory Integration**: Update particle positions using numerical integration
6. **Visualization Update**: Render field lines, particles, and force vectors

## Files Structure
- `MagneticSimulation.gd`: Main electromagnetic physics engine
- `magnetic_field.tscn`: 3D visualization scene
- Particle system and field visualization components

## Parameters
- **Field Strength**: Magnetic field intensity (Tesla)
- **Particle Properties**: Charge, mass, initial velocity
- **Source Configuration**: Magnet positions, orientations, strengths
- **Simulation**: Time step, integration method, boundary conditions
- **Visualization**: Field line density, particle trails, vector display

## Theoretical Foundation
Based on:
- **Electromagnetic Theory**: Maxwell's equations and magnetic field physics
- **Classical Mechanics**: Particle motion under electromagnetic forces
- **Numerical Methods**: Runge-Kutta integration for trajectory calculation
- **Vector Field Theory**: Mathematical field representation and visualization

## Applications
- Physics education and demonstration
- Electromagnetic device design
- Particle accelerator simulation
- Magnetic confinement research
- Motor and generator modeling
- Scientific visualization

## Visual Features
- Real-time magnetic field line rendering
- Particle trajectory trails
- Force vector visualization
- Multiple magnetic source types
- Interactive field manipulation

## Usage
Set up magnetic field sources and release charged particles to observe their trajectories. Experiment with different field configurations to study electromagnetic phenomena like cyclotron motion, magnetic bottles, and particle focusing effects.