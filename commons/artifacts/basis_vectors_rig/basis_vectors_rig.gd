# basis_vectors_rig.gd
# Interactive basis vectors (i, j, k)
# Shows how any 3D point is a linear combination: P = xi + yj + zk
#
# VR-enabled: grab and rotate the entire basis, or grab individual axes
# QFEP: Basis as "frame of reference" - the order from which we measure

extends Node3D

class_name BasisVectorsRig

## Display settings
@export var axis_length: float = 0.5
@export var arrow_thickness: float = 0.015

## Target point to decompose
@export var target_point: Vector3 = Vector3(0.3, 0.4, 0.2):
	set(value):
		target_point = value
		_update_visualization()

## Colors (standard RGB for XYZ)
@export var color_i: Color = Color(1.0, 0.2, 0.2)  # Red = X
@export var color_j: Color = Color(0.2, 1.0, 0.2)  # Green = Y
@export var color_k: Color = Color(0.2, 0.4, 1.0)  # Blue = Z
@export var color_point: Color = Color(1.0, 0.8, 0.3)  # Yellow = target
@export var color_component: Color = Color(0.5, 0.5, 0.5, 0.5)  # Gray = decomposition

var _arrow_i: Node3D
var _arrow_j: Node3D
var _arrow_k: Node3D
var _component_lines: Array[MeshInstance3D] = []
var _point_marker: MeshInstance3D
var _handle_point: Node3D
var _info_label: Label3D
var _coords_label: Label3D
var _control_panel: Node3D

# Standard basis (can be transformed)
var _basis: Basis = Basis.IDENTITY

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_create_base()
	_create_basis_arrows()
	_create_component_lines()
	_create_point_marker()
	_create_labels()
	_create_vr_controls()
	_update_visualization()

func _create_base():
	# Ground grid
	var base = MeshInstance3D.new()
	base.name = "Base"
	
	var plane = PlaneMesh.new()
	plane.size = Vector2(axis_length * 3, axis_length * 3)
	base.mesh = plane
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.12, 0.6)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	base.material_override = mat
	base.position = Vector3(0, -0.01, 0)
	add_child(base)
	
	# Origin sphere
	var origin = MeshInstance3D.new()
	origin.name = "Origin"
	var sphere = SphereMesh.new()
	sphere.radius = 0.025
	sphere.height = 0.05
	origin.mesh = sphere
	var origin_mat = StandardMaterial3D.new()
	origin_mat.albedo_color = Color(1, 1, 1)
	origin_mat.emission_enabled = true
	origin_mat.emission = Color(1, 1, 1)
	origin_mat.emission_energy_multiplier = 0.5
	origin.material_override = origin_mat
	add_child(origin)

func _create_basis_arrows():
	_arrow_i = _create_axis_arrow("ArrowI", color_i, "î")
	_arrow_j = _create_axis_arrow("ArrowJ", color_j, "ĵ")
	_arrow_k = _create_axis_arrow("ArrowK", color_k, "k̂")
	
	add_child(_arrow_i)
	add_child(_arrow_j)
	add_child(_arrow_k)

func _create_axis_arrow(arrow_name: String, color: Color, label_text: String) -> Node3D:
	var arrow = Node3D.new()
	arrow.name = arrow_name
	
	# Shaft
	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = arrow_thickness
	cylinder.bottom_radius = arrow_thickness
	cylinder.height = axis_length
	shaft.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.3
	shaft.material_override = mat
	shaft.position = Vector3(0, axis_length / 2, 0)
	arrow.add_child(shaft)
	
	# Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = arrow_thickness * 2.5
	cone.height = arrow_thickness * 6
	head.mesh = cone
	head.material_override = mat
	head.position = Vector3(0, axis_length, 0)
	arrow.add_child(head)
	
	# Label at tip
	var lbl = Label3D.new()
	lbl.name = "Label"
	lbl.text = label_text
	lbl.pixel_size = 0.002
	lbl.font_size = 20
	lbl.modulate = color
	lbl.position = Vector3(0.04, axis_length + 0.03, 0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow.add_child(lbl)
	
	return arrow

func _create_component_lines():
	# Create 3 component lines (decomposition of point)
	for i in range(3):
		var line = MeshInstance3D.new()
		line.name = "ComponentLine%d" % i
		_component_lines.append(line)
		add_child(line)

func _create_point_marker():
	_point_marker = MeshInstance3D.new()
	_point_marker.name = "PointMarker"
	var sphere = SphereMesh.new()
	sphere.radius = 0.035
	sphere.height = 0.07
	_point_marker.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_point
	mat.emission_enabled = true
	mat.emission = color_point
	mat.emission_energy_multiplier = 0.5
	_point_marker.material_override = mat
	add_child(_point_marker)
	
	# Grabbable handle
	_handle_point = Node3D.new()
	_handle_point.name = "HandlePoint"
	
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.06
	collision.shape = shape
	area.add_child(collision)
	_handle_point.add_child(area)
	add_child(_handle_point)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 18
	_info_label.position = Vector3(0, axis_length + 0.25, 0)
	_info_label.text = "BASIS VECTORS"
	add_child(_info_label)
	
	_coords_label = Label3D.new()
	_coords_label.name = "CoordsLabel"
	_coords_label.pixel_size = 0.0015
	_coords_label.font_size = 16
	_coords_label.position = Vector3(0, -0.1, axis_length + 0.15)
	_coords_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_coords_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, axis_length + 0.25)
	_control_panel.rotation_degrees = Vector3(30, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.4, 0.12, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	_control_panel.add_child(panel_back)
	
	# Point presets
	var presets = [
		["PURE X", Vector3(0.4, 0, 0)],
		["PURE Y", Vector3(0, 0.4, 0)],
		["PURE Z", Vector3(0, 0, 0.4)],
		["XY", Vector3(0.3, 0.3, 0)],
		["XYZ", Vector3(0.25, 0.3, 0.2)]
	]
	
	for i in range(presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % i
		btn.position = Vector3(-0.14 + i * 0.07, 0.02, 0.015)
		btn.scale = Vector3(0.65, 0.65, 0.65)
		_control_panel.add_child(btn)
		_add_button_label(btn, presets[i][0])
		
		var pt = presets[i][1]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(): _set_target_point(pt))
	
	# Basis rotation presets
	var rotations = [
		["RESET", Basis.IDENTITY],
		["TILT", Basis(Vector3.RIGHT, deg_to_rad(30))],
		["SPIN", Basis(Vector3.UP, deg_to_rad(45))]
	]
	
	for i in range(rotations.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Rotation%d" % i
		btn.position = Vector3(-0.1 + i * 0.1, -0.025, 0.015)
		btn.scale = Vector3(0.65, 0.65, 0.65)
		_control_panel.add_child(btn)
		_add_button_label(btn, rotations[i][0])
		
		var b = rotations[i][1]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(): _set_basis(b))

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 7
	lbl.position = Vector3(0, -0.022, 0.01)
	btn.add_child(lbl)

func _set_target_point(p: Vector3):
	target_point = p
	_handle_point.position = target_point

func _set_basis(b: Basis):
	_basis = b
	_update_visualization()

func _update_visualization():
	# Update basis arrow orientations
	_orient_arrow(_arrow_i, _basis.x * axis_length)
	_orient_arrow(_arrow_j, _basis.y * axis_length)
	_orient_arrow(_arrow_k, _basis.z * axis_length)
	
	# Update point marker
	_point_marker.position = target_point
	_handle_point.position = target_point
	
	# Get components in current basis
	var coords = _basis.inverse() * target_point
	
	# Update component lines (decomposition path)
	_update_component_lines(coords)
	
	# Update labels
	_update_labels(coords)

func _orient_arrow(arrow: Node3D, direction: Vector3):
	if direction.length() < 0.001:
		return
	
	# Reset transform
	arrow.transform = Transform3D.IDENTITY
	
	# Look along direction (default arrow points up/+Y)
	var up = Vector3.UP
	if abs(direction.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	
	arrow.look_at(arrow.global_position + direction, up)
	arrow.rotate_object_local(Vector3.RIGHT, -PI/2)

func _update_component_lines(coords: Vector3):
	# Show decomposition: origin → x*i → +y*j → +z*k → point
	var p0 = Vector3.ZERO
	var p1 = _basis.x * coords.x
	var p2 = p1 + _basis.y * coords.y
	var p3 = p2 + _basis.z * coords.z  # Should equal target_point
	
	_draw_dashed_line(_component_lines[0], p0, p1, color_i * 0.7)
	_draw_dashed_line(_component_lines[1], p1, p2, color_j * 0.7)
	_draw_dashed_line(_component_lines[2], p2, p3, color_k * 0.7)

func _draw_dashed_line(line: MeshInstance3D, start: Vector3, end: Vector3, color: Color):
	var direction = end - start
	var length = direction.length()
	
	if length < 0.01:
		line.visible = false
		return
	line.visible = true
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.006
	cylinder.bottom_radius = 0.006
	cylinder.height = length
	line.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.material_override = mat
	
	var mid = (start + end) / 2.0
	line.position = mid
	
	var up = Vector3.UP
	if abs(direction.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	line.look_at(line.global_position + direction, up)
	line.rotate_object_local(Vector3.RIGHT, PI/2)

func _update_labels(coords: Vector3):
	_coords_label.text = "P = %.2f·î + %.2f·ĵ + %.2f·k̂\n" % [coords.x, coords.y, coords.z]
	_coords_label.text += "P = (%.2f, %.2f, %.2f)\n" % [target_point.x, target_point.y, target_point.z]
	_coords_label.text += "|P| = %.3f" % target_point.length()

func _process(_delta):
	if _handle_point and _handle_point.position != target_point:
		target_point = _handle_point.position

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _set_target_point(Vector3(0.4, 0, 0))
			KEY_2: _set_target_point(Vector3(0, 0.4, 0))
			KEY_3: _set_target_point(Vector3(0, 0, 0.4))
			KEY_4: _set_target_point(Vector3(0.3, 0.3, 0))
			KEY_5: _set_target_point(Vector3(0.25, 0.3, 0.2))
			KEY_R: _set_basis(Basis.IDENTITY)
			KEY_T: _set_basis(Basis(Vector3.RIGHT, deg_to_rad(30)))
			KEY_Y: _set_basis(Basis(Vector3.UP, deg_to_rad(45)))

func set_point(p: Vector3):
	target_point = p
	_handle_point.position = target_point

func get_coordinates() -> Vector3:
	return _basis.inverse() * target_point

func rotate_basis(axis: Vector3, angle: float):
	_basis = _basis.rotated(axis.normalized(), angle)
	_update_visualization()
