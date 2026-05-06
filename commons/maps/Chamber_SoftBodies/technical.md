# Chamber SoftBodies — Technical

The chamber has no catalyst mode. The learner pushes the spring_hopper directly, and the push propagates as a deformation wave through the mass-spring lattice.

## Mass-Spring Lattice

```gdscript
class_name MassSpringBody extends Node3D

var masses: Array = []   # positions
var velocities: Array = []  # velocities
var springs: Array = []  # [i, j, rest_length, stiffness]
@export var damping: float = 0.5
@export var mass_value: float = 1.0

func build_lattice(size: Vector3i, spacing: float) -> void:
    for z in range(size.z):
        for y in range(size.y):
            for x in range(size.x):
                masses.append(Vector3(x, y, z) * spacing)
                velocities.append(Vector3.ZERO)
    # Edge springs
    for z in range(size.z):
        for y in range(size.y):
            for x in range(size.x):
                var idx: int = index_of(x, y, z, size)
                if x + 1 < size.x:
                    springs.append([idx, index_of(x + 1, y, z, size), spacing, 20.0])
                if y + 1 < size.y:
                    springs.append([idx, index_of(x, y + 1, z, size), spacing, 20.0])
                if z + 1 < size.z:
                    springs.append([idx, index_of(x, y, z + 1, size), spacing, 20.0])
```

## Physics Step

```gdscript
func _physics_process(delta: float) -> void:
    var forces: Array = []
    for _i in range(masses.size()):
        forces.append(Vector3.ZERO)
    # Spring forces
    for spring in springs:
        var i: int = spring[0]; var j: int = spring[1]
        var rest: float = spring[2]; var k: float = spring[3]
        var delta_p: Vector3 = masses[j] - masses[i]
        var current_length: float = delta_p.length()
        var extension: float = current_length - rest
        var direction: Vector3 = delta_p.normalized()
        var force: Vector3 = direction * extension * k
        forces[i] += force
        forces[j] -= force
    # Integrate
    for i in range(masses.size()):
        var acceleration: Vector3 = forces[i] / mass_value
        velocities[i] = (velocities[i] + acceleration * delta) * (1.0 - damping * delta)
        masses[i] += velocities[i] * delta
```

## Push Response

When the learner pushes the hopper, the push applies a force to nearby masses and propagates through the lattice.

```gdscript
func apply_push(push_position: Vector3, push_force: Vector3, radius: float) -> void:
    for i in range(masses.size()):
        var distance: float = masses[i].distance_to(push_position)
        if distance < radius:
            var falloff: float = 1.0 - distance / radius
            velocities[i] += push_force * falloff
```

## Mesh Reconstruction

The visual mesh is reconstructed each frame from the mass positions.

```gdscript
func rebuild_visual_mesh() -> void:
    var array_mesh := ArrayMesh.new()
    var vertices: PackedVector3Array = []
    for m in masses:
        vertices.append(m)
    var arrays: Array = []
    arrays.resize(ArrayMesh.ARRAY_MAX)
    arrays[ArrayMesh.ARRAY_VERTEX] = vertices
    arrays[ArrayMesh.ARRAY_INDEX] = compute_surface_indices()
    array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    mesh_instance.mesh = array_mesh
```

## Science Screen — Field Display

The screen renders displacement as a continuous field using colour intensity and traces energy over time.

```gdscript
class_name SoftScreen extends Node3D

var displacement_samples: Array = []  # grid of displacement magnitudes
var energy_trace: Array = []

func sample_displacement_field() -> void:
    displacement_samples.clear()
    for m in spring_hopper.masses:
        var rest_pos: Vector3 = spring_hopper.rest_position_for(m)
        var displacement_mag: float = (m - rest_pos).length()
        displacement_samples.append(displacement_mag)
    redraw_field_display()

func sample_energy() -> void:
    var total_potential: float = 0.0
    var total_kinetic: float = 0.0
    for spring in spring_hopper.springs:
        var dp: float = (spring_hopper.masses[spring[1]] - spring_hopper.masses[spring[0]]).length() - spring[2]
        total_potential += 0.5 * spring[3] * dp * dp
    for v in spring_hopper.velocities:
        total_kinetic += 0.5 * spring_hopper.mass_value * v.length_squared()
    energy_trace.append([total_potential, total_kinetic])
```

## Complexity

Spring forces are O(spring count) per step. Integration is O(mass count). For a 5×5×5 lattice with 3×125 = 375 springs and 125 masses, the step cost is negligible. Larger lattices are possible via GPU compute shaders.

## Within the Sequence

Chamber_SoftBodies closes the Soft Bodies sequence with contact as distributed wave.

## Save State Integration

The chamber's progress is tracked via the save manager. Befriending a creature, completing a configuration, or reaching a milestone is recorded in the learner's profile and becomes available in subsequent sessions.

```gdscript
func on_befriend_event(creature_name: String) -> void:
    var save = get_tree().get_first_node_in_group("save_manager")
    save.add_befriended_creature(creature_name)
    save.mark_milestone(chamber_id + "_befriended", Time.get_datetime_string_from_system())
```

## Performance Budget

The chamber's per-frame cost is dominated by creature animations and the science screen's rendering. Both are modest: the creature uses a vertex-displacement shader or a prebuilt animation, and the science screen redraws scatter points incrementally rather than from scratch each frame.

```gdscript
func _process(_delta: float) -> void:
    if science_screen.needs_redraw():
        science_screen.redraw_incremental()
```

## VR Comfort

The chamber avoids fast camera moves and sudden lighting changes. Projectiles fire from the learner's hand rather than from fixed spawners, so the learner controls the motion. The chamber's lighting is stable across the encounter; any changes happen gradually through creature state transitions.

## Accessibility

The chamber supports seated play: all interactive elements are within arm's reach, and the projectile direction is controllable from a single hand. The creature responds to either controller, so handedness is not a barrier.

## Within the Curriculum

This chamber is one of the curriculum's catalyst chambers — small, self-contained rooms where the sequence's accumulated vocabulary becomes relationship with a creature. The pattern is consistent across sequences: creature, catalyst (or its deliberate absence), science screen, return to Lab.
