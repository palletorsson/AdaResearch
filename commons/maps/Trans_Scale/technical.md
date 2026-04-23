# Trans_Scale - Technical Tutorial

## Scale in Code

### Basic Scaling

```gdscript
# Uniform scale (same in all directions)
node.scale = Vector3(2, 2, 2)  # Double size
node.scale = Vector3.ONE * 0.5  # Half size

# Non-uniform scale (different per axis)
node.scale = Vector3(1, 2, 1)  # Stretched vertically
node.scale = Vector3(2, 1, 0.5)  # Wide and flat
```

### Scale vs Size

### The Cube Law: Volume Scales Exponentially

When you double linear scale, volume increases 8-fold (2³):

```gdscript
# Original cube: 1x1x1
var volume_before = 1.0

# Scale by factor of 3
var scale_factor = 3.0
cube.scale = Vector3(scale_factor, scale_factor, scale_factor)

# New volume: 3x3x3 = 27
var volume_after = pow(scale_factor, 3)  # 27x the volume!

# This is why giants don't exist in nature:
# A creature scaled 10x has:
# - 100x the cross-sectional area (strength)
# - 1000x the volume (mass to support)
# Strength-to-weight ratio: 100/1000 = 0.1
# Only 1/10 as strong relative to weight
```

### Alice's Problem: Relative Size

Like Alice in Wonderland, size only has meaning relative to context:

### Interactive Scaling with VR Gestures

The scale_me artifact implements gesture-based scaling:

```gdscript
extends Node3D

@export var min_scale: float = 0.1
@export var max_scale: float = 5.0
@export var scale_sensitivity: float = 2.0

var initial_hand_distance: float = 0.0
var initial_scale: Vector3
var is_scaling: bool = false
var left_hand: XRController3D
var right_hand: XRController3D

func start_scaling():
    is_scaling = true
    initial_hand_distance = get_hand_distance()
    initial_scale = scale

func _process(delta):
    if is_scaling:
        var current_distance = get_hand_distance()
        var scale_factor = current_distance / initial_hand_distance
        var new_scale = initial_scale * scale_factor

        # Clamp to limits
        new_scale = new_scale.clamp(
            Vector3.ONE * min_scale,
            Vector3.ONE * max_scale
        )
        scale = new_scale

func get_hand_distance() -> float:
    return left_hand.global_position.distance_to(
        right_hand.global_position
    )
```

### Pinch-to-Scale Gesture

### Scale and Collision

Scaling affects physics:

```gdscript
# When scaling physics bodies, collision shapes must also scale
func scale_with_collision(new_scale: Vector3):
    scale = new_scale

    # CollisionShape3D scales automatically with parent
    # But physics properties may need adjustment:

    if self is RigidBody3D:
        # Mass scales with volume (cubic)
        var volume_factor = new_scale.x * new_scale.y * new_scale.z
        mass = base_mass * volume_factor

        # Inertia scales with mass and size
        # (handled automatically if using default inertia)
```

### Scale Inheritance

### Prism Reference Geometry

The prism blocks provide scale reference:

```gdscript
# Create prism for scale comparison
extends MeshInstance3D

func _ready():
    var prism = PrismMesh.new()
    prism.size = Vector3(1, 1, 1)  # Unit prism
    mesh = prism

# Prisms make scale visible because:
# 1. They have clear geometric proportions
# 2. Their angles stay constant under uniform scale
# 3. Human perception compares object sizes automatically
```

### Animated Scaling

### Scale in Transform Matrix

```gdscript
# Scale is encoded in the basis matrix
var basis = transform.basis

# Extract scale from basis
var scale_x = basis.x.length()
var scale_y = basis.y.length()
var scale_z = basis.z.length()
var extracted_scale = Vector3(scale_x, scale_y, scale_z)

# Note: non-uniform scale + rotation = shear
# The basis can't cleanly separate rotation from non-uniform scale
```

### Negative Scale: Reflection

Scale can be negative, which mirrors the object:

## Key Takeaway

Scale changes size while preserving proportions (for uniform scale) or distorts proportions (for non-uniform scale). Unlike translation and rotation, scale is **immediately visible** - objects look bigger or smaller.

Interactive scaling empowers the player to control transformation directly. "Scale me" is an invitation: you are the agent of change.

## Implementation Notes and Complexity

Scaling a Node3D in Godot is O(1) — the operation writes three floats into the transform basis. The cost of the operation is not in the scale itself but in the downstream propagation: every child's world transform must be recomputed when the parent's scale changes. For a tree of N nodes, a single scale on the root triggers O(N) transform updates on the next frame.

Non-uniform scale is where the practical complexity arrives. A uniform scale commutes with rotation; a non-uniform scale does not. The basis matrix that would represent rotation followed by non-uniform scale cannot generally be decomposed back into clean rotation and scale components — the decomposition produces shear. Code that intermixes the two operations often ends up with nodes whose children inherit unintended skew, and the skew is not easy to remove after the fact because it was encoded in the basis when the scale was applied.

Collision shapes follow the parent's scale automatically in Godot, but physics properties do not. A rigid body with its scale doubled will still have its original mass unless the author adjusts it explicitly. The scale_with_collision routine above shows the cubic law applied to mass; real applications frequently forget to apply it and end up with rigid bodies that punch through walls because their inertia is wrong for their new size.

Within the sequence, Trans_Scale sits between translation and rotation as the third of three fundamental geometric transformations. The scale_me artifact lets the learner control the operation directly with their hands, so the cubic volume law becomes a body-level experience rather than an equation. The prism blocks provide scale reference because their angular geometry is unambiguous at every size, and human perception automatically compares angles across scales even when it cannot compare lengths reliably.
