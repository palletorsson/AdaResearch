# vector_addition_demo.gd
# Interactive vector addition: A + B = C
# VR-enabled with grabbable arrow endpoints
#
# Visualizes the parallelogram law: 
# Place vectors head-to-tail, resultant is the diagonal

extends Node3D

class_name VectorAdditionDemo

## Display settings
@export var max_vector_length: float = 1.0
@export var arrow_thickness: float = 0.02

## Vector A
@export var vector_a: Vector3 = Vector3(0.5, 0.3, 0.0):
	set(value):
		vector_a = value.limit_length(max_vector_length)
		_update_vectors()

## Vector B  
@export var vector_b: Vector3 = Vector3(0.2, 0.5, 0.3):
	set(value):
		vector_b = value.limit_length(max_vector_length)
		_update_vectors()

## Colors
@export var color_a: Color = Color(1.0, 0.3, 0.3)  # Red
@export var color_b: Color = Color(0.3, 0.5, 1.0)  # Blue
@export var color_result: Color = Color(0.3, 1.0, 0.4)  # Green
@export var color_ghost: Color = Color(0.5, 0.5, 0.5, 0.4)

var _arrow_a: Node3D
var _arrow_b: Node3D
var _arrow_result: Node3D
var _arrow_a_ghost: Node3D
var _arrow_b_ghost: Node3D
var _handle_a: Node3D
var _handle_b: Node3D
var _info_label: Label3D
var _formula_label: Label3D

# VR Controls
var _control_panel: Node3D

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_create_base()
	_create_arrows()
	_create_handles()
	_create_labels()
	_create_vr_controls()
	_update_vectors()

func _create_base():
	# Ground plane with grid
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

func _create_arrows():
	_arrow_a = _create_arrow("ArrowA", color_a)
	_arrow_b = _create_arrow("ArrowB", color_b)
	_arrow_result = _create_arrow("ArrowResult", color_result)
	
	# Ghost arrows for parallelogram
	_arrow_a_ghost = _create_arrow("ArrowAGhost", color_ghost, true)
	_arrow_b_ghost = _create_arrow("ArrowBGhost", color_ghost, true)
	
	add_child(_arrow_a)
	add_child(_arrow_b)
	add_child(_arrow_result)
	add_child(_arrow_a_ghost)
	add_child(_arrow_b_ghost)

func _create_arrow(arrow_name: String, color: Color, ghost: bool = false) -> Node3D:
	var arrow = Node3D.new()
	arrow.name = arrow_name
	
	# Shaft
	var shaft = MeshInstance3D.new()
	shaft.name = "Shaft"
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = arrow_thickness * (0.5 if ghost else 1.0)
	cylinder.bottom_radius = arrow_thickness * (0.5 if ghost else 1.0)
	cylinder.height = 1.0  # Will be scaled
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
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 20
	_info_label.position = Vector3(0, max_vector_length + 0.2, 0)
	_info_label.text = "VECTOR ADDITION"
	add_child(_info_label)
	
	_formula_label = Label3D.new()
	_formula_label.name = "FormulaLabel"
	_formula_label.pixel_size = 0.0015
	_formula_label.font_size = 16
	_formula_label.position = Vector3(0, -0.1, max_vector_length + 0.15)
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_formula_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, max_vector_length + 0.25)
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
		["ACUTE", Vector3(0.6, 0.2, 0), Vector3(0.2, 0.6, 0)],
		["3D", Vector3(0.4, 0.3, 0.2), Vector3(0.2, 0.4, 0.5)],
		["RESET", Vector3(0.5, 0.3, 0), Vector3(0.2, 0.5, 0.3)]
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
			area.button_pressed.connect(func(): _apply_preset(va, vb))

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
	var result = vector_a + vector_b
	
	# Update arrow A (from origin)
	_position_arrow(_arrow_a, Vector3.ZERO, vector_a)
	
	# Update arrow B (from origin)  
	_position_arrow(_arrow_b, Vector3.ZERO, vector_b)
	
	# Update result arrow (from origin to A+B)
	_position_arrow(_arrow_result, Vector3.ZERO, result)
	
	# Ghost A (from tip of B)
	_position_arrow(_arrow_a_ghost, vector_b, vector_b + vector_a)
	
	# Ghost B (from tip of A)
	_position_arrow(_arrow_b_ghost, vector_a, vector_a + vector_b)
	
	# Update formula
	_update_formula(result)

func _position_arrow(arrow: Node3D, start: Vector3, end: Vector3):
	var direction = end - start
	var length = direction.length()
	
	if length < 0.001:
		arrow.visible = false
		return
	arrow.visible = true
	
	var shaft = arrow.get_node("Shaft")
	var head = arrow.get_node("Head")
	
	# Position and orient
	var mid = (start + end) / 2.0
	var head_offset = direction.normalized() * (length / 2.0 - arrow_thickness * 2.5)
	
	shaft.position = mid
	shaft.scale = Vector3(1, length - arrow_thickness * 5, 1)
	
	head.position = end - direction.normalized() * arrow_thickness * 2.5
	
	# Orient to direction
	if direction.length() > 0.001:
		var up = Vector3.UP
		if abs(direction.normalized().dot(up)) > 0.99:
			up = Vector3.FORWARD
		arrow.look_at(arrow.global_position + direction, up)
		arrow.rotate_object_local(Vector3.RIGHT, PI/2)

func _update_formula(result: Vector3):
	_formula_label.text = "A = (%.2f, %.2f, %.2f)\nB = (%.2f, %.2f, %.2f)\nA + B = (%.2f, %.2f, %.2f)" % [
		vector_a.x, vector_a.y, vector_a.z,
		vector_b.x, vector_b.y, vector_b.z,
		result.x, result.y, result.z
	]

func _process(_delta):
	# Check if handles moved (for future grabbable implementation)
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
				_apply_preset(Vector3(0.6, 0.2, 0), Vector3(0.2, 0.6, 0))
			KEY_3:
				_apply_preset(Vector3(0.4, 0.3, 0.2), Vector3(0.2, 0.4, 0.5))
			KEY_R:
				_apply_preset(Vector3(0.5, 0.3, 0), Vector3(0.2, 0.5, 0.3))

func set_vectors(a: Vector3, b: Vector3):
	vector_a = a
	vector_b = b
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func get_result() -> Vector3:
	return vector_a + vector_b
