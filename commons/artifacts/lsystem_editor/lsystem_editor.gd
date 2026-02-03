# lsystem_editor.gd
# Interactive L-system viewer with VR controls
# Grammar as a generative tool

extends Node3D

class_name LSystemEditor

## Display settings
@export var display_size: float = 1.0
@export var line_color: Color = Color(0.3, 0.8, 0.3)
@export var max_line_length: float = 0.02

## L-system parameters
@export var axiom: String = "F"
@export var angle_degrees: float = 25.0:
	set(value):
		angle_degrees = clampf(value, 5.0, 90.0)
		_generate()
		_sync_angle_slider()

@export var generations: int = 4:
	set(value):
		generations = clampi(value, 1, 10)
		_generate()
		_sync_gen_slider()

## Current preset
@export_enum("Koch Curve", "Sierpinski", "Dragon Curve", "Plant", "Bush", "Fern", "Binary Tree") var preset: int = 3:
	set(value):
		preset = clampi(value, 0, 6)
		_apply_preset()
		_sync_preset_slider()

const PRESETS = {
	0: ["F", {"F": "F+F-F-F+F"}, 90.0, 4, "Koch Curve"],
	1: ["F-G-G", {"F": "F-G+F+G-F", "G": "GG"}, 120.0, 5, "Sierpinski"],
	2: ["FX", {"X": "X+YF+", "Y": "-FX-Y"}, 90.0, 10, "Dragon Curve"],
	3: ["X", {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}, 25.0, 5, "Plant"],
	4: ["F", {"F": "FF+[+F-F-F]-[-F+F+F]"}, 22.5, 4, "Bush"],
	5: ["X", {"X": "F-[[X]+X]+F[+FX]-X", "F": "FF"}, 25.0, 5, "Fern"],
	6: ["F", {"F": "G[+F]-F", "G": "GG"}, 45.0, 6, "Binary Tree"],
}

var _rules: Dictionary = {}
var _current_string: String = ""
var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _info_label: Label3D

# VR Controls
var _preset_slider: Node
var _gen_slider: Node
var _angle_slider: Node
var _control_panel: Node3D

const SLIDER_HORIZONTAL = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON = preload("res://commons/interactables/push_button.tscn")

func _ready():
	_create_display()
	_create_base()
	_create_labels()
	_create_vr_controls()
	_apply_preset()

func _create_display():
	_immediate_mesh = ImmediateMesh.new()
	
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.name = "LSystemDisplay"
	_mesh_instance.mesh = _immediate_mesh
	
	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = line_color
	mat.vertex_color_use_as_albedo = true
	_mesh_instance.material_override = mat
	
	add_child(_mesh_instance)

func _create_base():
	var base = MeshInstance3D.new()
	base.name = "Base"
	
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = display_size * 0.5
	cylinder.bottom_radius = display_size * 0.55
	cylinder.height = 0.04
	base.mesh = cylinder
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.15)
	mat.metallic = 0.6
	mat.roughness = 0.4
	base.material_override = mat
	
	base.position = Vector3(0, -0.02, 0)
	add_child(base)

func _create_labels():
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = 0.002
	_info_label.font_size = 24
	_info_label.position = Vector3(0, display_size + 0.1, 0)
	add_child(_info_label)

func _create_vr_controls():
	_control_panel = Node3D.new()
	_control_panel.name = "ControlPanel"
	_control_panel.position = Vector3(0, 0.04, display_size * 0.5 + 0.15)
	_control_panel.rotation_degrees = Vector3(30, 0, 0)
	add_child(_control_panel)
	
	# Panel backing
	var panel_back = MeshInstance3D.new()
	var panel_mesh = BoxMesh.new()
	panel_mesh.size = Vector3(0.5, 0.2, 0.01)
	panel_back.mesh = panel_mesh
	var panel_mat = StandardMaterial3D.new()
	panel_mat.albedo_color = Color(0.08, 0.08, 0.1)
	panel_mat.metallic = 0.3
	panel_back.material_override = panel_mat
	_control_panel.add_child(panel_back)
	
	# Preset slider (0-6)
	_preset_slider = SLIDER_HORIZONTAL.instantiate()
	_preset_slider.name = "PresetSlider"
	_preset_slider.position = Vector3(0, 0.055, 0.015)
	var preset_label = _preset_slider.get_node_or_null("Frame/LabelName")
	if preset_label:
		preset_label.text = "PRESET"
	_control_panel.add_child(_preset_slider)
	_preset_slider.slider_moved.connect(_on_preset_slider_moved)
	
	# Generation slider (1-10)
	_gen_slider = SLIDER_HORIZONTAL.instantiate()
	_gen_slider.name = "GenSlider"
	_gen_slider.position = Vector3(-0.12, -0.02, 0.015)
	var gen_label = _gen_slider.get_node_or_null("Frame/LabelName")
	if gen_label:
		gen_label.text = "GEN"
	_control_panel.add_child(_gen_slider)
	_gen_slider.slider_moved.connect(_on_gen_slider_moved)
	
	# Angle slider (5-90)
	_angle_slider = SLIDER_HORIZONTAL.instantiate()
	_angle_slider.name = "AngleSlider"
	_angle_slider.position = Vector3(0.12, -0.02, 0.015)
	var angle_label = _angle_slider.get_node_or_null("Frame/LabelName")
	if angle_label:
		angle_label.text = "ANGLE"
	_control_panel.add_child(_angle_slider)
	_angle_slider.slider_moved.connect(_on_angle_slider_moved)
	
	call_deferred("_sync_sliders_deferred")

func _sync_sliders_deferred():
	_sync_preset_slider()
	_sync_gen_slider()
	_sync_angle_slider()

func _sync_preset_slider():
	if _preset_slider and _preset_slider.has_method("set_normalized_value"):
		_preset_slider.set_normalized_value(float(preset) / 6.0)

func _sync_gen_slider():
	if _gen_slider and _gen_slider.has_method("set_normalized_value"):
		_gen_slider.set_normalized_value(float(generations - 1) / 9.0)

func _sync_angle_slider():
	if _angle_slider and _angle_slider.has_method("set_normalized_value"):
		_angle_slider.set_normalized_value((angle_degrees - 5.0) / 85.0)

func _on_preset_slider_moved(_position):
	if _preset_slider and _preset_slider.has_method("get_normalized_value"):
		var norm = _preset_slider.get_normalized_value()
		var new_preset = int(norm * 6.99)
		if new_preset != preset:
			preset = new_preset

func _on_gen_slider_moved(_position):
	if _gen_slider and _gen_slider.has_method("get_normalized_value"):
		var norm = _gen_slider.get_normalized_value()
		var new_gen = 1 + int(norm * 9.99)
		if new_gen != generations:
			generations = new_gen

func _on_angle_slider_moved(_position):
	if _angle_slider and _angle_slider.has_method("get_normalized_value"):
		var norm = _angle_slider.get_normalized_value()
		angle_degrees = 5.0 + norm * 85.0

func _apply_preset():
	if preset >= 0 and preset < PRESETS.size():
		var p = PRESETS[preset]
		axiom = p[0]
		_rules = p[1].duplicate()
		angle_degrees = p[2]
		generations = mini(p[3], 10)
	
	_generate()
	call_deferred("_sync_sliders_deferred")

func _generate():
	_current_string = axiom
	
	for _gen in range(generations):
		var new_string = ""
		for c in _current_string:
			if _rules.has(c):
				new_string += _rules[c]
			else:
				new_string += c
		_current_string = new_string
		# Limit string length for performance
		if _current_string.length() > 100000:
			break
	
	_draw_lsystem()
	_update_info()

func _draw_lsystem():
	_immediate_mesh.clear_surfaces()
	
	if _current_string.length() == 0:
		return
	
	var pos = Vector3.ZERO
	var dir = Vector3.UP
	var right = Vector3.RIGHT
	var stack: Array = []
	
	var line_length = minf(max_line_length, display_size / pow(_current_string.length(), 0.4))
	var lines: Array[Vector3] = []
	var min_bounds = Vector3.INF
	var max_bounds = -Vector3.INF
	
	var angle_rad = deg_to_rad(angle_degrees)
	
	for c in _current_string:
		match c:
			"F", "G":
				var new_pos = pos + dir * line_length
				lines.append(pos)
				lines.append(new_pos)
				pos = new_pos
				min_bounds = min_bounds.min(pos)
				max_bounds = max_bounds.max(pos)
			"f":
				pos += dir * line_length
			"+":
				var axis = dir.cross(right).normalized()
				if axis.length() < 0.1:
					axis = Vector3.FORWARD
				dir = dir.rotated(axis, angle_rad)
				right = right.rotated(axis, angle_rad)
			"-":
				var axis = dir.cross(right).normalized()
				if axis.length() < 0.1:
					axis = Vector3.FORWARD
				dir = dir.rotated(axis, -angle_rad)
				right = right.rotated(axis, -angle_rad)
			"[":
				stack.append([pos, dir, right])
			"]":
				if stack.size() > 0:
					var state = stack.pop_back()
					pos = state[0]
					dir = state[1]
					right = state[2]
	
	var bounds_size = max_bounds - min_bounds
	var max_dim = maxf(maxf(bounds_size.x, bounds_size.y), bounds_size.z)
	if max_dim < 0.001:
		max_dim = 1.0
	
	var scale_factor = display_size * 0.8 / max_dim
	var center = (min_bounds + max_bounds) / 2.0
	
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for i in range(0, lines.size(), 2):
		var p1 = (lines[i] - center) * scale_factor
		var p2 = (lines[i + 1] - center) * scale_factor
		
		var t1 = clampf((p1.y + display_size * 0.4) / display_size, 0, 1)
		var t2 = clampf((p2.y + display_size * 0.4) / display_size, 0, 1)
		
		var c1 = line_color.lerp(Color(0.9, 0.95, 0.8), t1 * 0.5)
		var c2 = line_color.lerp(Color(0.9, 0.95, 0.8), t2 * 0.5)
		
		_immediate_mesh.surface_set_color(c1)
		_immediate_mesh.surface_add_vertex(p1)
		_immediate_mesh.surface_set_color(c2)
		_immediate_mesh.surface_add_vertex(p2)
	
	_immediate_mesh.surface_end()

func _update_info():
	var name = "Custom"
	if preset < PRESETS.size():
		name = PRESETS[preset][4]
	
	_info_label.text = "%s\nGen: %d | Angle: %.1f°" % [name, generations, angle_degrees]

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1, KEY_2, KEY_3, KEY_4, KEY_5, KEY_6, KEY_7:
				preset = event.keycode - KEY_1
			KEY_LEFT:
				generations = maxi(1, generations - 1)
			KEY_RIGHT:
				generations = mini(10, generations + 1)
			KEY_UP:
				angle_degrees += 5.0
			KEY_DOWN:
				angle_degrees = maxf(5.0, angle_degrees - 5.0)

func set_rules(new_axiom: String, new_rules: Dictionary, new_angle: float = 25.0, new_generations: int = 4):
	axiom = new_axiom
	_rules = new_rules.duplicate()
	angle_degrees = new_angle
	generations = new_generations
	preset = 7
	_generate()

func get_string() -> String:
	return _current_string
