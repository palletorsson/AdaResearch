# Physics Simulation: Foundations - Map Summary

## Overview

This map teaches the mathematical bedrock of all physics simulation. It answers three questions in sequence: *What are the rules?* (Newton's laws), *How do we approximate them on a computer?* (numerical integration), and *What's the best way to do it?* (Verlet integration). Every subsequent physics map builds on these foundations.

## Spatial Layout

- **9×11 platform**, clean geometric gallery
- **Max height: 3** — low-profile, whiteboard-room aesthetic
- **Raised central platform** (height 2) in a diamond shape, housing the Verlet integration artifact
- **Octagonal floor plan** with beveled corners creating an intimate, focused space
- **Wall height 3** enclosing the perimeter, open ceiling with sky backdrop

## Key Elements

### Interactables

| Artifact | Position | Facing | Height | Purpose |
|----------|----------|--------|--------|---------|
| `newtons_laws` | West (2,3) | North | 1 | Demonstrates F=ma, action-reaction pairs, inertia. The three laws as interactive demonstrations. |
| `numerical_integration` | East (6,3) | South | 1 | Shows Euler integration stepping through time — visible accumulation of error over frames. |
| `verlet_integration` | Center (4,5) | North | 2 | The elevated centerpiece. Demonstrates Störmer-Verlet's position-based approach — same simulation, dramatically more stable. |

### Utilities

| Utility | Position | Purpose |
|---------|----------|---------|
| Spawn point | North center (4,0) | Player entry at height 5.5 — drops onto the platform |
| Teleporter | South center (4,10) | "To Bodies Lab" — continues to PhysicsSim_Bodies |
| Annotation boards | (3,2), (5,2), (3,8), (5,8) | Four boards flanking the space with explanatory notes |

## Atmosphere

- **Ambient light**: Cool blue-white (0.5, 0.5, 0.55) at 0.7 energy — clinical, intellectual
- **Directional light**: Warm white (1.0, 0.98, 0.95) from above-northwest — soft shadows, paper-like
- **Background**: Pale sky (0.85, 0.88, 0.92) — the whiteboard room
- **Grid visible**: Yes — reinforcing the mathematical nature of the space
- **Feel**: A clean lecture hall. Chalk dust and light. The room where you learn the rules before entering the arena.

## Learning Sequence

1. **Player spawns** at height 5.5 above the north entrance, dropping onto the platform — immediately perceiving the layout from above.
2. **Encounters Newton's laws** (west station) — the theoretical foundation. Force, mass, acceleration. Every action has a reaction. Objects at rest stay at rest.
3. **Crosses to numerical integration** (east station) — sees the theory translated to discrete time steps. Euler's method: simple, intuitive, and visibly unstable over time.
4. **Ascends the central platform** to Verlet integration — the synthesis. Same physics, different method, dramatically better results. The "aha" moment: *how* you compute matters as much as *what* you compute.
5. **Reads annotation boards** for deeper context — mathematical notation, historical notes.
6. **Exits south** through the teleporter to PhysicsSim_Bodies, carrying the understanding that simulation is approximation, and approximation technique matters.

## Design Intent

The map is deliberately austere. No distractions, no spectacle — just three ideas presented in ascending order of sophistication. The central platform's elevation is meaningful: Verlet integration is literally and conceptually *above* the others, the synthesis that makes practical simulation possible. The whiteboard aesthetic signals "this is where you learn the math."

## Connection to Sequence

**Position**: Map 1 of 5 in the Physics Simulation sequence.
**Prerequisite**: None — this is the entry point.
**Prepares for**: PhysicsSim_Bodies (rigid bodies, collisions, constraints) — everything in Bodies relies on the integration methods learned here.
**Key handoff**: The player leaves understanding that `position += velocity * dt` is naive, and that Verlet's `new_pos = 2*pos - old_pos + accel*dt²` is the engine's real heartbeat.
