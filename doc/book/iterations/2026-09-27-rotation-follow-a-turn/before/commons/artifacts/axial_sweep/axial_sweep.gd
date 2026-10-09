extends Node3D
## @identity: A body's geometry and the space occupied over a turn are different.
## A cube sweeps a cylinder; a triangular XY profile sweeps a cone around Y.
## Cyan contours describe the analytical outer boundary, drawn at finite resolution.
## They are not collision, motion blur, or a new solid replacing the turning body.

const Parts = preload("res://commons/artifacts/rotation_studies/parts.gd")
const Witness = preload("res://commons/artifacts/rotation_studies/cube_witness.gd")
const BUTTON_SCENE := "res://commons/interactables/push_button.tscn"
const HALF_CUBE := 0.30
const PROFILE_RADIUS := 0.45
const PROFILE_HALF_HEIGHT := 0.35
const HISTORY_LIMIT := 24
const RING_SEGMENTS := 128
const CYAN := Color(0.12, 0.90, 0.98)
const AMBER := Color(0.98, 0.54, 0.22)

@export_enum("cube", "triangle") var shape_id := "cube"
@export var plane_height := 1.7
@export_range(1.0, 90.0, 1.0) var degrees_per_second := 18.0
@export var playing := true
@export var show_envelope := false
@export var show_history := false

var elapsed := 0.0
var meshspin: Node3D
var envelope: Node3D
var body_mesh: MeshInstance3D
var contour_mesh: MeshInstance3D
var history: MeshInstance3D
var history_angles: Array[float] = []
var buttons: Array[Node3D] = []
var _readout: Label3D
var _button_labels: Array[Label3D] = []
var _history_phase := 0.0
var _last_playing := true
var _shape_material: StandardMaterial3D
var _edge_material: StandardMaterial3D


func _ready() -> void:
	_build_pedestal()
	meshspin = Node3D.new()
	meshspin.name = "RotatingBody"
	meshspin.position.y = plane_height + PROFILE_HALF_HEIGHT
	add_child(meshspin)
	envelope = Node3D.new()
	envelope.name = "AnalyticalOuterBoundary"
	envelope.position = meshspin.position
	add_child(envelope)
	history = MeshInstance3D.new()
	history.name = "SampledHistoryEdges"
	history.position = meshspin.position
	add_child(history)
	_shape_material = _material(AMBER, false)
	_shape_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_shape_material.emission_enabled = true
	_shape_material.emission = AMBER
	_shape_material.emission_energy_multiplier = 0.12
	_edge_material = _material(Color(1.0, 0.91, 0.75), true)
	var spindle_at := Vector3(0, plane_height + 0.42, 0)
	Parts.axis(self, spindle_at, Vector3.UP, Color(0.7, 0.73, 0.78), 0.94)
	_rebuild_shape()
	set_envelope(show_envelope)
	set_history(show_history)
	seek(elapsed)
	_build_controls()
	_update_labels()


func _build_pedestal() -> void:
	# Compact base and stem; the larger viewing plate sits above the walking floor.
	Parts.box(self, "Foot", Vector3(0.66, 0.08, 0.66), Vector3(0, 0.04, 0), Color(0.10, 0.12, 0.17))
	Parts.box(self, "Stem", Vector3(0.28, plane_height - 0.14, 0.28), Vector3(0, (plane_height - 0.14) / 2.0 + 0.08, 0), Color(0.16, 0.18, 0.23))
	Parts.box(self, "ViewingPlate", Vector3(1.14, 0.06, 1.14), Vector3(0, plane_height - 0.03, 0), Color(0.14, 0.17, 0.22))
	Parts.box(self, "PlateRim", Vector3(1.16, 0.012, 1.16), Vector3(0, plane_height - 0.052, 0), Color(0.35, 0.52, 0.58), false)
	Parts.box(self, "ReadoutCase", Vector3(0.96, 0.30, 0.06), Vector3(0, 1.43, -0.17), Color(0.07, 0.09, 0.13))
	_readout = Parts.label(self, "", Vector3(0, 1.44, -0.206), 26)
	_readout.name = "StudyCaption"
	_readout.pixel_size = 0.0018
	_readout.outline_size = 2


func _build_controls() -> void:
	Parts.box(self, "ControlCase", Vector3(0.96, 0.21, 0.16), Vector3(0, 1.075, -0.57), Color(0.10, 0.13, 0.18))
	# Load after project autoloads; the hand button depends on XR settings.
	var button_scene: PackedScene = load(BUTTON_SCENE)
	var actions: Array[Callable] = [_cycle_shape, _toggle_play, _toggle_envelope]
	for i in 3:
		var button: Node3D = button_scene.instantiate()
		button.name = ["ShapeButton", "PlayButton", "BoundaryButton"][i]
		button.position = Vector3((i - 1) * 0.31, 1.12, -0.67)
		button.rotation_degrees = Vector3(-65, 0, 0)
		button.scale = Vector3.ONE * 1.28
		button.released_color = CYAN if i == 2 else Color(0.87, 0.75, 0.55)
		# Hand/pointer detection remains active; the button adds no solid obstacle.
		for solid in button.find_children("*", "StaticBody3D", true, false):
			solid.collision_layer = 0
			solid.collision_mask = 0
		add_child(button)
		button.pressed.connect(actions[i])
		buttons.append(button)
		var text := Parts.label(self, "", Vector3((i - 1) * 0.31, 1.012, -0.655), 24)
		text.pixel_size = 0.0016
		text.outline_size = 2
		_button_labels.append(text)


func _process(delta: float) -> void:
	if playing != _last_playing:
		_update_labels()
	if not playing or not is_instance_valid(meshspin):
		return
	elapsed += delta
	var step := deg_to_rad(degrees_per_second) * delta
	meshspin.rotation.y = fposmod(meshspin.rotation.y + step, TAU)
	if show_history:
		_history_phase += absf(step)
		if _history_phase >= TAU / float(HISTORY_LIMIT):
			_history_phase = fposmod(_history_phase, TAU / float(HISTORY_LIMIT))
			_record_history()


func set_shape(value: Variant) -> void:
	var next := str(value).to_lower()
	if value is int:
		next = "cube" if int(value) == 0 else "triangle"
	if next == "triangle_profile" or next == "profile":
		next = "triangle"
	if next != "cube" and next != "triangle":
		return
	if next == shape_id and is_instance_valid(meshspin) and meshspin.get_child_count() > 0:
		return
	shape_id = next
	if is_instance_valid(meshspin):
		_rebuild_shape()
		_clear_history()
		if show_history: _record_history()
	_update_labels()


func set_envelope(value: bool) -> void:
	show_envelope = value
	if is_instance_valid(envelope): envelope.visible = value
	_update_labels()


func set_history(value: bool) -> void:
	show_history = value
	_clear_history()
	if is_instance_valid(history):
		history.visible = value
		if value: _record_history()
	_update_labels()


func seek(seconds: float) -> void:
	if not is_finite(seconds): return
	elapsed = maxf(0.0, seconds)
	if is_instance_valid(meshspin):
		meshspin.rotation.y = fposmod(elapsed * deg_to_rad(degrees_per_second), TAU)
	_clear_history()
	if show_history and is_instance_valid(history): _record_history()


func envelope_radius_at(local_y: float) -> float:
	# Coordinates are relative to meshspin, not to the floor or museum origin.
	if shape_id == "cube":
		return sqrt(2.0) * HALF_CUBE if absf(local_y) <= HALF_CUBE + 0.000001 else 0.0
	if local_y < -PROFILE_HALF_HEIGHT or local_y > PROFILE_HALF_HEIGHT:
		return 0.0
	return PROFILE_RADIUS * (PROFILE_HALF_HEIGHT - local_y) / (2.0 * PROFILE_HALF_HEIGHT)


func get_shape_vertices() -> PackedVector3Array:
	if shape_id == "triangle":
		return PackedVector3Array([Vector3(0, -0.35, 0), Vector3(0.45, -0.35, 0), Vector3(0, 0.35, 0)])
	var points := PackedVector3Array()
	for i in 8:
		points.append(Vector3(1 if i & 1 else -1, 1 if i & 2 else -1, 1 if i & 4 else -1) * HALF_CUBE)
	return points


func _rebuild_shape() -> void:
	for child in meshspin.get_children():
		meshspin.remove_child(child)
		child.queue_free()
	var visible_body := MeshInstance3D.new()
	visible_body.name = "Cube" if shape_id == "cube" else "TriangularProfile"
	if shape_id == "cube":
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE * HALF_CUBE * 2.0
		visible_body.mesh = cube
	else:
		var triangle := ImmediateMesh.new()
		triangle.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		for point in get_shape_vertices():
			triangle.surface_set_normal(Vector3.FORWARD)
			triangle.surface_add_vertex(point)
		triangle.surface_end()
		visible_body.mesh = triangle
	body_mesh = visible_body
	visible_body.material_override = _shape_material
	meshspin.add_child(visible_body)
	if shape_id == "cube":
		var mark := MeshInstance3D.new()
		mark.name = "FaceWitness"
		var poses: Array[Transform3D] = [Transform3D.IDENTITY]
		mark.mesh = Witness.build(HALF_CUBE, poses)
		meshspin.add_child(mark)
	var edges := MeshInstance3D.new()
	edges.name = "BodyEdges"
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES, _edge_material)
	_emit_edges(lines, Basis.IDENTITY)
	lines.surface_end()
	edges.mesh = lines
	meshspin.add_child(edges)
	_rebuild_envelope()


func _rebuild_envelope() -> void:
	for child in envelope.get_children():
		envelope.remove_child(child)
		child.queue_free()
	var contour := MeshInstance3D.new()
	contour.name = "OuterContourRings"
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES, _material(CYAN, true))
	var half_height := HALF_CUBE if shape_id == "cube" else PROFILE_HALF_HEIGHT
	for row in 9:
		var y := lerpf(-half_height, half_height, float(row) / 8.0)
		var radius := envelope_radius_at(y)
		if radius <= 0.000001: continue
		for segment in RING_SEGMENTS:
			var a := TAU * float(segment) / float(RING_SEGMENTS)
			var b := TAU * float(segment + 1) / float(RING_SEGMENTS)
			lines.surface_add_vertex(Vector3(cos(a) * radius, y, sin(a) * radius))
			lines.surface_add_vertex(Vector3(cos(b) * radius, y, sin(b) * radius))
	# Meridians join the rings; spokes mark the cap disks of the swept solid.
	for segment in 8:
		var a := TAU * float(segment) / 8.0
		var radial := Vector3(cos(a), 0, sin(a))
		var lower := radial * envelope_radius_at(-half_height) + Vector3.DOWN * half_height
		var upper := radial * envelope_radius_at(half_height) + Vector3.UP * half_height
		lines.surface_add_vertex(lower)
		lines.surface_add_vertex(upper)
		lines.surface_add_vertex(Vector3.DOWN * half_height)
		lines.surface_add_vertex(lower)
		if shape_id == "cube":
			lines.surface_add_vertex(Vector3.UP * half_height)
			lines.surface_add_vertex(upper)
	lines.surface_end()
	contour_mesh = contour
	contour.mesh = lines
	envelope.add_child(contour)
	envelope.visible = show_envelope


func _emit_edges(lines: ImmediateMesh, pose: Basis) -> void:
	var points := get_shape_vertices()
	if shape_id == "triangle":
		for i in 3:
			lines.surface_add_vertex(pose * points[i])
			lines.surface_add_vertex(pose * points[(i + 1) % 3])
	else:
		for corner in 8:
			for bit in [1, 2, 4]:
				if corner & bit: continue
				lines.surface_add_vertex(pose * points[corner])
				lines.surface_add_vertex(pose * points[corner | bit])


func _clear_history() -> void:
	history_angles.clear()
	_history_phase = 0.0
	if is_instance_valid(history): history.mesh = null


func _record_history() -> void:
	history_angles.append(meshspin.rotation.y)
	if history_angles.size() > HISTORY_LIMIT: history_angles.pop_front()
	var lines := ImmediateMesh.new()
	lines.surface_begin(Mesh.PRIMITIVE_LINES, _material(Color(0.38, 0.56, 0.65), true))
	for angle in history_angles:
		_emit_edges(lines, Basis(Vector3.UP, angle))
	lines.surface_end()
	history.mesh = lines


func _material(color: Color, unshaded: bool) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.6
	if unshaded: material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material


func _update_labels() -> void:
	_last_playing = playing
	if is_instance_valid(_readout):
		var name_text := "CUBE" if shape_id == "cube" else "TRIANGLE"
		var result := "CYLINDER" if shape_id == "cube" else "CONE"
		_readout.text = name_text + " / A TURN AROUND Y\n" + ("SWEPT BOUNDARY: " + result if show_envelope else "FOLLOW AN EDGE")
		if show_history: _readout.text += "\nRECENT POSES"
	if _button_labels.size() == 3:
		_button_labels[0].text = "SHAPE"
		_button_labels[1].text = "PAUSE" if playing else "PLAY"
		_button_labels[2].text = "HIDE" if show_envelope else "BOUNDARY"


func _cycle_shape() -> void:
	set_shape("triangle" if shape_id == "cube" else "cube")


func _toggle_play() -> void:
	playing = not playing
	_update_labels()


func _toggle_envelope() -> void:
	set_envelope(not show_envelope)


func cycle_shape() -> void:
	_cycle_shape()


func toggle_envelope() -> void:
	_toggle_envelope()


func toggle_playing() -> void:
	_toggle_play()
