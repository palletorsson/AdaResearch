# cross_product_demo.gd
# Interactive cross product visualizer
# Shows: A × B = normal vector perpendicular to both A and B
# |A × B| = |A||B|sin(θ) = area of parallelogram
#
# VR-enabled with grabbable vector endpoints
# QFEP: Cross product as "emergence" - a third direction from two

extends Node3D

class_name CrossProductDemo

## Display settings
@export var max_vector_length: float = 1.2
@export var arrow_thickness: float = 0.025

## Vector A
@export var vector_a: Vector3 = Vector3(0.8, 0.0, 0.0):
	set(value):
		vector_a = value.limit_length(max_vector_length)
		if is_inside_tree():
			_update_visualization()

## Vector B
@export var vector_b: Vector3 = Vector3(0.0, 0.0, 0.8):
	set(value):
		vector_b = value.limit_length(max_vector_length)
		if is_inside_tree():
			_update_visualization()

## Colors
@export var color_a: Color = Color(1.0, 0.3, 0.3)  # Red
@export var color_b: Color = Color(0.3, 0.5, 1.0)  # Blue  
@export var color_result: Color = Color(0.3, 1.0, 0.4)  # Green - cross product
@export var color_parallelogram: Color = Color(0.8, 0.6, 1.0, 0.3)  # Purple - area
@export var panel_color: Color = Color(0.06, 0.06, 0.08, 0.9)

var _arrow_a: Node3D
var _arrow_b: Node3D
var _arrow_result: Node3D
var _parallelogram: MeshInstance3D
var _handle_a: Node3D
var _handle_b: Node3D
var _title_panel: Node3D
var _result_panel: Node3D
var _formula_panel: Node3D
var _right_hand_indicator: Node3D
var _control_panel: Node3D

# Vector labels
var _label_a: Label3D
var _label_b: Label3D
var _label_result: Label3D

# Coordinate axes
var _axes_container: Node3D

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
	
	# Top and bottom edges
	for y_mult in [-1.0, 1.0]:
		var edge = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(size.x + thickness * 2, thickness, depth)
		edge.mesh = box
		edge.material_override = frame_mat
		edge.position = Vector3(0, half_h * y_mult, -depth/2 + 0.002)
		panel.add_child(edge)
	
	# Left and right edges
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
	_create_coordinate_axes()
	_create_arrows()
	_create_vector_labels()
	_create_parallelogram()
	_create_handles()
	_create_right_hand_indicator()
	_create_labels()
	_create_vr_controls()
	_update_visualization()

func _create_base():
	# Ground plane with grid
	var base = MeshInstance3D.new()
	base.name = "Base"
	
	var plane = PlaneMesh.new()
	plane.size = Vector2(max_vector_length * 3, max_vector_length * 3)
	base.mesh = plane
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.12, 0.8)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	base.material_override = mat
	base.position = Vector3(0, -0.01, 0)
	add_child(base)
	
	# Origin marker
	var origin = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.035
	sphere.height = 0.07
	origin.mesh = sphere
	var origin_mat = StandardMaterial3D.new()
	origin_mat.albedo_color = Color(1, 1, 1)
	origin_mat.emission_enabled = true
	origin_mat.emission = Color(1, 1, 1)
	origin_mat.emission_energy_multiplier = 0.3
	origin.material_override = origin_mat
	add_child(origin)

func _create_coordinate_axes():
	_axes_container = Node3D.new()
	_axes_container.name = "Axes"
	add_child(_axes_container)
	
	var axis_length = max_vector_length * 1.4
	_create_axis_line(Vector3(axis_length, 0, 0), Color(1.0, 0.3, 0.3, 0.5), "X")
	_create_axis_line(Vector3(0, axis_length, 0), Color(0.3, 1.0, 0.3, 0.5), "Y")
	_create_axis_line(Vector3(0, 0, axis_length), Color(0.3, 0.5, 1.0, 0.5), "Z")

func _create_axis_line(direction: Vector3, color: Color, label_text: String):
	var length = direction.length()
	var norm = direction.normalized()
	
	var shaft = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.005
	cylinder.bottom_radius = 0.005
	cylinder.height = length
	shaft.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	shaft.material_override = mat
	shaft.position = direction / 2.0
	
	if abs(norm.dot(Vector3.UP)) < 0.99:
		shaft.look_at(shaft.position + direction, Vector3.UP)
		shaft.rotate_object_local(Vector3.RIGHT, PI/2)
	
	_axes_container.add_child(shaft)
	
	var lbl = Label3D.new()
	lbl.text = label_text
	lbl.pixel_size = 0.002
	lbl.font_size = 16
	lbl.modulate = color
	lbl.position = direction + norm * 0.05
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_axes_container.add_child(lbl)

func _create_vector_labels():
	_label_a = _create_vector_label("A", color_a)
	_label_b = _create_vector_label("B", color_b)
	_label_result = _create_vector_label("A×B", color_result)
	add_child(_label_a)
	add_child(_label_b)
	add_child(_label_result)

func _create_vector_label(text: String, color: Color) -> Label3D:
	var label = Label3D.new()
	label.text = text
	label.pixel_size = 0.0018
	label.font_size = 16
	label.modulate = color
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.outline_size = 6
	label.outline_modulate = Color(0, 0, 0, 0.7)
	return label

func _create_arrows():
	_arrow_a = _create_arrow("ArrowA", color_a)
	_arrow_b = _create_arrow("ArrowB", color_b)
	_arrow_result = _create_arrow("ArrowResult", color_result)
	
	add_child(_arrow_a)
	add_child(_arrow_b)
	add_child(_arrow_result)

func _create_arrow(arrow_name: String, color: Color) -> Node3D:
	var arrow = Node3D.new()
	arrow.name = arrow_name
	
	# Shaft
	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = arrow_thickness
	cylinder.bottom_radius = arrow_thickness
	cylinder.height = 1.0
	shaft.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.2
	shaft.material_override = mat
	arrow.add_child(shaft)
	
	# Head
	var head = MeshInstance3D.new()
	head.name = "Head"
	var cone = CylinderMesh.new()
	cone.top_radius = 0.0
	cone.bottom_radius = arrow_thickness * 2.5
	cone.height = arrow_thickness * 5
	head.mesh = cone
	head.material_override = mat
	arrow.add_child(head)
	
	return arrow

func _create_parallelogram():
	_parallelogram = MeshInstance3D.new()
	_parallelogram.name = "Parallelogram"
	add_child(_parallelogram)

func _create_handles():
	_handle_a = _create_handle("HandleA", color_a)
	_handle_a.position = vector_a
	add_child(_handle_a)
	
	_handle_b = _create_handle("HandleB", color_b)
	_handle_b.position = vector_b
	add_child(_handle_b)

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
	
	# Collision
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.06
	collision.shape = shape
	area.add_child(collision)
	handle.add_child(area)
	
	return handle

func _create_right_hand_indicator():
	# Visual hint for right-hand rule
	_right_hand_indicator = Node3D.new()
	_right_hand_indicator.name = "RightHandIndicator"
	add_child(_right_hand_indicator)
	
	# Curving arrow to show rotation direction
	var arc = MeshInstance3D.new()
	arc.name = "RotationArc"
	_right_hand_indicator.add_child(arc)

func _create_labels():
	# Title panel - facing player
	_title_panel = _create_text_panel(
		"TitlePanel",
		"CROSS PRODUCT",
		Vector3(0, max_vector_length * 1.6 + 0.15, -0.3),
		Vector2(0.30, 0.07),
		22
	)
	_title_panel.rotation_degrees = Vector3(0, 180, 0)
	add_child(_title_panel)
	
	# Result panel - below title, facing player
	_result_panel = _create_text_panel(
		"ResultPanel",
		"",
		Vector3(0, max_vector_length * 1.6, -0.3),
		Vector2(0.52, 0.08),
		14
	)
	_result_panel.rotation_degrees = Vector3(0, 180, 0)
	add_child(_result_panel)
	
	# Formula panel - to the side
	_formula_panel = _create_text_panel(
		"FormulaPanel",
		"",
		Vector3(-max_vector_length - 0.2, max_vector_length * 0.6, 0),
		Vector2(0.48, 0.14),
		12
	)
	_formula_panel.rotation_degrees = Vector3(0, 90, 0)
	add_child(_formula_panel)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, max_vector_length + 0.3)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.45, 0.1, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Preset buttons for different configurations
	var presets = [
		["X×Z", Vector3(0.8, 0, 0), Vector3(0, 0, 0.8)],    # Standard XZ → Y
		["Z×X", Vector3(0, 0, 0.8), Vector3(0.8, 0, 0)],    # Reversed → -Y
		["X×Y", Vector3(0.8, 0, 0), Vector3(0, 0.8, 0)],    # XY → Z
		["3D", Vector3(0.6, 0.4, 0.3), Vector3(0.3, 0.5, 0.7)],  # General 3D
		["RESET", Vector3(0.8, 0, 0), Vector3(0, 0, 0.8)]
	]
	
	for i in range(presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % i
		btn.position = Vector3(-0.16 + i * 0.08, 0, 0)
		btn.scale = Vector3(0.7, 0.7, 0.7)
		_control_panel.add_child(btn)
		_add_button_label(btn, presets[i][0])
		
		var va = presets[i][1]
		var vb = presets[i][2]
		var area = btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _apply_preset(va, vb))

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 8
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)

func _apply_preset(va: Vector3, vb: Vector3):
	vector_a = va
	vector_b = vb
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func _update_visualization():
	# Calculate cross product
	var cross = vector_a.cross(vector_b)
	var magnitude = cross.length()
	
	# Update arrows
	_position_arrow(_arrow_a, Vector3.ZERO, vector_a)
	_position_arrow(_arrow_b, Vector3.ZERO, vector_b)
	_position_arrow(_arrow_result, Vector3.ZERO, cross)
	
	# Update vector labels
	_label_a.position = vector_a * 0.5 + Vector3(0.04, 0.04, 0)
	_label_b.position = vector_b * 0.5 + Vector3(0.04, 0, 0.04)
	_label_result.position = cross * 0.5 + Vector3(0.05, 0, 0)
	
	# Update parallelogram (shows area)
	_update_parallelogram()
	
	# Update right-hand rule indicator
	_update_right_hand_indicator(cross)
	
	# Update labels
	_update_labels(cross, magnitude)

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

func _update_parallelogram():
	# Create parallelogram mesh showing the area
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	# Four corners: origin, A, A+B, B
	var p0 = Vector3.ZERO
	var p1 = vector_a
	var p2 = vector_a + vector_b
	var p3 = vector_b
	
	# Small Y offset to avoid z-fighting
	var offset = Vector3(0, 0.005, 0)
	p0 += offset
	p1 += offset
	p2 += offset
	p3 += offset
	
	# Two triangles
	immediate_mesh.surface_add_vertex(p0)
	immediate_mesh.surface_add_vertex(p1)
	immediate_mesh.surface_add_vertex(p2)
	
	immediate_mesh.surface_add_vertex(p0)
	immediate_mesh.surface_add_vertex(p2)
	immediate_mesh.surface_add_vertex(p3)
	
	immediate_mesh.surface_end()
	_parallelogram.mesh = immediate_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_parallelogram
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_parallelogram.material_override = mat

func _update_right_hand_indicator(cross: Vector3):
	# Update rotation arc showing right-hand rule
	var arc = _right_hand_indicator.get_node("RotationArc")
	
	if cross.length() < 0.01:
		arc.visible = false
		return
	arc.visible = true
	
	# Create arc around the cross product direction
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	var segments = 16
	var radius = 0.08
	var arc_angle = PI * 1.2  # Partial arc to indicate direction
	
	# Get perpendicular basis
	var up = cross.normalized()
	var right = vector_a.normalized() if vector_a.length() > 0.01 else Vector3.RIGHT
	var forward = up.cross(right).normalized()
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var angle = t * arc_angle
		var point = right * cos(angle) + forward * sin(angle)
		point = point * radius + cross * 0.5
		immediate_mesh.surface_add_vertex(point)
	
	immediate_mesh.surface_end()
	arc.mesh = immediate_mesh
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.6)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc.material_override = mat

func _update_labels(cross: Vector3, magnitude: float):
	# Direction indicator
	var direction_word = ""
	if magnitude > 0.01:
		if abs(cross.y) > abs(cross.x) and abs(cross.y) > abs(cross.z):
			direction_word = "(+Y up)" if cross.y > 0 else "(-Y down)"
		elif abs(cross.x) > abs(cross.z):
			direction_word = "(+X right)" if cross.x > 0 else "(-X left)"
		else:
			direction_word = "(+Z forward)" if cross.z > 0 else "(-Z back)"
	
	var result_label = _get_panel_label(_result_panel)
	if result_label:
		result_label.text = "A × B = (%.2f, %.2f, %.2f) %s\n|A × B| = %.3f (area)" % [
			cross.x, cross.y, cross.z, direction_word, magnitude
		]
	
	var formula_label = _get_panel_label(_formula_panel)
	if formula_label:
		formula_label.text = "A = (%.2f, %.2f, %.2f)\n" % [vector_a.x, vector_a.y, vector_a.z]
		formula_label.text += "B = (%.2f, %.2f, %.2f)\n" % [vector_b.x, vector_b.y, vector_b.z]
		formula_label.text += "Right-hand rule: curl A→B, thumb = result"

func _process(_delta):
	if _handle_a and _handle_a.position != vector_a:
		vector_a = _handle_a.position
	if _handle_b and _handle_b.position != vector_b:
		vector_b = _handle_b.position

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _apply_preset(Vector3(0.8, 0, 0), Vector3(0, 0, 0.8))
			KEY_2: _apply_preset(Vector3(0, 0, 0.8), Vector3(0.8, 0, 0))
			KEY_3: _apply_preset(Vector3(0.8, 0, 0), Vector3(0, 0.8, 0))
			KEY_4: _apply_preset(Vector3(0.6, 0.4, 0.3), Vector3(0.3, 0.5, 0.7))
			KEY_R: _apply_preset(Vector3(0.8, 0, 0), Vector3(0, 0, 0.8))

func set_vectors(a: Vector3, b: Vector3):
	vector_a = a
	vector_b = b
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func get_cross_product() -> Vector3:
	return vector_a.cross(vector_b)

func get_area() -> float:
	return vector_a.cross(vector_b).length()
