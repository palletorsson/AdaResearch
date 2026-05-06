# form_editor.gd — Desktop editor for body recipes (flower, fungus, walker,
# tree, modulor, column, pedestal, amphora, ruin wall). Pick a form in the
# dropdown; DNA sliders drive the chosen recipe; the preview rebuilds live
# in the orbit camera viewport. Sliders irrelevant to the current form
# are hidden so the UI only shows genes the active recipe actually reads.
extends BaseGeometryEditor

const FlowerBody     = preload("res://commons/morphology/sdf/flower_body.gd")
const FungusBody     = preload("res://commons/morphology/sdf/fungus_body.gd")
const WalkerBody     = preload("res://commons/morphology/sdf/walker_body.gd")
const TreeBody       = preload("res://commons/morphology/sdf/tree_body.gd")
const ModulorWalker  = preload("res://commons/morphology/sdf/modulor_walker.gd")
const ColumnRecipe   = preload("res://commons/morphology/objects/classical/column.gd")
const PedestalRecipe = preload("res://commons/morphology/objects/classical/pedestal.gd")
const AmphoraRecipe  = preload("res://commons/morphology/objects/classical/amphora.gd")
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

# Each entry: recipe key + material key + the DNA keys this recipe actually
# reads. Gene names here MUST match what the recipe's _build_from_dna()
# calls dna.get(...) with — otherwise the slider is a no-op.
const FORMS: Array[Dictionary] = [
	{"label": "Flower",    "recipe": "flower",   "mat": "flower",  "genes": ["scale", "segments", "symmetry", "pattern_scale"]},
	{"label": "Fungus",    "recipe": "fungus",   "mat": "fungus",  "genes": ["scale", "segments", "symmetry", "pattern_density"]},
	{"label": "Walker",    "recipe": "walker",   "mat": "walker",  "genes": ["scale", "segments", "symmetry", "pattern_scale"]},
	{"label": "Tree",      "recipe": "tree",     "mat": "tree",    "genes": ["scale", "segments", "symmetry", "pattern_density"]},
	{"label": "Modulor",   "recipe": "modulor",  "mat": "walker",  "genes": ["scale", "segments", "symmetry", "ladder_offset"]},
	{"label": "Column",    "recipe": "column",   "mat": "stone",   "genes": ["height", "base_radius", "taper"]},
	{"label": "Pedestal",  "recipe": "pedestal", "mat": "stone",   "genes": ["height", "width", "depth"]},
	{"label": "Amphora",   "recipe": "amphora",  "mat": "ceramic", "genes": ["height", "belly_width", "neck_ratio"]},
	{"label": "Ruin Wall", "recipe": "ruin",     "mat": "stone",   "genes": ["length", "height", "thickness", "jaggedness", "rubble_count"]},
	{"label": "Graph Tree", "recipe": "graph_tree", "mat": "tree", "genes": ["trunk_length", "branch_count", "tree_depth", "length_decay", "angle_spread", "radius_base", "radius_decay", "jitter", "seed"],
		"rename": {"tree_depth": "depth"}},
	{"label": "Rhizome",    "recipe": "rhizome",    "mat": "tree", "genes": ["max_depth", "step_length", "variance", "rhizome_radius", "seed"],
		"rename": {"rhizome_radius": "radius"}},
	{"label": "Koch Curve", "recipe": "koch",       "mat": "neutral", "genes": ["koch_depth", "koch_length", "koch_radius"],
		"rename": {"koch_depth": "depth", "koch_length": "length", "koch_radius": "radius"}},
	{"label": "Sierpinski", "recipe": "sierpinski", "mat": "neutral", "genes": ["sierp_depth", "sierpinski_size", "sierpinski_radius"],
		"rename": {"sierp_depth": "depth", "sierpinski_size": "size", "sierpinski_radius": "radius"}},
	{"label": "Klein Bottle","recipe": "klein",     "mat": "ceramic", "genes": ["klein_scale", "num_u", "num_v"],
		"rename": {"klein_scale": "scale"}},
	{"label": "Mobius",     "recipe": "mobius",     "mat": "ceramic", "genes": ["mobius_radius", "mobius_width", "twists", "segments", "w_segments"],
		"rename": {"mobius_radius": "radius", "mobius_width": "width"}},
	{"label": "Supershape", "recipe": "supershape", "mat": "ceramic", "genes": ["super_scale", "m", "n1", "n2", "n3", "num_u", "num_v"],
		"rename": {"super_scale": "scale"}},
]


func _get_editor_name() -> String:
	return "Form Editor"


func _get_parameter_groups() -> Array:
	var form_labels: Array[String] = []
	for f in FORMS:
		form_labels.append(f["label"])
	return [
		{"name": "Form", "params": [
			{"id": "form_idx", "label": "Form", "options": form_labels, "default": 0.0},
		]},
		{"name": "Kingdom DNA", "params": [
			{"id": "scale",           "label": "Scale",        "min": 0.3, "max": 1.6, "step": 0.02, "default": 0.8},
			{"id": "segments",        "label": "Segments",     "min": 1.0, "max": 8.0, "step": 1.0,  "default": 4.0},
			{"id": "symmetry",        "label": "Symmetry",     "min": 2.0, "max": 12.0, "step": 1.0, "default": 6.0},
			{"id": "pattern_scale",   "label": "Pattern Scale","min": 0.3, "max": 1.8, "step": 0.05, "default": 1.0},
			{"id": "pattern_density", "label": "Density",      "min": 0.1, "max": 1.0, "step": 0.05, "default": 0.6},
			{"id": "ladder_offset",   "label": "Ladder Rung",  "min": 0.0, "max": 6.0, "step": 1.0,  "default": 0.0},
		]},
		{"name": "Classical DNA", "params": [
			{"id": "height",       "label": "Height",       "min": 0.3, "max": 4.0,  "step": 0.05, "default": 1.13},
			{"id": "width",        "label": "Width",        "min": 0.3, "max": 1.2,  "step": 0.05, "default": 0.53},
			{"id": "depth",        "label": "Depth",        "min": 0.3, "max": 1.2,  "step": 0.05, "default": 0.53},
			{"id": "base_radius",  "label": "Base Radius",  "min": 0.08, "max": 0.35, "step": 0.01, "default": 0.20},
			{"id": "taper",        "label": "Taper",        "min": 0.5, "max": 1.0,  "step": 0.01, "default": 0.82},
			{"id": "belly_width",  "label": "Belly Width",  "min": 0.2, "max": 0.7,  "step": 0.02, "default": 0.4},
			{"id": "neck_ratio",   "label": "Neck Ratio",   "min": 0.2, "max": 0.6,  "step": 0.02, "default": 0.35},
			{"id": "length",       "label": "Length",       "min": 1.0, "max": 4.0,  "step": 0.1,  "default": 2.0},
			{"id": "thickness",    "label": "Thickness",    "min": 0.15, "max": 0.6, "step": 0.02, "default": 0.35},
			{"id": "jaggedness",   "label": "Jaggedness",   "min": 0.0, "max": 1.0,  "step": 0.05, "default": 0.7},
			{"id": "rubble_count", "label": "Rubble Count", "min": 0.0, "max": 10.0, "step": 1.0,  "default": 4.0},
		]},
		{"name": "Graph Tree DNA", "params": [
			{"id": "trunk_length", "label": "Trunk Length",  "min": 0.5, "max": 3.0, "step": 0.05, "default": 1.5},
			{"id": "branch_count", "label": "Branch Count",  "min": 1.0, "max": 6.0, "step": 1.0,  "default": 3.0},
			{"id": "tree_depth",   "label": "Tree Depth",    "min": 1.0, "max": 5.0, "step": 1.0,  "default": 4.0},
			{"id": "length_decay", "label": "Length Decay",  "min": 0.4, "max": 0.9, "step": 0.02, "default": 0.65},
			{"id": "angle_spread", "label": "Angle Spread",  "min": 10.0, "max": 80.0, "step": 1.0, "default": 45.0},
			{"id": "radius_base",  "label": "Radius Base",   "min": 0.05, "max": 0.4, "step": 0.01, "default": 0.18},
			{"id": "radius_decay", "label": "Radius Decay",  "min": 0.4, "max": 0.9, "step": 0.02, "default": 0.62},
			{"id": "jitter",       "label": "Jitter",        "min": 0.0, "max": 0.8, "step": 0.02, "default": 0.25},
			{"id": "seed",         "label": "Seed",          "min": 0.0, "max": 99.0, "step": 1.0, "default": 7.0},
		]},
		{"name": "Rhizome DNA", "params": [
			{"id": "max_depth",      "label": "Max Depth",    "min": 5.0, "max": 100.0, "step": 5.0, "default": 40.0},
			{"id": "step_length",    "label": "Step Length",  "min": 0.1, "max": 1.5,   "step": 0.05, "default": 0.5},
			{"id": "variance",       "label": "Variance",     "min": 0.0, "max": 0.8,   "step": 0.02, "default": 0.3},
			{"id": "rhizome_radius", "label": "Radius",       "min": 0.02, "max": 0.2,  "step": 0.01, "default": 0.06},
		]},
		{"name": "Fractal DNA", "params": [
			{"id": "koch_depth",        "label": "Koch Depth",         "min": 1.0, "max": 5.0,  "step": 1.0,  "default": 3.0},
			{"id": "koch_length",       "label": "Koch Length",        "min": 0.5, "max": 4.0,  "step": 0.1,  "default": 2.0},
			{"id": "koch_radius",       "label": "Koch Radius",        "min": 0.01, "max": 0.1, "step": 0.005, "default": 0.04},
			{"id": "sierp_depth",       "label": "Sierp. Depth",       "min": 1.0, "max": 4.0,  "step": 1.0,  "default": 3.0},
			{"id": "sierpinski_size",   "label": "Sierp. Size",        "min": 0.5, "max": 2.5,  "step": 0.05, "default": 1.0},
			{"id": "sierpinski_radius", "label": "Sierp. Radius",      "min": 0.005, "max": 0.05, "step": 0.002, "default": 0.02},
		]},
		{"name": "Parametric DNA", "params": [
			{"id": "klein_scale",   "label": "Klein Scale",  "min": 0.02, "max": 0.15, "step": 0.005, "default": 0.05},
			{"id": "mobius_radius", "label": "Mobius Radius","min": 0.3, "max": 2.0,   "step": 0.05, "default": 1.0},
			{"id": "mobius_width",  "label": "Mobius Width", "min": 0.1, "max": 0.8,   "step": 0.02, "default": 0.3},
			{"id": "twists",        "label": "Twists",       "min": 1.0, "max": 7.0,   "step": 2.0,  "default": 1.0},
			{"id": "segments",      "label": "Segments",     "min": 12.0, "max": 96.0, "step": 4.0,  "default": 48.0},
			{"id": "w_segments",    "label": "W Segments",   "min": 4.0, "max": 24.0,  "step": 1.0,  "default": 8.0},
			{"id": "super_scale",   "label": "Super Scale",  "min": 0.2, "max": 1.5,   "step": 0.05, "default": 0.5},
			{"id": "m",             "label": "M",            "min": 0.0, "max": 16.0,  "step": 0.5,  "default": 6.0},
			{"id": "n1",            "label": "n1",           "min": 0.1, "max": 4.0,   "step": 0.1,  "default": 1.0},
			{"id": "n2",            "label": "n2",           "min": 0.1, "max": 4.0,   "step": 0.1,  "default": 1.0},
			{"id": "n3",            "label": "n3",           "min": 0.1, "max": 4.0,   "step": 0.1,  "default": 1.0},
			{"id": "num_u",         "label": "Num U",        "min": 16.0, "max": 128.0,"step": 8.0,  "default": 48.0},
			{"id": "num_v",         "label": "Num V",        "min": 8.0, "max": 96.0,  "step": 4.0,  "default": 32.0},
		]},
	]


func _create_initial_geometry() -> void:
	super._create_initial_geometry()
	_sync_slider_visibility()


# Hook dropdown changes: when Form changes, swap visible slider set.
func _on_dropdown_changed(index: int, param_id: String) -> void:
	super._on_dropdown_changed(index, param_id)
	if param_id == "form_idx":
		_sync_slider_visibility()


# Hide slider rows that aren't in the current form's gene set. The slider
# HBox is the parent of each HSlider stored in _sliders, so toggling that
# hides the whole row (label + slider + value display).
func _sync_slider_visibility() -> void:
	var form_idx: int = clampi(int(p("form_idx", 0)), 0, FORMS.size() - 1)
	var active_genes: Array = FORMS[form_idx]["genes"]
	for param_id in _sliders:
		var slider: HSlider = _sliders[param_id] as HSlider
		if slider == null: continue
		var row: Node = slider.get_parent()
		if row is Control:
			(row as Control).visible = (param_id in active_genes)


func _rebuild() -> void:
	_clear_content()

	var form_idx: int = clampi(int(p("form_idx", 0)), 0, FORMS.size() - 1)
	var form: Dictionary = FORMS[form_idx]

	# Build DNA from only the genes this recipe reads, applying any
	# slider-id → recipe-key rename so that e.g. "koch_length" arrives
	# at the recipe as "length".
	var rename: Dictionary = form.get("rename", {})
	var dna: Dictionary = {}
	for gene in form["genes"]:
		var key: String = rename.get(gene, gene)
		dna[key] = p(gene, 0.0)

	var recipe_script: GDScript = _script_for(form["recipe"])
	if recipe_script == null:
		return
	var recipe = recipe_script.new()
	recipe.dna = dna
	if "joint_k" in recipe:
		recipe.joint_k = 0.08
	recipe.build()

	var body: Node3D = recipe.build_mesh_body(_materials_for(form["mat"]))
	if body:
		content_root.add_child(body)

	await get_tree().process_frame
	_frame_camera_on_content()


func _frame_camera_on_content() -> void:
	var aabb: AABB = _combined_aabb(content_root)
	if aabb.size.length() <= 0.01:
		orbit_dist = 3.0
		return
	var max_dim: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	orbit_dist = maxf(max_dim * 2.0, 1.2)


func _combined_aabb(node: Node3D) -> AABB:
	var first := true
	var total := AABB()
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D and n.mesh:
			var ab: AABB = n.global_transform * n.get_aabb()
			if first:
				total = ab; first = false
			else:
				total = total.merge(ab)
		for c in n.get_children():
			if c is Node3D:
				stack.append(c)
	if first:
		return AABB(Vector3(-1, 0, -1), Vector3(2, 2, 2))
	return total


func _script_for(key: String) -> GDScript:
	match key:
		"flower":   return FlowerBody
		"fungus":   return FungusBody
		"walker":   return WalkerBody
		"tree":     return TreeBody
		"modulor":  return ModulorWalker
		"column":   return ColumnRecipe
		"pedestal": return PedestalRecipe
		"amphora":  return AmphoraRecipe
		"ruin":     return RuinWallRecipe
		"graph_tree": return GraphTreeBody
		"rhizome":    return RhizomeBody
		"koch":       return KochCurveBody
		"sierpinski": return SierpinskiBody
		"klein":      return KleinBottleBody
		"mobius":     return MobiusStripBody
		"supershape": return SupershapeBody
	return null


# ─── Materials ────────────────────────────────────────────────

func _materials_for(key: String) -> Dictionary:
	match key:
		"flower":  return _flower_mats()
		"fungus":  return _fungus_mats()
		"walker":  return _walker_mats()
		"tree":    return _tree_mats()
		"stone":   return _stone_mats()
		"ceramic": return _ceramic_mats()
	return _neutral_mats()


func _neutral_mats() -> Dictionary:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.88, 0.85, 0.75); m.roughness = 0.6
	return {"default": m, "body": m}

func _stone_mats() -> Dictionary:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.78, 0.76, 0.72); m.roughness = 0.9
	return {"default": m, "body": m,
		"shaft": m, "plinth": m, "capital": m, "abacus": m,
		"base": m, "die": m, "cornice": m,
		"wall_block": m, "rubble": m, "base_course": m}

func _ceramic_mats() -> Dictionary:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.28, 0.18); m.roughness = 0.55; m.metallic = 0.1
	return {"default": m, "body": m,
		"foot": m, "belly": m, "shoulder": m,
		"neck": m, "lip": m, "handle": m}

func _tree_mats() -> Dictionary:
	var bark := ShaderMaterial.new(); bark.shader = SHADER_BARK
	bark.set_shader_parameter("bark_color", Color(0.38, 0.25, 0.17))
	bark.set_shader_parameter("crevice_color", Color(0.12, 0.08, 0.05))
	var leaf := ShaderMaterial.new(); leaf.shader = SHADER_PLANT
	leaf.set_shader_parameter("base_color", Color(0.25, 0.5, 0.2))
	leaf.set_shader_parameter("edge_color", Color(0.8, 0.9, 0.5))
	return {"body": bark, "default": leaf}

func _walker_mats() -> Dictionary:
	var skin := ShaderMaterial.new(); skin.shader = SHADER_FLESH
	skin.set_shader_parameter("skin_color", Color(0.75, 0.62, 0.5))
	skin.set_shader_parameter("interior_color", Color(0.9, 0.4, 0.3))
	return {"default": skin, "body": skin}

func _flower_mats() -> Dictionary:
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

func _fungus_mats() -> Dictionary:
	var stem := ShaderMaterial.new(); stem.shader = SHADER_BARK
	stem.set_shader_parameter("bark_color", Color(0.85, 0.78, 0.65))
	stem.set_shader_parameter("crevice_color", Color(0.55, 0.45, 0.35))
	var cap := ShaderMaterial.new(); cap.shader = SHADER_FLESH
	cap.set_shader_parameter("skin_color", Color(0.65, 0.28, 0.25))
	cap.set_shader_parameter("interior_color", Color(0.35, 0.1, 0.08))
	return {"default": stem, "body": stem, "cap": cap}
