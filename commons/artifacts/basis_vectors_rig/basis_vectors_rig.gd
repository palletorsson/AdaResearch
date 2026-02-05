# basis_vectors_rig.gd
# Interactive basis vectors (i, j, k)
# Shows how any 3D point is a linear combination: P = xi + yj + zk
#
# VR-enabled: grab and rotate the entire basis, or grab individual axes
# QFEP: Basis as "frame of reference" - the order from which we measure
#
# UPGRADED VISUALS - Sleek modern look with glow effects

extends Node3D

class_name BasisVectorsRig

## Display settings
@export var axis_length: float = 0.6
@export var arrow_thickness: float = 0.01  # Thin like y_oscillation_cube

## Target point to decompose
@export var target_point: Vector3 = Vector3(0.35, 0.45, 0.25):
	set(value):
		target_point = value
		if is_inside_tree():
			_update_visualization()

# Sleek color palette (RGB aligned with XYZ)
var color_i: Color = Color(1.0, 0.3, 0.35)   # Red = X
var color_j: Color = Color(0.35, 1.0, 0.4)   # Green = Y  
var color_k: Color = Color(0.35, 0.5, 1.0)   # Blue = Z
var color_point: Color = Color(1.0, 0.85, 0.3)  # Golden yellow = target
var color_component: Color = Color(0.6, 0.6, 0.7, 0.5)  # Gray = decomposition

var _arrow_i: Node3D
var _arrow_j: Node3D
var _arrow_k: Node3D
var _component_lines: Array[MeshInstance3D] = []
var _point_marker: MeshInstance3D
var _point_glow: MeshInstance3D
var _handle_point: Node3D
var _title_panel: Node3D
var _coords_panel: Node3D
var _control_panel: Node3D
var _ground: Node3D

# Standard basis (can be transformed)
var _basis: Basis = Basis.IDENTITY

# Animation
var _time: float = 0.0

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_create_ground()
	_create_basis_arrows()
	_create_component_lines()
	_create_point_marker()
	_create_labels()
	_create_vr_controls()
	_update_visualization()

func _create_ground():
	_ground = VectorVisuals.create_ground(self, axis_length * 3)

func _create_basis_arrows():
	_arrow_i = _create_basis_arrow("ArrowI", color_i, "î", "X")
	_arrow_j = _create_basis_arrow("ArrowJ", color_j, "ĵ", "Y")
	_arrow_k = _create_basis_arrow("ArrowK", color_k, "k̂", "Z")
	
	add_child(_arrow_i)
	add_child(_arrow_j)
	add_child(_arrow_k)

func _create_basis_arrow(arrow_name: String, color: Color, unit_label: String, axis_label: String) -> Node3D:
	var arrow = Node3D.new()
	arrow.name = arrow_name
	
	# Shaft with glow
	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = arrow_thickness
	cylinder.bottom_radius = arrow_thickness
	cylinder.height = axis_length
	cylinder.radial_segments = 12
	shaft.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.5
	mat.metallic = 0.3
	mat.roughness = 0.4
	shaft.material_override = mat
	shaft.position = Vector3(0, axis_length / 2, 0)
	arrow.add_child(shaft)
	
	# Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = arrow_thickness * 2.8
	cone.height = arrow_thickness * 6
	cone.radial_segments = 12
	head.mesh = cone
	head.material_override = mat
	head.position = Vector3(0, axis_length, 0)
	arrow.add_child(head)
	
	# Glow shell
	var glow = MeshInstance3D.new()
	glow.name = "Glow"
	var glow_cyl = CylinderMesh.new()
	glow_cyl.top_radius = arrow_thickness * 2.0
	glow_cyl.bottom_radius = arrow_thickness * 2.0
	glow_cyl.height = axis_length
	glow.mesh = glow_cyl
	
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(color.r, color.g, color.b, 0.12)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.material_override = glow_mat
	glow.position = Vector3(0, axis_length / 2, 0)
	arrow.add_child(glow)
	
	# Axis label (X, Y, Z) - at arrow tip, offset toward +Z for visibility
	var axis_lbl = Label3D.new()
	axis_lbl.name = "AxisLabel"
	axis_lbl.text = axis_label
	axis_lbl.pixel_size = 0.003
	axis_lbl.font_size = 24
	axis_lbl.modulate = color
	axis_lbl.outline_size = 10
	axis_lbl.outline_modulate = Color(0, 0, 0, 0.8)
	axis_lbl.position = Vector3(0, axis_length + 0.04, 0.06)  # Offset toward +Z
	axis_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow.add_child(axis_lbl)
	
	# Unit vector label (î, ĵ, k̂) - smaller
	var unit_lbl = Label3D.new()
	unit_lbl.name = "UnitLabel"
	unit_lbl.text = unit_label
	unit_lbl.pixel_size = 0.002
	unit_lbl.font_size = 16
	unit_lbl.modulate = color * 0.85
	unit_lbl.outline_size = 5
	unit_lbl.outline_modulate = Color(0, 0, 0, 0.6)
	unit_lbl.position = Vector3(0, axis_length - 0.04, 0.05)  # Offset toward +Z
	unit_lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	arrow.add_child(unit_lbl)
	
	return arrow

func _create_component_lines():
	for i in range(3):
		var line = MeshInstance3D.new()
		line.name = "ComponentLine%d" % i
		_component_lines.append(line)
		add_child(line)

func _create_point_marker():
	# Main point sphere
	_point_marker = MeshInstance3D.new()
	_point_marker.name = "PointMarker"
	var sphere = SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	sphere.radial_segments = 24
	sphere.rings = 12
	_point_marker.mesh = sphere
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_point
	mat.emission_enabled = true
	mat.emission = color_point
	mat.emission_energy_multiplier = 0.8
	mat.metallic = 0.5
	mat.roughness = 0.3
	_point_marker.material_override = mat
	add_child(_point_marker)
	
	# Glow sphere
	_point_glow = MeshInstance3D.new()
	_point_glow.name = "PointGlow"
	var glow_sphere = SphereMesh.new()
	glow_sphere.radius = 0.065
	glow_sphere.height = 0.13
	_point_glow.mesh = glow_sphere
	
	var glow_mat = StandardMaterial3D.new()
	glow_mat.albedo_color = Color(color_point.r, color_point.g, color_point.b, 0.15)
	glow_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	glow_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_point_glow.material_override = glow_mat
	add_child(_point_glow)
	
	# Handle with orbit rings
	_handle_point = VectorVisuals.create_handle(self, "HandlePoint", color_point, 0.05)
	
	# Remove duplicate sphere (handle already has one)
	_handle_point.position = target_point

func _create_labels():
	# Title panel - behind artifact, facing player at +Z
	_title_panel = VectorVisuals.create_panel(self, "TitlePanel",
		"BASIS VECTORS",
		Vector3(0, axis_length + 0.35, -axis_length - 0.15),
		Vector2(0.38, 0.08), 22)
	# No rotation - faces +Z by default toward player
	
	# Coordinates panel - to the right, facing player
	_coords_panel = VectorVisuals.create_panel(self, "CoordsPanel", "",
		Vector3(axis_length + 0.2, axis_length * 0.5, 0),
		Vector2(0.48, 0.18), 13, HORIZONTAL_ALIGNMENT_LEFT)
	_coords_panel.rotation_degrees = Vector3(0, -90, 0)  # Face toward +Z

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.06, axis_length + 0.35)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)  # Tilted up, facing +Z toward player
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.5, 0.14, 0.012)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.04, 0.04, 0.06, 0.95)
	panel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.008
	_control_panel.add_child(panel_back)
	
	# Point presets (top row)
	var point_presets = [
		["PURE X", Vector3(0.4, 0, 0)],
		["PURE Y", Vector3(0, 0.4, 0)],
		["PURE Z", Vector3(0, 0, 0.4)],
		["XY", Vector3(0.3, 0.3, 0)],
		["XYZ", Vector3(0.25, 0.3, 0.2)]
	]
	
	for i in range(point_presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "PointPreset%d" % i
		btn.position = Vector3(-0.17 + i * 0.085, 0.03, 0.01)
		btn.scale = Vector3(0.7, 0.7, 0.7)
		_control_panel.add_child(btn)
		_add_button_label(btn, point_presets[i][0])
		
		var pt = point_presets[i][1]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _set_target_point(pt))
	
	# Basis rotation presets (bottom row)
	var rotation_presets = [
		["RESET", Basis.IDENTITY],
		["TILT", Basis(Vector3.RIGHT, deg_to_rad(30))],
		["SPIN", Basis(Vector3.UP, deg_to_rad(45))],
	]
	
	for i in range(rotation_presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "RotationPreset%d" % i
		btn.position = Vector3(-0.12 + i * 0.12, -0.03, 0.01)
		btn.scale = Vector3(0.7, 0.7, 0.7)
		_control_panel.add_child(btn)
		_add_button_label(btn, rotation_presets[i][0])
		
		var b = rotation_presets[i][1]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _set_basis(b))

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 8
	lbl.outline_size = 3
	lbl.outline_modulate = Color(0, 0, 0, 0.5)
	lbl.position = Vector3(0, -0.025, 0.01)
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
	_point_glow.position = target_point
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
	
	arrow.transform = Transform3D.IDENTITY
	
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
	var p3 = p2 + _basis.z * coords.z
	
	_draw_dashed_line(_component_lines[0], p0, p1, color_i * 0.6)
	_draw_dashed_line(_component_lines[1], p1, p2, color_j * 0.6)
	_draw_dashed_line(_component_lines[2], p2, p3, color_k * 0.6)

func _draw_dashed_line(line: MeshInstance3D, start: Vector3, end: Vector3, color: Color):
	var direction = end - start
	var length = direction.length()
	
	if length < 0.01:
		line.visible = false
		return
	line.visible = true
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.008
	cylinder.bottom_radius = 0.008
	cylinder.height = length
	line.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = 0.3
	line.material_override = mat
	
	var mid = (start + end) / 2.0
	line.position = mid
	
	var up = Vector3.UP
	if abs(direction.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	line.look_at(line.global_position + direction, up)
	line.rotate_object_local(Vector3.RIGHT, PI/2)

func _update_labels(coords: Vector3):
	var label = VectorVisuals.get_panel_label(_coords_panel)
	if label:
		label.text = "P = %.2f·î + %.2f·ĵ + %.2f·k̂\n\n" % [coords.x, coords.y, coords.z]
		label.text += "P = (%.2f, %.2f, %.2f)\n" % [target_point.x, target_point.y, target_point.z]
		label.text += "|P| = %.3f" % target_point.length()

func _process(delta):
	_time += delta
	
	# Pulse the glow
	var pulse = 0.12 + sin(_time * 3.0) * 0.03
	var glow_mat = _point_glow.material_override as StandardMaterial3D
	if glow_mat:
		glow_mat.albedo_color.a = pulse
	
	VectorVisuals.pulse_handle(_handle_point, delta, _time)
	
	if _handle_point.position != target_point:
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
