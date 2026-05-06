# Soft Bodies Carousel

Rotating platform with soft cubes. Centrifugal deformation.

Build a rotating platform.

```gdscript
class_name SoftCarousel extends Node3D

@export var rotation_speed: float = 1.0

func _physics_process(delta: float) -> void:
    rotate_y(rotation_speed * delta)
```

Constant angular velocity. Soft bodies on the platform experience centrifugal acceleration.

Spawn soft cubes on the platform.

```gdscript
func spawn_soft_cube_at(position: Vector3) -> Node3D:
    var cube := preload("res://commons/softbodies/mass_spring_cube.tscn").instantiate()
    cube.position = position
    add_child(cube)
    return cube
```

Each cube is an independent mass-spring lattice. Multiple cubes populate the carousel.

Apply centrifugal force.

```gdscript
func apply_centrifugal(cube: MassSpringCube, angular_velocity: float) -> void:
    for i in cube.masses.size():
        var world_pos: Vector3 = cube.to_global(cube.masses[i])
        var radial: Vector3 = world_pos - global_position
        radial.y = 0
        var centrifugal: Vector3 = radial.normalized() * radial.length() * angular_velocity * angular_velocity
        cube.velocities[i] += cube.to_local(centrifugal) * get_physics_process_delta_time()
```

Outward force proportional to radial distance and angular velocity squared. Cubes deform outward.

Vary distances.

```gdscript
func populate_rings() -> void:
    const RADII := [0.8, 1.5, 2.2]
    const COUNT_PER_RING := [4, 6, 8]
    for ring_idx in 3:
        for i in COUNT_PER_RING[ring_idx]:
            var angle: float = i * TAU / COUNT_PER_RING[ring_idx]
            var position := Vector3(cos(angle) * RADII[ring_idx], 0, sin(angle) * RADII[ring_idx])
            spawn_soft_cube_at(position)
```

Three rings. Outer cubes deform more than inner ones. Visible gradient of stretch.

Stabilise corner cubes.

```gdscript
func pin_corners() -> void:
    for cube in get_children():
        if cube is MassSpringCube:
            cube.pinned_indices = [0, cube.size - 1, cube.size * cube.size - 1]
```

Pinning prevents a mass from moving. Anchors the cube's base to the platform surface.

Skip update for pinned masses.

```gdscript
var pinned_indices: Array = []

func _physics_process(delta: float) -> void:
    super(delta)
    for i in pinned_indices:
        masses[i] = initial_masses[i]
        velocities[i] = Vector3.ZERO
```

After integration, reset pinned masses to their starting positions. Zero their velocities.

You can now build a rotating platform, apply centrifugal force to soft bodies, populate rings at different radii, and pin corner vertices. SoftBodies_Obsticals extends into collision with static obstacles.

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

Scale cube size by distance.

```gdscript
func cube_size_for_radius(radius: float) -> int:
    return clamp(int(2 + radius * 1.5), 2, 5)
```

Larger cubes at outer rings mean more visible deformation. Scales dramatically outward.

Detach and throw a cube.

```gdscript
func detach_cube(cube: Node3D, impulse: Vector3) -> void:
    cube.reparent(get_tree().root)
    cube.apply_impulse_to_all(impulse)
```

Removes the cube from the carousel's parent. Inherits the platform's rotational velocity at the moment of release.