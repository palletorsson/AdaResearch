# Nature of Code Chapter 1: Vectors

VR translations of Daniel Shiffman's vector fundamentals — the building blocks of physics simulation and motion.

## QFEP Connection

Vectors are **the language of change** — direction + magnitude. They describe how things move, where forces point, what direction to look. Understanding vectors is prerequisite for all physics-based simulation. Pure F (mathematics) enabling the description of E (dynamic systems).

## Examples Included

| File | Topic | Description |
|------|-------|-------------|
| `example_1_1_bouncing_ball_with_no_vectors_vr` | **Without Vectors** | Separate x, y, z variables |
| `example_1_2_bouncing_ball_with_vectors_vr` | **With Vectors** | Single Vector3 for position/velocity |
| `example_1_3_vector_subtraction_vr` | **Subtraction** | Direction between points |
| `example_1_4_vector_multiplication_vr` | **Multiplication** | Scaling vectors |
| And more... | **Operations** | Normalize, limit, dot product |

## Core Concepts

### Vector Basics
```gdscript
var position = Vector3(x, y, z)
var velocity = Vector3(vx, vy, vz)
var acceleration = Vector3(ax, ay, az)
```

A vector bundles components into a single object.

### Motion Update
```gdscript
velocity += acceleration
position += velocity
```

The fundamental simulation loop — acceleration changes velocity, velocity changes position.

### Vector Operations

| Operation | Code | Result |
|-----------|------|--------|
| Addition | `a + b` | Combined effect |
| Subtraction | `a - b` | Direction from b to a |
| Multiplication | `a * scalar` | Scale magnitude |
| Normalize | `a.normalized()` | Unit vector (length 1) |
| Magnitude | `a.length()` | Vector length |
| Limit | `a.limit_length(max)` | Cap magnitude |

### Why Vectors Matter

Without vectors:
```gdscript
x += xspeed
y += yspeed
z += zspeed
# Repeat for every object, every property
```

With vectors:
```gdscript
position += velocity
# Clean, extensible, dimension-agnostic
```

## Source

All implementations translated from:
- **The Nature of Code** by Daniel Shiffman
- Original: Processing/p5.js
- License: CC BY-NC-SA 3.0

Adapted for Godot 4, 3D space, and VR interaction.

## Usage

```gdscript
var bouncing = preload("res://algorithms/vectors/noc_ch01/example_1_2_bouncing_ball_with_vectors_vr.tscn").instantiate()
add_child(bouncing)
```

## VR Experience

Watch balls bounce in 3D space. The "without vectors" example shows how messy code gets with separate components; the "with vectors" version shows the elegance of vector math. Interactive controllers let you adjust parameters in real-time.

## Educational Progression

1. **1.1**: Bouncing without vectors (see the pain)
2. **1.2**: Bouncing with vectors (see the improvement)
3. **1.3**: Vector subtraction (pointing at things)
4. **1.4**: Vector multiplication (scaling)
5. Further: Normalization, limiting, acceleration

## See Also

- `forces/` — Vectors as forces
- `steering/` — Vectors for autonomous agents
- `oscillation/` — Angular vectors
