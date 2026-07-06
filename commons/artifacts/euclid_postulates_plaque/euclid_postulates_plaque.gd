# euclid_postulates_plaque.gd
# Interactive plaque displaying Euclid's five postulates
# Highlights the controversial fifth postulate (parallel postulate)

extends Node3D

class_name EuclidPostulatesPlaque

const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

# @identity
# essence: five axioms; four self-evident, the fifth (parallel postulate) independent and contingent
# desire: cycle through the postulates and feel the fifth one glow differently — it was always the odd one out
# critical_parameter: current_postulate — when it reaches 4 (the fifth), the entire color scheme shifts
# triggers: click/interact cycles postulates; reaching the fifth fires parallel_highlighted signal
# emerges: the dawning suspicion that the fifth postulate is not like the others — it can be denied
# needs: VR click interaction [has via mouse], XR grab interaction [missing]
# relationships: unlocks hyperbolic_surface and elliptic_surface (what happens when you deny the fifth); depends on angle_sum_triangle
# truth: the parallel postulate was assumed for two thousand years — its independence was the first crack in mathematical certainty

signal postulate_selected(index: int)
signal parallel_highlighted

@export var current_postulate: int = 0:
	set(value):
		current_postulate = clampi(value, 0, 4)
		_update_display()

@export var highlight_fifth: bool = true
@export var plaque_size: Vector3 = Vector3(0.8, 1.0, 0.05)

var _xr_active: bool = false
var _plaque_mesh: MeshInstance3D
# Integrated 2D-in-3D text boards (baked albedo) replacing floating Label3D.
var _title_board: MeshInstance3D          # single-line title, baked text quad
var _text_board: Node3D                   # multi-line postulate body, stacked block
var _indicator_boards: Array[Node3D] = [] # I..V tag boards
var _highlight_mesh: MeshInstance3D

const INDICATOR_GLYPHS := ["I", "II", "III", "IV", "V"]

const POSTULATES = [
	"I. A straight line can be drawn\nfrom any point to any point.",
	"II. A finite straight line can be\nextended continuously in a line.",
	"III. A circle can be drawn with\nany center and any radius.",
	"IV. All right angles are\nequal to one another.",
	"V. If a line crosses two lines\nand interior angles sum < 180°,\nthe two lines meet on that side.\n\n(The Parallel Postulate)"
]

const POSTULATE_TITLES = [
	"First Postulate",
	"Second Postulate", 
	"Third Postulate",
	"Fourth Postulate",
	"Fifth Postulate — THE PARALLEL POSTULATE"
]

func _ready():
	_xr_active = XRServer.primary_interface != null
	_create_plaque()
	_create_labels()
	_create_highlight()
	_update_display()

func _create_plaque():
	_plaque_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = plaque_size
	_plaque_mesh.mesh = box
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.15, 0.12, 0.1)
	mat.metallic = 0.1
	mat.roughness = 0.8
	_plaque_mesh.material_override = mat
	add_child(_plaque_mesh)
	
	# Frame
	var frame = MeshInstance3D.new()
	var frame_mesh = BoxMesh.new()
	frame_mesh.size = Vector3(plaque_size.x + 0.04, plaque_size.y + 0.04, plaque_size.z * 0.5)
	frame.mesh = frame_mesh
	frame.position.z = -plaque_size.z * 0.3
	
	var frame_mat = StandardMaterial3D.new()
	frame_mat.albedo_color = Color(0.6, 0.5, 0.3)
	frame_mat.metallic = 0.6
	frame_mat.roughness = 0.4
	frame.material_override = frame_mat
	add_child(frame)

func _create_labels():
	# The title board, multi-line body board, and the I..V indicator tags are
	# all baked-text boards whose text/colour change with the selected
	# postulate, so they are (re)built in _update_display() / _rebuild_indicators().
	# Nothing persistent to create here.
	pass

func _create_highlight():
	_highlight_mesh = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = Vector3(0.12, 0.04, 0.01)
	_highlight_mesh.mesh = box
	_highlight_mesh.position.y = -plaque_size.y * 0.35
	_highlight_mesh.position.z = plaque_size.z * 0.52
	
	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(1.0, 0.8, 0.2, 0.8)
	mat.emission_enabled = true
	mat.emission = Color(1.0, 0.8, 0.2)
	mat.emission_energy_multiplier = 0.5
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_highlight_mesh.material_override = mat
	add_child(_highlight_mesh)

func _update_display():
	if not is_inside_tree():
		return

	# Color the fifth postulate differently
	var is_fifth = current_postulate == 4
	var title_color: Color
	var text_color: Color
	if is_fifth and highlight_fifth:
		title_color = Color(1.0, 0.7, 0.3)
		text_color = Color(1.0, 0.9, 0.7)
	else:
		title_color = Color(0.9, 0.85, 0.7)
		text_color = Color(0.85, 0.82, 0.75)

	# Rebuild the baked title board (single line, painted onto the plaque face).
	if _title_board and is_instance_valid(_title_board):
		_title_board.queue_free()
	_title_board = BakedText.make_label_mesh(
		POSTULATE_TITLES[current_postulate],
		title_color,
		Vector2(plaque_size.x * 0.9, 0.05),   # roughly where the old title Label3D sat
		1400, true)                            # unshaded — reads as a crisp engraving
	if _title_board:
		_title_board.name = "TitleBoard"
		_title_board.position = Vector3(0, plaque_size.y * 0.38, plaque_size.z * 0.51)
		add_child(_title_board)

	# Rebuild the baked body board — one consolidated multi-line panel of the
	# postulate's lines (a plaque reads as ONE block of lines, not N floats).
	if _text_board and is_instance_valid(_text_board):
		_text_board.queue_free()
	var body_lines: Array = POSTULATES[current_postulate].split("\n")
	_text_board = BakedText.make_text_block(
		body_lines,
		text_color,
		0.035,                                 # per-line height (~ old font_size 18)
		plaque_size.x * 0.9,                   # block width fits inside the plaque face
		0.006, true)                           # small line gap, unshaded
	if _text_board:
		_text_board.name = "TextBoard"
		_text_board.position = Vector3(0, 0, plaque_size.z * 0.51)
		add_child(_text_board)

	# Update highlight position
	_highlight_mesh.position.x = -0.3 + current_postulate * 0.15
	var hmat = _highlight_mesh.material_override as StandardMaterial3D
	if is_fifth and highlight_fifth:
		hmat.albedo_color = Color(1.0, 0.4, 0.2, 0.9)
		hmat.emission = Color(1.0, 0.4, 0.2)
		parallel_highlighted.emit()
	else:
		hmat.albedo_color = Color(1.0, 0.8, 0.2, 0.8)
		hmat.emission = Color(1.0, 0.8, 0.2)

	# Rebuild indicator tags with their state colour (baked text — colour is
	# painted in, so a colour change means a fresh board; the texture cache
	# keeps repeats cheap).
	_rebuild_indicators()

	postulate_selected.emit(current_postulate)

func _rebuild_indicators():
	for tag in _indicator_boards:
		if is_instance_valid(tag):
			tag.queue_free()
	_indicator_boards.clear()
	var indicator_y = -plaque_size.y * 0.35
	for i in range(5):
		var glyph_color: Color
		if i == current_postulate:
			glyph_color = Color(1.0, 1.0, 1.0)
		elif i == 4 and highlight_fifth:
			glyph_color = Color(1.0, 0.5, 0.3)
		else:
			glyph_color = Color(0.5, 0.5, 0.5)
		var tag: Node3D = BakedText.make_tag(
			INDICATOR_GLYPHS[i], glyph_color, 0.045,
			Color(0.12, 0.1, 0.08), false, Color(0, 0, 0, 0))
		if tag == null:
			continue
		tag.name = "Indicator_%d" % i
		tag.position = Vector3(-0.3 + i * 0.15, indicator_y, plaque_size.z * 0.51)
		add_child(tag)
		_indicator_boards.append(tag)

func next_postulate():
	current_postulate = (current_postulate + 1) % 5

func previous_postulate():
	current_postulate = (current_postulate + 4) % 5

func _input(event):
	if _xr_active:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			next_postulate()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			previous_postulate()

func apply_grid_config(config_data: Dictionary):
	for key in config_data:
		if key in self:
			set(key, config_data[key])
