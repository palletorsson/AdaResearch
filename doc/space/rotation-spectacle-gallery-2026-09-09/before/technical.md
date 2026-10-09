# Trans_Rotation_2 - Technical Tutorial

## Layered Rotation: The Carousel Cake

### Multi-Layer Independent Rotation

```gdscript
extends Node3D

@export var layer_count: int = 5
@export var base_radius: float = 2.0
@export var layer_height: float = 0.5
@export var radius_decay: float = 0.8  # Each layer smaller than previous

var layers: Array[MeshInstance3D] = []
var rotation_speeds: Array[float] = []

func _ready():
    create_layers()

func create_layers():
    for i in range(layer_count):
        var layer = create_cylinder_layer(i)
        layers.append(layer)
        # Alternate rotation directions, vary speeds
        var speed = randf_range(0.3, 1.5)
        if i % 2 == 1:
            speed = -speed  # Reverse every other layer
        rotation_speeds.append(speed)

func create_cylinder_layer(index: int) -> MeshInstance3D:
    var mesh_instance = MeshInstance3D.new()
    var cylinder = CylinderMesh.new()

    var radius = base_radius * pow(radius_decay, index)
    cylinder.top_radius = radius
    cylinder.bottom_radius = radius
    cylinder.height = layer_height

    mesh_instance.mesh = cylinder
    mesh_instance.position.y = index * layer_height
    add_child(mesh_instance)
    return mesh_instance

func _process(delta):
    for i in range(layers.size()):
        layers[i].rotate_y(rotation_speeds[i] * delta)
```

### Stripe Shader for Rotation Visibility

The carousel uses a stripe shader to make rotation visible:

```glsl
shader_type spatial;

uniform float stripe_count : hint_range(1, 32) = 8.0;
uniform vec3 color_a : source_color = vec3(1.0, 0.3, 0.3);
uniform vec3 color_b : source_color = vec3(0.3, 0.3, 1.0);

varying vec3 local_pos;

void vertex() {
    local_pos = VERTEX;
}

void fragment() {
    // Calculate angle around Y axis
    float angle = atan(local_pos.x, local_pos.z);
    float normalized = (angle + PI) / TAU;

    // Create stripes
    float stripe = mod(normalized * stripe_count, 1.0);
    float band = step(0.5, stripe);

    ALBEDO = mix(color_a, color_b, band);
}
```

### Per-Layer Instance Custom Data

Using MultiMesh for efficient layered rendering:

```gdscript
func setup_multimesh_layers():
    var mm = MultiMesh.new()
    mm.mesh = cylinder_mesh
    mm.transform_format = MultiMesh.TRANSFORM_3D
    mm.use_custom_data = true
    mm.instance_count = layer_count

    for i in range(layer_count):
        var transform = Transform3D()
        transform.origin.y = i * layer_height
        transform = transform.scaled(Vector3(
            pow(radius_decay, i),
            1.0,
            pow(radius_decay, i)
        ))
        mm.set_instance_transform(i, transform)

        # Custom data: layer index for shader
        mm.set_instance_custom_data(i, Color(float(i), 0, 0, 0))
```

### Boolean Operations

The boolean_tunnel demonstrates constructive solid geometry:

```gdscript
# CSG in Godot
extends CSGCombiner3D

func _ready():
    # Create base solid
    var box = CSGBox3D.new()
    box.size = Vector3(4, 4, 4)
    add_child(box)

    # Create tunnel cutter (subtraction)
    var tunnel = CSGCylinder3D.new()
    tunnel.radius = 1.0
    tunnel.height = 6.0
    tunnel.rotation_degrees.x = 90  # Horizontal tunnel
    tunnel.operation = CSGShape3D.OPERATION_SUBTRACTION
    add_child(tunnel)
```

### Animated Boolean Carving

```gdscript
# Rotating cutter creates spiral tunnel
extends CSGCylinder3D

@export var carve_speed: float = 0.5

func _ready():
    operation = CSGShape3D.OPERATION_SUBTRACTION

func _process(delta):
    rotate_z(carve_speed * delta)
    # The boolean updates automatically
```

### Long Corridor Generation

```gdscript
# Procedural corridor with walls
func create_corridor(length: int, width: float, wall_height: float):
    for z in range(length):
        # Floor tile
        place_tile(Vector3(0, 0, z), 1)

        # Left wall
        place_tile(Vector3(-1, 0, z), wall_height)

        # Right wall
        place_tile(Vector3(width, 0, z), wall_height)

        # Gap in middle (void)
        # No tile placed at center positions
```

### Rotation Composition Matrix

```gdscript
# Multiple rotations compose via matrix multiplication
func compose_rotations(rotations: Array[Transform3D]) -> Transform3D:
    var result = Transform3D.IDENTITY
    for r in rotations:
        result = result * r  # Order matters!
    return result

# The carousel layers compose:
# Layer 3's world rotation = Layer 0 rot * Layer 1 rot * Layer 2 rot * Layer 3 rot
# But since layers are siblings (not nested), each rotates independently
```

### SLERP: Smooth Rotation Interpolation

Unlike linear interpolation for position, rotation uses spherical interpolation:

```gdscript
# Spherical Linear Interpolation (SLERP)
var start_rotation = Quaternion.IDENTITY
var end_rotation = Quaternion(Vector3(0, 1, 0), deg_to_rad(180))
var t = 0.0

func _process(delta):
    t += delta * 0.5
    if t > 1.0:
        t = 1.0

    # SLERP creates smooth arc through rotation space
    var current_quat = start_rotation.slerp(end_rotation, t)
    rotation = current_quat.get_euler()

    # Unlike linear interpolation, SLERP maintains constant angular velocity
    # The rotation doesn't speed up or slow down in the middle
```

### Observing Rotation Speed Differences

```gdscript
# Visual comparison of rotation speeds
func demonstrate_speed_difference():
    # Fast layer
    var fast = create_layer()
    fast.rotation_speed = 2.0

    # Slow layer
    var slow = create_layer()
    slow.rotation_speed = 0.5

    # After 1 second:
    # fast has rotated 2 radians (~115 degrees)
    # slow has rotated 0.5 radians (~29 degrees)

    # After TAU/0.5 = 12.57 seconds:
    # slow completes one full rotation
    # fast has completed 4 full rotations
```

## Key Takeaway

The carousel_cake demonstrates that complex rotational behavior emerges from simple components rotating independently. Each layer knows only its own rotation speed - yet the composite effect is hypnotic, organic, alive.

Boolean operations show rotation's power to shape space. A rotating cylinder cuts a curved tunnel. Rotation is not just orientation but **formation**.
