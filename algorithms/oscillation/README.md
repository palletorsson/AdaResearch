# Oscillation

Rotation, waves, pendulums. The mathematics of periodic motion.

## QFEP Connection

Oscillation is the **dynamic equilibrium** between order and entropy — the system moves but returns, explores but comes home. Pendulums embody this perfectly: gravity (F) pulls toward center, momentum (entropy) carries past it. The double pendulum shows how simple oscillation becomes chaos.

## Contents

Based on **Nature of Code Chapter 3: Oscillation**.

### Angular Motion

| File | Description |
|------|-------------|
| `example_3_1_angular_motion_using_rotate_vr.gd` | Basic rotation with angular velocity |
| `example_3_2_forces_with_arbitrary_angular_motion_vr.gd` | Torque and angular acceleration |
| `example_3_3_pointing_in_the_direction_of_motion_vr.gd` | Velocity-aligned orientation |
| `exercise_3_1_baton_vr.gd` | Spinning baton demonstration |
| `exercise_3_6_asteroids_vr.gd` | Asteroids-style rotation + thrust |

### Polar Coordinates & Spirals

| File | Description |
|------|-------------|
| `example_3_4_polar_to_cartesian_vr.gd` | (r, θ) → (x, y) conversion |
| `exercise_3_5_spiral_vr.gd` | Archimedes and logarithmic spirals |

### Simple Harmonic Motion

| File | Description |
|------|-------------|
| `example_3_5_simple_harmonic_motion_vr.gd` | Basic sine wave motion |
| `example_3_6_simple_harmonic_motion_ii_vr.gd` | SHM with amplitude/frequency control |
| `example_3_7_oscillator_objects_vr.gd` | Multiple oscillating objects |

### Waves

| File | Description |
|------|-------------|
| `example_3_8_static_wave_vr.gd` | Standing wave visualization |
| `example_3_9_the_wave_vr.gd` | Traveling wave animation |
| `exercise_3_11_oop_wave_vr.gd` | Object-oriented wave system |
| `exercise_3_12_additive_wave_vr.gd` | Fourier: sum of sines makes any wave |

### Pendulums & Springs

| File | Description |
|------|-------------|
| `example_3_10_swinging_pendulum_vr.gd` | Simple pendulum (gravity + constraint) |
| `example_3_11_a_spring_connection_vr.gd` | Hooke's law spring dynamics |
| `exercise_3_15_double_pendulum_vr.gd` | **Chaos!** Sensitive dependence on initial conditions |

### Misc

| File | Description |
|------|-------------|
| `example_1_10_accelerating_towards_the_mouse_vr.gd` | Seek behavior with oscillatory approach |

## Key Concepts

1. **Angular velocity & acceleration** — Rotation follows same rules as linear motion
2. **Simple Harmonic Motion** — x(t) = A·sin(ωt + φ)
3. **Pendulum** — Gravity creates restoring force → oscillation
4. **Waves** — Oscillation propagating through space
5. **Fourier synthesis** — Any periodic signal = sum of sines
6. **Double pendulum** — Deterministic chaos from coupled oscillators

## VR Experience

- Swing pendulums with hand tracking
- Watch chaos emerge from double pendulum
- Walk through wave fields
- Feel the rhythm of harmonic motion

## Files

- 18 GDScript files
- 18 scene files
- 0 documentation files (needs map docs!)
