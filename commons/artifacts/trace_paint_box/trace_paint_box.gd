extends Node3D
## A hand enters a bounded volume; its movement becomes a retained sculpture.
## Coordinates belong to this box. Leaving, losing tracking or sleeping a floor
## closes the stroke, never deletes it. Only the explicit Clear button erases.

const CLEAR_BUTTON = preload("res://commons/interactables/cube_button.tscn")
const VOLUME := AABB(Vector3(-0.3, 0.6, -0.3), Vector3(0.6, 1.4, 0.6))
const CAPACITY := 2048
const COLOURS := {
	"tube": Color("#ef789e"), "ribbon": Color("#77d4b8"),
	"beads": Color("#eeb65b"), "grid": Color("#a299ef")
}
const NUMBERS := {"tube": "01", "ribbon": "02", "beads": "03", "grid": "04"}

@export_enum("tube", "ribbon", "beads", "grid") var brush := "tube"

var strokes: Array[Dictionary] = []
var mark_count := 0
var _active: Dictionary = {}
var _origin: XROrigin3D
var _hands: Array[XRController3D] = []
var _scan_in := 0.0
var _segments: MultiMesh
var _dots: MultiMesh
var _segment_count := 0
var _dot_count := 0
var _status: Label3D
var _edge: StandardMaterial3D


func apply_grid_config(config: Dictionary) -> void:
	# Brush is a construction choice. Editor pose changes must retain the work.
	if not is_node_ready():
		var requested := str(config.get("brush", brush))
		if COLOURS.has(requested): brush = requested


func _ready() -> void:
	if not COLOURS.has(brush): brush = "tube"
	_build()
	visibility_changed.connect(_close_strokes)


func _notification(what: int) -> void:
	if what == NOTIFICATION_PAUSED or what == NOTIFICATION_DISABLED:
		_close_strokes()


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		_close_strokes()
		return
	_scan_in -= delta
	if _scan_in <= 0.0:
		_scan_in = 0.5
		_find_hands()
	if not is_instance_valid(_origin) or not _origin.current:
		_close_strokes()
		return
	var present: Dictionary = {}
	for hand in _hands:
		if not is_instance_valid(hand): continue
		var id := hand.get_instance_id()
		if not hand.get_is_active() or not hand.get_has_tracking_data():
			_active.erase(id)
			continue
		present[id] = true
		var local_point := to_local(hand.global_position)
		var across := global_basis.inverse() * hand.global_basis.x
		_sample(id, local_point, across)
	for id in _active.keys():
		if not present.has(id): _active.erase(id)
	_refresh_status()


func _find_hands() -> void:
	if not is_instance_valid(_origin) or not _origin.current:
		_origin = null
		_hands.clear()
		# Prefer the active camera's rig; the fallback also permits XRServer
		# supplied tracking in the native test harness, without an HMD.
		var camera: Node = get_viewport().get_camera_3d()
		while is_instance_valid(camera):
			if camera is XROrigin3D and camera.current:
				_origin = camera
				break
			camera = camera.get_parent()
		if _origin == null:
			for candidate in get_tree().root.find_children("*", "XROrigin3D", true, false):
				if candidate.current and candidate.get_viewport() == get_viewport():
					_origin = candidate
					break
	if _origin == null: return
	_hands.clear()
	for controller in _origin.find_children("*", "XRController3D", true, false):
		if controller.tracker in [&"left_hand", &"right_hand"]:
			_hands.append(controller)


func _sample(id: int, local_point: Vector3, across: Vector3) -> void:
	if not VOLUME.has_point(local_point):
		_active.erase(id)
		return
	if mark_count >= CAPACITY: return
	# Keep the thickness of paint inside the box, including at its edges.
	var margin := 0.03
	var point := local_point.clamp(VOLUME.position + Vector3.ONE * margin,
		VOLUME.end - Vector3.ONE * margin)
	if brush == "grid":
		point = point.snapped(Vector3.ONE * 0.05).clamp(
			Vector3(-0.25, 0.65, -0.25), Vector3(0.25, 1.95, 0.25))
	if not _active.has(id):
		strokes.append({"hand": id, "brush": brush, "points": [point]})
		_active[id] = strokes.size() - 1
		_add_dot(point)
		mark_count += 1
		return
	var points: Array = strokes[int(_active[id])].points
	var previous: Vector3 = points.back()
	var spacing := 0.045 if brush == "beads" else 0.008
	if point.distance_to(previous) < spacing: return
	points.append(point)
	mark_count += 1
	if brush == "beads":
		_add_dot(point)
	else:
		_add_segment(previous, point, across)
		if brush == "grid": _add_dot(point)


func _add_dot(point: Vector3) -> void:
	_dots.set_instance_transform(_dot_count, Transform3D(Basis.IDENTITY, point))
	_dot_count += 1
	_dots.visible_instance_count = _dot_count


func _add_segment(a: Vector3, b: Vector3, across: Vector3) -> void:
	var y := (b - a).normalized()
	var x := across - y * across.dot(y)
	if x.length_squared() < 0.001:
		var alternate := Vector3.UP if absf(y.y) < 0.9 else Vector3.RIGHT
		x = alternate.cross(y)
	x = x.normalized()
	var basis := Basis(x, y * a.distance_to(b), x.cross(y).normalized())
	_segments.set_instance_transform(_segment_count, Transform3D(basis, (a + b) * 0.5))
	_segment_count += 1
	_segments.visible_instance_count = _segment_count


func clear_paint() -> void:
	strokes.clear()
	_active.clear()
	mark_count = 0
	_dot_count = 0
	_segment_count = 0
	_dots.visible_instance_count = 0
	_segments.visible_instance_count = 0
	_refresh_status()


func _close_strokes() -> void:
	_active.clear()
	if is_instance_valid(_status): _refresh_status()


func _refresh_status() -> void:
	if mark_count >= CAPACITY:
		_status.text = "FULL / work kept\nClear to draw again"
	elif not _active.is_empty():
		_status.text = "DRAWING / %d hand%s" % [_active.size(), "s" if _active.size() > 1 else ""]
	else:
		_status.text = "HAND IN / DRAW\nHAND OUT / KEEP"
	_edge.emission_energy_multiplier = 0.9 if not _active.is_empty() else 0.15


func _build() -> void:
	var chalk := _material(Color("#e4e1d9"))
	var ink := Color("#343239")
	var colour: Color = COLOURS[brush]
	_box("Plinth", Vector3(0, 0.3, 0), Vector3(0.6, 0.6, 0.6), chalk)
	var solid := StaticBody3D.new()
	solid.name = "PlinthCollision"
	solid.collision_layer = 1
	solid.collision_mask = 0
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3.ONE * 0.6
	collider.shape = shape
	collider.position.y = 0.3
	solid.add_child(collider)
	add_child(solid)
	_edge = _material(colour)
	_edge.emission_enabled = true
	_edge.emission = colour
	_edge.emission_energy_multiplier = 0.15
	for x in [-0.295, 0.295]:
		for z in [-0.295, 0.295]:
			_box("Upright", Vector3(x, 1.3, z), Vector3(0.01, 1.4, 0.01), chalk)
	for y in [0.605, 1.995]:
		for side in [-0.295, 0.295]:
			_box("Rim", Vector3(0, y, side), Vector3(0.6, 0.01, 0.01), _edge)
			_box("Rim", Vector3(side, y, 0), Vector3(0.01, 0.01, 0.6), _edge)
	# A faint back pane locates the volume. Every face admits the hand.
	var glass := _material(Color(colour, 0.055))
	glass.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glass.cull_mode = BaseMaterial3D.CULL_DISABLED
	_box("BackPane", Vector3(0, 1.3, -0.299), Vector3(0.596, 1.39, 0.002), glass)
	_label("Title", NUMBERS[brush] + " / " + brush.to_upper(), Vector3(0, 0.49, 0.303), 35, ink)
	_status = _label("Status", "", Vector3(-0.065, 0.32, 0.303), 18, ink)
	_label("Dimensions", "60 x 60 x 140 cm", Vector3(0, 0.12, 0.303), 19, ink)
	var clear := CLEAR_BUTTON.instantiate()
	clear.name = "Clear"
	clear.label = "CLEAR"
	clear.cube_size = 0.045
	clear.scale = Vector3.ONE * 0.65
	clear.position = Vector3(0.195, 0.29, 0.31)
	clear.accent = colour
	add_child(clear)
	clear.pressed.connect(clear_paint)
	var paint := _material(colour)
	paint.roughness = 0.3
	paint.emission_enabled = true
	paint.emission = colour
	paint.emission_energy_multiplier = 0.3
	var segment: Mesh
	if brush == "ribbon":
		var ribbon := BoxMesh.new()
		ribbon.size = Vector3(0.045, 1, 0.004)
		segment = ribbon
	else:
		var tube := CylinderMesh.new()
		tube.top_radius = 0.006 if brush == "grid" else 0.009
		tube.bottom_radius = tube.top_radius
		tube.height = 1
		tube.radial_segments = 8
		tube.rings = 0
		segment = tube
	_segments = _multimesh("Strokes", segment, paint)
	var sphere := SphereMesh.new()
	sphere.radius = 0.018 if brush == "beads" else 0.009
	sphere.height = sphere.radius * 2
	sphere.radial_segments = 12
	sphere.rings = 6
	_dots = _multimesh("Points", sphere, paint)
	_refresh_status()


func _multimesh(title: String, mesh: Mesh, material: Material) -> MultiMesh:
	var batch := MultiMesh.new()
	batch.transform_format = MultiMesh.TRANSFORM_3D
	batch.mesh = mesh
	batch.instance_count = CAPACITY
	batch.visible_instance_count = 0
	var view := MultiMeshInstance3D.new()
	view.name = title
	view.multimesh = batch
	view.material_override = material
	add_child(view)
	return batch


func _box(title: String, at: Vector3, size: Vector3, material: Material) -> void:
	var view := MeshInstance3D.new()
	view.name = title
	var mesh := BoxMesh.new()
	mesh.size = size
	view.mesh = mesh
	view.material_override = material
	view.position = at
	add_child(view)


func _label(title: String, words: String, at: Vector3, size: int, colour: Color) -> Label3D:
	var label := Label3D.new()
	label.name = title
	label.text = words
	label.position = at
	label.font_size = size
	label.pixel_size = 0.0009
	label.outline_size = 0
	label.modulate = colour
	add_child(label)
	return label


func _material(colour: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = colour
	material.roughness = 0.65
	return material
