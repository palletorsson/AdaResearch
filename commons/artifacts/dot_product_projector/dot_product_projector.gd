# dot_product_projector.gd
# Interactive dot product visualizer
# Shows: A · B = |A||B|cos(θ) = projection of A onto B × |B|
#
# VR-enabled with grabbable vector endpoints
# QFEP: Dot product as "alignment" - how much two directions agree
#
# UPGRADED VISUALS - Sleek modern look with glow effects

extends Node3D

class_name DotProductProjector

## Display settings
@export var max_vector_length: float = 1.2
@export var arrow_thickness: float = 0.012  # Thin like y_oscillation_cube

## Vector A (the vector being projected)
@export var vector_a: Vector3 = Vector3(0.7, 0.5, 0.0):
	set(value):
		vector_a = value.limit_length(max_vector_length)
		if is_inside_tree():
			_update_visualization()

## Vector B (the vector projected onto)
@export var vector_b: Vector3 = Vector3(0.9, 0.0, 0.0):
	set(value):
		vector_b = value.limit_length(max_vector_length)
		if vector_b.length() < 0.01:
			vector_b = Vector3(0.9, 0, 0)
		if is_inside_tree():
			_update_visualization()

# Sleek color palette
var color_a: Color = Color(1.0, 0.35, 0.4)        # Coral - vector A
var color_b: Color = Color(0.3, 0.5, 1.0)         # Blue - vector B
var color_projection: Color = Color(0.4, 1.0, 0.5) # Green - projection
var color_perpendicular: Color = Color(1.0, 0.75, 0.3, 0.6)  # Orange - perp
var color_angle: Color = Color(0.8, 0.5, 1.0, 0.5) # Purple - angle arc

var _arrow_a: Node3D
var _arrow_b: Node3D
var _arrow_projection: Node3D
var _arrow_perpendicular: Node3D
var _drop_line: MeshInstance3D
var _angle_arc: MeshInstance3D
var _handle_a: Node3D
var _handle_b: Node3D
var _title_panel: Node3D
var _result_panel: Node3D
var _formula_panel: Node3D
var _control_panel: Node3D
var _ground: Node3D
var _axes: Node3D

# Vector labels
var _label_a: Label3D
var _label_b: Label3D
var _label_proj: Label3D
var _label_angle: Label3D

# Animation
var _time: float = 0.0

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_ground = VectorVisuals.create_ground(self, max_vector_length * 2.5)
	_axes = VectorVisuals.create_axes(self, max_vector_length * 1.3)
	
	_create_arrows()
	_create_projection_visuals()
	_create_handles()
	_create_labels()
	_create_vr_controls()
	_update_visualization()

func _create_arrows():
	_arrow_a = VectorVisuals.create_arrow(self, "ArrowA", color_a, arrow_thickness)
	_arrow_b = VectorVisuals.create_arrow(self, "ArrowB", color_b, arrow_thickness)
	_arrow_projection = VectorVisuals.create_arrow(self, "ArrowProjection", color_projection, arrow_thickness)
	_arrow_perpendicular = VectorVisuals.create_arrow(self, "ArrowPerpendicular", color_perpendicular, arrow_thickness, true)

func _create_projection_visuals():
	# Drop line (perpendicular from A tip to projection)
	_drop_line = MeshInstance3D.new()
	_drop_line.name = "DropLine"
	add_child(_drop_line)
	
	# Angle arc
	_angle_arc = MeshInstance3D.new()
	_angle_arc.name = "AngleArc"
	add_child(_angle_arc)

func _create_handles():
	_handle_a = VectorVisuals.create_handle(self, "HandleA", color_a, 0.045)
	_handle_a.position = vector_a
	
	_handle_b = VectorVisuals.create_handle(self, "HandleB", color_b, 0.045)
	_handle_b.position = vector_b

func _create_labels():
	# Title panel - behind artifact, facing player
	_title_panel = VectorVisuals.create_panel(self, "TitlePanel",
		"DOT PRODUCT",
		Vector3(0, max_vector_length + 0.45, -max_vector_length - 0.2),
		Vector2(0.42, 0.09), 26)
	# No rotation - faces +Z toward player
	
	# Result panel - below title
	_result_panel = VectorVisuals.create_panel(self, "ResultPanel", "",
		Vector3(0, max_vector_length + 0.28, -max_vector_length - 0.2),
		Vector2(0.6, 0.1), 18)
	# No rotation - faces +Z toward player
	
	# Formula panel - to the right, facing player
	_formula_panel = VectorVisuals.create_panel(self, "FormulaPanel", "",
		Vector3(max_vector_length + 0.28, max_vector_length * 0.4, 0),
		Vector2(0.6, 0.28), 12, HORIZONTAL_ALIGNMENT_LEFT)
	_formula_panel.rotation_degrees = Vector3(0, -90, 0)  # Face toward +Z
	
	# Vector labels
	_label_a = VectorVisuals.create_vector_label(self, "LabelA", "A⃗", color_a)
	_label_b = VectorVisuals.create_vector_label(self, "LabelB", "B⃗", color_b)
	_label_proj = VectorVisuals.create_vector_label(self, "LabelProj", "proj", color_projection)
	
	# Angle label
	_label_angle = Label3D.new()
	_label_angle.name = "LabelAngle"
	_label_angle.pixel_size = 0.0018
	_label_angle.font_size = 14
	_label_angle.modulate = color_angle
	_label_angle.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_angle.outline_size = 6
	_label_angle.outline_modulate = Color(0, 0, 0, 0.7)
	add_child(_label_angle)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.06, max_vector_length + 0.4)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.5, 0.12, 0.012)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.04, 0.04, 0.06, 0.95)
	panel_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	panel_back.material_override = panel_mat
	panel_back.position.z = -0.008
	_control_panel.add_child(panel_back)
	
	var presets = [
		["ALIGNED", Vector3(0.6, 0.0, 0), Vector3(0.8, 0.0, 0)],
		["ORTHO", Vector3(0.0, 0.6, 0), Vector3(0.8, 0.0, 0)],
		["OPPOSED", Vector3(-0.5, 0.0, 0), Vector3(0.8, 0.0, 0)],
		["ACUTE", Vector3(0.5, 0.4, 0), Vector3(0.8, 0.0, 0)],
		["OBTUSE", Vector3(-0.3, 0.5, 0), Vector3(0.8, 0.0, 0)]
	]
	
	for i in range(presets.size()):
		var btn = PUSH_BUTTON.instantiate()
		btn.name = "Preset%d" % i
		btn.position = Vector3(-0.18 + i * 0.09, 0, 0.01)
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
	lbl.font_size = 8
	lbl.outline_size = 3
	lbl.outline_modulate = Color(0, 0, 0, 0.5)
	lbl.position = Vector3(0, -0.028, 0.01)
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
	
	# Update arrows - all thin
	VectorVisuals.position_arrow(_arrow_a, Vector3.ZERO, vector_a, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_b, Vector3.ZERO, vector_b, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_projection, Vector3.ZERO, projection, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_perpendicular, projection, vector_a, arrow_thickness)
	
	# Update labels - offset toward +Z for player visibility
	_label_a.position = vector_a * 0.5 + Vector3(0, 0.06, 0.08)
	_label_b.position = vector_b * 0.5 + Vector3(0, 0.06, 0.08)
	_label_proj.position = projection * 0.5 + Vector3(0, -0.06, 0.08)
	
	# Update drop line
	_update_drop_line(vector_a, projection)
	
	# Update angle arc and label
	_update_angle_arc(angle_rad)
	_label_angle.position = Vector3(0.15, 0.08, 0)
	_label_angle.text = "θ = %.1f°" % angle_deg
	
	# Update panels
	_update_panels(dot, projection_length, angle_deg)

func _update_drop_line(a_tip: Vector3, proj: Vector3):
	var perp = a_tip - proj
	if perp.length() < 0.01:
		_drop_line.visible = false
		return
	_drop_line.visible = true
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.004
	cylinder.bottom_radius = 0.004
	cylinder.height = perp.length()
	_drop_line.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1, 1, 1, 0.4)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 0.2
	_drop_line.material_override = mat
	
	var mid = (a_tip + proj) / 2.0
	_drop_line.position = mid
	
	var up = Vector3.UP
	if abs(perp.normalized().dot(up)) > 0.99:
		up = Vector3.FORWARD
	_drop_line.look_at(_drop_line.global_position + perp, up)
	_drop_line.rotate_object_local(Vector3.RIGHT, PI/2)

func _update_angle_arc(angle_rad: float):
	if angle_rad < 0.05 or angle_rad > PI - 0.05:
		_angle_arc.visible = false
		return
	_angle_arc.visible = true
	
	var arc_radius = 0.15
	var segments = int(angle_rad * 20) + 6
	
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	
	var a_dir = vector_a.normalized()
	var b_dir = vector_b.normalized()
	
	for i in range(segments + 1):
		var t = float(i) / float(segments)
		var interp = b_dir.slerp(a_dir, t).normalized() * arc_radius
		
		immediate_mesh.surface_add_vertex(interp * 0.85)
		immediate_mesh.surface_add_vertex(interp * 1.0)
	
	immediate_mesh.surface_end()
	_angle_arc.mesh = immediate_mesh
	
	var arc_mat = StandardMaterial3D.new()
	arc_mat.albedo_color = color_angle
	arc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	arc_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	arc_mat.emission_enabled = true
	arc_mat.emission = Color(color_angle.r, color_angle.g, color_angle.b, 1.0)
	arc_mat.emission_energy_multiplier = 0.3
	_angle_arc.material_override = arc_mat

func _update_panels(dot: float, proj_len: float, angle_deg: float):
	var alignment = "aligned" if dot > 0.01 else ("opposed" if dot < -0.01 else "orthogonal")
	
	# Result panel
	var result_label = VectorVisuals.get_panel_label(_result_panel)
	if result_label:
		result_label.text = "A⃗ · B⃗ = %.3f  (%s)" % [dot, alignment]
		if dot > 0:
			result_label.modulate = Color(0.4, 1.0, 0.5)
		elif dot < 0:
			result_label.modulate = Color(1.0, 0.4, 0.4)
		else:
			result_label.modulate = Color(1.0, 1.0, 0.4)
	
	# Formula panel
	var formula_label = VectorVisuals.get_panel_label(_formula_panel)
	if formula_label:
		formula_label.text = "A⃗ = (%.2f, %.2f, %.2f)\n" % [vector_a.x, vector_a.y, vector_a.z]
		formula_label.text += "|A⃗| = %.3f\n\n" % vector_a.length()
		formula_label.text += "B⃗ = (%.2f, %.2f, %.2f)\n" % [vector_b.x, vector_b.y, vector_b.z]
		formula_label.text += "|B⃗| = %.3f\n\n" % vector_b.length()
		formula_label.text += "A⃗ · B⃗ = |A⃗||B⃗|cos(θ)\n"
		formula_label.text += "θ = %.1f°   proj = %.3f" % [angle_deg, proj_len]

func _process(delta):
	_time += delta
	
	VectorVisuals.pulse_handle(_handle_a, delta, _time)
	VectorVisuals.pulse_handle(_handle_b, delta, _time + 1.0)
	VectorVisuals.pulse_arrow(_arrow_projection, delta, _time)
	
	if _handle_a.position != vector_a:
		vector_a = _handle_a.position
	if _handle_b.position != vector_b:
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

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
