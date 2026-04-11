# cross_product_demo.gd
# Interactive cross product visualizer
# Shows: A × B = normal vector perpendicular to both A and B
# |A × B| = |A||B|sin(θ) = area of parallelogram
#
# VR-enabled with grabbable vector endpoints
# QFEP: Cross product as "emergence" - a third direction from two
#
# UPGRADED VISUALS - Sleek modern look with glow effects

extends Node3D

class_name CrossProductDemo

## Display settings
@export var max_vector_length: float = 1.2
@export var arrow_thickness: float = 0.012  # Thin like y_oscillation_cube

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

# Sleek color palette
var color_a: Color = Color(1.0, 0.35, 0.4)        # Coral
var color_b: Color = Color(0.3, 0.5, 1.0)         # Blue
var color_result: Color = Color(0.4, 1.0, 0.5)    # Green - cross product
var color_parallelogram: Color = Color(0.8, 0.5, 1.0, 0.25)  # Purple - area

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
var _ground: Node3D
var _axes: Node3D

# Labels
var _label_a: Label3D
var _label_b: Label3D
var _label_result: Label3D
var _label_area: Label3D

# Animation
var _time: float = 0.0

const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_ground = VectorVisuals.create_ground(self, max_vector_length * 2.8)
	_axes = VectorVisuals.create_axes(self, max_vector_length * 1.4)
	
	_create_arrows()
	_create_parallelogram()
	_create_handles()
	_create_right_hand_indicator()
	_create_labels()
	_create_vr_controls()
	_update_visualization()

func _create_arrows():
	_arrow_a = VectorVisuals.create_arrow(self, "ArrowA", color_a, arrow_thickness)
	_arrow_b = VectorVisuals.create_arrow(self, "ArrowB", color_b, arrow_thickness)
	_arrow_result = VectorVisuals.create_arrow(self, "ArrowResult", color_result, arrow_thickness)

func _create_parallelogram():
	_parallelogram = MeshInstance3D.new()
	_parallelogram.name = "Parallelogram"
	add_child(_parallelogram)

func _create_handles():
	_handle_a = VectorVisuals.create_handle(self, "HandleA", color_a, 0.045)
	_handle_a.position = vector_a
	
	_handle_b = VectorVisuals.create_handle(self, "HandleB", color_b, 0.045)
	_handle_b.position = vector_b

func _create_right_hand_indicator():
	_right_hand_indicator = Node3D.new()
	_right_hand_indicator.name = "RightHandIndicator"
	add_child(_right_hand_indicator)
	
	var arc = MeshInstance3D.new()
	arc.name = "RotationArc"
	_right_hand_indicator.add_child(arc)

func _create_labels():
	# Title panel - behind artifact, facing player
	_title_panel = VectorVisuals.create_panel(self, "TitlePanel",
		"CROSS PRODUCT",
		Vector3(0, max_vector_length * 1.5 + 0.3, -max_vector_length - 0.2),
		Vector2(0.45, 0.09), 26)
	# No rotation - faces +Z toward player
	
	# Result panel - below title
	_result_panel = VectorVisuals.create_panel(self, "ResultPanel", "",
		Vector3(0, max_vector_length * 1.5 + 0.1, -max_vector_length - 0.2),
		Vector2(0.7, 0.12), 16)
	# No rotation - faces +Z toward player
	
	# Formula panel - to the right, facing player
	_formula_panel = VectorVisuals.create_panel(self, "FormulaPanel", "",
		Vector3(max_vector_length + 0.32, max_vector_length * 0.5, 0),
		Vector2(0.58, 0.25), 12, HORIZONTAL_ALIGNMENT_LEFT)
	_formula_panel.rotation_degrees = Vector3(0, -90, 0)  # Face toward +Z
	
	# Vector labels
	_label_a = VectorVisuals.create_vector_label(self, "LabelA", "A⃗", color_a)
	_label_b = VectorVisuals.create_vector_label(self, "LabelB", "B⃗", color_b)
	_label_result = VectorVisuals.create_vector_label(self, "LabelResult", "A⃗×B⃗", color_result)
	
	# Area label
	_label_area = Label3D.new()
	_label_area.name = "LabelArea"
	_label_area.pixel_size = 0.0016
	_label_area.font_size = 12
	_label_area.modulate = color_parallelogram * 2.0
	_label_area.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_area.outline_size = 5
	_label_area.outline_modulate = Color(0, 0, 0, 0.6)
	add_child(_label_area)

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
		["X×Z→Y", Vector3(0.8, 0, 0), Vector3(0, 0, 0.8)],
		["Z×X→-Y", Vector3(0, 0, 0.8), Vector3(0.8, 0, 0)],
		["X×Y→Z", Vector3(0.8, 0, 0), Vector3(0, 0.8, 0)],
		["3D", Vector3(0.6, 0.4, 0.2), Vector3(0.2, 0.4, 0.6)],
		["RESET", Vector3(0.8, 0, 0), Vector3(0, 0, 0.8)]
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
	# Calculate cross product
	var cross = vector_a.cross(vector_b)
	var magnitude = cross.length()
	
	# Update arrows - all thin
	VectorVisuals.position_arrow(_arrow_a, Vector3.ZERO, vector_a, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_b, Vector3.ZERO, vector_b, arrow_thickness)
	VectorVisuals.position_arrow(_arrow_result, Vector3.ZERO, cross, arrow_thickness)
	
	# Update labels - offset toward +Z for player visibility
	_label_a.position = vector_a * 0.5 + Vector3(0, 0.06, 0.08)
	_label_b.position = vector_b * 0.5 + Vector3(0, 0.06, 0.08)
	_label_result.position = cross * 0.5 + Vector3(0, 0.06, 0.08)
	
	# Update parallelogram
	_update_parallelogram()
	_label_area.position = (vector_a + vector_b) * 0.5 + Vector3(0, 0.08, 0)
	_label_area.text = "Area = %.3f" % magnitude
	
	# Update right-hand rule
	_update_right_hand_indicator(cross)
	
	# Update panels
	_update_panels(cross, magnitude)

func _update_parallelogram():
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	
	var p0 = Vector3.ZERO
	var p1 = vector_a
	var p2 = vector_a + vector_b
	var p3 = vector_b
	
	var offset = Vector3(0, 0.003, 0)
	p0 += offset
	p1 += offset
	p2 += offset
	p3 += offset
	
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
	mat.emission_enabled = true
	mat.emission = Color(color_parallelogram.r, color_parallelogram.g, color_parallelogram.b, 1.0)
	mat.emission_energy_multiplier = 0.15
	_parallelogram.material_override = mat

func _update_right_hand_indicator(cross: Vector3):
	var arc = _right_hand_indicator.get_node("RotationArc")
	
	if cross.length() < 0.01:
		arc.visible = false
		return
	arc.visible = true
	
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	
	var segments = 20
	var radius = 0.1
	var arc_angle = PI * 1.3
	
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
	mat.albedo_color = Color(1, 1, 1, 0.7)
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 0.3
	arc.material_override = mat

func _update_panels(cross: Vector3, magnitude: float):
	var direction_word = ""
	if magnitude > 0.01:
		if abs(cross.y) > abs(cross.x) and abs(cross.y) > abs(cross.z):
			direction_word = "↑Y" if cross.y > 0 else "↓Y"
		elif abs(cross.x) > abs(cross.z):
			direction_word = "→X" if cross.x > 0 else "←X"
		else:
			direction_word = "↗Z" if cross.z > 0 else "↙Z"
	
	var result_label = VectorVisuals.get_panel_label(_result_panel)
	if result_label:
		result_label.text = "A⃗ × B⃗ = (%.2f, %.2f, %.2f)  %s\n|A⃗ × B⃗| = %.3f (area)" % [
			cross.x, cross.y, cross.z, direction_word, magnitude
		]
	
	var formula_label = VectorVisuals.get_panel_label(_formula_panel)
	if formula_label:
		formula_label.text = "A⃗ = (%.2f, %.2f, %.2f)\n" % [vector_a.x, vector_a.y, vector_a.z]
		formula_label.text += "B⃗ = (%.2f, %.2f, %.2f)\n\n" % [vector_b.x, vector_b.y, vector_b.z]
		formula_label.text += "|A⃗ × B⃗| = |A⃗||B⃗|sin(θ)\n\n"
		formula_label.text += "Right-hand rule:\nCurl A⃗→B⃗, thumb = result"

func _process(delta):
	_time += delta
	
	VectorVisuals.pulse_handle(_handle_a, delta, _time)
	VectorVisuals.pulse_handle(_handle_b, delta, _time + 1.0)
	VectorVisuals.pulse_arrow(_arrow_result, delta, _time)
	
	if _handle_a.position != vector_a:
		vector_a = _handle_a.position
	if _handle_b.position != vector_b:
		vector_b = _handle_b.position

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: _apply_preset(Vector3(0.8, 0, 0), Vector3(0, 0, 0.8))
			KEY_2: _apply_preset(Vector3(0, 0, 0.8), Vector3(0.8, 0, 0))
			KEY_3: _apply_preset(Vector3(0.8, 0, 0), Vector3(0, 0.8, 0))
			KEY_4: _apply_preset(Vector3(0.6, 0.4, 0.2), Vector3(0.2, 0.4, 0.6))
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

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
