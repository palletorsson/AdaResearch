# Physics Simulation: Continuum Mechanics - Map Summary

## Overview

This map teaches the simulation of continuous matter — substances that flow, flex, and deform without discrete boundaries. It covers the two great discretization strategies (SPH for fluids, FEM for solids), the compromise of soft bodies, the exotic case of magnetic simulation, and the artistic synthesis of the surreal kinetic sculpture where physics becomes medium rather than subject.

## Spatial Layout

- **Laboratory architecture** (dimensions TBD — map_data.json pending)
- **Five stations** progressing from fluid to solid to hybrid to exotic to artistic
- **Contained volumes** — tanks, chambers, display cases — because continuous matter needs boundaries to be legible
- **Central sculptural element** (the kinetic sculpture) as the focal point and culmination

## Key Elements

### Interactables

| Artifact | Position | Purpose |
|----------|----------|---------|
| `fluid_simulation` | First station | Smoothed Particle Hydrodynamics (SPH): continuous fluid approximated as particles with smoothing kernels. Pressure, viscosity, surface tension. Water in a virtual tank. |
| `fem_simulation` | Second station | Finite Element Method: continuous solid discretized into triangular/tetrahedral elements. Stress, strain, deformation. A beam bends under load — the math of structural engineering. |
| `soft_bodies` | Third station | The compromise between rigid and fluid. Pressure-based soft bodies, shape-matching. Objects that squish but recover. Jelly, rubber, biological tissue. |
| `magnetic_simulation` | Fourth station | Electromagnetic fields and their effect on matter. Ferrofluids, magnetic attraction/repulsion, field-dependent material behavior. An exotic force that doesn't fit the gravitational paradigm. |
| `surreal_kinetic_sculpture` | Final station | The synthesis and transcendence: a sculpture that uses all the physics systems — fluid, elastic, magnetic, gravitational — to create something that is no longer a demonstration but an artwork. Physics as creative medium. |

### Utilities

| Utility | Position | Purpose |
|---------|----------|---------|
| Spawn point | Entry | Laboratory entrance |
| Teleporter | Exit | Sequence complete — returns to map hub or sequence overview |
| Annotation boards | Throughout | SPH mathematics, FEM basis functions, continuum mechanics notation |

## Atmosphere

- **Feel**: A research laboratory where experiments are running. Fluid tanks bubble, FEM meshes deform under load, soft bodies wobble. The kinetic sculpture in the center moves ceaselessly, hypnotically.
- **Visual richness**: This is the most visually complex map in the sequence. Fluids shimmer, solids stress-color under load, magnetic field lines arc through space.
- **Culmination aesthetic**: The shift from science to art. The first four stations are demonstrations; the fifth is a statement.

## Learning Sequence

1. **Player enters** from PhysicsSim_Fields, transitioning from discrete particles to continuous matter.
2. **Fluid simulation (SPH)** — learns how continuous fluid is approximated by particles with smoothing kernels. Each particle carries density, pressure, velocity. Navier-Stokes made computational.
3. **FEM simulation** — learns the complementary approach for solids. Continuous material discretized into elements, each with shape functions. Stress and strain computed per element.
4. **Soft bodies** — the middle ground. Not rigid (they deform), not fluid (they recover). Pressure soft bodies, shape matching, volume preservation.
5. **Magnetic simulation** — an exotic force. Not gravity (it's dipolar, not monopolar). Ferrofluids, field visualization, material response to electromagnetic fields.
6. **Surreal kinetic sculpture** — the culmination of the entire five-map sequence. All the physics learned across all maps — Newton's laws, integration, collision, springs, fields, fluids, FEM — combined into a single kinetic artwork. The player sees physics as creative medium, not just scientific tool.
7. **Exits** — the sequence is complete.

## Design Intent

The map moves from scientific demonstration to artistic expression. The first four stations are rigorous — each teaches a specific discretization technique for continuous media. The kinetic sculpture at the end breaks this pattern deliberately: it uses the same techniques but for aesthetic rather than pedagogical purposes. This transition says: *now that you understand the tools, look at what you can create with them.*

## Connection to Sequence

**Position**: Map 5 of 5 in the Physics Simulation sequence. The finale.
**Prerequisite**: All prior maps — Foundations (integration), Bodies (rigid objects), Springs (elastic connections), Fields (force fields, particles).
**Prepares for**: Nothing — this is the culmination. But the techniques learned here (SPH, FEM, soft bodies) are foundational for any advanced simulation work.
**Key handoff**: The player leaves the sequence understanding the full arc: from Newton's laws (the rules) through integration (the approximation) through bodies, springs, fields, and fluids (the applications) to art (the purpose). Physics simulation is not just science — it's a creative medium.
