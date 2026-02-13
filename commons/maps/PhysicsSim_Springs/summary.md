# Physics Simulation: Springs & Elastic Connections - Map Summary

## Overview

This map teaches the physics of deformable connection. Where the Bodies map dealt with solid, unyielding objects, Springs introduces elasticity — the ability to stretch, compress, oscillate, and eventually produce emergent complexity like cloth. Hooke's law (F = -kx) is the single equation that generates all of it.

## Spatial Layout

- **Corridor gallery** architecture (dimensions TBD — map_data.json pending)
- **Linear progression** from simple to complex: single spring → spring-mass system → spring network → cloth
- **Elongated form factor** encouraging a walk-through experience rather than hub-and-spoke
- **Hanging elements** suggested by the cloth simulation — vertical emphasis

## Key Elements

### Interactables

| Artifact | Position | Purpose |
|----------|----------|---------|
| `mass_spring_damper` | First station | The fundamental oscillator: one mass, one spring, one damper. Demonstrates the second-order ODE: mx'' + cx' + kx = 0. Shows underdamped, critically damped, and overdamped behavior. |
| `spring_mass_system` | Second station | Multiple masses connected by springs in a chain. Standing waves, propagation, resonance. The first hint that connected springs create behavior no single spring exhibits. |
| `spring_system` | Third station | A 2D network of springs — lattice or mesh. Structural springs, shear springs, bend springs. The topology of connection determines the material's character. |
| `cloth_simulation` | Final station | The culmination: a grid of particles connected by springs that behaves like fabric. Wind, gravity, collision with objects. The most visible and intuitive result of spring physics. |

### Utilities

| Utility | Position | Purpose |
|---------|----------|---------|
| Spawn point | Entry end | Gallery entrance |
| Teleporter | Exit end | "To Fields Observatory" — continues to PhysicsSim_Fields |
| Annotation boards | Along corridor | Progressive explanations of spring mathematics |

## Atmosphere

- **Feel**: A corridor of hanging things. Pendulums, curtains, elastic meshes. Everything sways and oscillates. The room itself seems to breathe.
- **Progression**: From the sterile single-spring oscillator to the organic billow of cloth — the aesthetic shifts from mechanical to textile as you walk through.
- **Sound design** (implied): Oscillation, resonance, the twang of springs. Rhythmic, almost musical.

## Learning Sequence

1. **Player enters** from PhysicsSim_Bodies, transitioning from rigid to elastic.
2. **Mass-spring-damper** — the simplest oscillator. One mass, one spring. Pull it, release it, watch it bounce. Adjust damping and watch energy dissipate. This is the atom of deformable physics.
3. **Spring-mass system** — connect oscillators in a chain. Suddenly: wave propagation, standing waves, resonance frequencies. Emergence from connection.
4. **Spring system** — extend to 2D. A lattice of springs behaves like a material. Different spring topologies (structural, shear, bend) create different material properties.
5. **Cloth simulation** — the grand demonstration. All the springs working together produce fabric that drapes, ripples, tears, and responds to wind. The player sees their earlier lessons made tangible.
6. **Exits** to PhysicsSim_Fields — from connected bodies to fields of force.

## Design Intent

The corridor format is intentional: springs are about *connection in sequence*. The linear layout mirrors the way springs themselves chain together. Each station adds complexity by adding connections — the map's architecture embodies its lesson. Cloth at the end is the payoff: something visually rich and immediately understood (everyone knows what cloth looks like) built entirely from the simple F = -kx learned at the first station.

## Connection to Sequence

**Position**: Map 3 of 5 in the Physics Simulation sequence.
**Prerequisite**: PhysicsSim_Bodies (rigid bodies, constraints) — springs connect bodies; constraints are the rigid version of what springs do elastically.
**Prepares for**: PhysicsSim_Fields (force fields, particle systems, n-body) — fields apply forces to many particles simultaneously, a generalization of the spring forces learned here.
**Key handoff**: The player leaves understanding that F = -kx plus many connections equals emergent material behavior. In Fields, the forces will come not from connections but from space itself.
