# Trans_Rotation_1 - Technical Tutorial

## Rotation in Code

### Basic Rotation Methods

```gdscript
# Rotate around specific axis
node.rotate_x(deg_to_rad(45))  # Pitch
node.rotate_y(deg_to_rad(45))  # Yaw
node.rotate_z(deg_to_rad(45))  # Roll

# Rotate around arbitrary axis
node.rotate(Vector3.UP, deg_to_rad(90))

# Set rotation directly (Euler angles in radians)
node.rotation = Vector3(0, PI/2, 0)

# Set rotation in degrees
node.rotation_degrees = Vector3(0, 90, 0)
```

### Rotation Representations

Godot supports multiple rotation representations:

```gdscript
# Euler angles (rotation_degrees)
var euler = node.rotation_degrees  # Vector3

# Quaternion (avoids gimbal lock)
var quat = node.quaternion  # Quaternion

# Basis matrix (includes scale)
var basis = node.transform.basis  # Basis

# Convert between representations
var quat_from_euler = Quaternion.from_euler(node.rotation)
var euler_from_quat = quat.get_euler()
```

### Non-Commutative Rotation

Unlike translation, rotation order matters:

```gdscript
# Rotation is NON-COMMUTATIVE: order changes result

# Rotate 90° around X, then 90° around Y
var rotation_xy = Vector3(deg_to_rad(90), deg_to_rad(90), 0)

# Rotate 90° around Y, then 90° around X
var rotation_yx = Vector3(deg_to_rad(90), 0, deg_to_rad(90))

# These produce DIFFERENT final orientations
# Compare to translation where:
# Translate(5,0,0) then (0,3,0) = Translate(0,3,0) then (5,0,0)
# Both give same result - but rotation does not!
```

### Gimbal Lock

When using Euler angles, certain rotations cause gimbal lock - loss of a degree of freedom:

```gdscript
# Rotate 90 degrees around X axis
cube.rotation.x = deg_to_rad(90)

# Now Y and Z rotations produce similar effects
# One degree of freedom is lost - this is gimbal lock
# The object can no longer rotate freely in all directions

# Quaternions avoid this problem:
var quat = Quaternion(Vector3(0, 1, 0), deg_to_rad(90))
# Quaternions represent rotation without Euler's limitations
# But are conceptually harder to understand
```

### Continuous Spin

The spin objects demonstrate continuous rotation:

```gdscript
extends Node3D

@export var spin_speed: float = 1.0  # Radians per second
@export var spin_axis: Vector3 = Vector3.UP
@export var initial_angle: float = 0.0  # Degrees

func _ready():
    rotation_degrees.y = initial_angle

func _process(delta):
    rotate(spin_axis, spin_speed * delta)
```

### Spin at Different Offsets

The two spin objects (180° and 0°) show phase difference:

```gdscript
# spin:0:1 - starts at 0°, speed 1
var spin_a = create_spin(0, 1.0)

# spin:180:1 - starts at 180°, speed 1
var spin_b = create_spin(180, 1.0)

# Both spin at same rate, but face opposite directions
# When spin_a faces north, spin_b faces south
```

### RotateGridCubes Implementation

```gdscript
extends Node3D

@export var grid_size: Vector2i = Vector2i(3, 3)
@export var cube_spacing: float = 1.0
@export var rotation_speed: float = 0.5

var cubes: Array[MeshInstance3D] = []

func _ready():
    create_grid()

func create_grid():
    for x in range(grid_size.x):
        for z in range(grid_size.y):
            var cube = create_cube()
            cube.position = Vector3(
                x * cube_spacing,
                0,
                z * cube_spacing
            )
            add_child(cube)
            cubes.append(cube)

func _process(delta):
    # Rotate entire grid (parent rotation)
    rotate_y(rotation_speed * delta)

    # Individual cubes inherit parent rotation
    # Their relative positions stay fixed
    # But world orientations all change together
```

### Anisotropic Space

"Anisotropic" means direction-dependent. Code demonstration:

```gdscript
# Isotropic operation - same in all directions
func translate_isotropic(distance: float) -> Vector3:
    # Translation by scalar is direction-agnostic
    # Must specify direction separately
    return direction.normalized() * distance

# Anisotropic operation - direction matters
func apply_rotation_effect(object: Node3D):
    # Front face receives light
    var front_brightness = 1.0

    # Back face is shadowed
    var back_brightness = 0.3

    # Rotation changes which face is "front"
    var facing = -object.global_transform.basis.z
    var light_dir = Vector3(0, -1, -1).normalized()
    var brightness = lerp(back_brightness, front_brightness,
                          (facing.dot(-light_dir) + 1) / 2)
```

### Rotation and Direction Vectors

```gdscript
# Get facing direction from rotation
var forward = -transform.basis.z  # Local Z points backward in Godot
var right = transform.basis.x
var up = transform.basis.y

# Rotate a direction vector
var world_dir = Vector3(1, 0, 0)
var local_dir = transform.basis.inverse() * world_dir

# Apply rotation to direction
var rotated = transform.basis * local_dir
```

### Look-At Rotation

```gdscript
# Make object face a target
func face_target(target_position: Vector3):
    look_at(target_position, Vector3.UP)

# Custom look-at with constraints
func face_horizontal(target_position: Vector3):
    var flat_target = target_position
    flat_target.y = global_position.y  # Ignore Y difference
    look_at(flat_target, Vector3.UP)
```

### Rotation Interpolation

```gdscript
# Smooth rotation using quaternions (slerp)
func smooth_rotate_to(target_rotation: Quaternion, delta: float):
    quaternion = quaternion.slerp(target_rotation, delta * rotation_speed)

# Using tweens
func tween_rotation(target: Vector3, duration: float):
    var tween = create_tween()
    tween.tween_property(self, "rotation_degrees", target, duration)
```

## Key Takeaway

Rotation produces anisotropy - it makes directions unequal. A translated object treats all directions the same (it could have been translated anywhere). A rotated object has a facing, a front and back, a preferred direction.

The spin objects at 0° and 180° are mathematically related (180° offset) but experientially opposite. One faces you; one faces away. Rotation creates this difference.
