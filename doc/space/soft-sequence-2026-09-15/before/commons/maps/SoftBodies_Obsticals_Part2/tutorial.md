# Soft Bodies Obstacles Part 2

Moving obstacles. The soft body absorbs the motion.

Spawn a moving piston.

```gdscript
class_name Piston extends StaticBody3D

@export var movement_range: Vector3 = Vector3(0, 0, 2)
@export var period: float = 2.0

var start_position: Vector3

func _ready() -> void:
    start_position = global_position

func _physics_process(delta: float) -> void:
    var t: float = fmod(Time.get_ticks_msec() / 1000.0, period) / period
    var phase: float = sin(t * TAU)
    global_position = start_position + movement_range * phase
```

Sinusoidal back-and-forth motion. The piston pushes the soft body on its forward stroke.

Compute piston velocity.

```gdscript
var previous_position: Vector3

func _physics_process(delta: float) -> void:
    super(delta)
    linear_velocity = (global_position - previous_position) / delta
    previous_position = global_position
```

Finite difference. The velocity is used to drive the soft body's response.

Apply piston velocity to the soft body.

```gdscript
func apply_piston(cube: MassSpringCube, piston: Piston) -> void:
    for i in cube.masses.size():
        var mass_world: Vector3 = cube.to_global(cube.masses[i])
        var correction: Vector3 = penetration_at(mass_world, piston)
        if correction.length() > 0.01:
            cube.masses[i] += cube.to_local(correction)
            cube.velocities[i] += cube.to_local(piston.linear_velocity)
```

The soft body mass inherits the piston's velocity. Energy transfers from rigid to soft.

Spawn a rotating spoke.

```gdscript
class_name Spoke extends StaticBody3D

@export var rotation_speed: float = 3.0

func _physics_process(delta: float) -> void:
    rotate_y(rotation_speed * delta)
```

Angular rotation; combined with a collision shape, the spoke sweeps through the soft body.

Moving-collision-shape damage.

```gdscript
func apply_moving_shape(cube: MassSpringCube, shape_node: Node3D, shape_velocity: Vector3) -> void:
    for i in cube.masses.size():
        var mass_world: Vector3 = cube.to_global(cube.masses[i])
        var correction: Vector3 = penetration_at(mass_world, shape_node)
        if correction.length() > 0.01:
            cube.masses[i] += cube.to_local(correction)
            cube.velocities[i] += cube.to_local(shape_velocity * 0.5)
```

Scaled velocity inheritance (half the shape's velocity transfers). Softer than full transfer; avoids runaway acceleration.

Log impact events.

```gdscript
func log_impact(cube: MassSpringCube, point: Vector3, force: Vector3) -> void:
    impact_log.append({
        "time": Time.get_ticks_msec() / 1000.0,
        "position": point,
        "force_magnitude": force.length(),
    })
```

Timestamped impact records. Later analysis shows where and when forces hit.

You can now spawn moving pistons and rotating spokes, compute their velocities, apply them to soft bodies for velocity transfer, and log impact events. SoftBodies_Cloth_Physics extends into cloth simulation.

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

Reset the piston.

```gdscript
func reset_piston(piston: Piston) -> void:
    piston.start_position = piston.global_position
    piston.global_position = piston.start_position
```

Returns the piston to its cycle's starting position. Useful when the simulation state becomes noisy.