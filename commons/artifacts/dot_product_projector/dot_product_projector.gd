# dot_product_projector.gd
# Interactive dot product visualizer
# Shows: A · B = |A||B|cos(θ) = projection of A onto B × |B|
#
# VR-enabled with grabbable vector endpoints
# QFEP: Dot product as "alignment" - how much two directions agree

extends Node3D

class_name DotProductProjector

## Display settings
@export var max_vector_length: float = 1.0
@export var arrow_thickness: float = 0.02

## Vector A (the vector being projected)
@export var vector_a: Vector3 = Vector3(0.6, 0.5, 0.0):
	set(value):
		vector_a = value.limit_length(max_vector_length)
		_update_visualization()

## Vector B (the vector projected onto)
@export var vector_b: Vector3 = Vector3(0.8, 0.0, 0.0):
	set(value):
		vector_b = value.limit_length(max_vector_length)
		if vector_b.length() < 0.01:
			vector_b = Vector3(0.8, 0, 0)  # Prevent zero
		_update_visualization()

## Colors
@export var color_a: Color = Color(1.0, 0.3, 0.3)  # Red - vector A
@export var color_b: Color = Color(0.3, 0.5, 1.0)  # Blue - vector B
@export var color_projection: Color = Color(0.3, 1.0, 0.4)  # Green - projection
@export var color_perpendicular: Color = Color(1.0, 0.8, 0.3, 0.5)  # Yellow - perp component
@export var color_angle: Color = Color(0.8, 0.5, 1.0, 0.4)  # Purple - angle arc

var _arrow_a: Node3D
var _arrow_b: Node3D
var _arrow_projection: Node3D
var _arrow_perpendicular: Node3D
var _drop_line: MeshInstance3D
var _angle_arc: MeshInstance3D
var _handle_a: Node3D
var _handle_b: Node3D
var _info_label: Label3D
var _formula_label: Label3D
var _result_label: Label3D
var _control_panel: Node3D

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_create_base()
	_create_arrows()
	_create_projection_components()
	_create_handles()
	_create_labels()
	_create_vr_controls()
	_update_visualization()

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

func _create_arrows():
	_arrow_a = _create_arrow("ArrowA", color_a)
	_arrow_b = _create_arrow("ArrowB", color_b)
	_arrow_projection = _create_arrow("ArrowProjection", color_projection)
	_arrow_perpendicular = _create_arrow("ArrowPerpendicular", color_perpendicular, true)
	
	add_child(_arrow_a)
	add_child(_arrow_b)
	add_child(_arrow_projection)
	add_child(_arrow_perpendicular)

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
	
	# Head
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

func _create_projection_components():
	# Drop line (perpendicular from A tip to projection)
	_drop_line = MeshInstance3D.new()
	_drop_line.name = "DropLine"
	var line_mesh = CylinderMesh.new()
	line_mesh.top_radius = 0.003
	line_mesh.bottom_radius = 0.003
	line_mesh.height = 1.0
	_drop_line.mesh = line_mesh
	
	var line_mat = StandardMaterial3D.new()
	line_mat.albedo_color = Color(1, 1, 1, 0.4)
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_drop_line.material_override = line_mat
	add_child(_drop_line)
	
	# Angle arc
	_angle_arc = MeshInstance3D.new()
	_angle_arc.name = "AngleArc"
	add_child(_angle_arc)

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

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 20
	_info_label.position = Vector3(0, max_vector_length + 0.2, 0)
	_info_label.text = "DOT PRODUCT"
	add_child(_info_label)
	
	_formula_label = Label3D.new()
	_formula_label.name = "FormulaLabel"
	_formula_label.pixel_size = 0.0015
	_formula_label.font_size = 14
	_formula_label.position = Vector3(0, -0.12, max_vector_length + 0.15)
	_formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_formula_label)
	
	_result_label = Label3D.new()
	_result_label.name = "ResultLabel"
	_result_label.pixel_size = 0.002
	_result_label.font_size = 18
	_result_label.position = Vector3(0, max_vector_length + 0.08, 0)
	_result_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_result_label)

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
	
	# Preset buttons
	var presets = [
		["ALIGNED", Vector3(0.6, 0.0, 0), Vector3(0.8, 0.0, 0)],  # Same direction
		["ORTHO", Vector3(0.0, 0.6, 0), Vector3(0.8, 0.0, 0)],    # 90 degrees
		["OPPOSED", Vector3(-0.5, 0.0, 0), Vector3(0.8, 0.0, 0)], # Opposite
		["ACUTE", Vector3(0.5, 0.4, 0), Vector3(0.8, 0.0, 0)],    # Acute angle
		["OBTUSE", Vector3(-0.3, 0.5, 0), Vector3(0.8, 0.0, 0)]   # Obtuse angle
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
			area.button_pressed.connect(func(): _apply_preset(va, vb))

func _add_button_label(btn: Node, text: String):
	var lbl = Label3D.new()
	lbl.text = text
	lbl.pixel_size = 0.001
	lbl.font_size = 7
	lbl.position = Vector3(0, -0.025, 0)
	btn.add_child(lbl)

func _apply_preset(va: Vector3, vb: Vector3):
	vector_a = va
	vector_b = vb
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func _update_visualization():
	# Calculate dot product and projection
	var dot = vector_a.dot(vector_b)
	var b_normalized = vector_b.normalized()
	var projection_length = dot / vector_b.length() if vector_b.length() > 0.001 else 0.0
	var projection = b_normalized * projection_length
	var perpendicular = vector_a - projection
	
	# Calculate angle
	var cos_angle = dot / (vector_a.length() * vector_b.length()) if (vector_a.length() > 0.001 and vector_b.length() > 0.001) else 0.0
	cos_angle = clampf(cos_angle, -1.0, 1.0)
	var angle_rad = acos(cos_angle)
	var angle_deg = rad_to_deg(angle_rad)
	
	# Update arrows
	_position_arrow(_arrow_a, Vector3.ZERO, vector_a)
	_position_arrow(_arrow_b, Vector3.ZERO, vector_b)
	_position_arrow(_arrow_projection, Vector3.ZERO, projection)
	_position_arrow(_arrow_perpendicular, projection, vector_a)
	
	# Update drop line
	_update_drop_line(vector_a, projection)
	
	# Update angle arc
	_update_angle_arc(angle_rad)
	
	# Update labels
	_update_labels(dot, projection_length, angle_deg)

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

func _update_angle_arc(angle_rad: float):
	# Create arc mesh showing the angle between vectors
	if angle_rad < 0.01 or angle_rad > PI - 0.01:
		_angle_arc.visible = false
		return
	_angle_arc.visible = true
	
	var arc_radius = 0.12
	var segments = int(angle_rad * 20) + 4
	
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	var a_dir = vector_a.normalized()
	var b_dir = vector_b.normalized()
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var interp = b_dir.slerp(a_dir, t).normalized() * arc_radius
		
		immediate_mesh.surface_add_vertex(interp * 0.9)
		immediate_mesh.surface_add_vertex(interp * 1.1)
	
	immediate_mesh.surface_end()
	_angle_arc.mesh = immediate_mesh
	
	var arc_mat = StandardMaterial3D.new()
	arc_mat.albedo_color = color_angle
	arc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_angle_arc.material_override = arc_mat

func _update_labels(dot: float, proj_len: float, angle_deg: float):
	# Sign indicator
	var sign_word = "positive" if dot > 0.01 else ("negative" if dot < -0.01 else "zero")
	var alignment = "aligned" if dot > 0.01 else ("opposed" if dot < -0.01 else "orthogonal")
	
	_result_label.text = "A · B = %.3f (%s)" % [dot, alignment]
	_result_label.modulate = Color(0.3, 1.0, 0.4) if dot > 0 else (Color(1.0, 0.4, 0.3) if dot < 0 else Color(1.0, 1.0, 0.3))
	
	_formula_label.text = "A = (%.2f, %.2f, %.2f)  |A| = %.2f\n" % [vector_a.x, vector_a.y, vector_a.z, vector_a.length()]
	_formula_label.text += "B = (%.2f, %.2f, %.2f)  |B| = %.2f\n" % [vector_b.x, vector_b.y, vector_b.z, vector_b.length()]
	_formula_label.text += "θ = %.1f°  proj = %.2f" % [angle_deg, proj_len]

func _process(_delta):
	if _handle_a and _handle_a.position != vector_a:
		vector_a = _handle_a.position
	if _handle_b and _handle_b.position != vector_b:
		vector_b = _handle_b.position

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _apply_preset(Vector3(0.6, 0.0, 0), Vector3(0.8, 0.0, 0))
			KEY_2: _apply_preset(Vector3(0.0, 0.6, 0), Vector3(0.8, 0.0, 0))
			KEY_3: _apply_preset(Vector3(-0.5, 0.0, 0), Vector3(0.8, 0.0, 0))
			KEY_4: _apply_preset(Vector3(0.5, 0.4, 0), Vector3(0.8, 0.0, 0))
			KEY_5: _apply_preset(Vector3(-0.3, 0.5, 0), Vector3(0.8, 0.0, 0))

func set_vectors(a: Vector3, b: Vector3):
	vector_a = a
	vector_b = b
	_handle_a.position = vector_a
	_handle_b.position = vector_b

func get_dot_product() -> float:
	return vector_a.dot(vector_b)

func get_projection() -> Vector3:
	var dot = vector_a.dot(vector_b)
	return vector_b.normalized() * (dot / vector_b.length()) if vector_b.length() > 0.001 else Vector3.ZERO
