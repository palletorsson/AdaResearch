# sdf_gallery_row_artifact.gd
# Interactive per-row gallery artifact. Instead of showing all stages of a
# row side-by-side, a single form sits on a pedestal and the player drags
# a horizontal slider to step through the stages. A Label3D above the form
# names the current stage.
#
# Seven derived scenes each export a different `row_name` and the script
# builds the appropriate stage list for that row.
#
# Discrete rows (primitives, kingdoms, modulor, operators, dna_variance,
# stacked_ops): slider snaps to the nearest stage index.
# Continuous row (transition): slider drives a live flower↔fungus blend,
# rebuild throttled to ~4 Hz so the voxel resample stays cheap.

extends Node3D

const CapsuleSDF       = preload("res://commons/morphology/sdf/capsule_sdf.gd")
const EllipsoidSDF     = preload("res://commons/morphology/sdf/ellipsoid_sdf.gd")
const BoxSDF           = preload("res://commons/morphology/sdf/box_sdf.gd")
const RoundedBoxSDF    = preload("res://commons/morphology/sdf/rounded_box_sdf.gd")
const ConeSDF          = preload("res://commons/morphology/sdf/cone_sdf.gd")
const TreeBody         = preload("res://commons/morphology/sdf/tree_body.gd")
const WalkerBody       = preload("res://commons/morphology/sdf/walker_body.gd")
const FlowerBody       = preload("res://commons/morphology/sdf/flower_body.gd")
const FungusBody       = preload("res://commons/morphology/sdf/fungus_body.gd")
const ModulorWalker    = preload("res://commons/morphology/sdf/modulor_walker.gd")
const PatternOp        = preload("res://commons/morphology/sdf/pattern_op.gd")
const FoldOp           = preload("res://commons/morphology/sdf/fold_op.gd")
const TaperOp          = preload("res://commons/morphology/sdf/taper_op.gd")
const BlendedSDF       = preload("res://commons/morphology/sdf/blended_sdf.gd")
const SDFVoxelPreview  = preload("res://commons/morphology/sdf/sdf_voxel_preview.gd")
const SDFRaymarchPreview = preload("res://commons/morphology/sdf/sdf_raymarch_preview.gd")

const SHADER_PLANT = preload("res://commons/morphology/sdf/shaders/plant.gdshader")
const SHADER_FLESH = preload("res://commons/morphology/sdf/shaders/flesh.gdshader")
const SHADER_BARK  = preload("res://commons/morphology/sdf/shaders/bark.gdshader")

const SLIDER_SCENE = preload("res://commons/interactables/slider_horizontal.tscn")

const PEDESTAL_HEIGHT: float = 0.4

## Row name: "primitives", "kingdoms", "transition", "modulor",
## "operators", "dna_variance", "stacked_ops".
@export var row_name: String = "primitives"

# Runtime state
var _stages: Array = []                 # [{name, build: Callable}] for discrete
var _is_continuous: bool = false        # true for transition row
var _current_idx: int = -1
var _current_form: Node3D = null        # active visual
var _label: Label3D = null
var _stage_label: Label3D = null
var _hint_label: Label3D = null

# Continuous row state (transition)
var _live_blend = null
var _live_preview = null
var _live_t: float = 0.0
var _last_live_rebuild: float = -1.0

# Kingdom DNA reused across stages
var _kingdom_dna: Dictionary = {
	"scale": 0.8, "segments": 4.0, "symmetry": 6.0,
	"pattern_scale": 1.0, "pattern_density": 0.6,
}
var _small_dna: Dictionary = {
	"scale": 0.7, "segments": 4.0, "symmetry": 6.0,
	"pattern_scale": 1.0, "pattern_density": 0.6,
}


func _ready() -> void:
	_build_pedestal()
	_build_header_label()
	_build_stage_label()
	_build_stages()
	_build_slider()
	_build_hint_label()
	if _is_continuous:
		_spawn_live_blend()
	else:
		_show_stage(0)


# ─── Scaffold ──────────────────────────────────────────────────

func _build_pedestal() -> void:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(2.2, PEDESTAL_HEIGHT, 2.2)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.22, 0.25)
	mat.roughness = 0.85
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3(0, PEDESTAL_HEIGHT * 0.5, 0)
	add_child(mi)


func _build_header_label() -> void:
	_label = Label3D.new()
	_label.text = _row_title()
	_label.position = Vector3(0, PEDESTAL_HEIGHT + 2.5, 0)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.pixel_size = 0.01
	_label.modulate = Color(0.9, 0.85, 0.7)
	_label.outline_modulate = Color.BLACK
	add_child(_label)


func _build_stage_label() -> void:
	_stage_label = Label3D.new()
	_stage_label.text = "…"
	_stage_label.position = Vector3(0, PEDESTAL_HEIGHT + 2.15, 0)
	_stage_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stage_label.pixel_size = 0.012
	_stage_label.modulate = Color(1.0, 0.7, 0.4)
	_stage_label.outline_modulate = Color.BLACK
	add_child(_stage_label)


func _build_hint_label() -> void:
	_hint_label = Label3D.new()
	_hint_label.text = "drag slider →"
	_hint_label.position = Vector3(0, 0.95, -1.55)
	_hint_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_hint_label.pixel_size = 0.008
	_hint_label.modulate = Color(0.7, 0.75, 0.85)
	_hint_label.outline_modulate = Color.BLACK
	add_child(_hint_label)


func _build_slider() -> void:
	var slider := SLIDER_SCENE.instantiate()
	slider.name = "StageSlider"
	# Place slider at waist height in front of pedestal (south side = -Z),
	# so a player standing south of the artifact can reach it.
	slider.position = Vector3(0, 0.95, -1.25)
	slider.rotation = Vector3.ZERO
	add_child(slider)
	if slider.has_method("set_range"):
		slider.set_range(0.0, 1.0)
	if slider.has_method("set_normalized_value"):
		slider.set_normalized_value(0.0 if not _is_continuous else 0.5)
	if slider.has_signal("slider_moved"):
		slider.slider_moved.connect(_on_slider_moved)
	var name_lbl: Label3D = slider.get_node_or_null("Frame/LabelName")
	if name_lbl:
		name_lbl.text = _row_slider_name()


# ─── Stage definitions ─────────────────────────────────────────

func _build_stages() -> void:
	match row_name:
		"primitives":    _build_stages_primitives()
		"kingdoms":      _build_stages_kingdoms()
		"transition":    _is_continuous = true
		"modulor":       _build_stages_modulor()
		"operators":     _build_stages_operators()
		"dna_variance":  _build_stages_dna_variance()
		"stacked_ops":   _build_stages_stacked_ops()
		_:               _build_stages_primitives()


func _build_stages_primitives() -> void:
	_stages = [
		{"name": "Capsule",    "render": "mesh", "sdf": CapsuleSDF.make(Vector3(0, 0.2, 0), Vector3(0, 1.2, 0), 0.28)},
		{"name": "Ellipsoid",  "render": "mesh", "sdf": EllipsoidSDF.make(Vector3(0, 0.8, 0), Vector3(0.5, 0.7, 0.5))},
		{"name": "Box",        "render": "mesh", "sdf": BoxSDF.make(Vector3(0, 0.75, 0), Vector3(0.45, 0.45, 0.45))},
		{"name": "RoundedBox", "render": "mesh", "sdf": RoundedBoxSDF.make(Vector3(0, 0.75, 0), Vector3(0.55, 0.4, 0.55), 0.14)},
		{"name": "Cone",       "render": "mesh", "sdf": ConeSDF.make(Vector3(0, 1.4, 0), Vector3(0, 0.2, 0), 0.45)},
		{"name": "RotatedBox", "render": "mesh", "sdf": BoxSDF.make(Vector3(0, 0.8, 0), Vector3(0.4, 0.4, 0.4),
			Basis(Vector3.UP, deg_to_rad(30)) * Basis(Vector3.RIGHT, deg_to_rad(20)))},
	]


func _build_stages_kingdoms() -> void:
	_stages = [
		{"name": "Tree",   "render": "body", "recipe": TreeBody,   "materials": _tree_materials(),   "dna": _kingdom_dna},
		{"name": "Walker", "render": "body", "recipe": WalkerBody, "materials": _walker_materials(), "dna": _kingdom_dna},
		{"name": "Flower", "render": "body", "recipe": FlowerBody, "materials": _flower_materials(), "dna": _kingdom_dna},
		{"name": "Fungus", "render": "body", "recipe": FungusBody, "materials": _fungus_materials(), "dna": _kingdom_dna},
	]


func _build_stages_modulor() -> void:
	var levels := [0, 2, 4]
	_stages = []
	for off in levels:
		var dna := {"scale": 1.0, "segments": 4.0, "symmetry": 2.0, "ladder_offset": float(off)}
		_stages.append({
			"name": "rung %d" % off,
			"render": "body",
			"recipe": ModulorWalker,
			"materials": _walker_materials(),
			"dna": dna,
		})


func _build_stages_operators() -> void:
	# For operators, we pre-build the base recipe and wrap on demand.
	_stages = [
		{"name": "plain",   "render": "raymarch", "op": "plain"},
		{"name": "+noise",  "render": "raymarch", "op": "noise"},
		{"name": "+scales", "render": "raymarch", "op": "scales"},
		{"name": "+fold",   "render": "raymarch", "op": "fold"},
		{"name": "+taper",  "render": "raymarch", "op": "taper"},
	]


func _build_stages_dna_variance() -> void:
	_stages = [
		{"name": "3 petals", "render": "body", "recipe": FlowerBody, "materials": _flower_materials(),
			"dna": {"scale": 0.8, "segments": 2.0, "symmetry": 3.0, "pattern_scale": 0.8}},
		{"name": "5 petals", "render": "body", "recipe": FlowerBody, "materials": _flower_materials(),
			"dna": {"scale": 0.8, "segments": 3.0, "symmetry": 5.0, "pattern_scale": 1.0}},
		{"name": "7 petals", "render": "body", "recipe": FlowerBody, "materials": _flower_materials(),
			"dna": {"scale": 0.8, "segments": 4.0, "symmetry": 7.0, "pattern_scale": 1.1}},
		{"name": "leggy",    "render": "body", "recipe": FlowerBody, "materials": _flower_materials(),
			"dna": {"scale": 1.0, "segments": 6.0, "symmetry": 5.0, "pattern_scale": 1.4}},
		{"name": "compact",  "render": "body", "recipe": FlowerBody, "materials": _flower_materials(),
			"dna": {"scale": 0.6, "segments": 2.0, "symmetry": 8.0, "pattern_scale": 0.7}},
	]


func _build_stages_stacked_ops() -> void:
	_stages = [
		{"name": "noise+fold",    "render": "raymarch", "stack": "noise_fold"},
		{"name": "scales+taper",  "render": "raymarch", "stack": "scales_taper"},
		{"name": "flower fold",   "render": "raymarch", "stack": "flower_fold"},
		{"name": "tree stripes",  "render": "raymarch", "stack": "tree_stripes"},
		{"name": "dots",          "render": "raymarch", "stack": "dots"},
	]


# ─── Stage activation ──────────────────────────────────────────

func _show_stage(idx: int) -> void:
	idx = clampi(idx, 0, _stages.size() - 1)
	if idx == _current_idx:
		return
	_current_idx = idx

	if _current_form and is_instance_valid(_current_form):
		_current_form.queue_free()
		_current_form = null

	var stage: Dictionary = _stages[idx]
	var base_pos := Vector3(0, PEDESTAL_HEIGHT, 0)

	match stage.get("render", "mesh"):
		"mesh":
			_current_form = _make_mesh_form(stage.sdf, _neutral_material())
		"body":
			_current_form = _make_body_form(stage.recipe, stage.dna, stage.materials)
		"raymarch":
			_current_form = _make_op_form(stage)

	if _current_form:
		_current_form.position = base_pos
		add_child(_current_form)

	_stage_label.text = "%s  (%d/%d)" % [str(stage.name), idx + 1, _stages.size()]


func _make_mesh_form(sdf, material: Material) -> Node3D:
	var parts: Array = sdf.build_mesh_parts()
	var container := Node3D.new()
	for p in parts:
		var mi := MeshInstance3D.new()
		mi.mesh = p["mesh"]
		mi.transform = p["transform"]
		mi.material_override = material
		container.add_child(mi)
	return container


func _make_body_form(recipe, dna: Dictionary, materials: Dictionary) -> Node3D:
	var body = recipe.new()
	body.dna = dna
	body.joint_k = 0.06
	body.build()
	return body.build_mesh_body(materials)


func _make_op_form(stage: Dictionary) -> Node3D:
	var sdf = _build_op_sdf(stage)
	var preview = SDFRaymarchPreview.new()
	preview.sdf = sdf
	preview.resolution = Vector3i(48, 48, 48)
	preview.base_color = Color(0.85, 0.78, 0.7)
	preview.edge_color = Color(1.0, 0.9, 0.8)
	preview.rim_strength = 0.8
	preview.auto_rebuild_on_ready = false
	var wrap := Node3D.new()
	wrap.add_child(preview)
	preview.rebuild()
	return wrap


func _build_op_sdf(stage: Dictionary):
	# Operator row — wrap a walker / flower / tree with one operator
	if stage.has("op"):
		match stage.op:
			"plain":
				var w = WalkerBody.new(); w.dna = _small_dna; w.build(); return w
			"noise":
				var w2 = WalkerBody.new(); w2.dna = _small_dna; w2.build()
				return PatternOp.make(w2, "noise", 0.8, 4.0, 0.05)
			"scales":
				var w3 = WalkerBody.new(); w3.dna = _small_dna; w3.build()
				return PatternOp.make(w3, "scales", 0.9, 3.0, 0.04)
			"fold":
				var f = FlowerBody.new(); f.dna = _small_dna; f.build()
				return FoldOp.make(f, Vector3(0, 1.0, 0), Vector3.FORWARD, Vector3.UP, 0.7)
			"taper":
				var t = TreeBody.new(); t.dna = _small_dna; t.build()
				return TaperOp.make(t, Vector3.UP, 0.0, 1.6, 0.35)
	# Stacked-ops row — nested operators
	if stage.has("stack"):
		match stage.stack:
			"noise_fold":
				var w4 = WalkerBody.new(); w4.dna = _small_dna; w4.build()
				return FoldOp.make(
					PatternOp.make(w4, "noise", 0.7, 4.0, 0.06),
					Vector3(0, 0.6, 0), Vector3.FORWARD, Vector3.UP, 0.6)
			"scales_taper":
				var w5 = WalkerBody.new(); w5.dna = _small_dna; w5.build()
				return TaperOp.make(
					PatternOp.make(w5, "scales", 0.9, 3.0, 0.04),
					Vector3.FORWARD, -2.0, 2.0, 0.55)
			"flower_fold":
				var f2 = FlowerBody.new(); f2.dna = _small_dna; f2.build()
				return FoldOp.make(f2, Vector3(0, 1.0, 0), Vector3.FORWARD, Vector3.UP, 0.9)
			"tree_stripes":
				var t2 = TreeBody.new(); t2.dna = _small_dna; t2.build()
				return PatternOp.make(
					TaperOp.make(t2, Vector3.UP, 0.0, 2.0, 0.4),
					"stripes", 0.9, 6.0, 0.05)
			"dots":
				var t3 = TreeBody.new(); t3.dna = _small_dna; t3.build()
				return PatternOp.make(t3, "dots", 0.7, 3.0, 0.05)
	# Fallback
	var fb = WalkerBody.new(); fb.dna = _small_dna; fb.build(); return fb


# ─── Continuous transition row ─────────────────────────────────

func _spawn_live_blend() -> void:
	var flower = FlowerBody.new()
	flower.dna = _kingdom_dna
	flower.build()
	var fungus = FungusBody.new()
	fungus.dna = _kingdom_dna
	fungus.build()
	_live_blend = BlendedSDF.new()
	_live_blend.a = flower
	_live_blend.b = fungus
	_live_blend.t = 0.5
	_live_blend.mode = "weighted"
	_live_blend.smoothness = 0.25
	_live_blend.weighted_inflation = 0.35

	_live_preview = SDFVoxelPreview.new()
	_live_preview.sdf = _live_blend
	_live_preview.resolution = Vector3i(32, 40, 32)
	_live_preview.surface_threshold = 0.08
	_live_preview.auto_rebuild_on_ready = false
	_live_preview.size_by_depth = false
	_live_preview.position = Vector3(0, PEDESTAL_HEIGHT, 0)
	add_child(_live_preview)
	_live_preview.rebuild()
	_stage_label.text = "t = %.2f" % _live_blend.t


# ─── Slider callback ───────────────────────────────────────────

func _on_slider_moved(_value) -> void:
	var slider := get_node_or_null("StageSlider")
	if slider == null:
		return
	var v: float = 0.0
	if slider.has_method("get_normalized_value"):
		v = slider.get_normalized_value()
	if _is_continuous:
		_live_t = clamp(v, 0.0, 1.0)
		if _live_blend:
			_live_blend.t = _live_t
			_stage_label.text = "t = %.2f" % _live_t
	else:
		var n: int = _stages.size()
		if n <= 0: return
		# Snap v to nearest index. v=0 → 0, v=1 → n-1.
		var idx: int = clampi(int(round(v * float(n - 1))), 0, n - 1)
		if idx != _current_idx:
			_show_stage(idx)


func _process(delta: float) -> void:
	if not _is_continuous:
		return
	# Rebuild preview at ~4 Hz while user is dragging — voxel resample is
	# cheap at this resolution and keeps the morph responsive without
	# hammering the MultiMesh every frame.
	var now := Time.get_ticks_msec() / 1000.0
	if _live_preview and now - _last_live_rebuild > 0.25:
		_last_live_rebuild = now
		_live_preview.rebuild()


# ─── Labels / text ─────────────────────────────────────────────

func _row_title() -> String:
	match row_name:
		"primitives":   return "A · Primitives"
		"kingdoms":     return "B · Kingdoms"
		"transition":   return "C · Flower ↔ Fungus"
		"modulor":      return "D · Modulor ladder"
		"operators":    return "E · Operators"
		"dna_variance": return "F · DNA variance"
		"stacked_ops":  return "G · Stacked operators"
		_:              return row_name


func _row_slider_name() -> String:
	match row_name:
		"transition":   return "BLEND t"
		"modulor":      return "RUNG"
		"dna_variance": return "VARIANT"
		"operators":    return "OPERATOR"
		"stacked_ops":  return "STACK"
		"kingdoms":     return "KINGDOM"
		"primitives":   return "PRIMITIVE"
		_:              return "STAGE"


# ─── Materials ─────────────────────────────────────────────────

func _neutral_material() -> Material:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.88, 0.85, 0.75)
	mat.roughness = 0.6
	return mat

func _tree_materials() -> Dictionary:
	var bark_mat := ShaderMaterial.new()
	bark_mat.shader = SHADER_BARK
	bark_mat.set_shader_parameter("bark_color", Color(0.38, 0.25, 0.17))
	bark_mat.set_shader_parameter("crevice_color", Color(0.12, 0.08, 0.05))
	var leaf_mat := ShaderMaterial.new()
	leaf_mat.shader = SHADER_PLANT
	leaf_mat.set_shader_parameter("base_color", Color(0.25, 0.5, 0.2))
	leaf_mat.set_shader_parameter("edge_color", Color(0.8, 0.9, 0.5))
	return {"body": bark_mat, "default": leaf_mat}

func _walker_materials() -> Dictionary:
	var skin := ShaderMaterial.new()
	skin.shader = SHADER_FLESH
	skin.set_shader_parameter("skin_color", Color(0.75, 0.62, 0.5))
	skin.set_shader_parameter("interior_color", Color(0.9, 0.4, 0.3))
	return {"default": skin, "body": skin}

func _flower_materials() -> Dictionary:
	var stem := ShaderMaterial.new()
	stem.shader = SHADER_PLANT
	stem.set_shader_parameter("base_color", Color(0.25, 0.48, 0.18))
	var leaf := ShaderMaterial.new()
	leaf.shader = SHADER_PLANT
	leaf.set_shader_parameter("base_color", Color(0.3, 0.55, 0.2))
	leaf.set_shader_parameter("vein_strength", 0.25)
	var petal := ShaderMaterial.new()
	petal.shader = SHADER_PLANT
	petal.set_shader_parameter("base_color", Color(0.95, 0.45, 0.65))
	petal.set_shader_parameter("edge_color", Color(1.0, 0.85, 0.9))
	petal.set_shader_parameter("rim_strength", 1.5)
	petal.set_shader_parameter("roughness_val", 0.3)
	var stamen := ShaderMaterial.new()
	stamen.shader = SHADER_FLESH
	stamen.set_shader_parameter("skin_color", Color(1.0, 0.85, 0.3))
	stamen.set_shader_parameter("interior_color", Color(1.0, 0.5, 0.1))
	return {"stem": stem, "leaf": leaf, "petal": petal, "stamen": stamen}

func _fungus_materials() -> Dictionary:
	var stem := ShaderMaterial.new()
	stem.shader = SHADER_BARK
	stem.set_shader_parameter("bark_color", Color(0.85, 0.78, 0.65))
	stem.set_shader_parameter("crevice_color", Color(0.55, 0.45, 0.35))
	var cap := ShaderMaterial.new()
	cap.shader = SHADER_FLESH
	cap.set_shader_parameter("skin_color", Color(0.65, 0.28, 0.25))
	cap.set_shader_parameter("interior_color", Color(0.35, 0.1, 0.08))
	return {"default": stem, "body": stem, "cap": cap}


func apply_grid_config(_config_data: Dictionary) -> void:
	pass
