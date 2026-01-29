# Forces

Newton's laws in VR. Push, pull, resist, attract.

## QFEP Connection

Forces are the **F** in QFEP — the predictive, order-seeking component. Gravity creates orbits, friction dampens chaos, attraction builds structure. But add enough bodies (n-body problem) and deterministic forces create chaotic, unpredictable motion.

## Contents

Based on **Nature of Code Chapter 2: Forces**.

| File | Description |
|------|-------------|
| `example_2_1_forces_vr.gd` | Basic force application — push and acceleration |
| `example_2_2_forces_mass_variation_vr.gd` | F=ma with different masses |
| `example_2_3_gravity_scaled_by_mass_vr.gd` | Gravitational scaling (why all objects fall equally) |
| `example_2_4_friction_vr.gd` | Kinetic friction opposing motion |
| `example_2_5_fluid_resistance_vr.gd` | Drag in fluids (velocity² resistance) |
| `example_2_6_single_attractor_vr.gd` | Point mass gravitational attraction |
| `example_2_7_multiple_attractors_vr.gd` | Multiple attractors creating complex orbits |
| `example_2_8_two_body_attraction_vr.gd` | Mutual gravitational attraction |
| `example_2_9_n_body_attraction_vr.gd` | N-body problem — deterministic chaos |

### Tools

| File | Description |
|------|-------------|
| `algo_gun.gd` | Gun that shoots physics objects |
| `gravity_gun.gd` | Half-Life style gravity manipulation |

## Key Concepts

1. **Newton's Second Law** — F = ma (force equals mass times acceleration)
2. **Superposition** — Multiple forces sum to net force
3. **Friction** — Opposes motion, proportional to normal force
4. **Drag** — Fluid resistance proportional to velocity squared
5. **Gravitational attraction** — F = G(m₁m₂)/r²
6. **N-body chaos** — Three+ bodies create unpredictable long-term behavior

## VR Experience

- Feel forces through visual acceleration
- Manipulate attractors with hands
- Experience n-body chaos in 3D
- Use gravity gun to move objects

## Files

- 15 GDScript files
- 10 scene files
- 3 documentation files
