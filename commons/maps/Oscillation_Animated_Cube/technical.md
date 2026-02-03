# Transformation Intro - Technical Tutorial

## The Transform in Code

### What is a Transform?
In Godot, every Node3D has a `transform` property that encodes position, rotation, and scale in a single data structure:

```gdscript
var t = Transform3D()
# Contains: origin (position), basis (rotation + scale)
```

### The Three Operations

**Translation** - changing position:
```gdscript
# Move 2 units right
node.position += Vector3(2, 0, 0)
# Or using transform
node.transform.origin += Vector3(2, 0, 0)
```

**Rotation** - changing orientation:
```gdscript
# Rotate 45 degrees around Y axis
node.rotate_y(deg_to_rad(45))
# Or set rotation directly
node.rotation_degrees = Vector3(0, 45, 0)
```

**Scale** - changing size:
```gdscript
# Double the size
node.scale = Vector3(2, 2, 2)
# Non-uniform scale
node.scale = Vector3(1, 2, 1)  # Stretched vertically
```

### Combining Transformations

The cube variants in this map demonstrate combination:

```gdscript
# Static cube - identity transform
static_cube.transform = Transform3D.IDENTITY

# Rotating cube - continuous rotation
func _process(delta):
    rotating_cube.rotate_y(delta * rotation_speed)

# Transforming cube - all three operations
transforming_cube.position = Vector3(2, 1, 0)
transforming_cube.rotation_degrees = Vector3(0, 45, 0)
transforming_cube.scale = Vector3(0.5, 0.5, 0.5)
```

### Transform Composition

Transforms can be multiplied to combine them:

```gdscript
var translation = Transform3D().translated(Vector3(1, 0, 0))
var rotation = Transform3D().rotated(Vector3.UP, deg_to_rad(45))
var scale_t = Transform3D().scaled(Vector3(2, 2, 2))

# Combine: first scale, then rotate, then translate
var combined = translation * rotation * scale_t
node.transform = combined
```

**Order matters!** Rotation then translation gives different results than translation then rotation.

### The Basis Matrix

The `basis` property encodes rotation and scale as a 3x3 matrix:

```gdscript
var basis = node.transform.basis
# basis.x - right vector (affected by rotation + scale)
# basis.y - up vector
# basis.z - forward vector

# Extract rotation (as quaternion)
var quat = basis.get_rotation_quaternion()

# Extract scale
var scale = basis.get_scale()
```

### Pickup Cube Implementation

The grabbable cubes use XR interaction:

```gdscript
extends XRToolsPickable

func _ready():
    # Enable physics-based grabbing
    freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC

func picked_up(by):
    # Transform now follows controller
    freeze = true

func dropped(by):
    freeze = false
    # Resume physics simulation
```

### Rotation Animation

Continuous rotation like the rotating_cube:

```gdscript
@export var rotation_speed: float = 1.0
@export var rotation_axis: Vector3 = Vector3.UP

func _process(delta):
    rotate(rotation_axis, rotation_speed * delta)
```

## Key Takeaway

Transform is not a thing but an **operation**. Position, rotation, and scale are verbs applied to geometry. The cube does not "have" a rotation - it has been rotated. This distinction matters when you begin composing multiple transformations.
