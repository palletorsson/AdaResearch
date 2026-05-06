# Steering Behaviors

Autonomous agents with desires. Seek, flee, wander, flock.

## QFEP Connection

Steering behaviors bridge **individual agency** (local rules) and **collective emergence** (flocking, swarming). Each agent has its own F (desire to reach target) and the group creates φΔE through interaction — order emerging from local chaos.

## Contents

Based on **Nature of Code Chapter 5: Autonomous Agents**.

### Basic Behaviors

| File | Description |
|------|-------------|
| `noc_5_01_seek_vr.gd` | Seek — accelerate toward target |
| `noc_5_02_arrive_vr.gd` | Arrive — slow down when approaching target |
| `exercise_5_2_vr.gd` | Flee — accelerate away from threat |
| `exercise_5_4_wander_vr.gd` | Wander — random-ish exploration |

### Environment Interaction

| File | Description |
|------|-------------|
| `noc_5_03_stay_within_walls_vr.gd` | Wall avoidance / boundary behavior |
| `noc_5_04_flow_field_vr.gd` | Follow vector field (currents, wind) |
| `noc_5_05_path_following_simple_vr.gd` | Basic path following |
| `noc_5_08_path_following_vr.gd` | Advanced path following with prediction |
| `exercise_5_13_crowd_path_following_vr.gd` | Multiple agents following paths |

### Social Behaviors

| File | Description |
|------|-------------|
| `noc_5_07_separation_vr.gd` | Separation — avoid crowding neighbors |
| `noc_5_08_separation_and_seek_vr.gd` | Combined separation + seek |
| `example_5_9_flocking_vr.gd` | **Reynolds flocking** — separation + alignment + cohesion |
| `example_5_9_flocking_with_binning_vr.gd` | Optimized flocking with spatial binning |

### Utilities

| File | Description |
|------|-------------|
| `exercise_5_9_angle_between_vr.gd` | Calculate angles between vectors |
| `example_5_12_sine_cosine_lookup_table_vr.gd` | Fast trig via lookup tables |

## Key Concepts

1. **Steering = Desired - Current** — Force to change velocity
2. **Seek** — Go there (arrive slows down)
3. **Flee** — Get away from threat
4. **Wander** — Constrained random walk (not jittery)
5. **Reynolds Flocking** — Three rules create birds/fish/crowds:
   - **Separation** — Don't crowd neighbors
   - **Alignment** — Steer toward average heading
   - **Cohesion** — Steer toward center of mass
6. **Flow fields** — Environmental steering forces

## VR Experience

- Be inside a flock as it self-organizes
- Place attractors and watch agents seek
- Walk through flow fields
- Experience emergent crowd behavior

## Files

- 15 GDScript files
- 15 scene files
- 0 documentation files (needs map docs!)
