# Nature of Code Chapter 3: Oscillation

VR translations of Daniel Shiffman's oscillation examples — angular motion, pendulums, springs, and harmonic motion.

## QFEP Connection

Oscillation is **F and E in eternal dance** — systems that swing between states without settling. Pendulums trade potential and kinetic energy, springs compress and extend, waves rise and fall. This is λ at equilibrium: the system finds a stable cycle rather than collapsing to rest.

## Examples Included

| File | Topic | Description |
|------|-------|-------------|
| `example_3_1_angular_motion_using_rotate_vr` | **Angular Motion** | Rotation basics |
| `example_3_10_swinging_pendulum_vr` | **Pendulum** | Simple harmonic motion |
| `example_3_11_a_spring_connection_vr` | **Spring** | Hooke's Law visualization |
| `example_1_10_accelerating_towards_the_mouse_vr` | **Acceleration** | Target seeking |

## Core Concepts

### Angular Motion
```gdscript
angle += angular_velocity
angular_velocity += angular_acceleration
```

Rotation follows the same pattern as linear motion — position/velocity/acceleration.

### Simple Harmonic Motion
```gdscript
x = amplitude * sin(angle)
angle += angular_velocity
```

The sine function creates smooth oscillation between -amplitude and +amplitude.

### Pendulum Physics
```
F = -g * sin(θ)
angular_acceleration = F / length
```

Gravity's component perpendicular to the pendulum arm creates the restoring force.

### Spring (Hooke's Law)
```
F = -k * x
```

Force proportional to displacement from rest length, opposite to displacement direction.

## Parameters

Most examples include interactive controllers:
- **Amplitude**: Oscillation range
- **Frequency/Angular Velocity**: Speed of oscillation
- **Damping**: Energy loss per cycle
- **Spring constant (k)**: Stiffness

## Source

All implementations translated from:
- **The Nature of Code** by Daniel Shiffman
- Original: Processing/p5.js
- License: CC BY-NC-SA 3.0

Adapted for Godot 4, 3D space, and VR interaction.

## Usage

```gdscript
var pendulum = preload("res://algorithms/oscillation/noc_ch03/example_3_10_swinging_pendulum_vr.tscn").instantiate()
add_child(pendulum)
```

## VR Experience

Watch pendulums swing in 3D space, springs bounce with realistic physics, and objects rotate with angular momentum. The 3D environment makes these physics concepts more intuitive than 2D visualizations.

## Educational Value

These examples teach:
- **Trigonometry**: Sin/cos as oscillation
- **Energy conservation**: Potential ↔ kinetic
- **Differential equations**: Acceleration → velocity → position
- **Damping**: Real-world friction effects

## See Also

- `wavefunctions/` — Wave-based oscillations
- `forces/` — Force-based physics
- `joint/` — Constrained oscillation (pendulums)
