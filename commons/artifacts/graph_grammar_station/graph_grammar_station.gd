# graph_grammar_station.gd — In-VR live editor for graph grammar presets.
# Push-buttons pick a preset (classic tree, conifer, coral, bristle ball, ...);
# up to four horizontal sliders tune that preset's DNA; the graph rebuilds
# live on the central pedestal with bark + plant shader materials.
#
# Mirrors commons/artifacts/form_studio_station/ but drives the graph
# grammar system (commons/graph_grammar/) instead of the SDF body recipes.

extends Node3D

const GraphStateScript    = preload("res://commons/graph_grammar/graph_state.gd")
const GraphSelectorScript = preload("res://commons/graph_grammar/graph_selector.gd")
const GraphGrammarScript  = preload("res://commons/graph_grammar/graph_grammar.gd")
const GraphToMeshScript   = preload("res://commons/graph_grammar/graph_to_mesh.gd")
const SpawnBranchOpScript = preload("res://commons/graph_grammar/operations/spawn_branch_op.gd")
const SubdivideEdgeOpScript = preload("res://commons/graph_grammar/operations/subdivide_edge_op.gd")
const SpaceColonizeOpScript = preload("res://commons/graph_grammar/operations/space_colonize_op.gd")
const LeafTuftOpScript = preload("res://commons/graph_grammar/operations/leaf_tuft_op.gd")

const SHADER_PLANT = preload("res://commons/morphology/sdf/shaders/plant.gdshader")
const SHADER_BARK  = preload("res://commons/morphology/sdf/shaders/bark.gdshader")

const SLIDER_SCENE = preload("res://commons/interactables/slider_horizontal.tscn")
const PUSH_BUTTON  = preload("res://commons/interactables/push_button.tscn")

const PEDESTAL_HEIGHT: float = 0.4
const MAX_SLIDERS: int = 4


# ─── Preset catalog ──────────────────────────────────────────
# Each preset declares: label, build(dna) -> rules array, default DNA,
# slider specs {name, key, min, max}, and leaf color variant.

class PresetDef:
	var id: String
	var label: String
	var defaults: Dictionary
	var sliders: Array
	var leaf_color: String  # "plant" | "plant_bright" | "plant_red" | "flesh" | ""
	var builder: Callable   # (dna) -> Array of rules

	func _init(_id, _label, _def, _sl, _leaf, _build):
		id = _id; label = _label
		defaults = _def; sliders = _sl
		leaf_color = _leaf; builder = _build


var _presets: Array = []
var _current_idx: int = 0
var _current_dna: Dictionary = {}
var _current_mesh_root: Node3D = null
var _sliders: Array = []
var _buttons: Array = []
var _title_label: Label3D = null
var _readout_label: Label3D = null
var _rebuild_pending: bool = false


func _ready() -> void:
	_populate_presets()
	_build_pedestal()
	_build_title_label()
	_build_readout()
	_build_buttons()
	_build_sliders()
	_select_preset(0)


func _process(_delta: float) -> void:
	if _rebuild_pending:
		_rebuild_pending = false
		_rebuild_graph()


# ─── Presets ────────────────────────────────────────────────

func _populate_presets() -> void:
	_presets = [
		PresetDef.new("tree", "Tree",
			{"count": 3.0, "spread": 35.0, "iterations": 4.0, "radius_decay": 0.65},
			[
				{"name": "branch", "key": "count",        "min": 1.0, "max": 6.0},
				{"name": "spread", "key": "spread",       "min": 10.0, "max": 75.0},
				{"name": "depth",  "key": "iterations",   "min": 2.0, "max": 6.0},
				{"name": "decay",  "key": "radius_decay", "min": 0.4, "max": 0.85},
			],
			"plant",
			func(dna): return [
				SpawnBranchOpScript.new(GraphSelectorScript.leaves(), {
					"count": int(dna.count), "length": 0.9,
					"spread_deg": dna.spread, "radius_decay": dna.radius_decay,
				}),
			]),
		PresetDef.new("conifer", "Conifer",
			{"count": 2.0, "spread": 22.0, "iterations": 5.0, "tuft": 10.0},
			[
				{"name": "branch", "key": "count",      "min": 1.0, "max": 4.0},
				{"name": "spread", "key": "spread",     "min": 10.0, "max": 40.0},
				{"name": "depth",  "key": "iterations", "min": 3.0, "max": 6.0},
				{"name": "tuft",   "key": "tuft",       "min": 4.0, "max": 20.0},
			],
			"plant_bright",
			func(dna): return [
				SpawnBranchOpScript.new(GraphSelectorScript.leaves(), {
					"count": int(dna.count), "length": 0.7,
					"spread_deg": dna.spread, "radius_decay": 0.72,
				}),
			]),
		PresetDef.new("autumn", "Autumn",
			{"count": 3.0, "spread": 40.0, "iterations": 3.0, "tuft": 16.0},
			[
				{"name": "branch", "key": "count",      "min": 2.0, "max": 5.0},
				{"name": "spread", "key": "spread",     "min": 20.0, "max": 70.0},
				{"name": "depth",  "key": "iterations", "min": 2.0, "max": 4.0},
				{"name": "tuft",   "key": "tuft",       "min": 6.0, "max": 20.0},
			],
			"plant_red",
			func(dna): return [
				SpawnBranchOpScript.new(GraphSelectorScript.leaves(), {
					"count": int(dna.count), "length": 0.85,
					"spread_deg": dna.spread, "radius_decay": 0.65,
				}),
			]),
		PresetDef.new("bush", "Bush",
			{"count": 4.0, "spread": 60.0, "iterations": 3.0, "jitter": 0.4},
			[
				{"name": "branch", "key": "count",      "min": 3.0, "max": 6.0},
				{"name": "spread", "key": "spread",     "min": 40.0, "max": 80.0},
				{"name": "depth",  "key": "iterations", "min": 2.0, "max": 4.0},
				{"name": "jitter", "key": "jitter",     "min": 0.0, "max": 0.8},
			],
			"plant",
			func(dna): return [
				SpawnBranchOpScript.new(GraphSelectorScript.leaves(), {
					"count": int(dna.count), "length": 0.45,
					"spread_deg": dna.spread, "radius_decay": 0.6,
					"jitter": dna.jitter,
				}),
			]),
		PresetDef.new("coral", "Coral",
			{"count": 3.0, "spread": 50.0, "iterations": 4.0, "jitter": 0.5},
			[
				{"name": "branch", "key": "count",      "min": 2.0, "max": 5.0},
				{"name": "spread", "key": "spread",     "min": 30.0, "max": 80.0},
				{"name": "depth",  "key": "iterations", "min": 2.0, "max": 5.0},
				{"name": "jitter", "key": "jitter",     "min": 0.1, "max": 0.9},
			],
			"flesh",
			func(dna): return [
				SpawnBranchOpScript.new(GraphSelectorScript.leaves(), {
					"count": int(dna.count), "length": 0.5,
					"spread_deg": dna.spread, "radius_decay": 0.7,
					"jitter": dna.jitter,
				}),
			]),
		PresetDef.new("canopy", "Canopy",
			{"attractors": 250.0, "size_y": 1.0, "step": 0.13, "iterations": 1.0},
			[
				{"name": "points", "key": "attractors", "min": 80.0, "max": 500.0},
				{"name": "height", "key": "size_y",     "min": 0.5, "max": 3.0},
				{"name": "step",   "key": "step",       "min": 0.08, "max": 0.25},
			],
			"plant_bright",
			func(dna): return [
				SpaceColonizeOpScript.new(GraphSelectorScript.all_nodes(), {
					"iterations": 60, "attractor_count": int(dna.attractors),
					"cloud_shape": "ellipsoid",
					"cloud_size": [1.6, dna.size_y, 1.6],
					"cloud_center": [0, 1.5 + dna.size_y * 0.5, 0],
					"influence_radius": 1.0, "kill_radius": 0.22,
					"step": dna.step, "radius_decay": 0.97,
				}),
			]),
		PresetDef.new("bristle", "Bristle Ball",
			{"count": 60.0, "length": 0.6, "radius": 0.025, "splay": 1.0},
			[
				{"name": "count",  "key": "count",  "min": 10.0, "max": 100.0},
				{"name": "length", "key": "length", "min": 0.2, "max": 1.2},
				{"name": "radius", "key": "radius", "min": 0.01, "max": 0.06},
				{"name": "splay",  "key": "splay",  "min": 0.0, "max": 1.0},
			],
			"plant_bright",
			func(dna): return [
				LeafTuftOpScript.new(GraphSelectorScript.leaves(), {
					"count": int(dna.count), "length": dna.length,
					"radius": dna.radius, "splay": dna.splay,
				}),
			]),
	]


# ─── Scaffold ────────────────────────────────────────────────

func _build_pedestal() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.4, PEDESTAL_HEIGHT, 2.4)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.24); mat.roughness = 0.9
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3(0, PEDESTAL_HEIGHT * 0.5, 0)
	add_child(mi)


func _build_title_label() -> void:
	_title_label = Label3D.new()
	_title_label.text = "Graph Grammar Studio"
	_title_label.position = Vector3(0, PEDESTAL_HEIGHT + 3.2, 0)
	_title_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_title_label.pixel_size = 0.012
	_title_label.modulate = Color(0.5, 0.85, 0.55)
	_title_label.outline_modulate = Color.BLACK
	add_child(_title_label)


func _build_readout() -> void:
	_readout_label = Label3D.new()
	_readout_label.text = ""
	_readout_label.position = Vector3(0, PEDESTAL_HEIGHT + 2.85, 0)
	_readout_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout_label.pixel_size = 0.008
	_readout_label.modulate = Color(0.8, 0.9, 0.8)
	_readout_label.outline_modulate = Color.BLACK
	add_child(_readout_label)


func _build_buttons() -> void:
	var base_x: float = 1.8
	var base_y: float = 1.4
	var base_z: float = -0.9
	var v_spacing: float = 0.3
	for i in _presets.size():
		var p: PresetDef = _presets[i]
		var btn = PUSH_BUTTON.instantiate()
		btn.position = Vector3(base_x, base_y, base_z + float(i) * v_spacing)
		add_child(btn)

		var lbl := Label3D.new()
		lbl.text = p.label
		lbl.position = btn.position + Vector3(0.22, 0, 0)
		lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		lbl.pixel_size = 0.006
		lbl.modulate = Color(0.9, 0.9, 0.95)
		lbl.outline_modulate = Color.BLACK
		add_child(lbl)

		var area := btn.get_node_or_null("InteractableAreaButton")
		if area and area.has_signal("button_pressed"):
			var idx: int = i
			area.button_pressed.connect(func(_b): _select_preset(idx))
		_buttons.append(btn)


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


# ─── Selection + rebuild ─────────────────────────────────────

func _select_preset(idx: int) -> void:
	idx = clampi(idx, 0, _presets.size() - 1)
	_current_idx = idx
	var p: PresetDef = _presets[idx]
	_current_dna = p.defaults.duplicate()
	_title_label.text = "Graph Grammar · %s" % p.label

	for i in MAX_SLIDERS:
		var slider = _sliders[i]
		if i < p.sliders.size():
			var spec: Dictionary = p.sliders[i]
			slider.visible = true
			if slider.has_method("set_range"):
				slider.set_range(spec.min, spec.max)
			var cur: float = float(_current_dna.get(spec.key, spec.min))
			var norm: float = 0.0
			if spec.max > spec.min:
				norm = (cur - spec.min) / (spec.max - spec.min)
			if slider.has_method("set_normalized_value"):
				slider.set_normalized_value(clamp(norm, 0.0, 1.0))
			var name_lbl: Label3D = slider.get_node_or_null("Frame/LabelName")
			if name_lbl:
				name_lbl.text = str(spec.name).to_upper()
		else:
			slider.visible = false

	_rebuild_pending = true


func _on_slider_moved(idx: int) -> void:
	var p: PresetDef = _presets[_current_idx]
	if idx >= p.sliders.size(): return
	var spec: Dictionary = p.sliders[idx]
	var slider = _sliders[idx]
	if not slider.has_method("get_normalized_value"): return
	var v: float = slider.get_normalized_value()
	var raw: float = lerp(float(spec.min), float(spec.max), v)
	_current_dna[spec.key] = raw
	# Throttle expensive rebuilds via _process flag
	_rebuild_pending = true


func _rebuild_graph() -> void:
	if _current_mesh_root and is_instance_valid(_current_mesh_root):
		_current_mesh_root.queue_free()
		_current_mesh_root = null

	var p: PresetDef = _presets[_current_idx]
	# Build fresh state
	var state = GraphStateScript.new()
	state.seed_single_root(Vector3.ZERO, 0.18)

	var grammar = GraphGrammarScript.new()
	grammar.set_seed(state)
	grammar.max_nodes = 1500  # keep VR frame time sensible

	var rules: Array = (p.builder).call(_current_dna)
	for r in rules:
		grammar.add_rule(r)

	var iters: int = int(_current_dna.get("iterations", 1))
	grammar.apply_n(iters)

	var materials := _materials_for(p.leaf_color)
	var mesh_root: Node3D = GraphToMeshScript.to_node3d(grammar.state, materials)
	mesh_root.position = Vector3(0, PEDESTAL_HEIGHT, 0)
	add_child(mesh_root)
	_current_mesh_root = mesh_root

	_update_readout()


func _update_readout() -> void:
	if _readout_label == null: return
	var p: PresetDef = _presets[_current_idx]
	var lines: Array[String] = []
	for spec in p.sliders:
		var k: String = spec.key
		var v: float = float(_current_dna.get(k, 0.0))
		if k in ["count", "iterations", "attractors"]:
			lines.append("%s: %d" % [spec.name, int(v)])
		else:
			lines.append("%s: %.2f" % [spec.name, v])
	var node_count: int = 0
	if _current_mesh_root:
		node_count = _current_mesh_root.get_child_count()
	lines.append("edges: %d" % node_count)
	_readout_label.text = "  ".join(lines)


# ─── Materials ───────────────────────────────────────────────

func _materials_for(leaf_variant: String) -> Dictionary:
	var bark := ShaderMaterial.new()
	bark.shader = SHADER_BARK
	bark.set_shader_parameter("bark_color", Color(0.38, 0.25, 0.17))
	bark.set_shader_parameter("crevice_color", Color(0.12, 0.08, 0.05))

	var leaf := ShaderMaterial.new()
	leaf.shader = SHADER_PLANT
	match leaf_variant:
		"plant_bright":
			leaf.set_shader_parameter("base_color", Color(0.4, 0.68, 0.25))
			leaf.set_shader_parameter("edge_color", Color(0.95, 1.0, 0.6))
		"plant_red":
			leaf.set_shader_parameter("base_color", Color(0.7, 0.25, 0.25))
			leaf.set_shader_parameter("edge_color", Color(1.0, 0.75, 0.65))
		"flesh":
			# Use flesh-ish flat material since FLESH shader signature differs
			var m := StandardMaterial3D.new()
			m.albedo_color = Color(0.65, 0.28, 0.25); m.roughness = 0.55
			return {"default": m, "leaf": m}
		_:
			leaf.set_shader_parameter("base_color", Color(0.3, 0.55, 0.2))
			leaf.set_shader_parameter("edge_color", Color(0.85, 0.9, 0.5))
	return {"default": bark, "leaf": leaf}


func apply_grid_config(_config_data: Dictionary) -> void:
	pass
