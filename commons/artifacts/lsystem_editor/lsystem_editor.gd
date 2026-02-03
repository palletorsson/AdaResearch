# lsystem_editor.gd
# Interactive L-system viewer with presets
# Grammar as a generative tool - from axiom to tree

extends Node3D

class_name LSystemEditor

## Display settings
@export var display_size: float = 1.0
@export var line_color: Color = Color(0.3, 0.8, 0.3)
@export var max_line_length: float = 0.02

## L-system parameters
@export var axiom: String = "F"
@export var angle_degrees: float = 25.0
@export var generations: int = 4

## Current preset
@export_enum("Koch Curve", "Sierpinski", "Dragon Curve", "Plant", "Bush", "Fern", "Binary Tree", "Custom") var preset: int = 3:
	set(value):
		preset = value
		_apply_preset()

# Preset definitions: [axiom, rules_dict, angle, recommended_generations]
const PRESETS = {
	0: ["F", {"F": "F+F-F-F+F"}, 90.0, 4, "Koch Curve"],
	1: ["F-G-G", {"F": "F-G+F+G-F", "G": "GG"}, 120.0, 5, "Sierpinski"],
	2: ["FX", {"X": "X+YF+", "Y": "-FX-Y"}, 90.0, 10, "Dragon Curve"],
	3: ["X", {"X": "F+[[X]-X]-F[-FX]+X", "F": "FF"}, 25.0, 5, "Plant"],
	4: ["F", {"F": "FF+[+F-F-F]-[-F+F+F]"}, 22.5, 4, "Bush"],
	5: ["X", {"X": "F-[[X]+X]+F[+FX]-X", "F": "FF"}, 25.0, 5, "Fern"],
	6: ["F", {"F": "G[+F]-F", "G": "GG"}, 45.0, 6, "Binary Tree"],
}

# Rules dictionary
var _rules: Dictionary = {}

# Generated string
var _current_string: String = ""

# Visualization
var _mesh_instance: MeshInstance3D
var _immediate_mesh: ImmediateMesh
var _info_label: Label3D

func _ready():
	_create_display()
	_create_base()
	_create_labels()
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
	
	var hint = Label3D.new()
	hint.name = "ControlsHint"
	hint.pixel_size = 0.001
	hint.font_size = 18
	hint.text = "1-7 Presets | ←→ Generations | ↑↓ Angle"
	hint.position = Vector3(0, -0.05, display_size * 0.5)
	hint.modulate = Color(0.6, 0.6, 0.6)
	add_child(hint)

func _apply_preset():
	if preset >= 0 and preset < PRESETS.size():
		var p = PRESETS[preset]
		axiom = p[0]
		_rules = p[1].duplicate()
		angle_degrees = p[2]
		generations = p[3]
	
	_generate()

func _generate():
	# Generate the L-system string
	_current_string = axiom
	
	for _gen in range(generations):
		var new_string = ""
		for c in _current_string:
			if _rules.has(c):
				new_string += _rules[c]
			else:
				new_string += c
		_current_string = new_string
	
	# Draw the result
	_draw_lsystem()
	_update_info()

func _draw_lsystem():
	_immediate_mesh.clear_surfaces()
	
	if _current_string.length() == 0:
		return
	
	# Turtle state
	var pos = Vector3.ZERO
	var dir = Vector3.UP
	var right = Vector3.RIGHT
	var stack: Array = []
	
	# Calculate line length based on string length
	var line_length = minf(max_line_length, display_size / pow(_current_string.length(), 0.4))
	
	# Collect all line segments first
	var lines: Array[Vector3] = []
	var min_bounds = Vector3.INF
	var max_bounds = -Vector3.INF
	
	var angle_rad = deg_to_rad(angle_degrees)
	
	for c in _current_string:
		match c:
			"F", "G":  # Forward (draw)
				var new_pos = pos + dir * line_length
				lines.append(pos)
				lines.append(new_pos)
				pos = new_pos
				min_bounds = min_bounds.min(pos)
				max_bounds = max_bounds.max(pos)
			"f":  # Forward (no draw)
				pos += dir * line_length
			"+":  # Turn left
				var axis = dir.cross(right).normalized()
				if axis.length() < 0.1:
					axis = Vector3.FORWARD
				dir = dir.rotated(axis, angle_rad)
				right = right.rotated(axis, angle_rad)
			"-":  # Turn right
				var axis = dir.cross(right).normalized()
				if axis.length() < 0.1:
					axis = Vector3.FORWARD
				dir = dir.rotated(axis, -angle_rad)
				right = right.rotated(axis, -angle_rad)
			"[":  # Push state
				stack.append([pos, dir, right])
			"]":  # Pop state
				if stack.size() > 0:
					var state = stack.pop_back()
					pos = state[0]
					dir = state[1]
					right = state[2]
	
	# Calculate scale and offset to fit in display area
	var bounds_size = max_bounds - min_bounds
	var max_dim = maxf(maxf(bounds_size.x, bounds_size.y), bounds_size.z)
	if max_dim < 0.001:
		max_dim = 1.0
	
	var scale_factor = display_size * 0.8 / max_dim
	var center = (min_bounds + max_bounds) / 2.0
	
	# Draw scaled lines
	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	
	for i in range(0, lines.size(), 2):
		var p1 = (lines[i] - center) * scale_factor
		var p2 = (lines[i + 1] - center) * scale_factor
		
		# Color gradient based on height
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
	
	_info_label.text = "%s\nGen: %d | Angle: %.1f°\nChars: %d" % [
		name, generations, angle_degrees, _current_string.length()
	]

func _input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				preset = 0
			KEY_2:
				preset = 1
			KEY_3:
				preset = 2
			KEY_4:
				preset = 3
			KEY_5:
				preset = 4
			KEY_6:
				preset = 5
			KEY_7:
				preset = 6
			KEY_LEFT:
				generations = maxi(1, generations - 1)
				_generate()
			KEY_RIGHT:
				generations = mini(12, generations + 1)
				_generate()
			KEY_UP:
				angle_degrees += 5.0
				_generate()
			KEY_DOWN:
				angle_degrees = maxf(5.0, angle_degrees - 5.0)
				_generate()

## Set rules programmatically
func set_rules(new_axiom: String, new_rules: Dictionary, new_angle: float = 25.0, new_generations: int = 4):
	axiom = new_axiom
	_rules = new_rules.duplicate()
	angle_degrees = new_angle
	generations = new_generations
	preset = 7  # Custom
	_generate()

## Get current generated string
func get_string() -> String:
	return _current_string
