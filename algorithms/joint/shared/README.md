# Joint Demos - Shared

Base class and utilities for physics joint demonstrations — the foundation for all joint constraint examples.

## QFEP Connection

Joints are **constraints that enable motion**. A hinge prevents most movement (high F) but allows rotation around one axis (controlled E). Different joint types trade off freedom and constraint differently. This shared system provides the scaffolding for exploring that trade-off space.

## Base Class

`JointDemoBase` provides:
- Environment setup (lighting, camera)
- Helper functions for creating rigid bodies
- Consistent visual style across demos

```gdscript
extends Node3D
class_name JointDemoBase

func _ready():
    _setup_environment()
    _build_demo()  # Override in subclass

func _build_demo():
    # Implemented by each demo
    pass
```

## Helper Functions

| Function | Returns | Purpose |
|----------|---------|---------|
| `create_box(name, size, pos, mass, color)` | RigidBody3D | Dynamic physics box |
| `create_static_box(name, size, pos, color)` | StaticBody3D | Fixed anchor box |
| `create_cylinder(name, radius, height, pos, mass, color)` | RigidBody3D | Dynamic cylinder |
| `create_sphere(name, radius, pos, mass, color)` | RigidBody3D | Dynamic sphere |
| `add_label(text, pos)` | Label3D | Floating text label |

## Godot Joint Types

| Joint | Degrees of Freedom | Use Case |
|-------|-------------------|----------|
| `PinJoint3D` | 3 rotational | Ball socket, pendulum |
| `HingeJoint3D` | 1 rotational | Door, elbow |
| `SliderJoint3D` | 1 translational | Piston, drawer |
| `ConeTwistJoint3D` | Limited rotation | Hip, shoulder |
| `Generic6DOFJoint3D` | Configurable | Custom constraints |

## Demo Index

| Folder | Joint Type | Example |
|--------|------------|---------|
| `01_pendulum_pin` | PinJoint3D | Simple pendulum |
| `02_double_pendulum` | PinJoint3D | Chaotic double pendulum |
| `03_hinge_crank` | HingeJoint3D | Rotating mechanism |
| `04_slider_press` | SliderJoint3D | Linear motion |
| `05_spring_suspension` | Generic6DOF | Spring damper |
| `06_cone_twist_bag` | ConeTwistJoint3D | Punching bag |
| `07_chain_swing` | PinJoint3D chain | Swing set |
| `08_character_ragdoll` | ConeTwistJoint3D | Human joints |
| `09_drawbridge_hinge` | HingeJoint3D | Bridge mechanism |
| `10_gimbal_stabilizer` | HingeJoint3D chain | 3-axis gimbal |

## Usage

```gdscript
extends "res://algorithms/joint/shared/joint_demo_base.gd"

func _build_demo():
    var anchor = create_static_box("Anchor", Vector3(1,1,1), Vector3.ZERO)
    var bob = create_sphere("Bob", 0.5, Vector3(0,-2,0), 1.0)
    
    var joint = PinJoint3D.new()
    joint.node_a = anchor.get_path()
    joint.node_b = bob.get_path()
    add_child(joint)
```

## See Also

- Individual demo folders for specific joint examples
- `physicssimulation/` — Spring systems, soft bodies
- `forces/` — Force-based physics
