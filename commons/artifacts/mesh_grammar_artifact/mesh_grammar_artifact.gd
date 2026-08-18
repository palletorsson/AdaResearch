# mesh_grammar_artifact.gd
# Placeable wrapper around MeshGrammarNode. Reads a mesh-grammar config
# (basic seed type — cube/sphere/icosahedron — plus a list of rules) and
# builds the resulting procedural mesh. Mirrors render_mesh_grammar.gd's
# build core, dropping the camera/light/DNA-bridge complexity.
#
# Configs with seed types like {"ca": ...}, {"rd": ...}, {"lsystem": ...},
# {"compose": [...]} are NOT supported here yet — those need the bridges
# in render_mesh_grammar.gd. For those, fall back to image_billboard.
# Most of the gen00_*/gen01_* configs use basic string seeds and work fine.
#
# @identity
# essence: a mesh-grammar config rendered as a placeable Node3D
# desire: petals, mushrooms, towers, coral — gallery findings as 3D objects
# critical_parameter: config_path — the JSON config (seed + rules + generations)
# triggers: instantiation, apply_grid_config
# emerges: face-rewriting grammar produces meshes that inhabit maps
# needs: MeshGrammarNode + ops in commons/mesh_grammar/
# relationships: same build path as render_mesh_grammar (minus DNA bridges)
# truth: a face is rewritten until it becomes form

extends Node3D
class_name MeshGrammarArtifact

const ExtrudeFaceOp = preload("res://commons/mesh_grammar/operations/extrude_face_op.gd")
const InsetFaceOp   = preload("res://commons/mesh_grammar/operations/inset_face_op.gd")
const BulgeOp       = preload("res://commons/mesh_grammar/operations/bulge_op.gd")
const TubeBranchOp  = preload("res://commons/mesh_grammar/operations/tube_branch_op.gd")
const SplitFaceOp   = preload("res://commons/mesh_grammar/operations/split_face_op.gd")
const DeleteFaceOp  = preload("res://commons/mesh_grammar/operations/delete_face_op.gd")
const NoiseDisplaceOp = preload("res://commons/mesh_grammar/operations/noise_displace_op.gd")
const ScaleFaceOp   = preload("res://commons/mesh_grammar/operations/scale_face_op.gd")
const RotateFaceOp  = preload("res://commons/mesh_grammar/operations/rotate_face_op.gd")
const ScallopEdgeOp = preload("res://commons/mesh_grammar/operations/scallop_edge_op.gd")
const PetalSplayOp  = preload("res://commons/mesh_grammar/operations/petal_splay_op.gd")
const ScaleTileOp   = preload("res://commons/mesh_grammar/operations/scale_tile_op.gd")
const EdgeDecorateOp = preload("res://commons/mesh_grammar/operations/edge_decorate_op.gd")
const SurfaceScatterOp = preload("res://commons/mesh_grammar/operations/surface_scatter_op.gd")
const SmoothSubdivideOp = preload("res://commons/mesh_grammar/operations/smooth_subdivide_op.gd")

@export var config_path: String = ""
@export var vr_preview: bool = true   # cap generations for fast in-VR loads

var _current: Node = null


func _ready() -> void:
	if config_path.strip_edges().is_empty(): return
	_build()


func apply_grid_config(cfg: Dictionary) -> void:
	if cfg.has("config_path"): config_path = str(cfg["config_path"])
	_clear()
	_build()


func _clear() -> void:
	if _current:
		_current.queue_free()
		_current = null
	for c in get_children():
		c.queue_free()


func _build() -> void:
	if config_path.is_empty(): return
	var txt := FileAccess.get_file_as_string(config_path)
	if txt.is_empty():
		push_warning("[mesh_grammar_artifact] config not found: %s" % config_path)
		return
	var j := JSON.new()
	if j.parse(txt) != OK or not (j.data is Dictionary):
		push_warning("[mesh_grammar_artifact] bad JSON: %s" % config_path)
		return
	var cfg: Dictionary = j.data
	if vr_preview:
		cfg["generations"] = mini(int(cfg.get("generations", 2)), 2)

	# Skip DNA-bridged seeds — those need render_mesh_grammar's bridge code.
	# Falls back to a minimal cube so something visible appears.
	var seed_val = cfg.get("seed", "cube")
	var seed_type: String = "cube"
	if seed_val is String:
		seed_type = str(seed_val)
		if not seed_type in ["cube", "sphere", "icosahedron"]:
			seed_type = "cube"
	# Otherwise (Dictionary seed) keep cube — DNA bridge support is a TODO.

	var MeshGrammarNodeCls: GDScript = load("res://commons/mesh_grammar/mesh_grammar_node.gd")
	if MeshGrammarNodeCls == null:
		push_warning("[mesh_grammar_artifact] MeshGrammarNode script missing")
		return
	var mg_node = MeshGrammarNodeCls.new()
	mg_node.seed_type = seed_type
	mg_node.seed_scale = float(cfg.get("seed_scale", 0.6))
	mg_node.generations = int(cfg.get("generations", 2))
	mg_node.auto_generate = false
	mg_node.base_color = Color(0.82, 0.76, 0.6)
	if cfg.has("material") or cfg.has("roughness") or cfg.has("metallic"):
		if mg_node.has_method("configure"):
			mg_node.configure(cfg)

	for rdef in cfg.get("rules", []):
		var rule = _build_rule(rdef)
		if rule != null:
			mg_node.add_rule(rule)

	add_child(mg_node)
	_current = mg_node

	# MeshGrammarNode generates after entering the tree.
	# out-of-tree guard: get_tree() is null once a map is torn down mid-build
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	if mg_node.has_method("generate_all"):
		mg_node.generate_all()
	elif mg_node.has_method("generate"):
		mg_node.generate()


func _build_rule(rdef: Dictionary):
	var op: String = str(rdef.get("op", ""))
	var sel_str: String = str(rdef.get("selector", "all"))
	var params: Dictionary = rdef.get("params", {})
	var sel := _parse_selector(sel_str)
	match op:
		"extrude":          return ExtrudeFaceOp.new(sel, params)
		"bulge":            return BulgeOp.new(sel, params)
		"tube_branch":      return TubeBranchOp.new(sel, params)
		"inset":            return InsetFaceOp.new(sel, params)
		"split":            return SplitFaceOp.new(sel, params)
		"delete":           return DeleteFaceOp.new(sel, params)
		"noise":            return NoiseDisplaceOp.new(sel, params)
		"scale":            return ScaleFaceOp.new(sel, params)
		"rotate":           return RotateFaceOp.new(sel, params)
		"scallop":          return ScallopEdgeOp.new(sel, params)
		"petal_splay":      return PetalSplayOp.new(sel, params)
		"scale_tile":       return ScaleTileOp.new(sel, params)
		"edge_decorate":    return EdgeDecorateOp.new(sel, params)
		"scatter":          return SurfaceScatterOp.new(sel, params)
		"smooth_subdivide": return SmoothSubdivideOp.new(sel, params)
	push_warning("[mesh_grammar_artifact] unknown op: %s" % op)
	return null


func _parse_selector(s: String) -> MeshSelector:
	match s:
		"all":       return MeshSelector.all_faces()
		"up":        return MeshSelector.by_normal_direction(Vector3.UP, 60.0)
		"down":      return MeshSelector.by_normal_direction(Vector3.DOWN, 60.0)
		"side":      return MeshSelector.by_normal_direction(Vector3.UP, 60.0).not_matching().and_also(
			MeshSelector.by_normal_direction(Vector3.DOWN, 60.0).not_matching())
		"up_random": return MeshSelector.by_normal_direction(Vector3.UP, 60.0).and_also(MeshSelector.by_random(0.25))
		"random_30": return MeshSelector.by_random(0.3)
		"random_50": return MeshSelector.by_random(0.5)
		"boundary":  return MeshSelector.by_boundary()
	if s.begins_with("tag:"):
		return MeshSelector.by_tag(s.substr(4))
	if s.begins_with("depth:"):
		var d := int(s.substr(6))
		return MeshSelector.by_depth(d, d)
	if s.begins_with("index:"):
		var idx := int(s.substr(6))
		return MeshSelector.by_index(PackedInt32Array([idx]))
	return MeshSelector.all_faces()
