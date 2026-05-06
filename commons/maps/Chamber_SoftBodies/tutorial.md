# Chamber SoftBodies

Push the spring_hopper directly. No catalyst, just contact.

Build the spring hopper.

```gdscript
class_name SpringHopper extends MassSpringCube

@export var hop_strength: float = 3.0

func _ready() -> void:
    size = 4
    super()
    add_periodic_hop()

func add_periodic_hop() -> void:
    var timer := Timer.new()
    timer.wait_time = 2.0
    timer.timeout.connect(periodic_bounce)
    add_child(timer)
    timer.start()
```

A small mass-spring lattice that bounces periodically. The hopping is part of the creature's life.

Apply a bounce.

```gdscript
func periodic_bounce() -> void:
    for i in velocities.size():
        velocities[i] += Vector3.UP * hop_strength + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3))
```

Every two seconds, add upward velocity with a small horizontal scatter. The hopper bounces around.

Render the deformation field.

```gdscript
func compute_displacement_field() -> Array:
    var field: Array = []
    for i in masses.size():
        var rest_position := compute_rest_position(i)
        field.append(masses[i] - rest_position)
    return field
```

Each mass's displacement from its rest position. The field shows where and how the body is deformed.

Visualise the field as arrows.

```gdscript
func render_displacement_field(field: Array) -> void:
    for i in field.size():
        if field[i].length() > 0.05:
            spawn_arrow(masses[i], field[i])
```

One arrow per deformed mass. The arrows together show the deformation wave traveling through the body.

Track energy over time.

```gdscript
var energy_history: Array = []

func compute_total_energy() -> float:
    var kinetic: float = 0.0
    for v in velocities:
        kinetic += 0.5 * v.length_squared()
    var potential: float = 0.0
    for spring in springs:
        var delta: Vector3 = masses[spring[1]] - masses[spring[0]]
        var extension: float = delta.length() - spring[2]
        potential += 0.5 * spring[3] * extension * extension
    return kinetic + potential

func log_energy() -> void:
    energy_history.append(compute_total_energy())
```

Sum of kinetic plus spring potential energies. Without external input, energy decays.

Detect a push from the learner.

```gdscript
func detect_learner_push(learner: Node3D, threshold: float = 1.0) -> Vector3:
    var learner_velocity: Vector3 = learner.get("velocity") or Vector3.ZERO
    if learner_velocity.length() > threshold:
        return learner_velocity
    return Vector3.ZERO
```

Check the learner's velocity. If fast enough, treat as a push.

Propagate the push.

```gdscript
func _physics_process(delta: float) -> void:
    super(delta)
    var learner_push: Vector3 = detect_learner_push(learner)
    if learner_push.length() > 0:
        var contact_point: Vector3 = learner.global_position
        apply_push(contact_point, learner_push, 0.8)
```

Each push adds velocity to nearby masses. The wave propagates through the lattice as deformation.

You can now build a spring_hopper with periodic bouncing, compute and visualise the displacement field, track total energy, and propagate learner pushes through the lattice. The Soft Bodies sequence closes with contact as distributed wave.
