extends Node3D
## A four-metre entrance room: two held positions give one changing segment.
## Reuses the existing line calculation and XR Tools pickup/release driver.
## Openings match the author's north entrance and east passage in Point_Lines.
const LineScript = preload("res://commons/primitives/line/line.gd")
const Pickable = preload("res://addons/godot-xr-tools/objects/pickable.tscn")
const ButtonScript = preload("res://commons/interactables/interactable_area_button_pointer.gd")
const HOME_A := Vector3(-0.8, 1.25, 0.25)
const HOME_B := Vector3(0.8, 1.25, 0.25)
var line: Node3D
var point_a: XRToolsPickable
var point_b: XRToolsPickable
var readout: Label3D
var reset_button: Area3D
var _last_text := ""
var _partitions: Array[MeshInstance3D] = []

func _ready() -> void:
	_build_room()
	line = Node3D.new()
	line.name = "LineStudy"
	line.set_script(LineScript)
	line.set("line_thickness", 0.012)
	line.set("line_color", Color("fff5e6"))
	line.set("readout", "none")
	# The introductory study makes distance legible without the later work's
	# integer-triggered jitter. This does not change any older line placements.
	line.set("enable_resistance", false)
	point_a = _endpoint("GrabSphere", HOME_A)
	point_b = _endpoint("GrabSphere2", HOME_B)
	line.add_child(point_a)
	line.add_child(point_b)
	add_child(line)
	var segment: MeshInstance3D = line.get("current_line")
	segment.name = "Segment"
	(segment.mesh as CylinderMesh).radial_segments = 32
	var finish := segment.material_override as StandardMaterial3D
	finish.metallic = 0.18
	finish.roughness = 0.24
	finish.emission_energy_multiplier = 0.65
	var sound: AudioStreamPlayer3D = line.get("_glitch_player")
	if sound != null: sound.stop()
	# This room has its own modest caption; no inherited drop-message overlay.
	for endpoint in [point_a, point_b]:
		var drop := Callable(line, "_on_point_dropped")
		if endpoint.dropped.is_connected(drop): endpoint.dropped.disconnect(drop)
	readout = _label("1.60 m", Vector3(0, 1.83, 1.90), 65, Color("f2ece4"))
	_label("TWO POINTS / ONE LINE", Vector3(0, 2.16, 1.90), 24, Color("b1a4b1"))
	_label("Take either end.", Vector3(0, 0.99, 1.90), 27, Color("c1b8bc"))
	_build_reset()

func _build_room() -> void:
	var black := _material(Color("101015"), 0.88)
	var floor_mat := _material(Color("1b1b22"), 0.57)
	# Top lies 1 cm above the existing deck; no raised exhibition platform.
	_box("Floor", Vector3(4, 0.02, 4), Vector3(0, 0, 0), floor_mat, true)
	_box("Ceiling", Vector3(4, 0.08, 4), Vector3(0, 3.20, 0), black, true)
	_box("West", Vector3(0.08, 3.2, 4), Vector3(-1.96, 1.6, 0), black, true)
	_box("South", Vector3(4, 3.2, 0.08), Vector3(0, 1.6, 1.96), black, true)
	# Door interval [-1.05, .05], centred at -.5 along each boundary.
	_box("NorthLeft", Vector3(0.95, 3.2, 0.08), Vector3(-1.525, 1.6, -1.96), black, true)
	_box("NorthRight", Vector3(1.95, 3.2, 0.08), Vector3(1.025, 1.6, -1.96), black, true)
	_box("NorthLintel", Vector3(1.1, 0.9, 0.08), Vector3(-0.5, 2.75, -1.96), black, true)
	_box("EastFront", Vector3(0.08, 3.2, 0.95), Vector3(1.96, 1.6, -1.525), black, true)
	_box("EastRear", Vector3(0.08, 3.2, 1.95), Vector3(1.96, 1.6, 1.025), black, true)
	_box("EastLintel", Vector3(0.08, 0.9, 1.1), Vector3(1.96, 2.75, -0.5), black, true)
	var seam := _material(Color("ba849d"), 0.4, 0.65)
	_box("BackSeam", Vector3(3.82, 0.009, 0.012), Vector3(0, 0.055, 1.912), seam)
	_box("LeftSeam", Vector3(0.012, 0.009, 3.82), Vector3(-1.912, 0.055, 0), seam)
	var slit := _material(Color("ded4d5"), 0.4, 0.65)
	_box("CeilingSlit", Vector3(2.5, 0.008, 0.027), Vector3(0, 3.153, 0.25), slit)
	var lamp := OmniLight3D.new()
	lamp.name = "StudyLight"
	lamp.position = Vector3(0, 2.75, 0.15)
	lamp.light_color = Color("eee0e1")
	lamp.light_energy = 1.4
	lamp.omni_range = 3.7
	lamp.shadow_enabled = true
	add_child(lamp)

func _endpoint(title: String, at: Vector3) -> XRToolsPickable:
	var point := Pickable.instantiate() as XRToolsPickable
	point.name = title
	point.position = at
	point.freeze = true
	point.release_mode = XRToolsPickable.ReleaseMode.FROZEN
	var collision := SphereShape3D.new()
	collision.radius = 0.075
	point.get_node("CollisionShape3D").shape = collision
	var mesh := MeshInstance3D.new()
	mesh.name = "Handle"
	var sphere := SphereMesh.new()
	sphere.radius = 0.065
	sphere.height = 0.13
	sphere.radial_segments = 32
	sphere.rings = 16
	mesh.mesh = sphere
	mesh.material_override = _material(Color("e6dce0"), 0.23, 0.1)
	point.add_child(mesh)
	var collar := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = 0.067
	ring.outer_radius = 0.076
	ring.rings = 32
	ring.ring_segments = 8
	collar.mesh = ring
	collar.rotation.z = PI / 2.0
	collar.material_override = _material(Color("e49ebc"), 0.3, 0.4)
	point.add_child(collar)
	return point

func _process(_delta: float) -> void:
	if not is_instance_valid(readout): return
	var span := point_a.global_position.distance_to(point_b.global_position)
	var caption := "%.2f m" % span
	if caption != _last_text:
		readout.text = caption
		_last_text = caption
	# Coincident points have no segment; do not leave a stale visible rod.
	var segment: MeshInstance3D = line.get("current_line")
	if segment != null: segment.visible = span > 0.001

func reset_line() -> void:
	# A second visitor pressing reset must not move something in a held hand.
	if point_a.is_picked_up() or point_b.is_picked_up(): return
	for pair in [[point_a, HOME_A], [point_b, HOME_B]]:
		var point: XRToolsPickable = pair[0]
		var home := Transform3D(Basis.IDENTITY, pair[1])
		point.global_transform = line.global_transform * home
		PhysicsServer3D.body_set_state(point.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, point.global_transform)
		point.linear_velocity = Vector3.ZERO
		point.angular_velocity = Vector3.ZERO
	line.call("update_line_transform", point_a.position, point_b.position)
	_process(0.0)

func _build_reset() -> void:
	var cap := _box("ResetCap", Vector3(0.14, 0.14, 0.025), Vector3(1.40, 1.15, 1.90), _material(Color("aa8098"), 0.4))
	_label("RESET", Vector3(1.40, 0.96, 1.89), 20, Color("c1b8bc"))
	reset_button = Area3D.new()
	reset_button.name = "ResetButton"
	reset_button.set_script(ButtonScript)
	reset_button.set("button", NodePath("../ResetCap"))
	reset_button.set("displacement", Vector3.ZERO)
	reset_button.collision_layer = 1 << 20
	reset_button.collision_mask = 393216
	reset_button.position = cap.position - Vector3(0, 0, 0.04)
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(0.20, 0.20, 0.10)
	collision.shape = shape
	reset_button.add_child(collision)
	add_child(reset_button)
	reset_button.connect("button_pressed", func(_button): reset_line())

func _label(words: String, at: Vector3, size: int, colour: Color) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.position = at
	label.rotation.y = PI
	label.font_size = size
	label.pixel_size = 0.0018
	label.modulate = colour
	label.outline_size = 0
	label.no_depth_test = false
	add_child(label)
	return label

func _material(colour: Color, roughness: float, emission: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = roughness
	mat.emission_enabled = emission > 0.0
	mat.emission = colour
	mat.emission_energy_multiplier = emission
	return mat

func get_museum_occupied_cells() -> Array:
	# The room's envelope contains a route. Only full-height partitions seal
	# cells; the deck, ceiling, lintels and suspended segment remain traversable.
	var cells := {}
	for wall in _partitions:
		var bounds: AABB = wall.global_transform * wall.mesh.get_aabb()
		for z in range(int(floor(bounds.position.z)), int(ceil(bounds.end.z))):
			for x in range(int(floor(bounds.position.x)), int(ceil(bounds.end.x))):
				cells[Vector2i(x, z)] = true
	return cells.keys()

func _box(title: String, size: Vector3, at: Vector3, finish: Material, solid: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.material_override = finish
	mesh.position = at
	add_child(mesh)
	if solid:
		if size.y > 2.0: _partitions.append(mesh)
		var body := StaticBody3D.new()
		body.collision_layer = 1
		var collision := CollisionShape3D.new()
		var volume := BoxShape3D.new()
		volume.size = size
		collision.shape = volume
		body.add_child(collision)
		mesh.add_child(body)
	return mesh
