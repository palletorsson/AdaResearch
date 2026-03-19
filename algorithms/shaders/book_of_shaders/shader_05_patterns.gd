# Shader 05: Patterns — tiles, truchet, Wang tiles, Voronoi, noise synthesis
# Elevated: 3 modes, VR controls, apply_grid_config

# @identity
# essence: tile_uv = fract(uv * grid) — one function definition, infinite instantiation; three modes cover classic tiling, Wang+Voronoi aperiodic patterns, and noise synthesis
# desire: to press the Mode button and cycle from bricks to Voronoi to domain warp — to see the same UV space fold through radically different logics
# critical_parameter: grid_size — the integer that multiplies space, turning one tile into a field
# triggers: mode button cycles CLASSIC/WANG_VORONOI/NOISE; reset rebuilds current mode; aperiodic_mix slider interpolates between periodic and aperiodic Wang tiling
# emerges: Truchet tiles from random corner flips produce labyrinths no one designed; Voronoi edge mode (F2-F1) reveals crackle patterns — structure defined entirely by boundaries
# needs: [has] push_button for Mode and Reset; [has] ShaderRackPanel sliders per display
# relationships: synthesizes shader_01 through shader_04; gateway to shader_08_cellularnoise (Voronoi) and PatternGeneration_Wang_Tiles (aperiodic theory)
# truth: fract() does not copy — it folds space; the pattern was always there, the function just reveals where the seams are

extends Node3D

enum Mode { CLASSIC, WANG_VORONOI, NOISE }

const SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")

const MODE_NAMES := ["Classic Patterns", "Wang + Voronoi", "Noise Synthesis"]

const DISPLAY_SIZE := Vector3(2.0, 2.0, 0.05)
const DISPLAY_GAP := 2.8
const PANEL_OFFSET_Z := 1.2

# ─── Mode state ───
var _mode: int = Mode.CLASSIC

# ─── Classic mode data ───
var _classic_defs := [
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_tile.gdshader",
		"title": "Tiling",
		"code": "vec2 tile_uv = fract(uv * grid);",
		"sliders": [["Grid Size", 1.0, 20.0, 5.0, 1.0], ["Shape Size", 0.1, 0.5, 0.3, 0.01], ["Animate", 0.0, 1.0, 0.0, 1.0]],
		"uniforms": ["grid_size", "shape_size", "animate"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_truchet.gdshader",
		"title": "Truchet",
		"code": "arc from random corner flip",
		"sliders": [["Grid", 2.0, 20.0, 8.0, 1.0], ["Thickness", 0.01, 0.2, 0.08, 0.01], ["Seed", 0.0, 100.0, 42.0, 1.0]],
		"uniforms": ["grid_size", "line_thickness", "seed"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_offset.gdshader",
		"title": "Offset Rows",
		"code": "uv.x += mod(row, 2.0) * 0.5;",
		"sliders": [["Grid", 2.0, 16.0, 6.0, 1.0], ["Offset", 0.0, 0.5, 0.5, 0.01], ["Dot Size", 0.05, 0.45, 0.25, 0.01]],
		"uniforms": ["grid_size", "offset_amount", "dot_size"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_brick.gdshader",
		"title": "Brick",
		"code": "offset row + mortar gap",
		"sliders": [["Rows", 2.0, 20.0, 8.0, 1.0], ["Cols", 1.0, 10.0, 4.0, 0.5], ["Mortar", 0.01, 0.1, 0.04, 0.005]],
		"uniforms": ["rows", "cols", "mortar"]
	}
]

# ─── Wang + Voronoi mode data ───
var _wang_voronoi_defs := [
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_wang.gdshader",
		"title": "Wang Tiles",
		"code": "edge-matched aperiodic tiling",
		"sliders": [["Grid", 2.0, 24.0, 10.0, 1.0], ["Edge Width", 0.02, 0.25, 0.12, 0.01], ["Seed", 0.0, 100.0, 7.0, 1.0], ["Aperiodic", 0.0, 1.0, 1.0, 0.01]],
		"uniforms": ["grid_size", "edge_width", "seed", "aperiodic_mix"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_voronoi.gdshader",
		"title": "Voronoi Cells",
		"code": "min distance to random seeds",
		"sliders": [["Grid", 2.0, 16.0, 6.0, 1.0], ["Jitter", 0.0, 1.0, 0.85, 0.01], ["Display", 0.0, 3.0, 0.0, 1.0], ["Seed", 0.0, 100.0, 13.0, 1.0]],
		"uniforms": ["grid_size", "jitter", "display_mode", "seed"]
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_voronoi.gdshader",
		"title": "Voronoi Edges",
		"code": "second_dist - min_dist → cracks",
		"sliders": [["Grid", 2.0, 16.0, 8.0, 1.0], ["Jitter", 0.0, 1.0, 0.9, 0.01], ["Display", 0.0, 3.0, 2.0, 1.0], ["Seed", 0.0, 100.0, 31.0, 1.0]],
		"uniforms": ["grid_size", "jitter", "display_mode", "seed"]
	}
]

# ─── Noise mode data ───
var _noise_defs := [
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_noise.gdshader",
		"title": "Simplex FBM",
		"code": "sum(amp * simplex(freq * p))",
		"sliders": [["Scale", 1.0, 20.0, 6.0, 0.5], ["Octaves", 1.0, 8.0, 4.0, 1.0], ["Lacunarity", 1.5, 3.0, 2.0, 0.1]],
		"uniforms": ["noise_scale", "octaves_float", "lacunarity"],
		"extra_uniforms": {"noise_type": 0.0}
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_noise.gdshader",
		"title": "Worley Cells",
		"code": "min dist to cell points → organic",
		"sliders": [["Scale", 1.0, 20.0, 5.0, 0.5], ["Octaves", 1.0, 8.0, 3.0, 1.0], ["Lacunarity", 1.5, 3.0, 2.0, 0.1]],
		"uniforms": ["noise_scale", "octaves_float", "lacunarity"],
		"extra_uniforms": {"noise_type": 1.0}
	},
	{
		"shader": "res://algorithms/shaders/book_of_shaders/patterns_noise.gdshader",
		"title": "Domain Warp",
		"code": "simplex(uv + 4*simplex(uv)) → marble",
		"sliders": [["Scale", 1.0, 20.0, 4.0, 0.5], ["Octaves", 1.0, 8.0, 4.0, 1.0], ["Lacunarity", 1.5, 3.0, 2.0, 0.1]],
		"uniforms": ["noise_scale", "octaves_float", "lacunarity"],
		"extra_uniforms": {"noise_type": 2.0}
	}
]

# ─── Runtime arrays ───
var _panels: Array = []
var _materials: Array[ShaderMaterial] = []
var _displays: Array[MeshInstance3D] = []
var _titles: Array[Label3D] = []

# ─── Labels ───
var _label_mode: Label3D

# ─── VR Controls ───
var _btn_mode: Node
var _btn_reset: Node

# ─── Colors ───
const COL_TITLE = Color(0.7, 0.85, 1.0)
const COL_LABEL = Color(0.9, 0.9, 0.95)


func _ready() -> void:
	_create_labels()
	_create_controls()
	_build_mode()


func _process(_delta: float) -> void:
	_sync_sliders()


# ─── Labels ───

func _create_labels() -> void:
	_label_mode = Label3D.new()
	_label_mode.font_size = 42
	_label_mode.position = Vector3(0, 3.2, 0)
	_label_mode.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label_mode.modulate = COL_TITLE
	_label_mode.outline_size = 8
	_label_mode.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(_label_mode)


# ─── VR Controls ───

func _create_controls() -> void:
	# Mode button — left side
	_btn_mode = ButtonScene.instantiate()
	_btn_mode.position = Vector3(-3.5, 0.4, PANEL_OFFSET_Z)
	_btn_mode.scale = Vector3(0.25, 0.25, 0.25)
	add_child(_btn_mode)
	var mode_label = _btn_mode.get_node_or_null("Frame/LabelName")
	if mode_label:
		mode_label.text = "Mode"
	var mode_area = _btn_mode.get_node_or_null("InteractableAreaButton")
	if mode_area:
		mode_area.button_pressed.connect(_on_mode_pressed)

	# Reset button — below mode
	_btn_reset = ButtonScene.instantiate()
	_btn_reset.position = Vector3(-3.5, 0.15, PANEL_OFFSET_Z)
	_btn_reset.scale = Vector3(0.25, 0.25, 0.25)
	add_child(_btn_reset)
	var reset_label = _btn_reset.get_node_or_null("Frame/LabelName")
	if reset_label:
		reset_label.text = "Reset"
	var reset_area = _btn_reset.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(_on_reset_pressed)


func _on_mode_pressed() -> void:
	_mode = (_mode + 1) % 3
	_build_mode()


func _on_reset_pressed() -> void:
	_build_mode()


# ─── Mode building ───

func _get_defs() -> Array:
	match _mode:
		Mode.CLASSIC:
			return _classic_defs
		Mode.WANG_VORONOI:
			return _wang_voronoi_defs
		Mode.NOISE:
			return _noise_defs
	return _classic_defs


func _build_mode() -> void:
	# Clear previous displays
	_clear_displays()

	var defs := _get_defs()
	_label_mode.text = MODE_NAMES[_mode]

	var start_x := -(float(defs.size()) - 1.0) * DISPLAY_GAP * 0.5
	for i in range(defs.size()):
		var def: Dictionary = defs[i]
		var x_pos := start_x + float(i) * DISPLAY_GAP

		# Shader display quad
		var display := MeshInstance3D.new()
		display.name = "Display_%d" % i
		var box := BoxMesh.new()
		box.size = DISPLAY_SIZE
		display.mesh = box
		var mat := ShaderMaterial.new()
		mat.shader = load(def["shader"])
		# Set extra uniforms if defined (for noise type selection)
		if def.has("extra_uniforms"):
			for key in def["extra_uniforms"]:
				mat.set_shader_parameter(key, def["extra_uniforms"][key])
		display.material_override = mat
		display.position = Vector3(x_pos, 1.5, 0.0)
		add_child(display)
		_displays.append(display)
		_materials.append(mat)

		# Title label
		var title := Label3D.new()
		title.text = def["title"]
		title.font_size = 18
		title.pixel_size = 0.001
		title.modulate = COL_LABEL
		title.position = Vector3(x_pos, 2.7, 0.01)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(title)
		_titles.append(title)

		# Code snippet label
		var code_label := Label3D.new()
		code_label.text = def["code"]
		code_label.font_size = 14
		code_label.pixel_size = 0.001
		code_label.modulate = Color(0.6, 0.8, 0.6)
		code_label.position = Vector3(x_pos, 0.3, 0.01)
		code_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		add_child(code_label)
		_titles.append(code_label)

		# Slider panel
		var slider_count: int = def["sliders"].size()
		var panel := ShaderRackPanel.new()
		panel.setup(def["title"], mini(slider_count, 2), maxi(3, ceili(float(slider_count) / 2.0) + 2))
		panel.set_code_snippet("")  # code shown separately above
		for s in def["sliders"]:
			panel.add_slider(s[0], s[1], s[2], s[3], s[4])
		panel.position = Vector3(x_pos, 0.5, PANEL_OFFSET_Z)
		panel.rotation_degrees = Vector3(-15, 0, 0)
		add_child(panel)
		_panels.append(panel)


func _clear_displays() -> void:
	for d in _displays:
		if is_instance_valid(d):
			d.queue_free()
	_displays.clear()
	_materials.clear()
	for t in _titles:
		if is_instance_valid(t):
			t.queue_free()
	_titles.clear()
	for p in _panels:
		if is_instance_valid(p):
			p.queue_free()
	_panels.clear()


func _sync_sliders() -> void:
	var defs := _get_defs()
	for i in range(_panels.size()):
		if i >= _materials.size() or i >= defs.size():
			break
		var mat: ShaderMaterial = _materials[i]
		var panel = _panels[i]
		var uniforms: Array = defs[i]["uniforms"]
		for j in range(uniforms.size()):
			mat.set_shader_parameter(uniforms[j], panel.get_slider_value(j))


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


# ─── apply_grid_config ───

func apply_grid_config(config: Dictionary) -> void:
	if config.has("mode"):
		var m := str(config["mode"]).to_upper()
		match m:
			"CLASSIC": _mode = Mode.CLASSIC
			"WANG_VORONOI", "WANG": _mode = Mode.WANG_VORONOI
			"NOISE": _mode = Mode.NOISE
	if config.has("display_gap"):
		# Can't reassign const, but future-proof the config interface
		pass
	_build_mode()
