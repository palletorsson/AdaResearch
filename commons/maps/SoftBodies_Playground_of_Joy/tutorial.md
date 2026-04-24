# Playground of Joy

Interactive soft bodies. Throw, catch, mash.

Spawn a throwable soft sphere.

```gdscript
class_name SoftBall extends Node3D

@export var radius: float = 0.5
@export var segment_count: int = 16

func build() -> void:
    # Build a spherical mass-spring mesh
    for i in segment_count:
        var theta: float = i * PI / (segment_count - 1)
        for j in segment_count * 2:
            var phi: float = j * TAU / (segment_count * 2)
            var p := Vector3(
                radius * sin(theta) * cos(phi),
                radius * cos(theta),
                radius * sin(theta) * sin(phi)
            )
            spawn_mass_at(p)
```

Spherical parameterisation. Masses cover the surface of a sphere.

Make it grabbable.

```gdscript
func make_grabbable() -> void:
    add_to_group("grabbable")
    var grab_area := Area3D.new()
    var shape := CollisionShape3D.new()
    var s := SphereShape3D.new()
    s.radius = radius
    shape.shape = s
    grab_area.add_child(shape)
    add_child(grab_area)
```

Standard VR grab pattern. The learner's controller triggers the area.

Apply a grab as force to each mass.

```gdscript
func apply_grab_force(grab_position: Vector3, grab_strength: float = 5.0) -> void:
    for i in masses.size():
        var to_grab: Vector3 = grab_position - masses[i]
        velocities[i] += to_grab * grab_strength * get_physics_process_delta_time()
```

Each mass is pulled toward the grab point. Strong force deforms the ball into a bag shape.

Detect a release.

```gdscript
var was_grabbed: bool = false
var release_velocity: Vector3

func _on_grab_released(controller: XRController3D) -> void:
    if was_grabbed:
        release_velocity = controller.velocity
        was_grabbed = false
        apply_throw(release_velocity)
```

Capture the controller's velocity at release. The ball inherits it.

Apply a throw.

```gdscript
func apply_throw(initial_velocity: Vector3) -> void:
    for i in velocities.size():
        velocities[i] += initial_velocity
```

Add the velocity to every mass. The whole ball travels as a unit, then deformation propagates.

Spawn a soft floor mat.

```gdscript
class_name SoftMat extends MassSpringCube

func _ready() -> void:
    super()
    pinned_indices = get_bottom_layer_indices()

func get_bottom_layer_indices() -> Array:
    var indices: Array = []
    for x in size:
        for z in size:
            indices.append(index_of(x, 0, z))
    return indices
```

Bottom layer pinned to the floor. Balls land softly.

Detect bounce height.

```gdscript
var last_y: float = 0.0

func _process(_delta: float) -> void:
    var centroid_y: float = compute_centroid().y
    if centroid_y > last_y + 0.5:
        record_bounce(centroid_y)
    last_y = centroid_y
```

Record the height of each bounce. Useful for scoring or visual feedback.

You can now build a soft ball, make it grabbable, throw it, spawn a soft mat, and detect bounces. SoftBodies_Affect_Theory_Visualization extends into biological soft-body form.

Emergency stop the simulation.

```gdscript
var paused: bool = false

func toggle_pause() -> void:
    paused = not paused

func _physics_process(delta: float) -> void:
    if paused: return
    super(delta)
```

Lets the learner freeze the scene to examine a moment. Useful for studying specific deformation states.
