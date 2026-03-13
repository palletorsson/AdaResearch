# Liquid Simulation

A particle-based fluid simulation that models two liquids (water and oil) mixing inside a transparent container. Each particle carries concentration properties that diffuse into neighbors over time, and the system tracks Shannon entropy to quantify how mixed the fluids have become.

## Concept Taught

**Particle-based simulation, diffusion, and entropy.** This artifact teaches how complex fluid behavior emerges from simple per-particle rules. Gravity pulls particles down, viscosity couples their velocities, pressure prevents clumping, and diffusion slowly transfers liquid properties between neighbors. As the two liquids intermingle, Shannon entropy rises -- a direct, visual measurement of disorder. Students see the second law of thermodynamics play out in real time: the system moves from an ordered, separated state toward a well-mixed equilibrium, and the entropy value quantifies that transition.

## How It Works

1. A transparent box container is created at the specified size.
2. Particles are spawned in two groups -- water on the left, oil on the right -- each carrying 100% concentration of its type.
3. A spatial hash grid partitions particles into cells for efficient neighbor lookup.
4. Each frame runs multiple sub-steps for stability. Per sub-step:
   - The spatial grid is rebuilt.
   - Neighbors within the grid cell radius are found for every particle.
   - Forces are computed: gravity, viscous coupling (scaled by the particle's effective viscosity), and pressure repulsion.
   - Positions are updated using velocity Verlet integration.
   - Boundary conditions bounce particles off container walls with damping.
   - Diffusion transfers concentration values between neighboring particles, then renormalizes so concentrations sum to 1.0.
5. Particle colors are blended based on their mixed concentrations.
6. Shannon entropy is calculated from the global distribution of liquid types and displayed on a Label3D.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `container_size` | Vector3 | (2, 1, 2) | Dimensions of the liquid container |
| `particle_count` | int | 100 | Total number of simulation particles |
| `simulation_steps_per_frame` | int | 5 | Sub-steps per frame for stability |
| `gravity` | float | 9.8 | Gravitational acceleration |
| `viscosity_multiplier` | float | 1.0 | Scales effective viscosity |
| `diffusion_rate` | float | 0.05 | Rate of concentration transfer between neighbors |
| `show_entropy` | bool | true | Display the entropy label |

## Features

- Three built-in liquid types: water (low viscosity), oil (medium viscosity, lower density), and honey (high viscosity, higher density)
- Spatial hash grid for O(N) neighbor finding instead of O(N^2)
- Velocity Verlet integration for stable physics
- Per-particle mixed-state tracking with concentration dictionaries
- Diffusion-based mixing with automatic normalization
- Real-time Shannon entropy calculation and display
- Soft boundary conditions with bounce damping
- Public API: `add_liquid(position, type, amount)` to pour additional liquids, `get_entropy()` to read current entropy

## Files

| File | Purpose |
|------|---------|
| `liquid_simulation.gd` | Full particle simulation -- physics, spatial hashing, diffusion, entropy, and rendering |
