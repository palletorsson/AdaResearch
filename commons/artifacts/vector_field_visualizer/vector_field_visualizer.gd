extends Node3D
class_name VectorFieldVisualizer

## 3D vector field visualizer — grid of arrow glyphs showing flow direction and magnitude.
## Supports vortex, source, sink, and dipole field modes.
## Each arrow = shaft + 2 arrowhead lines drawn with ImmediateMesh PRIMITIVE_LINES.
##
## @identity
## essence: A 3D grid of arrow glyphs sampling a vector field — vortex, source, sink, or dipole — making invisible field structure visible
## desire: To reveal that "field" is not metaphor but a function from space to vectors, sampled and rendered at lattice points
## critical_parameter: field_mode and grid resolution — mode picks the topology, resolution decides whether the structure reads or aliases
## triggers: Coarse grids miss sinks; fine grids reveal dipole fall-off; switching modes shows the same lattice can host very different topologies
## emerges: Singular points (sources, sinks, saddles) become visible as places where arrows organize, even though the rendering is just sampling
## needs: ImmediateMesh arrow rendering [has], multiple field modes [has], grid config for mode/resolution [has]
## relationships: Companion to example_2_9_n_body in forces/N-Body_and_Chaos — field view of attraction. Echo of forces themselves as space-valued functions
## truth: A vector field is the rule that decides which way to go from where you are — and the visualization is the shape of that rule made standing-still.

# --- Configuration ---

@export var grid_x: int = 8
@export var grid_y: int = 4
@export var grid_z: int = 8
@export var grid_spacing: float = 0.12
@export var arrow_scale: float = 0.04
@export var field_mode: int = 0  # 0=vortex, 1=source, 2=sink, 3=dipole

# --- Internal ---

var _field_mesh: MeshInstance3D
var _title_label: Label3D
var _mode_label: Label3D
var _info_label: Label3D

const MODE_NAMES := ["VORTEX", "SOURCE", "SINK", "DIPOLE"]
const MODE_COUNT := 4


func _ready() -> void:
	_build_field()
	_build_labels()


func _build_field() -> void:
	_field_mesh = MeshInstance3D.new()
	_field_mesh.name = "FieldMesh"

	var mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_field_mesh.material_override = mat

	_rebuild_arrows()
	add_child(_field_mesh)


func _rebuild_arrows() -> void:
	var mesh = ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	var half_x = (grid_x - 1) * grid_spacing * 0.5
	var half_z = (grid_z - 1) * grid_spacing * 0.5
	var y_base = 0.1

	for ix in range(grid_x):
		for iy in range(grid_y):
			for iz in range(grid_z):
				var pos = Vector3(
					ix * grid_spacing - half_x,
					iy * grid_spacing + y_base,
					iz * grid_spacing - half_z
				)

				var field_vec = _evaluate_field(pos)
				var mag = field_vec.length()

				if mag < 0.001:
					continue

				var dir = field_vec.normalized()
				var display_length = clampf(mag * arrow_scale, 0.005, grid_spacing * 0.45)
				var color = _magnitude_to_color(mag)

				_draw_arrow(mesh, pos, dir, display_length, color)

	mesh.surface_end()
	_field_mesh.mesh = mesh


func _evaluate_field(pos: Vector3) -> Vector3:
	match field_mode:
		0:  # Vortex — F(x,z) = (-z, 0, x) normalized, with falloff
			return _field_vortex(pos)
		1:  # Source — radial outward from center
			return _field_source(pos)
		2:  # Sink — radial inward toward center
			return _field_sink(pos)
		3:  # Dipole — two opposite charges
			return _field_dipole(pos)
		_:
			return _field_vortex(pos)


func _field_vortex(pos: Vector3) -> Vector3:
	# Vortex around Y axis: tangential flow
	var r = Vector2(pos.x, pos.z).length()
	if r < 0.01:
		return Vector3.ZERO
	var strength = 1.0 / (0.3 + r)
	return Vector3(-pos.z, 0.0, pos.x).normalized() * strength


func _field_source(pos: Vector3) -> Vector3:
	# Radial outward from origin
	var center = Vector3(0, 0.3, 0)
	var diff = pos - center
	var r = diff.length()
	if r < 0.01:
		return Vector3.ZERO
	var strength = 1.0 / (0.2 + r * r)
	return diff.normalized() * strength


func _field_sink(pos: Vector3) -> Vector3:
	# Radial inward toward origin
	return -_field_source(pos)


func _field_dipole(pos: Vector3) -> Vector3:
	# Two charges: +1 at (0.2, 0.3, 0), -1 at (-0.2, 0.3, 0)
	var p_pos = Vector3(0.2, 0.3, 0.0)
	var p_neg = Vector3(-0.2, 0.3, 0.0)

	var diff_pos = pos - p_pos
	var diff_neg = pos - p_neg
	var r_pos = diff_pos.length()
	var r_neg = diff_neg.length()

	var field = Vector3.ZERO
	if r_pos > 0.05:
		field += diff_pos.normalized() / (0.1 + r_pos * r_pos)
	if r_neg > 0.05:
		field -= diff_neg.normalized() / (0.1 + r_neg * r_neg)

	return field


func _magnitude_to_color(mag: float) -> Color:
	# Blue (slow) -> cyan -> green -> yellow -> red (fast)
	var t = clampf(mag * 0.8, 0.0, 1.0)
	if t < 0.25:
		var s = t / 0.25
		return Color(0.1, 0.2 + 0.3 * s, 0.8 + 0.2 * s)  # dark blue -> cyan
	elif t < 0.5:
		var s = (t - 0.25) / 0.25
		return Color(0.1 + 0.2 * s, 0.5 + 0.4 * s, 1.0 - 0.5 * s)  # cyan -> green
	elif t < 0.75:
		var s = (t - 0.5) / 0.25
		return Color(0.3 + 0.7 * s, 0.9 - 0.1 * s, 0.5 - 0.4 * s)  # green -> yellow/orange
	else:
		var s = (t - 0.75) / 0.25
		return Color(1.0, 0.8 - 0.6 * s, 0.1 - 0.1 * s)  # orange -> red


func _draw_arrow(mesh: ImmediateMesh, origin: Vector3, dir: Vector3, length: float, color: Color) -> void:
	var tip = origin + dir * length
	var head_len = length * 0.3
	var head_width = length * 0.2

	# Find perpendicular vectors for arrowhead
	var perp = Vector3.UP
	if absf(dir.dot(Vector3.UP)) > 0.95:
		perp = Vector3.RIGHT
	var side = dir.cross(perp).normalized()

	# Shaft
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(origin)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(tip)

	# Arrowhead line 1
	var head_base = tip - dir * head_len
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(tip)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(head_base + side * head_width)

	# Arrowhead line 2
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(tip)
	mesh.surface_set_color(color)
	mesh.surface_add_vertex(head_base - side * head_width)


func _build_labels() -> void:
	var total_height = (grid_y - 1) * grid_spacing + 0.1

	# Title
	_title_label = Label3D.new()
	_title_label.name = "TitleLabel"
	_title_label.text = "VECTOR FIELD"
	_title_label.font_size = 32
	_title_label.pixel_size = 0.001
	_title_label.position = Vector3(0, total_height + 0.15, 0)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_title_label.modulate = Color(0.9, 0.95, 1.0)
	_title_label.outline_size = 5
	add_child(_title_label)

	# Mode label
	_mode_label = Label3D.new()
	_mode_label.name = "ModeLabel"
	_mode_label.text = "Mode: %s" % MODE_NAMES[field_mode]
	_mode_label.font_size = 22
	_mode_label.pixel_size = 0.001
	_mode_label.position = Vector3(0, total_height + 0.08, 0)
	_mode_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_mode_label.modulate = Color(0.7, 0.85, 0.95)
	_mode_label.outline_size = 3
	add_child(_mode_label)

	# Info label — field equation
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.text = _get_field_equation()
	_info_label.font_size = 16
	_info_label.pixel_size = 0.001
	_info_label.position = Vector3(0, -0.05, 0)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_info_label.modulate = Color(0.6, 0.7, 0.8, 0.8)
	_info_label.outline_size = 2
	add_child(_info_label)


func _get_field_equation() -> String:
	match field_mode:
		0: return "F(x,z) = (-z, 0, x) / (0.3 + r)"
		1: return "F = r / (0.2 + |r|^2)"
		2: return "F = -r / (0.2 + |r|^2)"
		3: return "F = sum of +/- charges"
		_: return ""


func set_field_mode(mode: int) -> void:
	field_mode = clampi(mode, 0, MODE_COUNT - 1)
	_rebuild_arrows()
	if _mode_label:
		_mode_label.text = "Mode: %s" % MODE_NAMES[field_mode]
	if _info_label:
		_info_label.text = _get_field_equation()


## Grid system integration — accept configuration from map data.
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("field_mode"):
		field_mode = clampi(int(config_data["field_mode"]), 0, MODE_COUNT - 1)
	if config_data.has("grid_spacing"):
		grid_spacing = float(config_data["grid_spacing"])
	if config_data.has("arrow_scale"):
		arrow_scale = float(config_data["arrow_scale"])
