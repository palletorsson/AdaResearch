# Nature of Code Chapter 5: Autonomous Agents

VR translations of Daniel Shiffman's steering behaviors — agents that seek, flee, wander, flock, and follow paths.

## QFEP Connection

Steering behaviors sit at the **edge of chaos**: agents have goals (F, order) but respond to dynamic environments (E, uncertainty). The magic happens when simple individual rules create complex collective behavior — flocking emerges from three local rules, no central control.

## Behaviors Implemented

| File | Behavior | Description |
|------|----------|-------------|
| `noc_5_01_seek_vr` | **Seek** | Steer toward target |
| `noc_5_02_arrive_vr` | **Arrive** | Seek with slowdown near target |
| `noc_5_03_stay_within_walls_vr` | **Boundaries** | Avoid walls, stay in bounds |
| `noc_5_04_flow_field_vr` | **Flow Field** | Follow vector field directions |
| `noc_5_05_path_following_simple_vr` | **Simple Path** | Follow line path |
| `noc_5_07_separation_vr` | **Separation** | Avoid crowding neighbors |
| `noc_5_08_separation_and_seek_vr` | **Combined** | Blend multiple behaviors |
| `noc_5_08_path_following_vr` | **Path Following** | Complex path navigation |
| `example_5_9_flocking_vr` | **Flocking** | Separation + Alignment + Cohesion |
| `example_5_9_flocking_with_binning_vr` | **Optimized Flocking** | Spatial partitioning for performance |
| `exercise_5_4_wander_vr` | **Wander** | Random steering with smoothness |
| `exercise_5_13_crowd_path_following_vr` | **Crowd** | Multiple agents following path |

## Reynolds' Steering Formula

```gdscript
steering = desired_velocity - current_velocity
steering = steering.limit_length(max_force)
acceleration += steering
velocity += acceleration
position += velocity
```

The core insight: don't set velocity directly, compute a **steering force** that gradually adjusts the agent's direction.

## Flocking (Boids)

Three simple rules create realistic bird/fish behavior:

| Rule | Description | Effect |
|------|-------------|--------|
| **Separation** | Steer away from nearby neighbors | Prevents collision |
| **Alignment** | Steer toward average heading of neighbors | Creates coherent movement |
| **Cohesion** | Steer toward average position of neighbors | Keeps flock together |

```gdscript
var separation = separate(neighbors)
var alignment = align(neighbors)
var cohesion = cohere(neighbors)

# Weight and combine
acceleration += separation * 1.5
acceleration += alignment * 1.0
acceleration += cohesion * 1.0
```

## Utility Functions

| File | Purpose |
|------|---------|
| `example_5_12_sine_cosine_lookup_table_vr` | Precomputed trig for performance |
| `exercise_5_9_angle_between_vr` | Vector angle calculations |

## Source

All implementations are translations from:
- **The Nature of Code** by Daniel Shiffman
- Original: Processing/p5.js
- License: CC BY-NC-SA 3.0

Adapted for:
- 3D space (Vector3 instead of Vector2)
- VR interaction
- Godot 4 / GDScript

## Usage

```gdscript
# Single behavior
var flocking = preload("res://algorithms/steering/noc_ch05/example_5_9_flocking_vr.tscn").instantiate()
add_child(flocking)

# Or load specific example
var seek = preload("res://algorithms/steering/noc_ch05/noc_5_01_seek_vr.tscn").instantiate()
```

## VR Experience

Watch agents navigate in 3D space. In flocking demos, you become the observer of emergent behavior — no single agent "knows" about the flock, yet the flock exists. In path following, see how agents smoothly correct their trajectories.

## Educational Value

These examples teach:
- **Vectors**: Direction and magnitude as first-class concepts
- **Emergent behavior**: Simple rules → complex systems
- **Force accumulation**: Multiple influences combined
- **Spatial reasoning**: Neighbors, distances, fields

## See Also

- `swarmintelligence/` — More collective behavior
- `forces/` — Physics-based motion
- `transformation/vector_field/` — Fields that agents follow
