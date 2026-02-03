# vector_projection_demo.gd
# Interactive projection and reflection visualizer
# Shows: proj_B(A) = (A·B/|B|²)B and reflect = A - 2·proj_n(A)
#
# VR-enabled with grabbable vector endpoints
# QFEP: Projection as "shadow" - reducing dimensions while preserving alignment

extends Node3D

class_name VectorProjectionDemo

## Display settings
@export var max_vector_length: float = 1.0
@export var arrow_thickness: float = 0.02

## Vector A (incident/source)
@export var vector_a: Vector3 = Vector3(0.5, 0.6, 0.2):
	set(value):
		vector_a = value.limit_length(max_vector_length)
		_update_visualization()

## Normal vector (surface normal for reflection)
@export var normal: Vector3 = Vector3(0.0, 1.0, 0.0):
	set(value):
		normal = value.normalized() * 0.5 if value.length() > 0.01 else Vector3(0, 1, 0) * 0.5
		_update_visualization()

## Colors
@export var color_a: Color = Color(1.0, 0.3, 0.3)  # Red - incident
@export var color_normal: Color = Color(0.3, 0.8, 1.0)  # Cyan - normal
@export var color_projection: Color = Color(0.3, 1.0, 0.4)  # Green - projection onto plane
@export var color_reflection: Color = Color(1.0, 0.6, 0.8)  # Pink - reflection
@export var color_proj_normal: Color = Color(1.0, 0.8, 0.3, 0.6)  # Yellow - proj onto normal
@export var panel_color: Color = Color(0.06, 0.06, 0.08, 0.9)

var _arrow_a: Node3D
var _arrow_normal: Node3D
var _arrow_projection: Node3D  # Projection onto plane (perpendicular to normal)
var _arrow_reflection: Node3D
var _arrow_proj_normal: Node3D  # Component along normal
var _plane_mesh: MeshInstance3D
var _drop_line: MeshInstance3D
var _handle_a: Node3D
var _handle_n: Node3D
var _title_panel: Node3D
var _formula_panel: Node3D
var _control_panel: Node3D

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

## Creates a text label with a backing panel frame
func _create_text_panel(panel_name: String, text: String, pos: Vector3, 
		size: Vector2 = Vector2(0.3, 0.08), font_size: int = 16, 
		alignment: HorizontalAlignment = HORIZONTAL_ALIGNMENT_CENTER) -> Node3D:
	var panel = Node3D.new()
	panel.name = panel_name
	panel.position = pos
	
	# Backing panel
	var backing = MeshInstance3D.new()
	backing.name = "Backing"
	var box = BoxMesh.new()
	box.size = Vector3(size.x, size.y, 0.008)
	backing.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = panel_color
	mat.metallic = 0.2
	mat.roughness = 0.8
	backing.material_override = mat
	backing.position.z = -0.005
	panel.add_child(backing)
	
	# Frame edges
	_add_panel_frame(panel, size)
	
	# Label
	var label = Label3D.new()
	label.name = "Label"
	label.text = text
	label.pixel_size = 0.001
	label.font_size = font_size
	label.horizontal_alignment = alignment
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position.z = 0.002
	panel.add_child(label)
	
	return panel

func _add_panel_frame(panel: Node3D, size: Vector2):
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.3, 0.32, 0.35)
	frame_mat.metallic = 0.5
	frame_mat.roughness = 0.4
	
	var thickness = 0.004
	var depth = 0.01
	var half_w = size.x / 2.0
	var half_h = size.y / 2.0
	
	for y_mult in [-1.0, 1.0]:
		var edge = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(size.x + thickness * 2, thickness, depth)
		edge.mesh = box
		edge.material_override = frame_mat
		edge.position = Vector3(0, half_h * y_mult, -depth/2 + 0.002)
		panel.add_child(edge)
	
	for x_mult in [-1.0, 1.0]:
		var edge = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(thickness, size.y, depth)
		edge.mesh = box
		edge.material_override = frame_mat
		edge.position = Vector3(half_w * x_mult, 0, -depth/2 + 0.002)
		panel.add_child(edge)

func _get_panel_label(panel: Node3D) -> Label3D:
	return panel.get_node_or_null("Label") as Label3D

func _ready():
	_create_base()
	_create_plane()
	_create_arrows()
	_create_drop_line()
	_create_handles()
	_create_labels()
	_create_vr_controls()
	_update_visualization()

func _create_base():
	# Origin marker
	var origin = MeshInstance3D.new()
	origin.name = "Origin"
	var sphere = SphereMesh.new()
	sphere.radius = 0.03
	sphere.height = 0.06
	origin.mesh = sphere
	var origin_mat = StandardMaterial3D.new()
	origin_mat.albedo_color = Color(1, 1, 1)
	origin_mat.emission_enabled = true
	origin_mat.emission = Color(1, 1, 1)
	origin_mat.emission_energy_multiplier = 0.3
	origin.material_override = origin_mat
	add_child(origin)

func _create_plane():
	_plane_mesh = MeshInstance3D.new()
	_plane_mesh.name = "ReflectionPlane"
	var plane = PlaneMesh.new()
	plane.size = Vector2(1.2, 1.2)
	_plane_mesh.mesh = plane
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.4, 0.6, 0.25)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.roughness = 0.3
	_plane_mesh.material_override = mat
	add_child(_plane_mesh)

func _create_arrows():
	_arrow_a = _create_arrow("ArrowA", color_a)
	_arrow_normal = _create_arrow("ArrowNormal", color_normal)
	_arrow_projection = _create_arrow("ArrowProjection", color_projection)
	_arrow_reflection = _create_arrow("ArrowReflection", color_reflection)
	_arrow_proj_normal = _create_arrow("ArrowProjNormal", color_proj_normal, true)
	
	add_child(_arrow_a)
	add_child(_arrow_normal)
	add_child(_arrow_projection)
	add_child(_arrow_reflection)
	add_child(_arrow_proj_normal)

func _create_arrow(arrow_name: String, color: Color, ghost: bool = false) -> Node3D:
	var arrow = Node3D.new()
	arrow.name = arrow_name
	
	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = arrow_thickness * (0.5 if ghost else 1.0)
	cylinder.bottom_radius = arrow_thickness * (0.5 if ghost else 1.0)
	cylinder.height = 1.0
	shaft.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	if ghost:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	else:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.2
	shaft.material_override = mat
	arrow.add_child(shaft)
	
	var head = MeshInstance3D.new()
	head.name = "Head"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = arrow_thickness * 2.5 * (0.5 if ghost else 1.0)
	cone.height = arrow_thickness * 5
	head.mesh = cone
	head.material_override = mat
	arrow.add_child(head)
	
	return arrow

func _create_drop_line():
	_drop_line = MeshInstance3D.new()
	_drop_line.name = "DropLine"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.004
	cylinder.bottom_radius = 0.004
	cylinder.height = 1.0
	_drop_line.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_drop_line.material_override = mat
	add_child(_drop_line)

func _create_handles():
	_handle_a = _create_handle("HandleA", color_a)
	_handle_a.position = vector_a
	add_child(_handle_a)
	
	_handle_n = _create_handle("HandleN", color_normal)
	_handle_n.position = normal
	add_child(_handle_n)

func _create_handle(handle_name: String, color: Color) -> Node3D:
	var handle = Node3D.new()
	handle.name = handle_name
	
	var sphere = MeshInstance3D.new()
	var mesh = SphereMesh.new()
	mesh.radius = 0.04
	mesh.height = 0.08
	sphere.mesh = mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.4
	sphere.material_override = mat
	handle.add_child(sphere)
	
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.06
	collision.shape = shape
	area.add_child(collision)
	handle.add_child(area)
	
	return handle

func _create_labels():
	_title_panel = _create_text_panel(
		"TitlePanel",
		"PROJECTION & REFLECTION",
		Vector3(0, max_vector_length + 0.2, 0),
		Vector2(0.42, 0.06),
		18
	)
	add_child(_title_panel)
	
	_formula_panel = _create_text_panel(
		"FormulaPanel",
		"",
		Vector3(0, 0.02, max_vector_length + 0.2),
		Vector2(0.5, 0.16),
		11
	)
	_formula_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_formula_panel)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, max_vector_length + 0.38)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.4, 0.1, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	var presets = [
		["FLOOR", Vector3(0.5, 0.5, 0.2), Vector3(0, 1, 0)],
		["WALL", Vector3(0.5, 0.3, 0.4), Vector3(1, 0, 0)],
		["45°", Vector3(0.6, 0.4, 0), Vector3(0.707, 0.707, 0)],
		["GLANCE", Vector3(0.7, 0.1, 0), Vector3(0, 1, 0)],
		["RESET", Vector3(0.5, 0.6, 0.2), Vector3(0, 1, 0)]
	]
	
	for i in range(presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % i
		btn.position = Vector3(-0.15 + i * 0.075, 0, 0)
		btn.scale = Vector3(0.7, 0.7, 0.7)
		_control_panel.add_child(btn)
		_add_button_label(btn, presets[i][0])
		
		var va = presets[i][1]
		var vn = presets[i][2]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _apply_preset(va, vn))

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 8
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)

func _apply_preset(va: Vector3, vn: Vector3):
	vector_a = va
	normal = vn.normalized() * 0.5
	_handle_a.position = vector_a
	_handle_n.position = normal

func _update_visualization():
	var n_unit = normal.normalized()
	
	# Projection of A onto normal (component along normal)
	var proj_onto_normal = n_unit * vector_a.dot(n_unit)
	
	# Projection onto plane (perpendicular to normal) = A - proj_onto_normal
	var proj_onto_plane = vector_a - proj_onto_normal
	
	# Reflection: A - 2 * proj_onto_normal
	var reflection = vector_a - 2.0 * proj_onto_normal
	
	# Update arrows
	_position_arrow(_arrow_a, Vector3.ZERO, vector_a)
	_position_arrow(_arrow_normal, Vector3.ZERO, normal)
	_position_arrow(_arrow_projection, Vector3.ZERO, proj_onto_plane)
	_position_arrow(_arrow_reflection, Vector3.ZERO, reflection)
	_position_arrow(_arrow_proj_normal, proj_onto_plane, vector_a)
	
	# Update plane orientation
	_update_plane_orientation(n_unit)
	
	# Update drop line
	_update_drop_line(vector_a, proj_onto_plane)
	
	# Update labels
	_update_labels(n_unit, proj_onto_plane, reflection, proj_onto_normal)

func _position_arrow(arrow: Node3D, start: Vector3, end: Vector3):
	var direction = end - start
	var length = direction.length()
	
	if length < 0.01:
		arrow.visible = false
		return
	arrow.visible = true
	
	var shaft = arrow.get_node("Shaft")
	var head = arrow.get_node("Head")
	
	var mid = (start + end) / 2.0
	shaft.position = mid
	shaft.scale = Vector3(1, length - arrow_thickness * 5, 1)
	head.position = end - direction.normalized() * arrow_thickness * 2.5
	
	if direction.length() > 0.001:
		var up = Vector3.UP
		if abs(direction.normalized().dot(up)) > 0.99:
			up = Vector3.FORWARD
		arrow.look_at(arrow.global_position + direction, up)
		arrow.rotate_object_local(Vector3.RIGHT, PI/2)

func _update_plane_orientation(n: Vector3):
	var tangent = n.cross(Vector3.RIGHT)
	if tangent.length() < 0.001:
		tangent = n.cross(Vector3.FORWARD)
	tangent = tangent.normalized()
	var bitangent = n.cross(tangent).normalized()
	_plane_mesh.transform.basis = Basis(tangent, bitangent, n)

func _update_drop_line(a_tip: Vector3, proj: Vector3):
	var perp = a_tip - proj
	if perp.length() < 0.01:
		_drop_line.visible = false
		return
	_drop_line.visible = true
	
	var mid = (a_tip + proj) / 2.0
	_drop_line.position = mid
	_drop_line.scale = Vector3(1, perp.length(), 1)
	
	var up = Vector3.UP
	if abs(perp.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	_drop_line.look_at(_drop_line.global_position + perp, up)
	_drop_line.rotate_object_local(Vector3.RIGHT, PI/2)

func _update_labels(n_unit: Vector3, proj_plane: Vector3, reflection: Vector3, proj_n: Vector3):
	var angle = 0.0
	if vector_a.length() > 0.001:
		angle = acos(clampf(vector_a.normalized().dot(n_unit), -1.0, 1.0))
	
	var label = _get_panel_label(_formula_panel)
	if label:
		label.text = "A = (%.2f, %.2f, %.2f)\n" % [vector_a.x, vector_a.y, vector_a.z]
		label.text += "n = (%.2f, %.2f, %.2f)\n" % [n_unit.x, n_unit.y, n_unit.z]
		label.text += "proj_plane = (%.2f, %.2f, %.2f)\n" % [proj_plane.x, proj_plane.y, proj_plane.z]
		label.text += "reflection = (%.2f, %.2f, %.2f)\n" % [reflection.x, reflection.y, reflection.z]
		label.text += "angle to normal = %.1f°" % rad_to_deg(angle)

func _process(_delta):
	if _handle_a and _handle_a.position != vector_a:
		vector_a = _handle_a.position
	if _handle_n:
		var new_n = _handle_n.position
		if new_n.length() > 0.01 and new_n != normal:
			normal = new_n.normalized() * 0.5
			_handle_n.position = normal

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _apply_preset(Vector3(0.5, 0.5, 0.2), Vector3(0, 1, 0))
			KEY_2: _apply_preset(Vector3(0.5, 0.3, 0.4), Vector3(1, 0, 0))
			KEY_3: _apply_preset(Vector3(0.6, 0.4, 0), Vector3(0.707, 0.707, 0))
			KEY_4: _apply_preset(Vector3(0.7, 0.1, 0), Vector3(0, 1, 0))
			KEY_R: _apply_preset(Vector3(0.5, 0.6, 0.2), Vector3(0, 1, 0))

func set_vectors(a: Vector3, n: Vector3):
	vector_a = a
	normal = n.normalized() * 0.5
	_handle_a.position = vector_a
	_handle_n.position = normal

func get_projection() -> Vector3:
	var n_unit = normal.normalized()
	return vector_a - n_unit * vector_a.dot(n_unit)

func get_reflection() -> Vector3:
	var n_unit = normal.normalized()
	return vector_a - 2.0 * n_unit * vector_a.dot(n_unit)
