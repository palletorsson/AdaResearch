# Character Ragdoll

Humanoid joint constraints using ConeTwistJoint3D — the physics of body articulation and realistic character physics.

## QFEP Connection

Human joints are **biologically constrained** — your elbow bends one way, not the other; your hip has cone-shaped range of motion. ConeTwistJoint3D encodes these limits (F) while allowing natural movement (E). A ragdoll without limits flails unnaturally; one with proper limits falls believably.

## Joint Type: ConeTwistJoint3D

```
        Torso
          │
    ┌─────┼─────┐  ← Cone of allowed motion
    │     │     │
    │     ○     │  ← Joint center
    │    /│\    │
    └───/ │ \───┘
       /  │  \
      Leg range
```

Parameters:
- `swing_span`: Cone angle (how far leg can swing)
- `twist_span`: Rotation around leg axis
- `bias`: Joint error correction strength
- `softness`: Joint compliance
- `relaxation`: How quickly joint settles

## Demo Structure

```
    ╔════════╗
    ║ Torso  ║  ← Heavy rigid body (mass: 6)
    ╚════════╝
        │
        ○  ← ConeTwistJoint3D (hip)
        │
    ╔════════╗
    ║  Leg   ║  ← Lighter rigid body (mass: 4)
    ╚════════╝
```

## Joint Settings

```gdscript
joint.swing_span = deg_to_rad(35.0)  # 35° cone
joint.twist_span = deg_to_rad(25.0)  # 25° twist
joint.bias = 0.3       # Moderate correction
joint.softness = 0.8   # Somewhat compliant
joint.relaxation = 1.0 # Normal settling
```

## Files

| File | Purpose |
|------|---------|
| `character_ragdoll.gd` | Joint demo |
| `*.tscn` | Scene file |

## Usage

```gdscript
var ragdoll = preload("res://algorithms/joint/08_character_ragdoll/character_ragdoll.tscn").instantiate()
add_child(ragdoll)
# Press spacebar to kick the leg
```

## VR Experience

Watch the torso and leg. Press spacebar (or interact) to apply impulse to the leg — it swings within its allowed cone but can't go beyond. The joint feels "real" because it has biological limits. Compare to a pin joint which would allow full rotation.

## Human Joint Types

| Body Joint | Godot Joint | Swing | Twist |
|------------|-------------|-------|-------|
| Hip | ConeTwistJoint3D | ~45° | ~30° |
| Knee | HingeJoint3D | ~140° | 0° |
| Shoulder | ConeTwistJoint3D | ~90° | ~90° |
| Elbow | HingeJoint3D | ~140° | ~90° |
| Wrist | ConeTwistJoint3D | ~80° | ~80° |

## Applications

- **Ragdoll physics**: Characters falling, being thrown
- **Inverse kinematics**: Constrained animation
- **Physical simulation**: Realistic body mechanics
- **Games**: Death animations, physics puzzles

## See Also

- `06_cone_twist_bag/` — Simpler cone twist example
- `shared/` — Base class documentation
- `physicssimulation/` — Other physics simulations
