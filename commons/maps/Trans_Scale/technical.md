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

```gdscript
# Scale is multiplicative, relative to original size
var original_size = Vector3(1, 1, 1)
node.scale = Vector3(3, 3, 3)
# Visual size is now 3 × original = 3, 3, 3

# To set absolute size, calculate required scale
func set_absolute_size(target_size: Vector3):
    var mesh = $MeshInstance3D.mesh
    var original = mesh.get_aabb().size
    node.scale = target_size / original
```

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

```gdscript
# Alice's scale
var alice_scale = 1.0  # Normal size

# Doorway height (constant)
var doorway_height = 2.0

# Alice drinks shrinking potion
alice_scale = 0.1  # 1/10 size

# Doorway now seems 20x taller (relative to Alice)
var relative_height = doorway_height / alice_scale  # 20.0

# The world has not changed
# Alice's relationship to it has transformed
# "Big" and "small" are relations, not intrinsic properties
```

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

```gdscript
# Using XR hand tracking
extends XRController3D

signal pinch_started
signal pinch_scale_changed(factor: float)
signal pinch_ended

var pinch_threshold: float = 0.02  # Meters
var is_pinching: bool = false
var initial_pinch_distance: float

func _process(delta):
    var thumb = get_finger_position("thumb_tip")
    var index = get_finger_position("index_tip")
    var distance = thumb.distance_to(index)

    if distance < pinch_threshold and not is_pinching:
        is_pinching = true
        initial_pinch_distance = distance
        emit_signal("pinch_started")
    elif distance >= pinch_threshold and is_pinching:
        is_pinching = false
        emit_signal("pinch_ended")
    elif is_pinching:
        var factor = distance / initial_pinch_distance
        emit_signal("pinch_scale_changed", factor)
```

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

```gdscript
# Child nodes inherit parent scale
var parent = Node3D.new()
parent.scale = Vector3(2, 2, 2)

var child = MeshInstance3D.new()
child.scale = Vector3(0.5, 0.5, 0.5)  # Local scale
parent.add_child(child)

# Child's effective world scale:
var world_scale = child.global_transform.basis.get_scale()
# Result: (1, 1, 1) - parent's 2x times child's 0.5x

# To get independent scaling:
child.top_level = true  # Disconnects from parent transform
```

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

```gdscript
# Smooth scale transitions
func scale_to(target: Vector3, duration: float):
    var tween = create_tween()
    tween.tween_property(self, "scale", target, duration)
    tween.set_ease(Tween.EASE_OUT)
    tween.set_trans(Tween.TRANS_ELASTIC)  # Bouncy effect

# Pulsing scale animation
func pulse_scale(base: float, amplitude: float, speed: float):
    var time = Time.get_ticks_msec() / 1000.0
    var pulse = base + sin(time * speed) * amplitude
    scale = Vector3.ONE * pulse
```

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

```gdscript
# Mirror across YZ plane (flip X axis)
cube.scale.x = -1.0

# The cube is now reflected
# Right becomes left, left becomes right
# This is chirality inversion - rotation cannot do this

# Scale to zero collapses dimensions:
cube.scale.z = 0.0
# 3D object becomes 2D plane - dimension lost
```

## Key Takeaway

Scale changes size while preserving proportions (for uniform scale) or distorts proportions (for non-uniform scale). Unlike translation and rotation, scale is **immediately visible** - objects look bigger or smaller.

Interactive scaling empowers the player to control transformation directly. "Scale me" is an invitation: you are the agent of change.
