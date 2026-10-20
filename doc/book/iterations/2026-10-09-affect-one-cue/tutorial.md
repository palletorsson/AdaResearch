# One shape, one cue

## Learning elements

- A controlled comparison
- Shared geometry, separate materials
- Node motion versus vertex deformation
- Resetting the previous condition
- Appearance and the mechanism it suggests

<!-- @radiolaria -->

Walk between the radiolaria forms. Stop ROTATION, then turn EFFECTS off. The specimens remain. Their spikes, rings and repeated parts were constructed; the surrounding particles and the turning were additional cues.

This court begins with a fixed construction seed. SEED selects another repeatable draw. COLOUR rebuilds the forms with another palette; keeping the seed helps you compare the same construction. SPIKES can change the geometry and later random choices, so it is a different experiment. A setting called “spikiness” is a generator parameter, not a measured capacity to defend a living body.

Last hall you kept positions and face indices while their source continued. Here we keep that shape fixed and vary its presentation. Two identical copies make the comparison clear: the left stays still and neutral; the right receives one cue. The forms in this room prompted the question. Your captured surface supplies the material for testing it.

## Continue with your captured shape

Work inside the prepared Endless Museum project, where the player, camera, lighting and XRTools already run. Create a Node3D named `OneCue` in a clear place at floor level and unit scale. Attach the following `study.gd`. Keep `vessel_surface.gd`, `solver.gd` and `point_body.gd` beside it: they are unchanged from the previous lesson and printed at the end. The supplied `study.tscn` contains just this root and script attachment.

For a repeatable starting point, this script reconstructs the previous lesson's step-40 snapshot from the same recipe. It does not load a drawing from disk or resume your previous play session. The solver runs those forty steps once. After that, only the display changes.

Hold the black point and press its trigger, or press **1** on desktop. Cycle through three conditions: both copies neutral and still; only the right copy turns; only the right copy changes colour. Press **2** to return to the first condition.

## Complete study.gd

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const VesselSurface = preload("vessel_surface.gd")
const PointBody = preload("point_body.gd")
const SAMPLE_STEP := 40
const TURN_SPEED := 0.7
const NEUTRAL := Color("d6cec0")
const ACCENT := Color("c982a9")
var surface = VesselSurface.new()
var left := MeshInstance3D.new()
var right := MeshInstance3D.new()
var point = PointBody.new()
var caption := Label3D.new()
var saved_positions := PackedVector3Array()
var saved_indices := PackedInt32Array()
var condition := 0

func _ready() -> void:
	# Reconstruct the previous lesson's step-40 snapshot from its same recipe.
	surface.sim.simulate(SAMPLE_STEP, 0.0166667)
	saved_positions = surface.sim.positions.duplicate()
	saved_indices = surface.indices.duplicate()
	var saved_mesh: ArrayMesh = surface.mesh_for(saved_positions, saved_indices)
	for body in [left, right]:
		body.mesh = saved_mesh
		var finish := StandardMaterial3D.new()
		finish.albedo_color = NEUTRAL
		finish.roughness = 0.5
		finish.cull_mode = BaseMaterial3D.CULL_DISABLED
		body.material_override = finish
		add_child(body)
	left.position = Vector3(-1.25, 2.2, 0)
	right.position = Vector3(1.25, 2.2, 0)
	point.position = Vector3(0, 1.1, 1.0)
	add_child(point)
	point.action_pressed.connect(func(_source): next_condition())
	caption.position = Vector3(0, 3.4, 0)
	caption.font_size = 32
	caption.pixel_size = 0.0025
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(caption)
	set_condition(0)

func _process(delta: float) -> void:
	if condition == 1:
		right.rotate_z(TURN_SPEED * delta)

func set_condition(value: int) -> void:
	condition = value
	right.rotation = Vector3.ZERO
	right.material_override.albedo_color = NEUTRAL
	if condition == 2:
		right.material_override.albedo_color = ACCENT
	caption.text = ["SAME SHAPE / same appearance", "SAME SHAPE / right turns", "SAME SHAPE / right changes colour"][condition]
	caption.text += "\nPoint trigger / 1: next    2: reset"

func next_condition() -> void:
	set_condition((condition + 1) % 3)

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			next_condition()
		elif event.keycode == KEY_2:
			set_condition(0)
```

## Read the comparison

Both MeshInstance3D nodes refer to `saved_mesh`. This shared resource is useful because neither copy edits it. Their positions put the same local geometry in two places.

Each loop iteration creates a separate material. Changing the right material therefore leaves the left material alone. If both nodes shared one material, the colour comparison would change both copies.

`_process` turns the right node only in condition 1. `delta` makes `TURN_SPEED` a rate in radians per second. The node's transform changes; its stored vertices do not. This is the transformation you learned earlier, applied to a shape whose deformation has already stopped.

`set_condition` first resets the right node's orientation and colour. Moving from rotation to colour therefore removes the previous cue. Without that reset, the coloured copy could keep a different orientation and you would be comparing more than one change.

No soft-body simulation runs in `_process`. Nothing senses the visitor, grows or decides where to turn. The point's trigger chooses a condition; it does not give the displayed surface a new physical behaviour.

## Make one comparison of your own

Change `TURN_SPEED` from `0.7` to `0.35`. Before running, predict what should differ after one second and what must stay unchanged. The turn angle should halve. The left copy, both vertex arrays and both colours should stay the same. Then return to the still condition before testing a different `ACCENT` colour.

Say what you saw before giving it a biological name. “The right copy turns while the left stays” can be checked against the program. “The right one feels more alive to me” records your response. An assertion can protect the first distinction; it cannot establish the second for every visitor.

The next hall changes the underlying state again: values spread and react across a field. We will be able to ask which visible differences come from those exchanges and which come from how the field is shown.

<!-- @ -->

## Carried files — unchanged

These are the complete files from **A shape kept**. Reuse your copies if they match; no new solver or point class is being introduced here.

### vessel_surface.gd

<!-- student-code:vessel_surface.gd -->
```gdscript
extends RefCounted
## Supplied adapter: the installed glass vessel's construction and solver.
const Solver = preload("solver.gd")
const RINGS := 14
const SEGMENTS := 22
const RADIUS := 0.55
var sim = Solver.new()
var indices := PackedInt32Array()

func _init() -> void:
	sim.stiffness = 0.6
	sim.damping = 0.995
	sim.gravity = Vector3(0, -9.8, 0)
	sim.floor_y = -10.0
	sim.constraint_passes = 5
	for ring in RINGS + 1:
		var phi := PI * float(ring) / RINGS
		var y := cos(phi) * RADIUS
		var ring_radius := sin(phi) * RADIUS
		for segment in SEGMENTS:
			var theta := TAU * float(segment) / SEGMENTS
			var p := Vector3(ring_radius * cos(theta), y, ring_radius * sin(theta))
			var pinned := p.y > RADIUS * (1.0 - 0.12 * 2.0)
			if not pinned:
				p *= 1.2
			sim.add_particle(p, pinned)
	for ring in RINGS:
		for segment in SEGMENTS:
			var next := (segment + 1) % SEGMENTS
			var a := ring * SEGMENTS + segment
			var b := ring * SEGMENTS + next
			var c := (ring + 1) * SEGMENTS + segment
			var d := (ring + 1) * SEGMENTS + next
			sim.add_spring(a, b)
			sim.add_spring(a, c)
			sim.add_spring(a, d)
			indices.append_array([a, c, d, a, d, b])

func mesh_for(points: PackedVector3Array, faces: PackedInt32Array) -> ArrayMesh:
	var normals := PackedVector3Array()
	normals.resize(points.size())
	for i in range(0, faces.size(), 3):
		var a := faces[i]
		var b := faces[i + 1]
		var c := faces[i + 2]
		var n := (points[b] - points[a]).cross(points[c] - points[a]).normalized()
		normals[a] += n
		normals[b] += n
		normals[c] += n
	for i in normals.size():
		normals[i] = normals[i].normalized() if normals[i].length_squared() > 0.0 else Vector3.UP
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = faces
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh
```

### point_body.gd

<!-- student-code:point_body.gd -->
```gdscript
extends XRToolsPickable
## Point Lines' frozen point construction, made smaller for the hand model.
var tint := Color("25212a")
var desktop_pointer: WeakRef

func _init() -> void:
	freeze = true
	freeze_mode = RigidBody3D.FREEZE_MODE_KINEMATIC
	release_mode = XRToolsPickable.ReleaseMode.FROZEN
	ranged_grab_method = XRToolsPickable.RangedMethod.NONE
	collision_layer = 4
	collision_mask = 0
	var surface := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.085
	sphere.height = 0.17
	sphere.radial_segments = 24
	sphere.rings = 12
	surface.mesh = sphere
	add_child(surface)
	var boundary := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.085
	boundary.shape = shape
	add_child(boundary)

func _ready() -> void:
	super._ready()
	var finish := StandardMaterial3D.new()
	finish.albedo_color = tint
	finish.roughness = 0.24
	get_child(0).material_override = finish

func held() -> bool:
	return is_picked_up() or (desktop_pointer != null and desktop_pointer.get_ref() != null)

func on_desktop_grab(pointer: Node) -> void:
	desktop_pointer = weakref(pointer)

func on_desktop_drop(_pointer: Node) -> void:
	desktop_pointer = null
```

### solver.gd

<!-- student-code:solver.gd -->
```gdscript
# soft_body_sim.gd — Deterministic Verlet-integrator soft body simulator.
# Particles connected by springs. Fixed-timestep headless simulation —
# load a config, step N times, capture the final geometry, render.
#
# This is NOT Godot's SoftBody3D (which is visual cloth only). This is
# a research simulator: same config + same seed = exact same pose every
# time, so the rendered PNG is a reproducible artifact of the DNA.
#
# Algorithm: Verlet integration + iterative distance-constraint relaxation.
# Each step:
#   1. update each non-pinned particle position with Verlet (pos' = 2*pos - prev + accel*dt²)
#   2. apply constraint solver N times (each spring pulls endpoints toward rest_length)
#
# Materials/rendering handled by soft_body_shapes.gd, not here.

extends RefCounted

# Particle indexed fields (parallel arrays — faster than per-particle dicts)
var positions: PackedVector3Array = PackedVector3Array()
var prev_positions: PackedVector3Array = PackedVector3Array()
var pinned: Array = []                 # bool per particle
var masses: PackedFloat32Array = PackedFloat32Array()

# Springs as (a_idx, b_idx, rest_length)
var springs: Array = []
var stiffness: float = 0.8    # 0..1, applied per constraint pass
var constraint_passes: int = 4

# Environment
var gravity: Vector3 = Vector3(0, -9.8, 0)
var damping: float = 0.995    # multiplied into Verlet velocity (1.0 = none)
var floor_y: float = -10.0    # particles stopped at this y

# Topology hints — used by the renderer to know how to draw.
# For cloth: grid_cols × grid_rows, lets the renderer emit triangles.
var topology: String = "generic"    # "cloth_grid" | "jelly_box" | "blob" | "generic"
var grid_cols: int = 0
var grid_rows: int = 0


## Step simulation forward by dt seconds (usually 1/60).
func step(dt: float = 0.0166667) -> void:
	# Verlet position update
	for i in positions.size():
		if pinned[i]:
			continue
		var pos: Vector3 = positions[i]
		var prev: Vector3 = prev_positions[i]
		var vel: Vector3 = (pos - prev) * damping
		var new_pos: Vector3 = pos + vel + gravity * dt * dt
		prev_positions[i] = pos
		positions[i] = new_pos
		# Floor collision
		if positions[i].y < floor_y:
			positions[i].y = floor_y
			prev_positions[i].y = floor_y

	# Constraint relaxation — distance constraints per spring, repeated
	for _p in constraint_passes:
		for s in springs:
			var a: int = s[0]
			var b: int = s[1]
			var rest: float = s[2]
			var pa: Vector3 = positions[a]
			var pb: Vector3 = positions[b]
			var diff: Vector3 = pb - pa
			var cur: float = diff.length()
			if cur < 1e-6:
				continue
			var correction: float = (cur - rest) * 0.5 * stiffness
			var dir: Vector3 = diff / cur
			var cv: Vector3 = dir * correction
			if not pinned[a]:
				positions[a] = pa + cv
			if not pinned[b]:
				positions[b] = pb - cv


## Run N simulation steps.
func simulate(n: int, dt: float = 0.0166667) -> void:
	for _i in n:
		step(dt)


## Add a particle. Returns index.
func add_particle(pos: Vector3, is_pinned: bool = false, mass: float = 1.0) -> int:
	var idx: int = positions.size()
	positions.append(pos)
	prev_positions.append(pos)
	pinned.append(is_pinned)
	masses.append(mass)
	return idx


## Add a spring between two particles. Rest length defaults to current distance.
func add_spring(a: int, b: int, rest_length: float = -1.0) -> void:
	if rest_length < 0.0:
		rest_length = positions[a].distance_to(positions[b])
	springs.append([a, b, rest_length])
```
