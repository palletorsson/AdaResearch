# Physics Simulation: Rigid Bodies & Collisions - Map Summary

## Overview

This map teaches what happens when simulated objects become *things* — solid, massy, capable of crashing into each other. It covers the four pillars of rigid body simulation: how bodies are represented (rigid body dynamics), how we detect contact (collision detection), how we restrict motion (constraints), and the simplest possible demonstration of it all working together (the bouncing ball).

## Spatial Layout

- **11×11 platform**, arena architecture
- **Max height: 3** — sunken central pit with raised walkways
- **Central 3×3 raised island** (height 1) surrounded by a zero-height moat — the collision arena floor
- **Raised perimeter ring** at heights 1 and 3 — observation walkways and walls
- **Octagonal symmetry** with beveled corners, four cardinal artifact stations

## Key Elements

### Interactables

| Artifact | Position | Facing | Height | Purpose |
|----------|----------|--------|--------|---------|
| `rigid_body` | North center (5,2) | North | 1 | Demonstrates rigid body state: position, orientation, linear velocity, angular velocity. How mass and inertia tensor define an object's resistance to forces and torques. |
| `collision_detection` | West (1,5) | East | 1 | Broad-phase (AABB) and narrow-phase (GJK/SAT) collision detection. Visualizes bounding boxes, contact points, collision normals. |
| `constraints` | East (9,5) | West | 1 | Joint constraints: hinges, ball-and-socket, sliders. How degrees of freedom are restricted between bodies. |
| `bouncing_ball` | South center (5,8) | South | 1 | The "hello world" — a ball falls, hits the ground, bounces. Demonstrates coefficient of restitution, energy loss, and the full simulation loop in its simplest form. |

### Utilities

| Utility | Position | Purpose |
|---------|----------|---------|
| Spawn point | North (4,0) | Player entry at height 5.5 — drops into the arena from above |
| Teleporter | South center (5,10) | "To Springs Gallery" — continues to PhysicsSim_Springs |

## Atmosphere

- **Ambient light**: Dark blue-gray (0.35, 0.35, 0.4) at 0.5 energy — dramatic, arena-like
- **Directional light**: Warm amber (1.0, 0.85, 0.7) at 1.4 energy — strong shadows, theatrical
- **Background**: Deep dark blue (0.15, 0.15, 0.25) — night sky, industrial
- **Grid visible**: Yes
- **Feel**: A crash-test facility. An arena where things collide under spotlights. The shift from the whiteboard room's calm to here signals: now the math becomes physical.

## Learning Sequence

1. **Player drops** into the arena from above, immediately seeing the four stations arranged around the central island — a compass rose of concepts.
2. **Rigid body** (north) — learns how objects are represented: position + orientation + velocities + mass properties. The data structure that makes something "solid."
3. **Collision detection** (west) — the hardest computational problem in the room. How do you know when two arbitrary shapes are touching? Broad phase filters, narrow phase confirms.
4. **Constraints** (east) — the opposite of collision. Instead of preventing overlap, constraints *enforce* relationships. Hinges, joints, ropes. Restriction as structure.
5. **Bouncing ball** (south) — the synthesis. Everything above, combined into the simplest possible demo. Gravity (Newton), integration (Verlet), collision (detection + response), energy loss (restitution). The whole pipeline in one bounce.
6. **Exits south** to PhysicsSim_Springs — from rigid to elastic.

## Design Intent

The arena layout is deliberate: collisions happen in arenas. The sunken pit with raised observation walkways creates a sense of watching experiments unfold below. The four cardinal stations create a natural circulation pattern — walk the perimeter, visit each station, converge on understanding. The bouncing ball at the south exit is the farewell demonstration: you now understand everything needed to simulate the simplest physical interaction.

## Connection to Sequence

**Position**: Map 2 of 5 in the Physics Simulation sequence.
**Prerequisite**: PhysicsSim_Foundations (Newton's laws, integration methods).
**Prepares for**: PhysicsSim_Springs (elastic connections, deformable objects) — springs connect bodies, and understanding rigid bodies is prerequisite to connecting them.
**Key handoff**: The player leaves knowing that rigid bodies are defined by state vectors, collisions are detection + response, and constraints add structure. Springs (next map) will connect these rigid bodies with elastic forces.
