# sdf_gallery.gd
# A walkable museum of everything we've built in the SDF system:
#   Row A — Primitives (capsule, ellipsoid, box, rounded box, cone, rotated box)
#   Row B — Kingdoms (tree, walker, flower, fungus)
#   Row C — Flower↔Fungus transition (5 blend stops)
#   Row D — Modulor walkers at 3 fold levels
#   Row E — Operator demonstrations (5 variants)
#
# Each form sits on a small pedestal with its label floating above. The
# camera starts facing the entrance; you walk north to traverse the rows.
#
# Attach this script to a Node3D with a WorldEnvironment child, a
# DirectionalLight3D, and a Camera3D. The accompanying .tscn includes all.

extends Node3D

const CapsuleSDF       = preload("res://commons/morphology/sdf/capsule_sdf.gd")
const EllipsoidSDF     = preload("res://commons/morphology/sdf/ellipsoid_sdf.gd")
const BoxSDF           = preload("res://commons/morphology/sdf/box_sdf.gd")
const RoundedBoxSDF    = preload("res://commons/morphology/sdf/rounded_box_sdf.gd")
const ConeSDF          = preload("res://commons/morphology/sdf/cone_sdf.gd")
const SymmetryOp       = preload("res://commons/morphology/sdf/symmetry_op.gd")
const PatternOp        = preload("res://commons/morphology/sdf/pattern_op.gd")
const FoldOp           = preload("res://commons/morphology/sdf/fold_op.gd")
const TaperOp          = preload("res://commons/morphology/sdf/taper_op.gd")
const TreeBody         = preload("res://commons/morphology/sdf/tree_body.gd")
const WalkerBody       = preload("res://commons/morphology/sdf/walker_body.gd")
const FlowerBody       = preload("res://commons/morphology/sdf/flower_body.gd")
const FungusBody       = preload("res://commons/morphology/sdf/fungus_body.gd")
const ModulorWalker    = preload("res://commons/morphology/sdf/modulor_walker.gd")
const BlendedSDF       = preload("res://commons/morphology/sdf/blended_sdf.gd")
const SDFVoxelPreview  = preload("res://commons/morphology/sdf/sdf_voxel_preview.gd")
const FoldChain        = preload("res://commons/morphology/sdf/fold_chain.gd")
const SDFRaymarchPreview = preload("res://commons/morphology/sdf/sdf_raymarch_preview.gd")

const SHADER_PLANT = preload("res://commons/morphology/sdf/shaders/plant.gdshader")
const SHADER_FLESH = preload("res://commons/morphology/sdf/shaders/flesh.gdshader")
const SHADER_BARK  = preload("res://commons/morphology/sdf/shaders/bark.gdshader")

const ROW_SPACING: float = 6.0
const ITEM_SPACING: float = 2.5
const PEDESTAL_HEIGHT: float = 0.4

## When false, skips building the floor + header labels so the gallery can be
## dropped into a host scene (an Ada map) that provides its own ground.
@export var include_chrome: bool = true

## Which rows to build. Values: "primitives", "kingdoms", "transition",
## "modulor", "operators", "dna_variance", "stacked_ops". Empty array = all.
## Per-row mode is used by the seven Ada maps so each row can be tested in
## VR in isolation for performance profiling.
@export var visible_rows: PackedStringArray = PackedStringArray()


func _is_row_visible(name: String) -> bool:
	if visible_rows.is_empty():
		return true
	return visible_rows.has(name)


func _ready() -> void:
	if include_chrome:
		_build_floor()
	_build_rows()
	if include_chrome:
		_build_header_labels()


func _build_floor() -> void:
	# Large dark floor so the pedestals read against it. Centered on the
	# span of all rows — origin at row A, extend +Z through row G.
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(60, 56)
	floor_mesh.subdivide_width = 24
	floor_mesh.subdivide_depth = 24
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.08, 0.09, 0.12)
	mat.roughness = 0.95
	mat.metallic = 0.0
	floor_mesh.surface_set_material(0, mat)
	var floor_mi := MeshInstance3D.new()
	floor_mi.mesh = floor_mesh
	# Center floor on the middle of the row span (rows A..G → z = 0..36).
	floor_mi.position = Vector3(0, -0.01, ROW_SPACING * 3.0)
	add_child(floor_mi)


func _build_rows() -> void:
	# Shared DNA used by multiple rows — declared up front so row guards
	# don't break references.
	var kingdom_dna: Dictionary = {
		"scale": 0.8, "segments": 4.0, "symmetry": 6.0,
		"pattern_scale": 1.0, "pattern_density": 0.6,
	}

	# ─── Row A: Primitives (mesh rendering, neutral material) ───
	if _is_row_visible("primitives"):
		var row_a_z: float = 0.0
		var primitives: Array = [
			{"name": "Capsule",      "sdf": CapsuleSDF.make(Vector3(0, 0.2, 0), Vector3(0, 1.2, 0), 0.28)},
			{"name": "Ellipsoid",    "sdf": EllipsoidSDF.make(Vector3(0, 0.8, 0), Vector3(0.5, 0.7, 0.5))},
			{"name": "Box",          "sdf": BoxSDF.make(Vector3(0, 0.75, 0), Vector3(0.45, 0.45, 0.45))},
			{"name": "RoundedBox",   "sdf": RoundedBoxSDF.make(Vector3(0, 0.75, 0), Vector3(0.55, 0.4, 0.55), 0.14)},
			{"name": "Cone",         "sdf": ConeSDF.make(Vector3(0, 1.4, 0), Vector3(0, 0.2, 0), 0.45)},
			{"name": "RotatedBox",   "sdf": BoxSDF.make(Vector3(0, 0.8, 0), Vector3(0.4, 0.4, 0.4),
				Basis(Vector3.UP, deg_to_rad(30)) * Basis(Vector3.RIGHT, deg_to_rad(20)))},
		]
		for i in primitives.size():
			var entry: Dictionary = primitives[i]
			var x: float = (float(i) - float(primitives.size() - 1) * 0.5) * ITEM_SPACING
			_place_mesh_form(entry.sdf, Vector3(x, 0, row_a_z), entry.name, _neutral_material())

	# ─── Row B: Kingdoms (with shaders) ───
	if _is_row_visible("kingdoms"):
		var row_b_z: float = ROW_SPACING
		var kingdoms: Array = [
			{"name": "Tree",   "recipe": TreeBody,   "materials": _tree_materials()},
			{"name": "Walker", "recipe": WalkerBody, "materials": _walker_materials()},
			{"name": "Flower", "recipe": FlowerBody, "materials": _flower_materials()},
			{"name": "Fungus", "recipe": FungusBody, "materials": _fungus_materials()},
		]
		for i in kingdoms.size():
			var k: Dictionary = kingdoms[i]
			var x: float = (float(i) - float(kingdoms.size() - 1) * 0.5) * ITEM_SPACING * 1.4
			var body = k.recipe.new()
			body.dna = kingdom_dna
			body.joint_k = 0.08
			body.build()
			_place_body_recipe(body, Vector3(x, 0, row_b_z), k.name, k.materials)

	# ─── Row C: Flower ↔ Fungus transition at 5 stops + LIVE slider ───
	var row_c_z: float = ROW_SPACING * 2.0
	if _is_row_visible("transition"):
		for i in 5:
			var t_val: float = float(i) / 4.0
			var flower_stop = FlowerBody.new()
			flower_stop.dna = kingdom_dna
			flower_stop.build()
			var fungus_stop = FungusBody.new()
			fungus_stop.dna = kingdom_dna
			fungus_stop.build()
			var blend = BlendedSDF.new()
			blend.a = flower_stop
			blend.b = fungus_stop
			blend.t = t_val
			blend.mode = "weighted"
			blend.smoothness = 0.25
			blend.weighted_inflation = 0.35
			var x: float = (float(i) - 2.0) * ITEM_SPACING * 1.4
			_place_voxel_form(blend, Vector3(x, 0, row_c_z), "t=%.2f" % t_val)

		# Live-morph station — animates t on the center preview over time
		_build_live_morph_station(Vector3(0, 0, row_c_z + 2.2), kingdom_dna)

	# ─── Row D: Modulor walkers at three fold levels ───
	if _is_row_visible("modulor"):
		var row_d_z: float = ROW_SPACING * 3.0
		var modulor_levels: Array = [0, 2, 4]
		for i in modulor_levels.size():
			var offset: int = modulor_levels[i]
			var w = ModulorWalker.new()
			var dna: Dictionary = {
				"scale": 1.0, "segments": 4.0, "symmetry": 2.0,
				"ladder_offset": float(offset),
			}
			w.dna = dna
			w.joint_k = 0.04
			w.build()
			var x: float = (float(i) - 1.0) * ITEM_SPACING * 2.0
			_place_body_recipe(w, Vector3(x, 0, row_d_z), "rung %d" % offset, _walker_materials())

	# Prepare small_dna — shared between Row E and Row G.
	var small_dna: Dictionary = kingdom_dna.duplicate()
	small_dna["scale"] = 0.7

	# ─── Row E: Operator demonstrations ───
	if _is_row_visible("operators"):
		var row_e_z: float = ROW_SPACING * 4.0
		var op_walker_plain = WalkerBody.new(); op_walker_plain.dna = small_dna; op_walker_plain.build()
		var op_walker_noise = WalkerBody.new(); op_walker_noise.dna = small_dna; op_walker_noise.build()
		var op_walker_scales = WalkerBody.new(); op_walker_scales.dna = small_dna; op_walker_scales.build()
		var op_flower_folded = FlowerBody.new(); op_flower_folded.dna = small_dna; op_flower_folded.build()
		var op_tree_tapered = TreeBody.new(); op_tree_tapered.dna = small_dna; op_tree_tapered.build()

		var operators: Array = [
			{"name": "plain",    "sdf": op_walker_plain},
			{"name": "+noise",   "sdf": PatternOp.make(op_walker_noise, "noise", 0.8, 4.0, 0.05)},
			{"name": "+scales",  "sdf": PatternOp.make(op_walker_scales, "scales", 0.9, 3.0, 0.04)},
			{"name": "+fold",    "sdf": FoldOp.make(op_flower_folded, Vector3(0, 1.0, 0), Vector3.FORWARD, Vector3.UP, 0.7)},
			{"name": "+taper",   "sdf": TaperOp.make(op_tree_tapered, Vector3.UP, 0.0, 1.6, 0.35)},
		]
		for i in operators.size():
			var op: Dictionary = operators[i]
			var x: float = (float(i) - 2.0) * ITEM_SPACING * 1.3
			# Operators are static SDFs — raymarch gives smooth surfaces, 1 draw call.
			_place_raymarch_form(op.sdf, Vector3(x, 0, row_e_z), op.name,
				Color(0.85, 0.78, 0.7), Color(1.0, 0.9, 0.8))

	# ─── Row F: DNA variance — one kingdom, many genes ───
	if _is_row_visible("dna_variance"):
		var row_f_z: float = ROW_SPACING * 5.0
		var dna_variants: Array = [
			{"name": "3 petals",   "dna": {"scale": 0.8, "segments": 2.0, "symmetry": 3.0, "pattern_scale": 0.8}},
			{"name": "5 petals",   "dna": {"scale": 0.8, "segments": 3.0, "symmetry": 5.0, "pattern_scale": 1.0}},
			{"name": "7 petals",   "dna": {"scale": 0.8, "segments": 4.0, "symmetry": 7.0, "pattern_scale": 1.1}},
			{"name": "leggy",      "dna": {"scale": 1.0, "segments": 6.0, "symmetry": 5.0, "pattern_scale": 1.4}},
			{"name": "compact",    "dna": {"scale": 0.6, "segments": 2.0, "symmetry": 8.0, "pattern_scale": 0.7}},
		]
		for i in dna_variants.size():
			var v: Dictionary = dna_variants[i]
			var f = FlowerBody.new()
			f.dna = v.dna
			f.joint_k = 0.08
			f.build()
			var x: float = (float(i) - 2.0) * ITEM_SPACING * 1.3
			_place_body_recipe(f, Vector3(x, 0, row_f_z), v.name, _flower_materials())

	# ─── Row G: Stacked operators — compound modifiers on one body ───
	if _is_row_visible("stacked_ops"):
		var row_g_z: float = ROW_SPACING * 6.0
		var stack_walker = WalkerBody.new(); stack_walker.dna = small_dna; stack_walker.build()
		var stack_walker_both = WalkerBody.new(); stack_walker_both.dna = small_dna; stack_walker_both.build()
		var stack_flower = FlowerBody.new(); stack_flower.dna = small_dna; stack_flower.build()
		var stack_tree_1 = TreeBody.new(); stack_tree_1.dna = small_dna; stack_tree_1.build()
		var stack_tree_2 = TreeBody.new(); stack_tree_2.dna = small_dna; stack_tree_2.build()

		var stacks: Array = [
			{"name": "noise+fold", "sdf": FoldOp.make(
				PatternOp.make(stack_walker, "noise", 0.7, 4.0, 0.06),
				Vector3(0, 0.6, 0), Vector3.FORWARD, Vector3.UP, 0.6)},
			{"name": "scales+taper", "sdf": TaperOp.make(
				PatternOp.make(stack_walker_both, "scales", 0.9, 3.0, 0.04),
				Vector3.FORWARD, -2.0, 2.0, 0.55)},
			{"name": "flower fold", "sdf": FoldOp.make(
				stack_flower, Vector3(0, 1.0, 0), Vector3.FORWARD, Vector3.UP, 0.9)},
			{"name": "tree stripes", "sdf": PatternOp.make(
				TaperOp.make(stack_tree_1, Vector3.UP, 0.0, 2.0, 0.4),
				"stripes", 0.9, 6.0, 0.05)},
			{"name": "dots", "sdf": PatternOp.make(stack_tree_2, "dots", 0.7, 3.0, 0.05)},
		]
		for i in stacks.size():
			var s: Dictionary = stacks[i]
			var x: float = (float(i) - 2.0) * ITEM_SPACING * 1.3
			# Stacked ops are static — raymarch them for smooth surfaces.
			_place_raymarch_form(s.sdf, Vector3(x, 0, row_g_z), s.name,
				Color(0.88, 0.8, 0.72), Color(1.0, 0.92, 0.82))


func _build_header_labels() -> void:
	var rows: Array = [
		{"z": -1.8, "text": "SDF GALLERY — walk north to traverse"},
		{"z": -0.8, "text": "A · Primitives"},
		{"z": ROW_SPACING - 0.8, "text": "B · Kingdoms"},
		{"z": ROW_SPACING * 2.0 - 0.8, "text": "C · Transition"},
		{"z": ROW_SPACING * 3.0 - 0.8, "text": "D · Modulor ladder"},
		{"z": ROW_SPACING * 4.0 - 0.8, "text": "E · Operators"},
		{"z": ROW_SPACING * 5.0 - 0.8, "text": "F · DNA variance"},
		{"z": ROW_SPACING * 6.0 - 0.8, "text": "G · Stacked operators"},
	]
	for r in rows:
		var lbl := Label3D.new()
		lbl.text = r.text
		lbl.position = Vector3(-8.0, 0.02, float(r.z))
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.pixel_size = 0.01
		lbl.modulate = Color(0.7, 0.7, 0.8)
		lbl.outline_modulate = Color.BLACK
		lbl.rotation.x = -PI * 0.5  # lie flat on floor
		add_child(lbl)


# ─── Placement helpers ──────────────────────────────────────────

func _make_pedestal(pos: Vector3) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = Vector3(1.6, PEDESTAL_HEIGHT, 1.6)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.22, 0.25)
	mat.roughness = 0.8
	mesh.surface_set_material(0, mat)
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = pos + Vector3(0, PEDESTAL_HEIGHT * 0.5, 0)
	return mi


func _place_mesh_form(sdf: Resource, pos: Vector3, label: String, material: Material) -> void:
	add_child(_make_pedestal(pos))
	var parts: Array = sdf.build_mesh_parts()
	var container := Node3D.new()
	container.position = pos + Vector3(0, PEDESTAL_HEIGHT, 0)
	for p in parts:
		var mi := MeshInstance3D.new()
		mi.mesh = p["mesh"]
		mi.transform = p["transform"]
		mi.material_override = material
		container.add_child(mi)
	add_child(container)
	_label_pedestal(pos, label)


func _place_body_recipe(recipe: Resource, pos: Vector3, label: String, materials: Dictionary) -> void:
	add_child(_make_pedestal(pos))
	var body: Node3D = recipe.build_mesh_body(materials)
	body.position = pos + Vector3(0, PEDESTAL_HEIGHT, 0)
	add_child(body)
	_label_pedestal(pos, label)


func _place_voxel_form(sdf: Resource, pos: Vector3, label: String) -> void:
	add_child(_make_pedestal(pos))
	var preview = SDFVoxelPreview.new()
	preview.sdf = sdf
	preview.resolution = Vector3i(24, 32, 24)
	preview.surface_threshold = 0.08
	preview.auto_rebuild_on_ready = false
	preview.size_by_depth = false
	preview.position = pos + Vector3(0, PEDESTAL_HEIGHT, 0)
	add_child(preview)
	preview.rebuild()
	_label_pedestal(pos, label)


## Raymarch-rendered variant. Same semantics as _place_voxel_form but uses
## one MeshInstance3D + fragment-shader sphere-tracing instead of a voxel
## MultiMesh. Smooth surfaces, 1 draw call, ~1000× cheaper per-frame for
## static SDFs. Use this for rows where a smooth read matters and the
## SDF doesn't change per-frame.
func _place_raymarch_form(sdf: Resource, pos: Vector3, label: String,
		base: Color = Color(0.9, 0.85, 0.75),
		edge: Color = Color(1.0, 0.95, 0.8)) -> void:
	add_child(_make_pedestal(pos))
	var preview = SDFRaymarchPreview.new()
	preview.sdf = sdf
	preview.resolution = Vector3i(48, 48, 48)
	preview.base_color = base
	preview.edge_color = edge
	preview.rim_strength = 0.8
	preview.auto_rebuild_on_ready = false
	preview.position = pos + Vector3(0, PEDESTAL_HEIGHT, 0)
	add_child(preview)
	preview.rebuild()
	_label_pedestal(pos, label)


## A pedestal with a preview whose blend t animates continuously. The
## preview rebuilds at ~3 Hz. Beneath it, a "track" of 5 dot markers show
## the discrete stops so you can see where the animation is on the scale.
var _live_blend = null
var _live_preview = null
var _live_marker: MeshInstance3D = null
var _live_marker_base_y: float = 0.0
var _live_track_start: Vector3 = Vector3.ZERO
var _live_track_end: Vector3 = Vector3.ZERO
var _live_time: float = 0.0
var _last_live_rebuild: float = -1.0

func _build_live_morph_station(pos: Vector3, kingdom_dna: Dictionary) -> void:
	# Larger pedestal to announce this as the interactive exhibit
	var big_pedestal_mesh := BoxMesh.new()
	big_pedestal_mesh.size = Vector3(3.6, PEDESTAL_HEIGHT, 2.0)
	var pmat := StandardMaterial3D.new()
	pmat.albedo_color = Color(0.32, 0.32, 0.38)
	pmat.roughness = 0.7
	big_pedestal_mesh.surface_set_material(0, pmat)
	var pm := MeshInstance3D.new()
	pm.mesh = big_pedestal_mesh
	pm.position = pos + Vector3(0, PEDESTAL_HEIGHT * 0.5, 0)
	add_child(pm)

	# Build the animated blend
	var flower = FlowerBody.new()
	flower.dna = kingdom_dna
	flower.build()
	var fungus = FungusBody.new()
	fungus.dna = kingdom_dna
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
	_live_preview.position = pos + Vector3(0, PEDESTAL_HEIGHT, 0)
	add_child(_live_preview)
	_live_preview.rebuild()

	# Track beneath the preview — 5 small dots at the five discrete stops
	var track_y: float = pos.y + PEDESTAL_HEIGHT + 0.05
	_live_track_start = pos + Vector3(-1.4, PEDESTAL_HEIGHT + 0.02, -0.8)
	_live_track_end = pos + Vector3(1.4, PEDESTAL_HEIGHT + 0.02, -0.8)
	for i in 5:
		var t: float = float(i) / 4.0
		var dot := MeshInstance3D.new()
		var dot_mesh := SphereMesh.new()
		dot_mesh.radius = 0.05
		dot_mesh.height = 0.1
		dot.mesh = dot_mesh
		dot.position = _live_track_start.lerp(_live_track_end, t)
		var dmat := StandardMaterial3D.new()
		dmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		dmat.albedo_color = Color(0.5, 0.5, 0.6)
		dot.material_override = dmat
		add_child(dot)

	# Sliding marker sphere that walks the track as t animates
	_live_marker = MeshInstance3D.new()
	var mmesh := SphereMesh.new()
	mmesh.radius = 0.09
	mmesh.height = 0.18
	_live_marker.mesh = mmesh
	var mmat := StandardMaterial3D.new()
	mmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mmat.albedo_color = Color(1.0, 0.65, 0.3)
	_live_marker.material_override = mmat
	_live_marker.position = _live_track_start
	_live_marker_base_y = _live_track_start.y
	add_child(_live_marker)

	# Label
	var lbl := Label3D.new()
	lbl.text = "live morph →"
	lbl.position = pos + Vector3(0, PEDESTAL_HEIGHT + 2.4, 0)
	lbl.pixel_size = 0.009
	lbl.modulate = Color(1.0, 0.7, 0.4)
	lbl.outline_modulate = Color.BLACK
	add_child(lbl)


func _process(delta: float) -> void:
	if _live_blend == null or _live_preview == null:
		return
	_live_time += delta
	# Ping-pong t between 0 and 1 at 0.2 Hz
	var phase: float = 0.5 + 0.5 * sin(_live_time * 0.6)
	_live_blend.t = phase
	# Marker rides the track at current t
	if _live_marker != null:
		_live_marker.position = _live_track_start.lerp(_live_track_end, phase)
	# Rebuild preview at ~3 Hz — voxel resample is cheap at this resolution
	if _live_time - _last_live_rebuild > 0.33:
		_last_live_rebuild = _live_time
		_live_preview.rebuild()


func _label_pedestal(pos: Vector3, text: String) -> void:
	var lbl := Label3D.new()
	lbl.text = text
	lbl.position = pos + Vector3(0, PEDESTAL_HEIGHT + 0.05, 1.0)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.pixel_size = 0.008
	lbl.modulate = Color(0.95, 0.9, 0.8)
	lbl.outline_modulate = Color.BLACK
	add_child(lbl)


# ─── Material factories ─────────────────────────────────────────

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
