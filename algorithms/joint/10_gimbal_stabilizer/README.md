# Gimbal Stabilizer

Multi-axis rotation using stacked hinge joints — camera gimbal mechanics with motorized control.

## QFEP Connection

A gimbal **isolates axes of rotation**. Each hinge allows rotation around one axis only (high F per joint), but stacked together they provide full orientation control (E in the output space). This is constraint as enablement — limitations on individual joints create capability in the system.

## Structure

```
    ╔════════════╗
    ║  Pedestal  ║  ← Static base
    ╚════════════╝
          │
          ○ ← Yaw hinge (vertical axis)
          │
    ╔════════════╗
    ║ Yaw Frame  ║  ← Rotates left/right
    ╚════════════╝
          │
          ○ ← Pitch hinge (horizontal axis)
          │
    ╔════════════╗
    ║Pitch Frame ║  ← Tilts up/down
    ╚════════════╝
          │
          ○ ← Pin joint (payload attachment)
          │
    ╔════════════╗
    ║  Payload   ║  ← Camera/sensor
    ╚════════════╝
```

## Joints

### Yaw Joint (HingeJoint3D)
- **Axis**: Vertical (Y)
- **Limits**: None (full rotation)
- **Motor**: Enabled, slow rotation
- Rotates the entire gimbal left/right

### Pitch Joint (HingeJoint3D)
- **Axis**: Horizontal (rotated 90°)
- **Limits**: ±45°
- **Motor**: Enabled
- Tilts the payload up/down

### Payload Joint (PinJoint3D)
- Attaches payload to pitch frame
- Allows some play/wobble

## Motor Configuration

```gdscript
# Enable motor
hinge.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
# Set torque (required!)
hinge.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, 60.0)
# Set target velocity
hinge.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, 0.2)
```

## Files

| File | Purpose |
|------|---------|
| `gimbal_stabilizer.gd` | Demo implementation |
| `*.tscn` | Scene file |

## Usage

```gdscript
var gimbal = preload("res://algorithms/joint/10_gimbal_stabilizer/gimbal_stabilizer.tscn").instantiate()
add_child(gimbal)
```

## VR Experience

Watch the gimbal rotate slowly on its yaw axis. The pitch frame tilts within its limits. The payload stays oriented while the frames move around it. This is how camera stabilizers work — isolating the camera from the operator's movement.

## Real-World Applications

- **Camera gimbals**: Steady footage while moving
- **Spacecraft attitude**: Controlling orientation
- **Telescope mounts**: Tracking celestial objects
- **Inertial measurement**: Gyroscope systems

## Gimbal Lock

When two axes align, you lose a degree of freedom — this is "gimbal lock." With only 2 axes here, it's limited, but full 3-axis gimbals must account for this. (Quaternions avoid gimbal lock entirely.)

## See Also

- `03_hinge_crank/` — Simpler hinge example
- `shared/` — Base class documentation
- `transformation/` — Rotation mathematics
