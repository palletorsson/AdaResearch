# Same fall, another encounter

## Learning elements

- Describe a comparison as two cases
- Change one coefficient while retaining the shared construction
- Rebuild starting conditions instead of resetting only the clock
- Keep a timed observation while the bodies continue

The last hall gave matching panels a pressure command. Keep those panel and PointBody classes. Here we remove the panels' pins, turn them flat and let them fall onto two copies of the black point. Both drops begin alike. Only their damping coefficients differ.

## Find a comparison in the museum

<!-- @softbody_gallery_part2 -->

The existing gallery contains twelve named encounters. High Drag gives a sphere more damping; Corner Strike changes where it meets a collider. Other cells change shape, stiffness or pressure together. Looking across the array can suggest a question, but it does not isolate its cause.

The desk's REPLAY reconstructs the group with seed 1337. VARIATION toggles additional changes to stiffness and pressure; GROUP selects another set. A seed repeats the chosen inputs to the random generator. It does not rewind a body or guarantee identical physical trajectories on every machine.

For our smaller comparison, there is no random input to seed. We can state the two cases directly.

## Two cases, one construction

Continue in the prepared Endless Museum: player, floor, camera, XRTools and Jolt already exist. Keep the previous `pressure_panel.gd` and `point_body.gd` beside the new `study.gd`. Attach the host to a unit-scale Node3D in a clear area. The complete inherited files are below.

`CASES` is a list of two dictionaries. Each dictionary names a case and supplies its damping coefficient. Everything else comes from the same panel constructor: mesh, mass, stiffness, pressure, solver setting and material. The two bays are simply separated so their bodies cannot collide with each other.

The old perimeter pins would prevent a fall. The host unpins them on both new panels, then rotates each panel by a quarter turn. Pressure remains zero; there is no sine driver in this experiment. Both black points have the same sphere mesh and collision shape. Their small offset places each point beneath a vertex in the panel's existing grid; it is part of the shared contact setup.

<!-- student-code:study.gd -->
```gdscript
extends Node3D

const SamplePanel = preload("pressure_panel.gd")
const Point = preload("point_body.gd")
const SAMPLE_TIME := 1.5
const CONTACT := Vector3(0.6 / 7.0, 1.1, 0.1)
const CASES := [
	{"name": "A", "damping": 0.1},
	{"name": "B", "damping": 0.6},
]
var panels: Array[SamplePanel] = []
var points: Array[XRToolsPickable] = []
var captions: Array[Label3D] = []
var results: Array[float] = []
var elapsed := 0.0
var running := false
var armed := false
var status := ""

func _ready() -> void:
	for i in CASES.size():
		var point := Point.new()
		point.position = bay(i) + CONTACT
		add_child(point)
		points.append(point)
		point.action_pressed.connect(func(_p): request_replay())
		var caption := Label3D.new()
		caption.position = bay(i) + Vector3(0, 2.8, 0.5)
		caption.font_size = 28
		caption.pixel_size = 0.003
		add_child(caption)
		captions.append(caption)
	replay()

func bay(i: int) -> Vector3:
	return Vector3((i - 0.5) * 2.0, 0, 0)

func request_replay() -> void:
	armed = true

func replay() -> void:
	for panel in panels:
		remove_child(panel)
		panel.queue_free()
	panels.clear()
	results.clear()
	for i in CASES.size():
		var panel := SamplePanel.new()
		for index in panel.pins:
			panel.set_point_pinned(index, false)
		panel.pins.clear()
		panel.position = bay(i) + Vector3(0, 2.1, 0)
		panel.rotation.z = PI * 0.5
		panel.damping_coefficient = CASES[i].damping
		add_child(panel)
		panels.append(panel)
	elapsed = 0.0
	running = true
	armed = false
	status = "Fresh drop"

func _physics_process(delta: float) -> void:
	var hand_inside := false
	for i in points.size():
		if points[i].held():
			hand_inside = true
		else:
			points[i].global_transform = global_transform * Transform3D(Basis.IDENTITY, bay(i) + CONTACT)
	if hand_inside:
		running = false
		results.clear()
		status = "Hand changes the experiment"
	elif armed:
		replay()
	elif running:
		elapsed += delta
		if elapsed >= SAMPLE_TIME:
			for panel in panels:
				results.append(height_span(panel))
			running = false
			status = "Sample kept; bodies continue"
	for i in captions.size():
		var reading := "height --"
		if results.size() == CASES.size():
			reading = "height %.3f m" % results[i]
		captions[i].text = "%s | damping %.2f\n%s | t %.2f s\n%s\n1 or grip / trigger / release: replay" % [CASES[i].name, CASES[i].damping, reading, elapsed, status]

func height_span(panel: SoftBody3D) -> float:
	var low := INF
	var high := -INF
	for i in panel.rest_points.size():
		var y := to_local(panel.get_point_transform(i)).y
		low = minf(low, y)
		high = maxf(high, y)
	return high - low

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_1:
		request_replay()
```

## Run and touch

The first pair drops when the study starts. Watch it from the side. Use **1** to repeat. In VR, grip either black point, press its trigger, then release it. The trigger requests a replay; releasing returns both points to their declared places before the new drop begins.

You can still move a point against a panel. Doing so interrupts the measured comparison and clears its readings: your hand has added another changing condition. Trigger and release when you want a fresh trial. A queued replay waits until neither point is held. The program never drags a held point back to its parking place.

`replay()` removes the two old panels from the world and constructs fresh ones. It clears the recorded results and starts the clock again. The PointBody instances remain. Resetting only `elapsed` would leave the existing folds and motion in place, giving the second attempt a different beginning.

## Keep one observation

At the first physics step reaching 1.5 seconds, the host reads each panel's vertex positions. It records the highest minus the lowest height in the study's coordinate frame. This is a vertical extent in metres, not volume, material quality or distance travelled. Keep the host upright and at unit scale.

`get_point_transform()` supplies world positions. `to_local()` brings them into the same reference frame before comparison. The value stays on the caption while the panels continue moving. Sampling does not freeze their physics.

Compare several fresh trials. More damping is expected to reduce motion, but contact, gravity and folding also affect the height at one chosen time. A different height is an observation to investigate; it is not a direct reading of damping. Keep other moving objects and your hands clear during the measured run.

## One independent change

Change B's damping from **0.6 to 0.1** and restart. Before running, predict what now matches: both recipes, contact shapes, initial orientations and release heights. Predict similar readings under the same conditions, rather than promising exact equality across all computers. If a difference persists, check the starting construction, environment and timing before adding another explanation.

You have a repeatable procedure and a small record of its outcome. In the next hall, we will ask what happens when a selected reading or a stopped surface comes to stand for the whole event.

<details>
<summary>Inherited pressure panel — unchanged; this host releases its pins</summary>

<!-- student-code:pressure_panel.gd -->
```gdscript
extends SoftBody3D

const SIZE := Vector3(0.16, 1.2, 1.8)
var rest_points: PackedVector3Array
var pins: Array[int] = []

func _init() -> void:
	var surface := BoxMesh.new()
	surface.size = SIZE
	surface.subdivide_height = 6
	surface.subdivide_depth = 8
	rest_points = surface.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	mesh = surface
	total_mass = 1.0
	linear_stiffness = 0.5
	damping_coefficient = 0.1
	pressure_coefficient = 0.0
	simulation_precision = 5
	collision_layer = 1
	collision_mask = 1 | 4 | (1 << 17) | (1 << 18)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("c98288")
	material_override = finish
	for i in rest_points.size():
		var p := rest_points[i]
		var edge := absf(absf(p.y) - SIZE.y * 0.5) < 0.001 or absf(absf(p.z) - SIZE.z * 0.5) < 0.001
		if edge:
			set_point_pinned(i, true)
			pins.append(i)
```

</details>

<details>
<summary>Inherited grabbable PointBody — unchanged</summary>

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

The installed gallery remains a larger collection of possibilities. This learner study isolates one comparison using the objects you already constructed; it does not rebuild all twelve exhibits.
