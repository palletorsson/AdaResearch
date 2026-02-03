# vector_subtraction_demo.gd
# Interactive vector subtraction: A - B = A + (-B)
# VR-enabled with grabbable arrow endpoints
#
# Visualizes subtraction as adding the opposite:
# A - B = A + (-B), shown with tip-to-tail method

extends Node3D

class_name VectorSubtractionDemo

## Display settings
@export var max_vector_length: float = 1.2
@export var arrow_thickness: float = 0.025

## Vector A
@export var vector_a: Vector3 = Vector3(0.8, 0.4, -0.1):
	set(value):
		vector_a = value.limit_length(max_vector_length)
		if is_inside_tree():
			_update_vectors()

## Vector B  
@export var vector_b: Vector3 = Vector3(0.2, 0.7, 0.3):
	set(value):
		vector_b = value.limit_length(max_vector_length)
		if is_inside_tree():
			_update_vectors()

## Colors
@export var color_a: Color = Color(1.0, 0.3, 0.3)  # Red
@export var color_b: Color = Color(0.3, 0.5, 1.0)  # Blue
@export var color_neg_b: Color = Color(0.5, 0.7, 1.0, 0.6)  # Light blue - negative B
@export var color_result: Color = Color(0.3, 1.0, 0.4)  # Green
@export var panel_color: Color = Color(0.06, 0.06, 0.08, 0.9)

var _arrow_a: Node3D
var _arrow_b: Node3D
var _arrow_neg_b: Node3D  # -B from origin
var _arrow_neg_b_tip: Node3D  # -B from tip of A (tip-to-tail)
var _arrow_result: Node3D
var _handle_a: Node3D
var _handle_b: Node3D
var _title_panel: Node3D
var _formula_panel: Node3D

# Vector labels
var _label_a: Label3D
var _label_b: Label3D
var _label_neg_b: Label3D
var _label_result: Label3D

# Coordinate axes
var _axes_container: Node3D

# VR Controls
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
	_create_handles()
	_create_labels()
	_create_vr_controls()
	_update_vectors()

func _create_base():
	# Ground plane
	var base = MeshInstance3D.new()
	base.name = "Base"
	
	var plane = PlaneMesh.new()
	plane.size = Vector2(max_vector_length * 2.5, max_vector_length * 2.5)
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

func _create_coordinate_axes():
	_axes_container = Node3D.new()
	_axes_container.name = "Axes"
	add_child(_axes_container)
	
	var axis_length = max_vector_length * 1.3
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
	_label_neg_b = _create_vector_label("-B", color_neg_b)
	_label_result = _create_vector_label("A-B", color_result)
	add_child(_label_a)
	add_child(_label_b)
	add_child(_label_neg_b)
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
	_arrow_neg_b = _create_arrow("ArrowNegB", color_neg_b, true)
	_arrow_neg_b_tip = _create_arrow("ArrowNegBTip", color_neg_b, true)
	_arrow_result = _create_arrow("ArrowResult", color_result)
	
	add_child(_arrow_a)
	add_child(_arrow_b)
	add_child(_arrow_neg_b)
	add_child(_arrow_neg_b_tip)
	add_child(_arrow_result)

func _create_arrow(arrow_name: String, color: Color, ghost: bool = false) -> Node3D:
	var arrow = Node3D.new()
	arrow.name = arrow_name
	
	# Shaft
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
	
	# Head (cone)
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

func _create_handles():
	# Grabbable handle for vector A tip
	_handle_a = _create_handle("HandleA", color_a)
	_handle_a.position = vector_a
	add_child(_handle_a)
	
	# Grabbable handle for vector B tip
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
	
	# Collision for grabbing
	var area = Area3D.new()
	var collision = CollisionShape3D.new()
	var shape = SphereShape3D.new()
	shape.radius = 0.06
	collision.shape = shape
	area.add_child(collision)
	handle.add_child(area)
	
	return handle

func _create_labels():
	# Title panel - facing player
	_title_panel = _create_text_panel(
		"TitlePanel",
		"VECTOR SUBTRACTION",
		Vector3(0, max_vector_length + 0.25, -0.3),
		Vector2(0.40, 0.07),
		22
	)
	_title_panel.rotation_degrees = Vector3(0, 180, 0)
	add_child(_title_panel)
	
	# Formula panel - to the side
	_formula_panel = _create_text_panel(
		"FormulaPanel",
		"",
		Vector3(-max_vector_length - 0.15, max_vector_length * 0.5, 0),
		Vector2(0.46, 0.18),
		13
	)
	_formula_panel.rotation_degrees = Vector3(0, 90, 0)
	add_child(_formula_panel)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, max_vector_length + 0.32)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.35, 0.1, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.01
	_control_panel.add_child(panel_back)
	
	# Preset buttons
	var presets = [
		["ORTHO", Vector3(0.5, 0, 0), Vector3(0, 0.5, 0)],
		["SAME", Vector3(0.5, 0.3, 0), Vector3(0.5, 0.3, 0)],
		["OPPOSE", Vector3(0.5, 0.3, 0), Vector3(-0.3, -0.2, 0)],
		["RESET", Vector3(0.6, 0.4, 0), Vector3(0.2, 0.6, 0.2)]
	]
	
	for i in range(presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % i
		btn.position = Vector3(-0.12 + i * 0.08, 0, 0)
		btn.scale = Vector3(0.8, 0.8, 0.8)
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
	lbl.font_size = 9
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)

func _apply_preset(va: Vector3, vb: Vector3):
	vector_a = va
	vector_b = vb
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func _update_vectors():
	var neg_b = -vector_b
	var result = vector_a - vector_b  # = vector_a + neg_b
	
	# Arrow A (from origin)
	_position_arrow(_arrow_a, Vector3.ZERO, vector_a)
	
	# Arrow B (from origin)
	_position_arrow(_arrow_b, Vector3.ZERO, vector_b)
	
	# Negative B from origin (shows the opposite)
	_position_arrow(_arrow_neg_b, Vector3.ZERO, neg_b)
	
	# Negative B from tip of A (tip-to-tail for A + (-B))
	_position_arrow(_arrow_neg_b_tip, vector_a, vector_a + neg_b)
	
	# Update vector labels
	_label_a.position = vector_a * 0.5 + Vector3(0.04, 0.04, 0)
	_label_b.position = vector_b * 0.5 + Vector3(0.04, 0.04, 0)
	_label_neg_b.position = neg_b * 0.5 + Vector3(0.04, 0.04, 0)
	_label_result.position = result * 0.5 + Vector3(0.04, 0.04, 0)
	
	# Result arrow (from origin to A - B)
	_position_arrow(_arrow_result, Vector3.ZERO, result)
	
	# Update formula
	_update_formula(neg_b, result)

func _position_arrow(arrow: Node3D, start: Vector3, end: Vector3):
	var direction = end - start
	var length = direction.length()
	
	if length < 0.001:
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

func _update_formula(neg_b: Vector3, result: Vector3):
	var label = _get_panel_label(_formula_panel)
	if label:
		label.text = "A = (%.2f, %.2f, %.2f)\n" % [vector_a.x, vector_a.y, vector_a.z]
		label.text += "B = (%.2f, %.2f, %.2f)\n" % [vector_b.x, vector_b.y, vector_b.z]
		label.text += "-B = (%.2f, %.2f, %.2f)\n" % [neg_b.x, neg_b.y, neg_b.z]
		label.text += "A - B = A + (-B) = (%.2f, %.2f, %.2f)" % [result.x, result.y, result.z]

func _process(_delta):
	if _handle_a and _handle_a.position != vector_a:
		vector_a = _handle_a.position
	if _handle_b and _handle_b.position != vector_b:
		vector_b = _handle_b.position

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				_apply_preset(Vector3(0.5, 0, 0), Vector3(0, 0.5, 0))
			KEY_2:
				_apply_preset(Vector3(0.5, 0.3, 0), Vector3(0.5, 0.3, 0))
			KEY_3:
				_apply_preset(Vector3(0.5, 0.3, 0), Vector3(-0.3, -0.2, 0))
			KEY_R:
				_apply_preset(Vector3(0.6, 0.4, 0), Vector3(0.2, 0.6, 0.2))

func set_vectors(a: Vector3, b: Vector3):
	vector_a = a
	vector_b = b
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func get_result() -> Vector3:
	return vector_a - vector_b
