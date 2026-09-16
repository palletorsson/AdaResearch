extends Node3D
## Opt-in study for the existing strip. Angles are interpolated; vertices are
## recomputed by rigid hinge rotations, never blended between target meshes.
## A grab leaves the study in manual mode until the visitor presses REPLAY.

const PERIOD := 48.0
const FRAME_INTERVAL := 1.0 / 24.0
const BUTTON = preload("res://commons/interactables/push_button.tscn")

var strip
var rest: Array[Vector3] = []
var elapsed := 0.0
var playing := true
var held: Dictionary = {}
var phase := "FLAT"
var single_degrees := 0.0
var paired_degrees := 0.0
var readout: Label3D
var _frame_time := 0.0
var _handle_visuals: Array[Dictionary] = []


func setup(subject: Node3D) -> void:
	strip = subject
	rest = strip.vertex_positions.duplicate()
	strip.drag_points.point_picked_up.connect(_on_grab)
	strip.drag_points.point_dropped.connect(_on_release)
	for handle: Node3D in strip.drag_points.get_spheres():
		var visual: Node3D = handle.get_node_or_null("MeshInstance3D")
		if visual == null: continue
		var coordinates: Node3D = visual.get_node_or_null("Label3D")
		_handle_visuals.append({"node":visual,"scale":visual.scale,"label":coordinates,"label_visible":coordinates.visible if coordinates else false})
		# The default0.3 scale makes a2.7mm bead in this placement. Match the
		# existing16.5mm world-space grab radius so the visible point is graspable.
		visual.scale = Vector3.ONE * 1.8
		if coordinates: coordinates.hide()
	_build_panel()
	set_study_time(0.0)


func _exit_tree() -> void:
	for record: Dictionary in _handle_visuals:
		if is_instance_valid(record.node): record.node.scale = record.scale
		if is_instance_valid(record.label): record.label.visible = record.label_visible


func is_playing() -> bool:
	return playing


func _process(delta: float) -> void:
	if not playing or not is_instance_valid(strip):
		return
	# Only the current encounter needs continuously rebuilt geometry.
	var camera := get_viewport().get_camera_3d()
	if camera and camera.global_position.distance_squared_to(global_position) > 576.0:
		return
	elapsed = fposmod(elapsed + delta, PERIOD)
	_frame_time += delta
	if _frame_time < FRAME_INTERVAL:
		return
	_frame_time = fmod(_frame_time, FRAME_INTERVAL)
	set_study_time(elapsed)


func set_study_time(seconds: float) -> void:
	if not playing or not held.is_empty():
		return
	elapsed = fposmod(seconds, PERIOD)
	single_degrees = 0.0
	paired_degrees = 0.0
	phase = "FLAT"
	if elapsed >= 4.0 and elapsed < 11.0:
		single_degrees = 70.0 * _ease((elapsed - 4.0) / 7.0)
		phase = "ONE HINGE"
	elif elapsed >= 11.0 and elapsed < 15.0:
		single_degrees = 70.0
		phase = "ONE HINGE"
	elif elapsed >= 15.0 and elapsed < 22.0:
		single_degrees = 70.0 * (1.0 - _ease((elapsed - 15.0) / 7.0))
		phase = "UNFOLD"
	elif elapsed >= 26.0 and elapsed < 34.0:
		paired_degrees = 40.0 * _ease((elapsed - 26.0) / 8.0)
		phase = "PAIRED HINGES"
	elif elapsed >= 34.0 and elapsed < 40.0:
		paired_degrees = 40.0
		phase = "PAIRED HINGES"
	elif elapsed >= 40.0:
		paired_degrees = 40.0 * (1.0 - _ease((elapsed - 40.0) / 8.0))
		phase = "UNFOLD"
	var points := folded_points(single_degrees, paired_degrees)
	if points != strip.vertex_positions:
		strip.vertex_positions = points
		strip.drag_points.set_points_positions(points)
		strip.update_mesh()
	_update_readout()


func folded_points(single: float, paired: float) -> Array[Vector3]:
	var points: Array[Vector3] = rest.duplicate()
	var hinge_count := maxi(0, points.size() - 3)
	var middle := int(hinge_count / 2)
	for i in hinge_count:
		var angle: float = paired * (1.0 if int(i / 2) % 2 == 0 else -1.0)
		if i == middle:
			angle += single
		if is_zero_approx(angle):
			continue
		var pivot: Vector3 = points[i + 1]
		var axis: Vector3 = (points[i + 2] - pivot).normalized()
		if axis.length_squared() < 0.5:
			continue
		for j in range(i + 3, points.size()):
			points[j] = pivot + (points[j] - pivot).rotated(axis, deg_to_rad(angle))
	return points


func restart() -> void:
	# Never pull geometry away from a hand that still holds a handle.
	if not held.is_empty():
		_update_readout()
		return
	for handle: Node3D in strip.drag_points.get_spheres():
		if handle is RigidBody3D:
			handle.freeze = true
			handle.linear_velocity = Vector3.ZERO
			handle.angular_velocity = Vector3.ZERO
	playing = true
	_frame_time = 0.0
	set_study_time(0.0)


func _on_grab(index: int, _pickable: Object, _meta: Dictionary) -> void:
	held[index] = true
	playing = false
	_update_readout()


func _on_release(index: int, _pickable: Object, _meta: Dictionary) -> void:
	held.erase(index)
	# The edit belongs to the visitor; releasing does not resume the clock.
	_update_readout()


func _update_readout() -> void:
	if readout == null:
		return
	if not playing:
		readout.text = "YOUR FOLD\n" + ("Release the points to replay" if not held.is_empty() else "Your edit stays. REPLAY to begin again.")
	else:
		var angle: float = maxf(single_degrees, paired_degrees)
		readout.text = "%s  %.0f°\n%d triangles · grab a point to take over" % [phase, angle, strip.num_triangles]


func _build_panel() -> void:
	# The map stages the root at1m and scale0.75. This support reaches its floor
	# and keeps the one replay control at approximately1.05m above the floor.
	var plinth := StaticBody3D.new()
	plinth.name = "StudyPlinth"
	plinth.position = Vector3(0, -0.67, 0.80)
	add_child(plinth)
	var plinth_mesh := MeshInstance3D.new()
	var plinth_box := BoxMesh.new()
	plinth_box.size = Vector3(0.90, 1.30, 0.38)
	plinth_mesh.mesh = plinth_box
	var plinth_material := StandardMaterial3D.new()
	plinth_material.albedo_color = Color("4c5551")
	plinth_material.roughness = 0.8
	plinth_mesh.material_override = plinth_material
	plinth.add_child(plinth_mesh)
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = plinth_box.size
	collider.shape = shape
	plinth.add_child(collider)
	var panel := Node3D.new()
	panel.name = "StudyPanel"
	panel.position = Vector3(0.0, 0.15, 0.85)
	add_child(panel)
	var casing := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(1.18, 0.34, 0.065)
	casing.mesh = box
	var material := StandardMaterial3D.new()
	material.albedo_color = Color("242f2c")
	material.roughness = 0.85
	casing.material_override = material
	panel.add_child(casing)
	readout = Label3D.new()
	readout.name = "Phase"
	readout.font_size = 30
	readout.pixel_size = 0.00115
	readout.outline_size = 0
	readout.position = Vector3(0, 0.075, 0.037)
	panel.add_child(readout)
	var button: Node3D = BUTTON.instantiate()
	button.name = "Replay"
	button.position = Vector3(0.38, -0.08, 0.037)
	button.pressed.connect(restart)
	panel.add_child(button)
	var caption := Label3D.new()
	caption.text = "REPLAY"
	caption.font_size = 26
	caption.pixel_size = 0.00115
	caption.outline_size = 0
	caption.position = Vector3(0.19, -0.075, 0.038)
	panel.add_child(caption)


static func _ease(t: float) -> float:
	var u := clampf(t, 0.0, 1.0)
	return u * u * (3.0 - 2.0 * u)
