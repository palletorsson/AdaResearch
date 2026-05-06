# Surreal Machines

A whimsical physics playground filled with interconnected mechanical contraptions -- pendulums, gears, pistons, conveyors, floating sculptures -- alongside soft-body blobs, cloth, and balloons, all wrapped in rainbow shaders and particle celebrations. The artifact teaches **physics joints and soft-body dynamics** by making every joint type in Godot 4 visible and tactile.

## Concept Taught

**Physics joint systems** are how game engines constrain rigid bodies to move relative to each other. Godot 4 offers `PinJoint3D`, `HingeJoint3D`, `SliderJoint3D`, `ConeTwistJoint3D`, and `Generic6DOFJoint3D`, each allowing different degrees of freedom. This artifact constructs five distinct machines that exercise all of these joint types, plus `SoftBody3D` objects that deform under forces. By watching pendulums swing on pin joints, pistons slide on slider joints, and gears mesh through 6DOF springs, the learner builds intuition for constrained multi-body physics.

## How It Works

1. **Rainbow Pendulum Machine** -- A chain of 5 capsule-shaped rigid bodies connected by `PinJoint3D` nodes, hanging from a static base. A weighted sphere at the end exaggerates the swing.
2. **Bouncy Gear Assembly** -- Four cylinder "gears" connected by `Generic6DOFJoint3D` joints with angular spring stiffness, producing wobbly coupled rotation.
3. **Floating Joint Sculpture** -- A central sphere orbited by 6 varied shapes (box, sphere, cylinder, torus), each connected by a different joint type (hinge, slider, cone-twist, pin) to demonstrate motion variety.
4. **Pride-Powered Engine** -- Three piston cylinders with `SliderJoint3D`-driven heads that oscillate up and down via tween animations.
5. **Celebration Conveyor** -- Eight box segments connected end-to-end with `HingeJoint3D` joints, forming a flexible belt.
6. **Soft Bodies** -- Bouncing blobs (pressurized spheres), a waving cloth flag, and lightweight balloons with strings, all using `SoftBody3D` with tuned stiffness and pressure.
7. **Particles** -- A rainbow fountain, confetti bursts at four positions, and sparkle trails attached to random mechanical parts.
8. **Shaders** -- A custom rainbow mechanical shader cycles through pride-flag colors with sparkle, and a celebration soft-body shader produces wobbling pastel glow.
9. Random impulses are applied to unfrozen parts each frame for organic movement.

## Parameters

| Export | Type | Default | Description |
|--------|------|---------|-------------|
| `machine_complexity` | int | `5` | Number of machine systems to create |
| `animation_speed` | float | `1.0` | Global animation speed multiplier |
| `physics_intensity` | float | `1.0` | Strength of random physics impulses |
| `rainbow_mode` | bool | `true` | Enable pride-flag rainbow color cycling |
| `bouncy_factor` | float | `1.5` | Multiplier for soft-body bounce forces |

## Features

- Five distinct mechanical contraptions exercising every Godot 4 joint type.
- Soft-body blobs, cloth, and balloons with configurable stiffness and pressure.
- Two custom GLSL shaders: rainbow metallic and celebration soft-body.
- GPU particle systems: rainbow fountain, confetti bursts, sparkle trails.
- Procedural sky with warm celebration lighting and bloom.
- Public API: `set_animation_speed()`, `toggle_rainbow_mode()`, `trigger_celebration_burst()`, `create_custom_machine_part()`, `add_joy_particles_to_object()`.

## Files

- `surreal_machines.gd` -- Main script: machine construction, soft bodies, particles, shaders, animation.
- `surreal_machines.tscn` -- Scene file.
