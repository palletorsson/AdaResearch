# form_studio_station.gd
# In-VR Form Studio. A single pedestal with the live body in the middle,
# a row of push-buttons for picking which form to inspect, and a column
# of horizontal sliders for editing the form's DNA genes in real time.
# Matches the web /form-studio but runs natively inside an Ada map.
#
# Usage: drop artifact `form_studio_station` into any map's interactables
# layer. No DNA config required — all data lives in the script.

extends Node3D

const FlowerBody    = preload("res://commons/morphology/sdf/flower_body.gd")
const FungusBody    = preload("res://commons/morphology/sdf/fungus_body.gd")
const WalkerBody    = preload("res://commons/morphology/sdf/walker_body.gd")
const TreeBody      = preload("res://commons/morphology/sdf/tree_body.gd")
const ModulorWalker = preload("res://commons/morphology/sdf/modulor_walker.gd")
const ColumnRecipe  = preload("res://commons/morphology/objects/classical/column.gd")
const PedestalRecipe = preload("res://commons/morphology/objects/classical/pedestal.gd")
const AmphoraRecipe = preload("res://commons/morphology/objects/classical/amphora.gd")
const RuinWallRecipe = preload("res://commons/morphology/objects/classical/ruin_wall.gd")
const GraphTreeBody  = preload("res://commons/morphology/graph/graph_tree_body.gd")
const RhizomeBody    = preload("res://commons/morphology/graph/rhizome_body.gd")
const KochCurveBody  = preload("res://commons/morphology/fractals/koch_curve_body.gd")
const SierpinskiBody = preload("res://commons/morphology/fractals/sierpinski_body.gd")
const KleinBottleBody = preload("res://commons/morphology/parametric/klein_bottle_body.gd")
const MobiusStripBody = preload("res://commons/morphology/parametric/mobius_strip_body.gd")
const SupershapeBody  = preload("res://commons/morphology/parametric/supershape_body.gd")

const SHADER_PLANT = preload("res://commons/morphology/sdf/shaders/plant.gdshader")
const SHADER_FLESH = preload("res://commons/morphology/sdf/shaders/flesh.gdshader")
const SHADER_BARK  = preload("res://commons/morphology/sdf/shaders/bark.gdshader")

const SLIDER_SCENE = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON  = preload("res://commons/interactables/push_button.tscn")

const PEDESTAL_HEIGHT: float = 0.4
const MAX_SLIDERS: int = 4


# ─── Form catalog ────────────────────────────────────────────
# Each entry: defaults, slider specs, recipe, materials key.

class FormDef:
	var id: String
	var label: String
	var recipe
	var materials_key: String
	var defaults: Dictionary
	var sliders: Array  # [{name, key, min, max, step}]

	func _init(_id, _label, _recipe, _mat, _def, _sl):
		id = _id; label = _label; recipe = _recipe
		materials_key = _mat; defaults = _def; sliders = _sl


var _forms: Array = []
var _current_idx: int = 0
var _current_dna: Dictionary = {}
var _current_body: Node3D = null
var _sliders: Array = []  # slider Node3Ds, length MAX_SLIDERS
var _buttons: Array = []  # button Node3Ds
var _readout_label: Label3D = null
var _title_label: Label3D = null


func _ready() -> void:
	_populate_forms()
	_build_pedestal()
	_build_title_label()
	_build_buttons()
	_build_sliders()
	_build_readout()
	_select_form(0)


func _populate_forms() -> void:
	_forms = [
		FormDef.new("flower", "Flower", FlowerBody, "flower",
			{"scale": 0.8, "segments": 4.0, "symmetry": 6.0, "pattern_scale": 1.0},
			[
				{"name": "scale",    "key": "scale",         "min": 0.3, "max": 1.4},
				{"name": "segments", "key": "segments",      "min": 1.0, "max": 8.0},
				{"name": "petals",   "key": "symmetry",      "min": 3.0, "max": 12.0},
				{"name": "pattern",  "key": "pattern_scale", "min": 0.3, "max": 1.8},
			]),
		FormDef.new("fungus", "Fungus", FungusBody, "fungus",
			{"scale": 0.8, "segments": 4.0, "symmetry": 6.0},
			[
				{"name": "scale",    "key": "scale",    "min": 0.3, "max": 1.4},
				{"name": "segments", "key": "segments", "min": 1.0, "max": 8.0},
				{"name": "symmetry", "key": "symmetry", "min": 3.0, "max": 12.0},
			]),
		FormDef.new("walker", "Walker", WalkerBody, "walker",
			{"scale": 0.8, "segments": 4.0, "symmetry": 2.0},
			[
				{"name": "scale",    "key": "scale",    "min": 0.3, "max": 1.4},
				{"name": "legs",     "key": "segments", "min": 2.0, "max": 8.0},
				{"name": "symmetry", "key": "symmetry", "min": 2.0, "max": 6.0},
			]),
		FormDef.new("tree", "Tree", TreeBody, "tree",
			{"scale": 1.0, "segments": 4.0, "symmetry": 5.0},
			[
				{"name": "scale",    "key": "scale",    "min": 0.4, "max": 1.6},
				{"name": "segments", "key": "segments", "min": 2.0, "max": 8.0},
				{"name": "branches", "key": "symmetry", "min": 3.0, "max": 8.0},
			]),
		FormDef.new("modulor", "Modulor", ModulorWalker, "walker",
			{"scale": 1.0, "segments": 4.0, "symmetry": 2.0, "ladder_offset": 0.0},
			[
				{"name": "rung",  "key": "ladder_offset", "min": 0.0, "max": 6.0},
				{"name": "scale", "key": "scale",         "min": 0.6, "max": 1.4},
			]),
		FormDef.new("column", "Column", ColumnRecipe, "stone",
			{"height": 2.26, "shaft_radius": 0.18},
			[
				{"name": "height", "key": "height",       "min": 1.0,  "max": 4.0},
				{"name": "radius", "key": "shaft_radius", "min": 0.08, "max": 0.35},
			]),
		FormDef.new("pedestal", "Pedestal", PedestalRecipe, "stone",
			{"height": 1.13, "width": 0.53, "depth": 0.53},
			[
				{"name": "height", "key": "height", "min": 0.4, "max": 2.2},
				{"name": "width",  "key": "width",  "min": 0.3, "max": 1.2},
				{"name": "depth",  "key": "depth",  "min": 0.3, "max": 1.2},
			]),
		FormDef.new("amphora", "Amphora", AmphoraRecipe, "ceramic",
			{"height": 0.7, "belly_width": 0.4, "neck_ratio": 0.35},
			[
				{"name": "height", "key": "height",      "min": 0.3, "max": 1.2},
				{"name": "belly",  "key": "belly_width", "min": 0.2, "max": 0.7},
				{"name": "neck",   "key": "neck_ratio",  "min": 0.2, "max": 0.6},
			]),
		FormDef.new("ruin", "Ruin wall", RuinWallRecipe, "stone",
			{"length": 2.0, "height": 1.4, "jaggedness": 0.7, "rubble_count": 4.0},
			[
				{"name": "length",     "key": "length",       "min": 1.0, "max": 4.0},
				{"name": "height",     "key": "height",       "min": 0.6, "max": 2.5},
				{"name": "jaggedness", "key": "jaggedness",   "min": 0.0, "max": 1.0},
				{"name": "rubble",     "key": "rubble_count", "min": 0.0, "max": 10.0},
			]),
		FormDef.new("graph_tree", "Graph Tree", GraphTreeBody, "tree",
			{"trunk_length": 1.5, "branch_count": 3.0, "depth": 4.0, "length_decay": 0.65,
			 "angle_spread": 45.0, "radius_base": 0.18, "radius_decay": 0.62, "jitter": 0.25, "seed": 7.0},
			[
				{"name": "branch", "key": "branch_count", "min": 1.0, "max": 6.0},
				{"name": "depth",  "key": "depth",        "min": 1.0, "max": 5.0},
				{"name": "spread", "key": "angle_spread", "min": 10.0, "max": 80.0},
				{"name": "seed",   "key": "seed",         "min": 0.0, "max": 99.0},
			]),
		FormDef.new("rhizome", "Rhizome", RhizomeBody, "tree",
			{"max_depth": 40.0, "step_length": 0.5, "variance": 0.3, "radius": 0.06, "seed": 11.0},
			[
				{"name": "depth",   "key": "max_depth",   "min": 5.0, "max": 80.0},
				{"name": "step",    "key": "step_length", "min": 0.1, "max": 1.5},
				{"name": "variance","key": "variance",    "min": 0.0, "max": 0.8},
				{"name": "seed",    "key": "seed",        "min": 0.0, "max": 99.0},
			]),
		FormDef.new("koch", "Koch Curve", KochCurveBody, "neutral",
			{"depth": 3.0, "length": 2.0, "radius": 0.04},
			[
				{"name": "depth",  "key": "depth",  "min": 1.0, "max": 5.0},
				{"name": "length", "key": "length", "min": 0.5, "max": 4.0},
				{"name": "radius", "key": "radius", "min": 0.01, "max": 0.1},
			]),
		FormDef.new("sierpinski", "Sierpinski", SierpinskiBody, "neutral",
			{"depth": 3.0, "size": 1.0, "radius": 0.02},
			[
				{"name": "depth",  "key": "depth",  "min": 1.0, "max": 4.0},
				{"name": "size",   "key": "size",   "min": 0.5, "max": 2.5},
				{"name": "radius", "key": "radius", "min": 0.005, "max": 0.05},
			]),
		FormDef.new("klein", "Klein", KleinBottleBody, "ceramic",
			{"scale": 0.05, "num_u": 48.0, "num_v": 24.0},
			[
				{"name": "scale", "key": "scale", "min": 0.02, "max": 0.15},
				{"name": "num_u", "key": "num_u", "min": 16.0, "max": 96.0},
				{"name": "num_v", "key": "num_v", "min": 12.0, "max": 48.0},
			]),
		FormDef.new("mobius", "Möbius", MobiusStripBody, "ceramic",
			{"radius": 1.0, "width": 0.3, "twists": 1.0, "segments": 48.0, "w_segments": 8.0},
			[
				{"name": "radius", "key": "radius", "min": 0.3, "max": 2.0},
				{"name": "width",  "key": "width",  "min": 0.1, "max": 0.8},
				{"name": "twists", "key": "twists", "min": 1.0, "max": 7.0},
				{"name": "segs",   "key": "segments", "min": 12.0, "max": 96.0},
			]),
		FormDef.new("supershape", "Supershape", SupershapeBody, "ceramic",
			{"scale": 0.5, "m": 6.0, "n1": 1.0, "n2": 1.0, "n3": 1.0, "num_u": 64.0, "num_v": 32.0},
			[
				{"name": "m",  "key": "m",  "min": 0.0, "max": 16.0},
				{"name": "n1", "key": "n1", "min": 0.1, "max": 4.0},
				{"name": "n2", "key": "n2", "min": 0.1, "max": 4.0},
				{"name": "n3", "key": "n3", "min": 0.1, "max": 4.0},
			]),
	]


# ─── Scaffold ────────────────────────────────────────────────

func _build_pedestal() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.4, PEDESTAL_HEIGHT, 2.4)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.24)
	mat.roughness = 0.9
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3(0, PEDESTAL_HEIGHT * 0.5, 0)
	add_child(mi)


func _build_title_label() -> void:
	_title_label = Label3D.new()
	_title_label.text = "Form Studio"
	_title_label.position = Vector3(0, PEDESTAL_HEIGHT + 2.8, 0)
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.pixel_size = 0.012
	_title_label.modulate = Color(1.0, 0.7, 0.4)
	_title_label.outline_modulate = Color.BLACK
	add_child(_title_label)


## Buttons laid out east of the pedestal in two columns, at eye height.
## Column A = x+1.8, Column B = x+2.5. 8 buttons per column gives room
## for 16 forms with 0.3m vertical spacing.
func _build_buttons() -> void:
	var base_y: float = 1.4
	var base_z: float = -1.2
	var v_spacing: float = 0.3
	var col_a_x: float = 1.8
	var col_b_x: float = 2.5
	var per_col: int = 8
	for i in _forms.size():
		var f: FormDef = _forms[i]
		var col: int = i / per_col
		var row: int = i % per_col
		var x: float = col_a_x if col == 0 else col_b_x
		var btn = PUSH_BUTTON.instantiate()
		btn.position = Vector3(x, base_y, base_z + float(row) * v_spacing)
		add_child(btn)

		# Label to the east of the button
		var lbl := Label3D.new()
		lbl.text = f.label
		lbl.position = btn.position + Vector3(0.22, 0, 0)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.pixel_size = 0.006
		lbl.modulate = Color(0.9, 0.9, 0.95)
		lbl.outline_modulate = Color.BLACK
		add_child(lbl)

		var area := btn.get_node_or_null("InteractableAreaButton")
		if area and area.has_signal("button_pressed"):
			var idx: int = i  # capture
			area.button_pressed.connect(func(_b): _select_form(idx))
		_buttons.append(btn)


## Four sliders stacked vertically south of the pedestal, at waist height.
func _build_sliders() -> void:
	var base_y: float = 1.3
	var base_z: float = -1.6
	var v_spacing: float = 0.22
	for i in MAX_SLIDERS:
		var slider = SLIDER_SCENE.instantiate()
		slider.position = Vector3(0, base_y - float(i) * v_spacing, base_z)
		slider.visible = false
		add_child(slider)
		if slider.has_method("set_range"):
			slider.set_range(0.0, 1.0)
		if slider.has_signal("slider_moved"):
			var idx: int = i
			slider.slider_moved.connect(func(_v): _on_slider_moved(idx))
		_sliders.append(slider)


func _build_readout() -> void:
	_readout_label = Label3D.new()
	_readout_label.text = ""
	_readout_label.position = Vector3(0, PEDESTAL_HEIGHT + 2.35, 0)
	_readout_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout_label.pixel_size = 0.008
	_readout_label.modulate = Color(0.85, 0.9, 1.0)
	_readout_label.outline_modulate = Color.BLACK
	add_child(_readout_label)


# ─── Selection + rebuild ─────────────────────────────────────

func _select_form(idx: int) -> void:
	idx = clampi(idx, 0, _forms.size() - 1)
	_current_idx = idx
	var f: FormDef = _forms[idx]
	_current_dna = f.defaults.duplicate()
	_title_label.text = "Form Studio — %s" % f.label

	# Configure sliders for this form
	for i in MAX_SLIDERS:
		var slider = _sliders[i]
		if i < f.sliders.size():
			var spec: Dictionary = f.sliders[i]
			slider.visible = true
			if slider.has_method("set_range"):
				slider.set_range(spec.min, spec.max)
			# Set normalized to match current DNA default
			var cur: float = float(_current_dna.get(spec.key, spec.min))
			var norm: float = 0.0
			if spec.max > spec.min:
				norm = (cur - spec.min) / (spec.max - spec.min)
			if slider.has_method("set_normalized_value"):
				slider.set_normalized_value(clamp(norm, 0.0, 1.0))
			# Slider face label
			var name_lbl: Label3D = slider.get_node_or_null("Frame/LabelName")
			if name_lbl:
				name_lbl.text = str(spec.name).to_upper()
		else:
			slider.visible = false

	_rebuild_body()


func _on_slider_moved(idx: int) -> void:
	var f: FormDef = _forms[_current_idx]
	if idx >= f.sliders.size(): return
	var spec: Dictionary = f.sliders[idx]
	var slider = _sliders[idx]
	if not slider.has_method("get_normalized_value"): return
	var v: float = slider.get_normalized_value()
	var raw: float = lerp(float(spec.min), float(spec.max), v)
	# Integer genes get rounded
	if _is_integer_gene(spec.key):
		raw = float(int(round(raw)))
	_current_dna[spec.key] = raw
	_rebuild_body()


func _is_integer_gene(key: String) -> bool:
	return key in [
		"segments", "symmetry", "ladder_offset", "rubble_count",
		"depth", "max_depth", "branch_count",
		"twists", "w_segments", "num_u", "num_v",
		"seed",
	]


func _rebuild_body() -> void:
	if _current_body and is_instance_valid(_current_body):
		_current_body.queue_free()
		_current_body = null

	var f: FormDef = _forms[_current_idx]
	var recipe = f.recipe.new()
	recipe.dna = _current_dna
	if "joint_k" in recipe:
		recipe.joint_k = 0.08
	recipe.build()
	var body: Node3D = recipe.build_mesh_body(_materials_for_key(f.materials_key))
	if body:
		body.position = Vector3(0, PEDESTAL_HEIGHT, 0)
		add_child(body)
		_current_body = body

	_update_readout()


func _update_readout() -> void:
	if _readout_label == null: return
	var f: FormDef = _forms[_current_idx]
	var lines: Array[String] = []
	for spec in f.sliders:
		var k: String = spec.key
		var v: float = float(_current_dna.get(k, spec.min))
		if _is_integer_gene(k):
			lines.append("%s: %d" % [spec.name, int(v)])
		else:
			lines.append("%s: %.2f" % [spec.name, v])
	_readout_label.text = "  ".join(lines)


# ─── Materials ───────────────────────────────────────────────

func _materials_for_key(key: String) -> Dictionary:
	match key:
		"flower":  return _flower_materials()
		"fungus":  return _fungus_materials()
		"walker":  return _walker_materials()
		"tree":    return _tree_materials()
		"stone":   return _stone_materials()
		"ceramic": return _ceramic_materials()
		_:         return _neutral_materials()


func _neutral_materials() -> Dictionary:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.88, 0.85, 0.75); m.roughness = 0.6
	return {"default": m, "body": m}

func _stone_materials() -> Dictionary:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.78, 0.76, 0.72); m.roughness = 0.9
	return {"default": m, "body": m,
		"shaft": m, "plinth": m, "capital": m, "abacus": m,
		"base": m, "die": m, "cornice": m,
		"wall_block": m, "rubble": m, "base_course": m}

func _ceramic_materials() -> Dictionary:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.28, 0.18); m.roughness = 0.55; m.metallic = 0.1
	return {"default": m, "body": m,
		"foot": m, "belly": m, "shoulder": m,
		"neck": m, "lip": m, "handle": m}

func _tree_materials() -> Dictionary:
	var bark := ShaderMaterial.new(); bark.shader = SHADER_BARK
	bark.set_shader_parameter("bark_color", Color(0.38, 0.25, 0.17))
	bark.set_shader_parameter("crevice_color", Color(0.12, 0.08, 0.05))
	var leaf := ShaderMaterial.new(); leaf.shader = SHADER_PLANT
	leaf.set_shader_parameter("base_color", Color(0.25, 0.5, 0.2))
	leaf.set_shader_parameter("edge_color", Color(0.8, 0.9, 0.5))
	return {"body": bark, "default": leaf}

func _walker_materials() -> Dictionary:
	var skin := ShaderMaterial.new(); skin.shader = SHADER_FLESH
	skin.set_shader_parameter("skin_color", Color(0.75, 0.62, 0.5))
	skin.set_shader_parameter("interior_color", Color(0.9, 0.4, 0.3))
	return {"default": skin, "body": skin}

func _flower_materials() -> Dictionary:
	var stem := ShaderMaterial.new(); stem.shader = SHADER_PLANT
	stem.set_shader_parameter("base_color", Color(0.25, 0.48, 0.18))
	var leaf := ShaderMaterial.new(); leaf.shader = SHADER_PLANT
	leaf.set_shader_parameter("base_color", Color(0.3, 0.55, 0.2))
	leaf.set_shader_parameter("vein_strength", 0.25)
	var petal := ShaderMaterial.new(); petal.shader = SHADER_PLANT
	petal.set_shader_parameter("base_color", Color(0.95, 0.45, 0.65))
	petal.set_shader_parameter("edge_color", Color(1.0, 0.85, 0.9))
	petal.set_shader_parameter("rim_strength", 1.5)
	var stamen := ShaderMaterial.new(); stamen.shader = SHADER_FLESH
	stamen.set_shader_parameter("skin_color", Color(1.0, 0.85, 0.3))
	stamen.set_shader_parameter("interior_color", Color(1.0, 0.5, 0.1))
	return {"stem": stem, "leaf": leaf, "petal": petal, "stamen": stamen, "default": stem}

func _fungus_materials() -> Dictionary:
	var stem := ShaderMaterial.new(); stem.shader = SHADER_BARK
	stem.set_shader_parameter("bark_color", Color(0.85, 0.78, 0.65))
	stem.set_shader_parameter("crevice_color", Color(0.55, 0.45, 0.35))
	var cap := ShaderMaterial.new(); cap.shader = SHADER_FLESH
	cap.set_shader_parameter("skin_color", Color(0.65, 0.28, 0.25))
	cap.set_shader_parameter("interior_color", Color(0.35, 0.1, 0.08))
	return {"default": stem, "body": stem, "cap": cap}


func apply_grid_config(_config_data: Dictionary) -> void:
	pass
