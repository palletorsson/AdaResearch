# Physics Engine Basics

Rigid bodies, joints, constraints. Let the engine do the math.

## QFEP Connection

Physics engines enforce **constraints (F)** while allowing **dynamics (E)**. A chain is constrained but flows; a bridge holds but sways. The engine computes equilibrium between structure and force — order emerging from solved constraints.

## Contents

Based on **Nature of Code Chapter 6: Physics Libraries**.

| File | Description |
|------|-------------|
| `example_6_1_basic_rigidbody_vr.gd` | Basic RigidBody3D — mass, velocity, forces |
| `example_6_2_falling_boxes_vr.gd` | Multiple rigid bodies with collision |
| `example_6_3_compound_bodies_vr.gd` | Complex shapes from primitives |
| `example_6_4_windmill_vr.gd` | Rotating hinge joint |
| `example_6_5_chain_vr.gd` | Chain of connected bodies |
| `example_6_6_grab_vr.gd` | Picking up and manipulating objects |
| `example_6_7_bridge_vr.gd` | Bridge with physics joints |
| `example_6_8_collision_layers_vr.gd` | Selective collision (layers/masks) |

## Key Concepts

1. **Rigid body** — Object with mass, can move but not deform
2. **Collider** — Shape that detects/responds to collisions
3. **Joint/Constraint** — Connects bodies (hinge, pin, spring, slider)
4. **Collision layers** — Which objects collide with which
5. **Compound body** — Multiple shapes forming one rigid body
6. **Solver iterations** — More iterations = more accurate constraints

## Joint Types

```
Hinge:   ○──┤├──○   Rotate around axis (door, windmill)
Pin:     ○────○     Fixed point connection (pendulum)
Spring:  ○╌╌╌╌○     Elastic connection (bungee)
Slider:  ○════○     Move along axis (piston)
Fixed:   ○████○     No relative motion (weld)
```

## VR Experience

- Grab and throw physics objects
- Build with joints and constraints
- Walk across physics bridges
- Feel the weight through visual feedback

## Files

- 8 GDScript files
- 8 scene files
