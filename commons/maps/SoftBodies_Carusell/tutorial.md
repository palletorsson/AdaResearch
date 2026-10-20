# Carusell — the support moves

## Learning elements

- A prescribed rotation: angular rate × elapsed time
- Move selected attachments in world coordinates
- Separate a command from the body's physical response
- Stop a driver without rebuilding the simulation

**Carry:** Unchanged `hanging_sheet.gd` and `point_body.gd`.  
**New work:** In `study.gd`, move the two attachments with a turning bar; let the sheet respond.  
**Supplied:** The prepared museum and Jolt’s solver.

In Cloth Physics you chose which points must stay. Keep that sheet and the same grabbable black point. This time the two upper corners follow a turning bar. Their attachment remains; its position changes.

## Watch the existing ride

The museum already contains a turning ring, jointed links and soft hanging bodies. Use SPEED, REVERSE and STOP while keeping one body in view. STOP stops the hub's rotation command. It does not remove gravity or restore the hanging bodies to their starting shapes.

The nearby cloth strips provide a fixed-support comparison. The pickup cubes, sticks and other soft objects remain available to explore. Reconstructing the whole collection is not this lesson's task.

## Continue the sheet

Save `study.gd` beside your unchanged `hanging_sheet.gd` and `point_body.gd` from Cloth Physics. Attach it to a unit-scale Node3D in an open part of the prepared museum. The museum supplies the player, camera, floor, XRTools and Jolt. The complete inherited files are included below for checking.

This study isolates the ride's driven-attachment operation using your existing sheet. It leaves out the ride's rigid links and joints. Its bar is visual and has no collider. Two gold markers show the attachment targets.

The familiar rotation rule advances `phase` in radians. Multiplying the rate by `delta` gives an angle for this physics step. `wrapf()` keeps the recorded angle between −π and π; it does not make the motion reverse at that boundary.

For each selected corner, `hub.to_global(offset)` converts a position on the bar into a position in the museum. `soft_body_move_point()` gives that target to the pinned vertex. `get_physics_rid()` identifies this sheet in Godot's physics server. Pinning prevents forces from moving these entries, but the program can still move them. The other entries remain the solver's responsibility.

Only the hub angle and the two attachment targets are prescribed. We never assign the sheet's whole rotation to make it follow the bar. The body can lag, fold or keep moving after the bar stops.

<!-- student-code:study.gd -->
```gdscript
extends Node3D

const Sheet = preload("hanging_sheet.gd")
const Point = preload("point_body.gd")
const RATE := 0.4
const HOME := Vector3(0, 1.3, 0)
var sheet: Sheet
var point: XRToolsPickable
var hub: Node3D
var caption: Label3D
var phase := 0.0
var rate := RATE

func _ready() -> void:
	caption = Label3D.new()
	caption.position = Vector3(0, 2.55, 0)
	caption.font_size = 28
	caption.pixel_size = 0.001
	add_child(caption)
	hub = Node3D.new()
	hub.position = HOME + Vector3.UP * Sheet.HEIGHT * 0.5
	add_child(hub)
	var bar := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(Sheet.WIDTH + 0.2, 0.05, 0.08)
	bar.mesh = box
	bar.position.y = 0.06
	hub.add_child(bar)
	var gold := StandardMaterial3D.new()
	gold.albedo_color = Color("d7ad67")
	for side in [-1, 1]:
		var marker := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.018
		sphere.height = 0.036
		marker.mesh = sphere
		marker.material_override = gold
		marker.position.x = side * Sheet.WIDTH * 0.5
		hub.add_child(marker)
	point = Point.new()
	point.position = Vector3(1.15, 1.3, 0.6)
	add_child(point)
	point.action_pressed.connect(func(_p): act("PLAY / HOLD"))
	rebuild()

func rebuild() -> void:
	if is_instance_valid(sheet):
		remove_child(sheet)
		sheet.queue_free()
	phase = 0.0
	rate = RATE
	hub.rotation.y = phase
	sheet = Sheet.new()
	sheet.set_pins(1)
	sheet.position = HOME
	add_child(sheet)

func _physics_process(delta: float) -> void:
	phase = wrapf(phase + rate * delta, -PI, PI)
	hub.rotation.y = phase
	for i in sheet.pins:
		var offset := Vector3(sheet.rest_points[i].x, 0, 0)
		var target := hub.to_global(offset)
		PhysicsServer3D.soft_body_move_point(sheet.get_physics_rid(), i, target)
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(1.15, 1.3, 0.6))
	caption.text = "%.2f rad/s | %.2f rad\n1: speed | 2: reverse | 3: stop | R: rebuild\nHeld trigger: play / hold" % [rate, phase]

func act(command: String) -> void:
	match command:
		"SPEED": rate = RATE * 2.0 if is_equal_approx(rate, RATE) else RATE
		"REVERSE": rate = -rate
		"STOP": rate = 0.0
		"PLAY / HOLD": rate = RATE if is_zero_approx(rate) else 0.0
		"REBUILD": rebuild()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: act("SPEED")
			KEY_2: act("REVERSE")
			KEY_3: act("STOP")
			KEY_R: act("REBUILD")
```

`rebuild()` selects the two corners before the fresh sheet enters the world. Its reference mesh and material settings are unchanged. The two attachment targets are updated on every physics step, including while stopped; a stopped support still holds its points.

## Use the same ball

Grip the black point and press it slowly into the sheet. Its collider and pickup behaviour are unchanged. The held trigger now pauses or resumes the turning support. It changes the host's rate; it does not replace the point or the cloth.

Desktop keys: **1** switches between the base rate and twice that rate; **2** reverses the current rate; **3** stops it; **R** rebuilds the sheet and starts again. Reversing zero still gives zero. Use **1**, or the held trigger, to start after stopping. Resuming selects the positive base rate. The installed museum desk keeps its own SPEED, REVERSE and STOP controls; its speed presets differ from this small study.

Stop after a turn. The angle stops changing, but the free vertices can continue moving. Stop again: nothing is rebuilt. Then use REBUILD and notice the different operation—the reference sheet returns and the angle starts again at zero.

## One independent change

Change `RATE` from 0.4 to 0.8 and restart. Predict twice the commanded angle over the same interval: 0.8 instead of 0.4 radians after one second. One full turn takes `TAU / rate` seconds at a constant positive rate. Keep the geometry, pins and response settings unchanged.

Does the free edge travel twice as far? That does not follow from doubling the command. Its movement also depends on its current shape, velocity, gravity and contact. Explain the difference using the two gold attachment markers and one point farther down the surface.

Carry this separation into the next room: a program can drive a changing condition while a simulated body responds. There the changing condition will be pressure, and the surface will enclose the visitor.

<details>
<summary>Inherited sheet — unchanged from Cloth Physics</summary>

<!-- student-code:hanging_sheet.gd -->
```gdscript
extends SoftBody3D

const WIDTH := 1.2
const HEIGHT := 1.4
const COLUMNS := 6
var rest_points: PackedVector3Array
var pins: Array[int] = []
var mode := 0

func _init() -> void:
	var surface := PlaneMesh.new()
	surface.orientation = PlaneMesh.FACE_Z
	surface.size = Vector2(WIDTH, HEIGHT)
	surface.subdivide_width = COLUMNS
	surface.subdivide_depth = 12
	rest_points = surface.get_mesh_arrays()[Mesh.ARRAY_VERTEX]
	mesh = surface
	simulation_precision = 5
	total_mass = 1.0
	linear_stiffness = 0.34
	damping_coefficient = 0.05
	pressure_coefficient = 0.0
	collision_layer = 1
	collision_mask = 1 | 4 | (1 << 17) | (1 << 18)
	var finish := StandardMaterial3D.new()
	finish.albedo_color = Color("e7dbce")
	finish.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = finish
	set_pins(0)

func set_pins(next_mode: int) -> void:
	assert(next_mode in [0, 1, 2])
	mode = next_mode
	pins.clear()
	for i in rest_points.size():
		var p := rest_points[i]
		var top := absf(p.y - HEIGHT * 0.5) < 0.001
		var corner := absf(absf(p.x) - WIDTH * 0.5) < 0.001
		var keep := top and (mode == 0 or (mode == 1 and corner))
		set_point_pinned(i, keep)
		if keep:
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

The installed ride advances `ride_hub.rotation.y` in `_physics_process()` and attaches its soft bodies to moving rigid links through `set_point_pinned()` attachment paths. The learner study exposes the world-space target directly so the existing sheet can carry the new operation. Both arrangements prescribe the support; this is not a simulation of a motor receiving reaction torque.

Sources: `algorithms/softbodies/joyride/revolving_joy_ride.gd`, `commons/artifacts/timing_machines/soft_workshop.gd`. API: [PhysicsServer3D: moving pinned points](https://docs.godotengine.org/en/4.6/classes/class_physicsserver3d.html#class-physicsserver3d-method-soft-body-move-point). The supplied solver handles the free entries; the complete boundary update is printed above.
