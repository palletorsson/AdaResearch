# A shape kept

## Learning elements

- Vertex positions and face indices
- Copying a snapshot
- Local coordinates and display placement
- Sampling time versus simulation state

<!-- @rounded_softbody_test -->

At the rounded body, change MEASURE. The display changes; the body keeps responding. FEEDBACK is a separate action: it changes pressure using the volume of an enclosing box as its reading. That box is a proxy, not the volume inside the skin. Explore this distinction here; the code lesson follows the glass vessel beside it.

<!-- @ -->

<!-- @frozen_glass_vessel -->

Last hall you kept a number while a panel continued to fall. Now keep a surface. The installed vessel already does this: start with a sphere, pin its upper region, simulate, then build a mesh from the resulting positions. DURATION reconstructs it with another number of steps. You are choosing which state becomes the object.

We use the vessel's construction and custom particle solver for this lesson. Its `positions` array is directly readable. This is a change of implementation from the previous Jolt panel, not a claim that those two solvers have interchangeable properties. The operation carried forward is sampling a moving body. Our black PointBody also returns, unchanged, as the capture control.

## Other shapes in this hall

Four comparison stations extend this encounter. In the first, choose which four moments of one simulation remain. In the second, pull the black point sideways and release: three matching constructions receive opposite lateral pulls. In the third, show the saved surface's triangle edges. Hiding the skin changes its appearance; its contact surface remains.

At **From the soft body gallery**, NEXT selects another group of three examples. POSE, or the held point's trigger, switches between starting and captured geometry: cloth, a lattice, a branch, a cellular-automata net and two mould experiments. Each pair keeps the same display frame. These are saved shapes; the controls do not resume their simulations. Cloth and sphere-grid skins are drawn over their saved connections; other examples show the spring network. A mould constrains particles in this model; it is not a simulation of molten glass.

Use these examples to ask what was retained. The tutorial below still builds one operation: copy the vessel's positions and face indices while its source continues.

## Build beside the encounter

Work in the prepared Endless Museum project. The player, camera, lighting, floor, XRTools and physics setup are already supplied. Create a Node3D named `ShapeKept` in a clear part of this hall, at floor level and unit scale. Attach `study.gd`. Put all four files below in the same folder. The downloadable `study.tscn` provides exactly that root and script attachment; it contains no hidden meshes.

`study.gd` is the new work. `point_body.gd` is the previous hall's class. `vessel_surface.gd` supplies the installed vessel's sphere, spring connections and mesh assembly. `solver.gd` is an unchanged copy of `commons/soft_body/soft_body_sim.gd`. They are printed below for a complete runnable example; writing a solver is not this lesson's task.

Two pink surfaces appear. The left one runs. At step 40, the right one keeps a copy. Hold the black point and press its trigger to replace that copy with a later state. On desktop, press **1** to capture and **2** to start again. Holding or moving the point does not deform these surfaces; here its trigger operates the sampler.

<!-- student-code:study.gd -->
```gdscript
extends Node3D
const VesselSurface = preload("vessel_surface.gd")
const PointBody = preload("point_body.gd")
const SAMPLE_STEP := 40
const STEP := 0.0166667
var surface = VesselSurface.new()
var live := MeshInstance3D.new()
var kept := MeshInstance3D.new()
var point = PointBody.new()
var caption := Label3D.new()
var step_count := 0
var saved_step := -1
var saved_positions := PackedVector3Array()
var saved_indices := PackedInt32Array()

func _ready() -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("c98288")
	material.roughness = 0.3
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	for body in [live, kept]:
		body.material_override = material
		add_child(body)
	live.position = Vector3(-0.85, 2.0, 0)
	kept.position = Vector3(0.85, 2.0, 0)
	point.position = Vector3(0, 1.1, 1.0)
	add_child(point)
	point.action_pressed.connect(func(_source): capture())
	caption.position = Vector3(0, 3.0, 0)
	caption.font_size = 32
	caption.pixel_size = 0.0025
	caption.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(caption)
	restart()

func _physics_process(_delta: float) -> void:
	surface.sim.step(STEP)
	step_count += 1
	live.mesh = surface.mesh_for(surface.sim.positions, surface.indices)
	if step_count == SAMPLE_STEP:
		capture()
	update_caption()

func capture() -> void:
	saved_positions = surface.sim.positions.duplicate()
	saved_indices = surface.indices.duplicate()
	saved_step = step_count
	kept.mesh = surface.mesh_for(saved_positions, saved_indices)
	update_caption()

func restart() -> void:
	surface = VesselSurface.new()
	step_count = 0
	saved_step = -1
	saved_positions.clear()
	saved_indices.clear()
	kept.mesh = null
	live.mesh = surface.mesh_for(surface.sim.positions, surface.indices)
	update_caption()

func update_caption() -> void:
	var reading := "waiting" if saved_step < 0 else "step %d" % saved_step
	caption.text = "LIVE: step %d    |    KEPT: %s\nPoint trigger / 1: capture    2: restart" % [step_count, reading]

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_1:
			capture()
		elif event.keycode == KEY_2:
			restart()
```

## Read the operation

`capture()` copies two arrays. Positions say where the vertices are. Indices say which entries form each triangle, just as in the earlier polyhedra lesson. We keep that connectivity while the positions change. The helper recalculates normals for the saved surface and returns a new ArrayMesh.

The copied positions remain in the solver's local frame, measured in the project's metre scale. The two mesh nodes place the same shape to the left and right. Their offsets stage the comparison; they do not change the saved data. Adding a world position to those vertices would apply placement twice.

Each physics callback advances the custom solver by its fixed `0.0166667` step, approximately `1/60` second. We count those steps explicitly. Step 40 means forty integrations; the caption does not promise that forty callbacks took a particular amount of wall-clock time. `SAMPLE_STEP` selects the automatic capture. A trigger can capture at any other step, including after that selection.

Only the live mesh is rebuilt each tick. The saved mesh stays until another capture or a restart. No disk file is written. This snapshot keeps positions, triangle connections and a step number. It omits the solver's previous positions, pins, spring settings and force history. A shape alone is not enough to resume this simulation. The displayed copy also has no collision body; the installed glass artifact does.

## Change when you stop

Change `SAMPLE_STEP` from `40` to `200`. Before running, predict what stays the same: the vertex count, face indices and display placement. Predict what may change: the saved positions. Run the whole example. Check the KEPT caption, then wait. The left side must continue; the right side must keep its step-200 shape. Trigger another capture and verify that the right side changes only then.

Use **2** to restart. The saved mesh and step label clear, the solver is reconstructed, and the same point object remains available. Resetting only the counter would not restart the experiment.

## Supplied files

These files expose the construction the host relies on. Keep their settings fixed for the capture-time experiment. The adapter follows the installed vessel's radius, rings, segments, upper pins, initial expansion and spring order. It uses the same local positions but displays both results in opaque pink so their contours can be compared.

<details>
<summary>vessel_surface.gd — sphere, constraints and mesh assembly</summary>

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

</details>

<details>
<summary>point_body.gd — the unchanged grabbable point</summary>

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

</details>

<details>
<summary>solver.gd — the supplied particle solver</summary>

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

</details>

## What travels onward

You can turn one state of a process into a separate object, state when you selected it, and name what you left out. In the next hall, organic-looking forms invite another inference: does looking alive tell us how something was made?

<!-- @ -->
