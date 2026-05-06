# Double Pendulum

Two connected pendulum rods demonstrating deterministic chaos — tiny differences in initial conditions lead to wildly different trajectories.

## QFEP Connection

The double pendulum is the **canonical example of chaotic dynamics**. The equations are deterministic (F), but the system is so sensitive to initial conditions that prediction becomes impossible (effective E). This is λ at its most dramatic: perfect mathematical rules producing unpredictable behavior.

## How It Works

```
    ○ ← Anchor (fixed)
    │
    │ ← Upper rod (PinJoint to anchor)
    │
    ○ ← Middle joint (PinJoint)
    │
    │ ← Lower rod
    │
    ○ ← End mass
```

Two rigid cylinders connected by pin joints:
1. Upper rod pivots from fixed anchor
2. Lower rod pivots from end of upper rod
3. Gravity acts on both
4. Small initial nudge starts the motion

## Chaos Demonstration

Run the simulation twice with nearly identical starting positions. Within seconds, the trajectories diverge completely. This is **sensitive dependence on initial conditions** — the butterfly effect.

## Controls

| Input | Action |
|-------|--------|
| Space/Enter | Apply impulse to lower rod |

## Physics Setup

- **Anchor**: StaticBody3D (fixed point)
- **Upper Rod**: RigidBody3D, mass 1.4
- **Lower Rod**: RigidBody3D, mass 1.4
- **Joints**: PinJoint3D with collision exclusion
- **Material**: Low friction (0.2), slight bounce (0.1)

## Files

| File | Purpose |
|------|---------|
| `DoublePendulum.tscn` | Scene |
| `DoublePendulum.gd` | Setup and nudge logic |
| `../shared/joint_demo_base.gd` | Base class for joint demos |

## Mathematical Background

The double pendulum has 4 degrees of freedom (2 angles, 2 angular velocities) and no closed-form solution. The equations of motion:

```
θ₁'' = f(θ₁, θ₂, θ₁', θ₂', m₁, m₂, l₁, l₂, g)
θ₂'' = g(θ₁, θ₂, θ₁', θ₂', m₁, m₂, l₁, l₂, g)
```

These coupled differential equations are solved numerically by Godot's physics engine.

## VR Experience

Watch the pendulum swing from different angles. The chaotic motion is mesmerizing — it never repeats, yet follows deterministic physics. Try nudging it with the Space key and observe how the same nudge from different states produces completely different results.

## Lyapunov Exponent

The system has a positive Lyapunov exponent, meaning nearby trajectories diverge exponentially. For the double pendulum, this exponent is approximately 0.5-1.0 depending on energy, meaning errors double every 1-2 seconds.

## See Also

- `01_pendulum_pin/` — Single pendulum (non-chaotic)
- `chaos/` — Other chaotic systems (Lorenz, Rössler)
