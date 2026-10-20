# Pressure — a drive and a room

## Learning elements

- A closed surface receives internal pressure
- Map a sine wave to a nonnegative pressure coefficient
- Separate amplitude, rate and material response
- Hold a drive without freezing its recipient

Carusell moved the attachments of your sheet. Here the attachments stay and a pressure coefficient changes. Keep the same black PointBody. Return to the closed box from the first Soft Bodies lesson: flatten it into a small panel, then place two copies opposite each other.

## Meet the existing walls

The museum's pink slabs already receive a periodic pressure command. Watch one fixed point and one free part of a surface. Use AMPLITUDE, RATE and HOLD DRIVE on the nearby desk. Holding the drive retains its last pressure; the physics simulation continues. RESET PHASE changes the drive's clock, not the body's history.

The installed walls are not identical samples. Their authored stiffness, shrinking settings and selected pins differ. A shared pressure command does not make their responses a controlled comparison of one parameter. The small learner model below deliberately starts its two panels with matching settings.

## Close the surface

An open cloth sheet does not enclose an interior. A thin BoxMesh does. Its six sides remain a closed surface even when the object looks almost flat. We reuse the coordinate test from Cloth Physics to pin the top, bottom and ends; the broad faces can deform between those boundaries.

Save `pressure_panel.gd` beside the unchanged `point_body.gd`. This is the same construction pattern as the yielding cube, with dimensions and a perimeter pin rule chosen for a wall. Mesh and pins are prepared before the body enters the physics world.

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

## Drive pressure

Save `study.gd` beside those files and attach it to a unit-scale Node3D in an open area of the prepared Endless Museum. Player, camera, floor, XRTools and Jolt are already supplied. This is a small two-panel study you can reach around; it does not replace the installed architecture. The inherited point file is printed below.

`sin(phase)` runs from −1 to 1. Adding one and halving gives 0 to 1. Multiplying by `amplitude` gives 0 to that chosen maximum. At phase zero the pressure is half the maximum. The coefficient is an engine control, not a calibrated value in pascals.

`rate * delta` advances phase in radians. Rate controls the period; amplitude controls the input range. Neither number specifies how far the surface must move. This host updates the command on physics steps; the installed scene uses its frame callback. Both leave vertex motion to the solver.

<!-- student-code:study.gd -->
```gdscript
extends Node3D

const PressurePanel = preload("pressure_panel.gd")
const Point = preload("point_body.gd")
const RATE := 1.0
const AMPLITUDE := 0.5
var panels: Array[PressurePanel] = []
var point: XRToolsPickable
var caption: Label3D
var phase := 0.0
var rate := RATE
var amplitude := AMPLITUDE
var held := false
var pressure := 0.0

func _ready() -> void:
	for side in [-1, 1]:
		var panel := PressurePanel.new()
		panel.position = Vector3(side * 0.8, 1.3, 0)
		add_child(panel)
		panels.append(panel)
	point = Point.new()
	point.position = Vector3(0, 1.3, 1.2)
	add_child(point)
	point.action_pressed.connect(func(_p): act("HOLD DRIVE"))
	caption = Label3D.new()
	caption.position = Vector3(0, 2.15, 0.8)
	caption.font_size = 28
	caption.pixel_size = 0.001
	add_child(caption)
	apply_pressure()

func _physics_process(delta: float) -> void:
	if not held:
		phase = wrapf(phase + rate * delta, 0.0, TAU)
	apply_pressure()
	if not point.held():
		point.global_transform = global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.3, 1.2))
	caption.text = "PRESSURE %.2f | phase %.2f\n1 amplitude %.2f | 2 rate %.2f | 3 hold %s\n4 stiffness | R reset phase | held trigger: hold drive" % [pressure, phase, amplitude, rate, held]

func apply_pressure() -> void:
	pressure = (sin(phase) + 1.0) * 0.5 * amplitude
	for panel in panels:
		panel.pressure_coefficient = pressure

func act(command: String) -> void:
	match command:
		"AMPLITUDE": amplitude = 0.15 if amplitude > 0.15 else AMPLITUDE
		"RATE": rate = RATE * 0.5 if is_equal_approx(rate, RATE) else RATE
		"HOLD DRIVE": held = not held
		"STIFFNESS":
			for panel in panels:
				panel.linear_stiffness = 0.2 if panel.linear_stiffness > 0.2 else 0.5
		"RESET PHASE": phase = 0.0
	apply_pressure()

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_1: act("AMPLITUDE")
			KEY_2: act("RATE")
			KEY_3: act("HOLD DRIVE")
			KEY_4: act("STIFFNESS")
			KEY_R: act("RESET PHASE")
```

## Hold the command

Grip the familiar black point. Its held trigger toggles HOLD DRIVE. You can still move the point and press it slowly against a panel. Releasing parks it at the opening. The point is a contact probe and a switch; its position is not mapped to pressure.

Desktop controls: **1** changes amplitude; **2** halves/restores the base rate; **3** holds/resumes the phase; **4** changes stiffness on both panels; **R** sets phase to zero. The installed desk uses its own presets. Read the value before comparing.

Hold near the pressure peak and watch. A constant pressure can still produce motion while the body responds. The program never pins all vertices or disables physics to make HOLD appear successful. Changing amplitude while held immediately changes the pressure at that same phase; holding the clock does not lock every control.

Use RESET PHASE while held. Pressure returns to half the current amplitude. The same panel objects and their current shapes remain. Resetting the signal is different from rebuilding its recipient.

## One independent change

Change `AMPLITUDE` from 0.5 to 0.25 and restart. Predict the pressure at phase zero, π/2 and 3π/2: 0.125, 0.25 and zero. The period remains `TAU / RATE`, about 6.28 seconds with RATE 1.0. Keep geometry, pins, stiffness and damping unchanged.

You halved the commanded pressure. Does the gap between the panels halve? Measure or watch before answering: their response also involves geometry, constraints, material settings and accumulated motion. A pressure value is not a clearance measurement.

The contact gallery and flag dancer remain further encounters in this hall. The tutorial follows one drive into two known bodies. In the next hall, we will control the starting conditions of a contact experiment so that a comparison can be repeated.

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

Source: the installed `breathing_room.tscn` uses `breathing_room_scene.gd`; the sibling `breathing_room.gd` builds a different, unused room. See [Godot's SoftBody3D pressure property](https://docs.godotengine.org/en/4.6/classes/class_softbody3d.html#class-softbody3d-property-pressure-coefficient) and [BoxMesh](https://docs.godotengine.org/en/4.6/classes/class_boxmesh.html). Jolt supplies the simulation; the complete construction and pressure command are printed here.
