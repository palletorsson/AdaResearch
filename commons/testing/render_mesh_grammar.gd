extends SceneTree

## Render one mesh grammar config to a PNG.
## Reads a JSON config, builds a MeshGrammarNode with the specified rules,
## applies N generations, and saves a single-angle screenshot.
##
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/render_mesh_grammar.gd -- \
##     --config=<path to config.json> --out=user://mg_gallery/<id>.png \
##     --size=640

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
const LSystemBranchOp = preload("res://commons/mesh_grammar/operations/lsystem_branch_op.gd")
const CellularSurfaceOp = preload("res://commons/mesh_grammar/operations/cellular_surface_op.gd")
const TagByGrammarOp    = preload("res://commons/mesh_grammar/operations/tag_by_grammar_op.gd")
const PaintByTagOp      = preload("res://commons/mesh_grammar/operations/paint_by_tag_op.gd")
const HideByRuleOp      = preload("res://commons/mesh_grammar/operations/hide_by_rule_op.gd")
const ExtrudeByRoleOp   = preload("res://commons/mesh_grammar/operations/extrude_by_role_op.gd")
const BulgeByRoleOp     = preload("res://commons/mesh_grammar/operations/bulge_by_role_op.gd")
const ClusterByRoleOp   = preload("res://commons/mesh_grammar/operations/cluster_by_role_op.gd")
const ReplaceWithMeshByRoleOp = preload("res://commons/mesh_grammar/operations/replace_with_mesh_by_role_op.gd")
const SmoothSubdivideOp = preload("res://commons/mesh_grammar/operations/smooth_subdivide_op.gd")
const MarkBillboardAnchorsOp = preload("res://commons/mesh_grammar/operations/mark_billboard_anchors_op.gd")
const RDSimScriptMG      = preload("res://commons/rd_grammar/rd_sim.gd")
const MeshDataClass      = preload("res://commons/mesh_grammar/mesh_data.gd")

## Named shortcut → scene path for Ada's primitive library.
## Any scene in commons/primitives/ can be used directly via "res://..." path;
## these are just convenience aliases so configs can say "dodecahedron".
const PRIMITIVE_LIBRARY := {
	"dodecahedron":  "res://commons/primitives/dodecahedron/dodecahedron.tscn",
	"octahedron":    "res://commons/primitives/octahedron/octahedron.tscn",
	"tetrahedron":   "res://commons/primitives/tetrahedron/tetrahedron.tscn",
	"bipyramid":     "res://commons/primitives/bipyramid/bipyramid.tscn",
	"crystal":       "res://commons/primitives/crystal/crystal.tscn",
	"diamond":       "res://commons/primitives/diamond/diamond.tscn",
	"arch":          "res://commons/primitives/arch/arch.tscn",
}

## Shortcut → Godot built-in mesh class (for shapes without their own .tscn).
const PRIMITIVE_BUILTIN_MESHES := {
	"cylinder": "CylinderMesh",
	"torus":    "TorusMesh",
	"capsule":  "CapsuleMesh",
	"prism":    "PrismMesh",
	"cone":     "cone",                # special: CylinderMesh with top_radius=0
}
const LSystemSimMG       = preload("res://commons/lsystem_grammar/lsystem_sim.gd")
const LSystemTurtleMG    = preload("res://commons/lsystem_grammar/lsystem_turtle.gd")
const CAPruneOpMG        = preload("res://commons/graph_grammar/operations/ca_prune_op.gd")

var _config_path: String = ""
var _output_path: String = "user://mg_gallery/out.png"
var _size: int = 640
var _wait: float = 1.0


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty():
		push_error("render_mesh_grammar: --config=<path> required")
		quit(1); return
	call_deferred("_run")


func _parse_args() -> void:
	for raw in OS.get_cmdline_user_args():
		var a := String(raw).strip_edges()
		if not a.begins_with("--"): continue
		var eq := a.find("=")
		if eq <= 2: continue
		var key := a.substr(2, eq - 2)
		var val := a.substr(eq + 1)
		match key:
			"config": _config_path = val
			"out":    _output_path = val
			"size":   if val.is_valid_int(): _size = clampi(int(val), 128, 2048)
			"wait":   if val.is_valid_float(): _wait = float(val)


func _run() -> void:
	# Load config
	var abs_config := ProjectSettings.globalize_path(_config_path)
	if not FileAccess.file_exists(abs_config) and not FileAccess.file_exists(_config_path):
		push_error("render_mesh_grammar: config not found: %s" % _config_path)
		quit(1); return
	var txt := FileAccess.get_file_as_string(_config_path if FileAccess.file_exists(_config_path) else abs_config)
	if txt.is_empty() and FileAccess.file_exists(abs_config):
		txt = FileAccess.get_file_as_string(abs_config)
	var json := JSON.new()
	if json.parse(txt) != OK or not (json.data is Dictionary):
		push_error("render_mesh_grammar: invalid config JSON")
		quit(1); return
	var config: Dictionary = json.data

	# Build scene
	var scene := Node3D.new()
	scene.name = "MGRender"
	root.add_child(scene)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.09, 0.1, 0.14)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.55, 0.55, 0.6)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	var we := WorldEnvironment.new(); we.environment = env
	scene.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -28, 0)
	key.light_energy = 1.3
	key.shadow_enabled = true
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 130, 0)
	fill.light_energy = 0.35
	scene.add_child(fill)

	# Ground
	var ground := MeshInstance3D.new()
	var gm := PlaneMesh.new(); gm.size = Vector2(14, 14)
	ground.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.12, 0.13, 0.16); gmat.roughness = 0.95
	ground.material_override = gmat
	ground.position = Vector3(0, -0.05, 0)
	scene.add_child(ground)

	# Camera placeholder — refined after we know AABB
	var cam := Camera3D.new()
	cam.current = true
	cam.fov = 45
	scene.add_child(cam)

	# Build mesh grammar node from config
	var MeshGrammarNodeCls: GDScript = load("res://commons/mesh_grammar/mesh_grammar_node.gd")
	var mg_node = MeshGrammarNodeCls.new()

	# DNA BRIDGE — seed can be a string (cube/sphere/icosahedron) OR a dict
	# that invokes another substrate: {"rd": {...}} builds a heightmap mesh
	# from Gray-Scott, {"lsystem": {...}} / {"ca": {...}} reserved for next.
	var seed_val = config.get("seed", "cube")
	var custom_seed_mesh = null
	if seed_val is Dictionary:
		if seed_val.has("rd") and seed_val["rd"] is Dictionary:
			custom_seed_mesh = _build_rd_seed_mesh(seed_val["rd"])
			mg_node.seed_type = "custom"
		elif seed_val.has("lsystem") and seed_val["lsystem"] is Dictionary:
			custom_seed_mesh = _build_lsystem_seed_mesh(seed_val["lsystem"])
			mg_node.seed_type = "custom"
		elif seed_val.has("ca") and seed_val["ca"] is Dictionary:
			custom_seed_mesh = _build_ca_seed_mesh(seed_val["ca"])
			mg_node.seed_type = "custom"
		elif seed_val.has("graph") and seed_val["graph"] is Dictionary:
			custom_seed_mesh = _build_graph_seed_mesh(seed_val["graph"])
			mg_node.seed_type = "custom"
		elif seed_val.has("graph_grammar") and seed_val["graph_grammar"] is Dictionary:
			custom_seed_mesh = _build_graph_grammar_seed_mesh(seed_val["graph_grammar"])
			mg_node.seed_type = "custom"
		elif seed_val.has("compose") and seed_val["compose"] is Array:
			custom_seed_mesh = await _build_composed_seed_mesh(seed_val["compose"])
			mg_node.seed_type = "custom"
		elif seed_val.has("scene"):
			custom_seed_mesh = await _load_scene_seed_mesh(str(seed_val["scene"]))
			if custom_seed_mesh != null:
				mg_node.seed_type = "custom"
			else:
				mg_node.seed_type = "cube"
		else:
			mg_node.seed_type = "cube"
	else:
		# String seed — try built-ins first, fall through to primitive library
		var s := str(seed_val)
		if s.begins_with("res://"):
			custom_seed_mesh = await _load_scene_seed_mesh(s)
			mg_node.seed_type = "custom" if custom_seed_mesh != null else "cube"
		elif PRIMITIVE_LIBRARY.has(s):
			custom_seed_mesh = await _load_scene_seed_mesh(PRIMITIVE_LIBRARY[s])
			mg_node.seed_type = "custom" if custom_seed_mesh != null else "cube"
		elif PRIMITIVE_BUILTIN_MESHES.has(s):
			custom_seed_mesh = _build_from_builtin_mesh(s, float(config.get("seed_scale", 0.6)))
			mg_node.seed_type = "custom" if custom_seed_mesh != null else "cube"
		else:
			mg_node.seed_type = s   # cube / sphere / icosahedron — native to MeshGrammarNode

	mg_node.seed_scale = float(config.get("seed_scale", 0.6))
	mg_node.generations = int(config.get("generations", 2))
	mg_node.auto_generate = false
	mg_node.base_color = Color(0.82, 0.76, 0.6)
	# Forward material sub-dict so configs can drive surface qualities
	# (metallic/roughness/iridescence/transparency/emission). These also
	# match CritterDNA's surface fields one-for-one for round-trip parity.
	if config.has("material") or config.has("roughness") or config.has("metallic"):
		mg_node.configure(config)

	var rules_arr: Array = config.get("rules", [])
	for rdef in rules_arr:
		var rule = _build_rule(rdef)
		if rule != null:
			mg_node.add_rule(rule)

	scene.add_child(mg_node)

	# Install custom seed mesh AFTER adding to tree (grammar exists now)
	if custom_seed_mesh != null:
		mg_node.set_seed_mesh(custom_seed_mesh)

	# Generate — MeshGrammarNode does the work
	await process_frame
	if mg_node.has_method("generate_all"):
		mg_node.generate_all()
	elif mg_node.has_method("generate"):
		mg_node.generate()
	await process_frame
	await process_frame

	# Foliage billboards — collect any face_metadata billboard markers
	# emitted by mark_billboard_anchors_op into one MultiMesh per atlas.
	# This is the cheap-foliage path: alpha-tested quads instead of
	# stamped solid primitives. Counts get logged so configs can verify
	# the budget savings.
	var BillboardCollector = load("res://commons/foliage/billboard_collector.gd")
	if BillboardCollector != null and mg_node.grammar != null \
			and mg_node.grammar.current_mesh != null:
		var n_atlases: int = BillboardCollector.collect_into(
			mg_node, mg_node.grammar.current_mesh)
		if n_atlases > 0:
			# Re-bake the main mesh now that billboard faces were removed.
			mg_node._update_display(mg_node.grammar.current_mesh)
			print("[render_mesh_grammar] billboards: %d MultiMesh batch(es) installed" % n_atlases)
		await process_frame

	# Seat the generated form on the floor plane so the ground does not cut through it.
	var prelift_aabb := _combined_aabb(mg_node)
	var floor_clearance: float = float(config.get("floor_clearance", 0.05))
	var target_min_y := ground.position.y + floor_clearance
	if prelift_aabb.position.y < target_min_y:
		mg_node.position.y += target_min_y - prelift_aabb.position.y
		await process_frame

	# Frame camera on the result
	var aabb := _combined_aabb(mg_node)
	var center: Vector3 = aabb.get_center()
	var focus_y_bias: float = float(config.get("camera_focus_y_bias", -0.08))
	var fit_padding: float = float(config.get("camera_fit_padding", 0.72))
	var focus: Vector3 = center + Vector3(0.0, aabb.size.y * focus_y_bias, 0.0)
	var yaw: float = float(config.get("camera_yaw", 0.55))
	var pitch: float = float(config.get("camera_pitch", 0.35))   # positive = looking down from above
	# Convenience preset: camera_angle = "top" | "iso" | "side" | "front"
	var cam_angle: String = String(config.get("camera_angle", "")).to_lower()
	match cam_angle:
		"top":   yaw = 0.0;  pitch = 1.45   # near-vertical, looking down — flowers from above
		"iso":   yaw = 0.55; pitch = 0.55
		"side":  yaw = 1.5708; pitch = 0.0
		"front": yaw = 0.0;  pitch = 0.0
	var orbit_dir := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)).normalized()
	var forward := -orbit_dir
	var basis := _camera_basis_from_forward(forward)
	var dist: float = _fit_distance_for_aabb(aabb, focus, basis, deg_to_rad(cam.fov), 1.0, fit_padding)
	var offset := orbit_dir * maxf(dist, 1.8)
	cam.global_position = focus + offset
	cam.look_at(focus, Vector3.UP)

	# Viewport size
	root.content_scale_size = Vector2i(_size, _size)
	root.size = Vector2i(_size, _size)

	await create_timer(_wait).timeout
	await process_frame
	await process_frame

	var img: Image = root.get_texture().get_image()
	if img == null:
		push_error("render_mesh_grammar: no viewport image"); quit(1); return

	var abs_out := ProjectSettings.globalize_path(_output_path)
	var od := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(od):
		DirAccess.make_dir_recursive_absolute(od)
	var err := img.save_png(abs_out)
	if err != OK:
		push_error("render_mesh_grammar: save failed")
		quit(1); return
	print("render_mesh_grammar: saved %s" % abs_out)
	quit(0)


func _build_rule(rdef: Dictionary):
	var op: String = str(rdef.get("op", ""))
	var sel_str: String = str(rdef.get("selector", "all"))
	var params: Dictionary = rdef.get("params", {})
	var sel := _parse_selector(sel_str)
	match op:
		"extrude":       return ExtrudeFaceOp.new(sel, params)
		"bulge":         return BulgeOp.new(sel, params)
		"tube_branch":   return TubeBranchOp.new(sel, params)
		"inset":         return InsetFaceOp.new(sel, params)
		"split":         return SplitFaceOp.new(sel, params)
		"delete":        return DeleteFaceOp.new(sel, params)
		"noise":         return NoiseDisplaceOp.new(sel, params)
		"scale":         return ScaleFaceOp.new(sel, params)
		"rotate":        return RotateFaceOp.new(sel, params)
		"scallop":       return ScallopEdgeOp.new(sel, params)
		"petal_splay":   return PetalSplayOp.new(sel, params)
		"scale_tile":    return ScaleTileOp.new(sel, params)
		"edge_decorate": return EdgeDecorateOp.new(sel, params)
		"scatter":       return SurfaceScatterOp.new(sel, params)
		"lsystem_branch":return LSystemBranchOp.new(sel, params)
		"cellular":      return CellularSurfaceOp.new(sel, params)
		"tag_by_grammar": return TagByGrammarOp.new(sel, params)
		"paint_by_tag":   return PaintByTagOp.new(sel, params)
		"hide_by_rule":   return HideByRuleOp.new(sel, params)
		"extrude_by_role": return ExtrudeByRoleOp.new(sel, params)
		"bulge_by_role":   return BulgeByRoleOp.new(sel, params)
		"cluster_by_role": return ClusterByRoleOp.new(sel, params)
		"replace_with_mesh_by_role": return ReplaceWithMeshByRoleOp.new(sel, params)
		"smooth_subdivide": return SmoothSubdivideOp.new(sel, params)
		"mark_billboard_anchors": return MarkBillboardAnchorsOp.new(sel, params)
	push_warning("Unknown op: %s" % op)
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
	# Accept composed selectors like "tag:extruded_top"
	if s.begins_with("tag:"):
		return MeshSelector.by_tag(s.substr(4))
	if s.begins_with("depth:"):
		var d := int(s.substr(6))
		return MeshSelector.by_depth(d, d)
	if s.begins_with("index:"):
		var idx := int(s.substr(6))
		return MeshSelector.by_index(PackedInt32Array([idx]))
	if s.begins_with("indices:"):
		var raw := s.substr(8).split(",", false)
		var indices := PackedInt32Array()
		for part in raw:
			var p := String(part).strip_edges()
			if p.is_valid_int():
				indices.append(int(p))
		return MeshSelector.by_index(indices)
	return MeshSelector.all_faces()


func _combined_aabb(node: Node3D) -> AABB:
	var first := true
	var total := AABB()
	var stack: Array = [node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D and n.mesh:
			var ab: AABB = n.global_transform * n.get_aabb()
			if first: total = ab; first = false
			else: total = total.merge(ab)
		for c in n.get_children():
			if c is Node3D:
				stack.append(c)
	if first:
		return AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	return total


func _camera_basis_from_forward(forward: Vector3) -> Dictionary:
	var world_up := Vector3.UP
	if abs(forward.dot(world_up)) > 0.98:
		world_up = Vector3.FORWARD
	var right := forward.cross(world_up).normalized()
	var up := right.cross(forward).normalized()
	return {
		"forward": forward,
		"right": right,
		"up": up,
	}


func _fit_distance_for_aabb(
		aabb: AABB,
		focus: Vector3,
		basis: Dictionary,
		vfov: float,
		aspect: float,
		padding: float) -> float:
	var tan_v: float = tan(vfov * 0.5) * padding
	var tan_h: float = tan(atan(tan(vfov * 0.5) * aspect)) * padding
	var forward: Vector3 = basis["forward"]
	var right: Vector3 = basis["right"]
	var up: Vector3 = basis["up"]
	var required_dist: float = 0.0
	for corner in _aabb_corners(aabb):
		var rel: Vector3 = corner - focus
		var x: float = abs(rel.dot(right))
		var y: float = abs(rel.dot(up))
		var z_offset: float = rel.dot(forward)
		required_dist = maxf(required_dist, x / maxf(tan_h, 0.001) - z_offset)
		required_dist = maxf(required_dist, y / maxf(tan_v, 0.001) - z_offset)
	var max_dim: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	return maxf(required_dist + max_dim * 0.12, 1.8)


func _aabb_corners(aabb: AABB) -> Array[Vector3]:
	var p: Vector3 = aabb.position
	var s: Vector3 = aabb.size
	return [
		Vector3(p.x, p.y, p.z),
		Vector3(p.x + s.x, p.y, p.z),
		Vector3(p.x, p.y + s.y, p.z),
		Vector3(p.x, p.y, p.z + s.z),
		Vector3(p.x + s.x, p.y + s.y, p.z),
		Vector3(p.x + s.x, p.y, p.z + s.z),
		Vector3(p.x, p.y + s.y, p.z + s.z),
		Vector3(p.x + s.x, p.y + s.y, p.z + s.z),
	]


## DNA BRIDGE — build a heightmap MeshData from a Gray-Scott RD simulation.
## The V-concentration field lifts each grid vertex on the Y axis, producing
## a terrain-like mesh that mesh-grammar ops can then face-rewrite (extrude
## ridges, inset valleys, bevel peaks).
func _build_rd_seed_mesh(rd_cfg: Dictionary):
	var N: int = int(rd_cfg.get("grid_size", 48))
	var world_size: float = float(rd_cfg.get("world_size", 0.7))
	var height_amp: float = float(rd_cfg.get("height_amp", 0.35))
	var field: PackedFloat32Array = RDSimScriptMG.simulate(rd_cfg)

	var verts := PackedVector3Array()
	var cell: float = world_size * 2.0 / float(N - 1)
	for iy in N:
		for ix in N:
			var x: float = -world_size + float(ix) * cell
			var z: float = -world_size + float(iy) * cell
			var h: float = field[iy * N + ix] * height_amp
			verts.append(Vector3(x, h, z))

	# Triangular faces covering the grid
	var faces: Array = []
	for iy in N - 1:
		for ix in N - 1:
			var i0: int = iy * N + ix
			var i1: int = iy * N + ix + 1
			var i2: int = (iy + 1) * N + ix + 1
			var i3: int = (iy + 1) * N + ix
			faces.append([i0, i1, i2])
			faces.append([i0, i2, i3])
	print("render_mesh_grammar: RD seed mesh %dx%d -> %d verts, %d faces" % [
		N, N, verts.size(), faces.size()])
	return MeshDataClass.from_arrays(verts, faces)


## DNA BRIDGE — build L-system seed mesh. Each turtle segment becomes a
## short oriented box (12 triangles). Mesh-grammar ops can then extrude
## branches, bulge leaves, or inset facets on the resulting tree-mesh.
func _build_lsystem_seed_mesh(ls_cfg: Dictionary):
	var axiom: String = String(ls_cfg.get("axiom", "F"))
	var rules: Dictionary = ls_cfg.get("rules", {})
	var iters: int = int(ls_cfg.get("iterations", 3))
	var s: String = LSystemSimMG.rewrite(axiom, rules, iters)
	var walk: Dictionary = LSystemTurtleMG.walk(s, {
		"angle_deg":   float(ls_cfg.get("angle_deg", 25.7)),
		"step_len":    float(ls_cfg.get("step_len", 0.15)),
		"step_shrink": float(ls_cfg.get("step_shrink", 0.72)),
		"base_width":  float(ls_cfg.get("base_width", 0.015)),
		"width_shrink":float(ls_cfg.get("width_shrink", 0.75)),
	})
	var segments: Array = walk["segments"]
	var verts := PackedVector3Array()
	var faces: Array = []

	for seg in segments:
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var w: float = max(float(seg[3]), 0.01)
		var axis: Vector3 = b - a
		var L: float = axis.length()
		if L < 1e-4: continue
		axis = axis / L
		# Build a local frame perpendicular to segment
		var up: Vector3 = Vector3.UP if absf(axis.dot(Vector3.UP)) < 0.95 else Vector3.RIGHT
		var right: Vector3 = axis.cross(up).normalized() * w
		var fwd: Vector3 = axis.cross(right).normalized() * w
		var base: int = verts.size()
		verts.append(a - right - fwd); verts.append(a + right - fwd)
		verts.append(a + right + fwd); verts.append(a - right + fwd)
		verts.append(b - right - fwd); verts.append(b + right - fwd)
		verts.append(b + right + fwd); verts.append(b - right + fwd)
		# 12 triangles for the 6 box faces
		var idx := [
			[base+0, base+2, base+1], [base+0, base+3, base+2], # bottom
			[base+4, base+5, base+6], [base+4, base+6, base+7], # top
			[base+0, base+1, base+5], [base+0, base+5, base+4], # side
			[base+1, base+2, base+6], [base+1, base+6, base+5],
			[base+2, base+3, base+7], [base+2, base+7, base+6],
			[base+3, base+0, base+4], [base+3, base+4, base+7],
		]
		for tri in idx: faces.append(tri)

	print("render_mesh_grammar: L-system seed mesh %d segments -> %d verts, %d faces" % [
		segments.size(), verts.size(), faces.size()])
	return MeshDataClass.from_arrays(verts, faces)


## DNA BRIDGE — build CA seed mesh. Each alive cell becomes a box; height
## scaled by live-neighbor count (same convention as ca_conway_city).
func _build_ca_seed_mesh(ca_cfg: Dictionary):
	var rule_name: String = String(ca_cfg.get("rule", "conway"))
	var N: int = int(ca_cfg.get("grid_size", 16))
	var iters: int = int(ca_cfg.get("iterations", 8))
	var density: float = float(ca_cfg.get("density", 0.45))
	var seed_val: int = int(ca_cfg.get("seed", 7))
	var cell_world: float = float(ca_cfg.get("cell_size", 0.08))
	var base_h: float = float(ca_cfg.get("base_height", 0.05))
	var h_scale: float = float(ca_cfg.get("height_scale", 0.03))

	var rules_def := {
		"conway":             {"B": [3],       "S": [2, 3]},
		"highlife":           {"B": [3, 6],    "S": [2, 3]},
		"seeds":              {"B": [2],       "S": []},
		"life_without_death": {"B": [3],       "S": [0,1,2,3,4,5,6,7,8]},
		"day_and_night":      {"B": [3,6,7,8], "S": [3,4,6,7,8]},
	}
	var r_def: Dictionary = rules_def.get(rule_name, rules_def["conway"])
	var grid: PackedInt32Array = CAPruneOpMG._simulate_ca(
		N, r_def["B"], r_def["S"], iters, density, seed_val)

	var verts := PackedVector3Array()
	var faces: Array = []
	var hw: float = cell_world * 0.45
	var origin_x: float = -float(N - 1) * 0.5 * cell_world
	var origin_z: float = -float(N - 1) * 0.5 * cell_world

	for iy in N:
		for ix in N:
			if grid[iy * N + ix] == 0: continue
			# neighbor count
			var n: int = 0
			for dy in [-1, 0, 1]:
				for dx in [-1, 0, 1]:
					if dx == 0 and dy == 0: continue
					var rr: int = iy + dy; var cc: int = ix + dx
					if rr < 0 or rr >= N or cc < 0 or cc >= N: continue
					if grid[rr * N + cc] == 1: n += 1
			var h: float = base_h + float(n) * h_scale
			var cx: float = origin_x + float(ix) * cell_world
			var cz: float = origin_z + float(iy) * cell_world
			var base: int = verts.size()
			verts.append(Vector3(cx - hw, 0,   cz - hw)); verts.append(Vector3(cx + hw, 0,   cz - hw))
			verts.append(Vector3(cx + hw, 0,   cz + hw)); verts.append(Vector3(cx - hw, 0,   cz + hw))
			verts.append(Vector3(cx - hw, h,   cz - hw)); verts.append(Vector3(cx + hw, h,   cz - hw))
			verts.append(Vector3(cx + hw, h,   cz + hw)); verts.append(Vector3(cx - hw, h,   cz + hw))
			var idx := [
				[base+0, base+2, base+1], [base+0, base+3, base+2],
				[base+4, base+5, base+6], [base+4, base+6, base+7],
				[base+0, base+1, base+5], [base+0, base+5, base+4],
				[base+1, base+2, base+6], [base+1, base+6, base+5],
				[base+2, base+3, base+7], [base+2, base+7, base+6],
				[base+3, base+0, base+4], [base+3, base+4, base+7],
			]
			for tri in idx: faces.append(tri)

	print("render_mesh_grammar: CA seed mesh %s %dx%d -> %d verts, %d faces" % [
		rule_name, N, N, verts.size(), faces.size()])
	return MeshDataClass.from_arrays(verts, faces)


## DNA BRIDGE — evolve a graph_grammar from rules, then skin it.
## This is the moment graph_grammar becomes a first-class mesh-grammar
## seed. Spec:
##   seed_node: {"pos":[x,y,z], "radius":r, "tags":["..."]}
##   rules: [{"op":"spawn_branch"|"subdivide_edge"|"noise_radii"|"noise_displace"|"sine_radii",
##            "selector":"all"|"leaves"|"roots"|"tag:foo", "params":{...}}, ...]
##   generations: int
##   skin_segments: int (passed to skin_graph)
func _build_graph_grammar_seed_mesh(gg_cfg: Dictionary):
	var GraphState = load("res://commons/graph_grammar/graph_state.gd")
	var GraphGrammar = load("res://commons/graph_grammar/graph_grammar.gd")
	var GraphSelector = load("res://commons/graph_grammar/graph_selector.gd")
	var SpawnBranchOp = load("res://commons/graph_grammar/operations/spawn_branch_op.gd")
	var SubdivideEdgeOp = load("res://commons/graph_grammar/operations/subdivide_edge_op.gd")
	var NoiseRadiiOp = load("res://commons/graph_grammar/operations/noise_radii_op.gd")
	var NoiseDisplaceOpGG = load("res://commons/graph_grammar/operations/noise_displace_op.gd")
	var SineRadiiOp = load("res://commons/graph_grammar/operations/sine_radii_op.gd")

	var state = GraphState.new()
	# Seed node.
	var seed_pos := Vector3.ZERO
	var seed_radius: float = 0.15
	var seed_tags := PackedStringArray(["leaf"])
	if gg_cfg.has("seed_node") and gg_cfg["seed_node"] is Dictionary:
		var sn: Dictionary = gg_cfg["seed_node"]
		if sn.has("pos") and sn["pos"] is Array:
			var pa: Array = sn["pos"]
			if pa.size() >= 3:
				seed_pos = Vector3(float(pa[0]), float(pa[1]), float(pa[2]))
		seed_radius = float(sn.get("radius", seed_radius))
		var tags_in = sn.get("tags", null)
		if tags_in is Array:
			seed_tags = PackedStringArray()
			for t in tags_in:
				seed_tags.append(String(t))
	state.add_node(seed_pos, seed_radius, -1, seed_tags)

	var grammar = GraphGrammar.new()
	grammar.set_seed(state)
	grammar.max_nodes = int(gg_cfg.get("max_nodes", 1500))

	for rdef in gg_cfg.get("rules", []):
		if not (rdef is Dictionary): continue
		var op_name: String = String(rdef.get("op", ""))
		var sel_str: String = String(rdef.get("selector", "leaves"))
		var p: Dictionary = rdef.get("params", {})
		var sel = null
		match sel_str:
			"all": sel = GraphSelector.all_nodes()
			"leaves": sel = GraphSelector.leaves()
			"roots": sel = GraphSelector.roots()
			_:
				if sel_str.begins_with("tag:"):
					sel = GraphSelector.by_tag(sel_str.substr(4))
				else:
					sel = GraphSelector.leaves()
		var rule = null
		match op_name:
			"spawn_branch":   rule = SpawnBranchOp.new(sel, p)
			"subdivide_edge": rule = SubdivideEdgeOp.new(sel, p)
			"noise_radii":    rule = NoiseRadiiOp.new(sel, p)
			"noise_displace": rule = NoiseDisplaceOpGG.new(sel, p)
			"sine_radii":     rule = SineRadiiOp.new(sel, p)
			_: push_warning("graph_grammar: unknown op %s" % op_name)
		if rule != null:
			grammar.add_rule(rule)

	grammar.apply_n(int(gg_cfg.get("generations", 3)))
	var final_state = grammar.state
	# Convert to skin_graph inputs.
	var nodes: Array = []
	var radii: Array = []
	for i in range(final_state.nodes.size()):
		nodes.append(final_state.nodes[i])
		radii.append(final_state.radii[i])
	var edges: Array = []
	for e in final_state.edges:
		edges.append([int(e[0]), int(e[1])])
	var packed_tags: Array = []
	for t in final_state.node_tags:
		var p2 := PackedStringArray()
		for s in t:
			p2.append(String(s))
		packed_tags.append(p2)
	var segments: int = int(gg_cfg.get("skin_segments", 6))
	var skin_mode: String = String(gg_cfg.get("skin_mode", "node_caps"))
	print("[render_mesh_grammar] graph_grammar evolved: %d nodes, %d edges -> skin segments=%d, mode=%s" % [
		nodes.size(), edges.size(), segments, skin_mode])
	return MeshDataClass.skin_graph(nodes, radii, edges, packed_tags, segments, skin_mode)


## DNA BRIDGE — compose multiple seeds into a single tagged mesh.
## Each entry is itself a seed spec (any of the seed dispatcher branches:
## flower_disk shorthand, graph, lsystem, scene, primitive name, ...) with
## an optional "offset": [x,y,z]. The first seed becomes the base; each
## subsequent seed is merged in via MeshData.merge.
##
## Enables a complete flower in one config: a flower_disk for petals/sepals
## merged with a stamen-ring graph for filaments, all tag-labelled.
func _build_composed_seed_mesh(compose_arr: Array):
	var base = null
	for entry in compose_arr:
		if not (entry is Dictionary):
			continue
		var entry_dict: Dictionary = entry
		var offset := Vector3.ZERO
		if entry_dict.has("offset") and entry_dict["offset"] is Array \
				and (entry_dict["offset"] as Array).size() >= 3:
			var oa: Array = entry_dict["offset"]
			offset = Vector3(float(oa[0]), float(oa[1]), float(oa[2]))
		var sub = null
		if entry_dict.has("graph") and entry_dict["graph"] is Dictionary:
			sub = _build_graph_seed_mesh(entry_dict["graph"])
		elif entry_dict.has("rd") and entry_dict["rd"] is Dictionary:
			sub = _build_rd_seed_mesh(entry_dict["rd"])
		elif entry_dict.has("lsystem") and entry_dict["lsystem"] is Dictionary:
			sub = _build_lsystem_seed_mesh(entry_dict["lsystem"])
		elif entry_dict.has("ca") and entry_dict["ca"] is Dictionary:
			sub = _build_ca_seed_mesh(entry_dict["ca"])
		elif entry_dict.has("scene"):
			sub = await _load_scene_seed_mesh(str(entry_dict["scene"]))
		elif entry_dict.has("primitive"):
			# Built-in named primitive at given scale.
			var name := String(entry_dict["primitive"])
			var sc := float(entry_dict.get("scale", 0.6))
			match name:
				"disk": sub = MeshDataClass.create_disk(sc, int(entry_dict.get("segments", 24)))
				"flower_disk": sub = MeshDataClass.create_flower_disk(
					sc, int(entry_dict.get("rings", 5)), int(entry_dict.get("segments", 24)))
				"cube": sub = MeshDataClass.create_cube(sc)
				"sphere": sub = MeshDataClass.create_sphere(sc, 12, 16)
				"icosahedron": sub = MeshDataClass.create_icosahedron(sc)
		if sub == null:
			continue
		# Apply per-seed extra tags so downstream paint_by_tag can address
		# this composite section even if the seed didn't tag itself.
		if entry_dict.has("tag"):
			var t := String(entry_dict["tag"])
			for fi in range(sub.face_tags.size()):
				sub.face_tags[fi].append(t)
		if base == null:
			# Translate base too if offset was given.
			if offset != Vector3.ZERO:
				for vi in range(sub.vertices.size()):
					sub.vertices[vi] = sub.vertices[vi] + offset
			base = sub
		else:
			base.merge(sub, offset)
	print("[render_mesh_grammar] composed seed: %d verts / %d faces from %d entries" % [
		(base.vertices.size() if base else 0),
		(base.faces.size() if base else 0),
		compose_arr.size()])
	return base


## DNA BRIDGE — skin a literal graph spec into a tagged tube mesh.
## Spec keys:
##   nodes: Array[Vector3 | [x,y,z]]
##   radii: Array[float] (matched to nodes)
##   edges: Array[[parent_idx, child_idx]]
##   node_tags: Array[Array[String]] (matched to nodes)
##   segments: int (default 8)
##   preset: String — convenience presets (e.g. "stamen_ring", "insect_legs")
func _build_graph_seed_mesh(g_cfg: Dictionary):
	# Allow named presets to bootstrap common topologies without hand-writing
	# 24 nodes for an insect.
	var preset: String = String(g_cfg.get("preset", "")).to_lower()
	var nodes_arr: Array = []
	var radii_arr: Array = []
	var edges_arr: Array = []
	var tags_arr: Array = []
	if preset == "stamen_ring":
		# Centre pistil + N stamen stalks rising at slight outward tilt.
		var n: int = int(g_cfg.get("count", 12))
		var ring_r: float = float(g_cfg.get("ring_radius", 0.5))
		var height: float = float(g_cfg.get("height", 0.7))
		var tilt: float = float(g_cfg.get("tilt", 0.15))
		nodes_arr.append(Vector3.ZERO)
		radii_arr.append(0.06); tags_arr.append(["base"])
		for i in range(n):
			var theta: float = TAU * float(i) / float(n)
			var bx: float = cos(theta) * ring_r * 0.25
			var bz: float = sin(theta) * ring_r * 0.25
			var tx: float = cos(theta) * (ring_r + tilt)
			var tz: float = sin(theta) * (ring_r + tilt)
			var base_idx: int = nodes_arr.size()
			nodes_arr.append(Vector3(bx, 0.0, bz))
			radii_arr.append(0.04); tags_arr.append(["stalk_base"])
			edges_arr.append([0, base_idx])
			var tip_idx: int = nodes_arr.size()
			nodes_arr.append(Vector3(tx, height, tz))
			radii_arr.append(0.06); tags_arr.append(["anther"])
			edges_arr.append([base_idx, tip_idx])
	elif preset == "spider":
		# Round abdomen + small thorax + 8 legs in 4 pairs, all branching from thorax.
		var leg_len: float = float(g_cfg.get("leg_length", 0.55))
		nodes_arr.append(Vector3(0, 0.18, -0.25))     # head
		radii_arr.append(0.06); tags_arr.append(["head"])
		nodes_arr.append(Vector3(0, 0.18, 0))          # thorax (idx 1)
		radii_arr.append(0.13); tags_arr.append(["thorax"])
		edges_arr.append([0, 1])
		nodes_arr.append(Vector3(0, 0.16, 0.35))       # abdomen (idx 2)
		radii_arr.append(0.22); tags_arr.append(["abdomen"])
		edges_arr.append([1, 2])
		# Eight legs in 4 pairs, each two segments.
		var z_offsets: Array = [-0.10, -0.03, 0.04, 0.11]
		for zi in range(z_offsets.size()):
			for side in [-1.0, 1.0]:
				var anchor_idx: int = nodes_arr.size()
				nodes_arr.append(Vector3(0.10 * side, 0.18, z_offsets[zi]))
				radii_arr.append(0.04); tags_arr.append(["coxa"])
				edges_arr.append([1, anchor_idx])
				var knee_idx: int = nodes_arr.size()
				nodes_arr.append(Vector3(0.42 * side, 0.30, z_offsets[zi] + 0.08 * side))
				radii_arr.append(0.03); tags_arr.append(["femur"])
				edges_arr.append([anchor_idx, knee_idx])
				var foot_idx: int = nodes_arr.size()
				nodes_arr.append(Vector3(0.55 * side, -0.05, z_offsets[zi] + 0.20 * side))
				radii_arr.append(0.018); tags_arr.append(["tibia"])
				edges_arr.append([knee_idx, foot_idx])
	elif preset == "bee":
		# Plump body + antennae + 6 legs + 2 wing stubs.
		nodes_arr.append(Vector3(0, 0.18, -0.45))      # head
		radii_arr.append(0.12); tags_arr.append(["head"])
		nodes_arr.append(Vector3(0, 0.18, -0.15))      # thorax (idx 1)
		radii_arr.append(0.16); tags_arr.append(["thorax"])
		edges_arr.append([0, 1])
		nodes_arr.append(Vector3(0, 0.18, 0.25))       # abdomen
		radii_arr.append(0.20); tags_arr.append(["abdomen"])
		edges_arr.append([1, 2])
		nodes_arr.append(Vector3(0, 0.16, 0.55))       # stinger
		radii_arr.append(0.04); tags_arr.append(["abdomen"])
		edges_arr.append([2, 3])
		# Antennae from head.
		nodes_arr.append(Vector3(-0.08, 0.32, -0.55))
		radii_arr.append(0.02); tags_arr.append(["antenna"])
		edges_arr.append([0, 4])
		nodes_arr.append(Vector3(0.08, 0.32, -0.55))
		radii_arr.append(0.02); tags_arr.append(["antenna"])
		edges_arr.append([0, 5])
		# Wings (short stub each side).
		nodes_arr.append(Vector3(-0.45, 0.32, -0.05))
		radii_arr.append(0.05); tags_arr.append(["wing"])
		edges_arr.append([1, 6])
		nodes_arr.append(Vector3(0.45, 0.32, -0.05))
		radii_arr.append(0.05); tags_arr.append(["wing"])
		edges_arr.append([1, 7])
		# Six legs in 3 pairs.
		for zi in range(3):
			var z: float = -0.10 + 0.10 * float(zi)
			for side in [-1.0, 1.0]:
				var aix: int = nodes_arr.size()
				nodes_arr.append(Vector3(0.12 * side, 0.18, z))
				radii_arr.append(0.04); tags_arr.append(["coxa"])
				edges_arr.append([1, aix])
				var kix: int = nodes_arr.size()
				nodes_arr.append(Vector3(0.30 * side, 0.05, z + 0.04))
				radii_arr.append(0.03); tags_arr.append(["femur"])
				edges_arr.append([aix, kix])
				var fix: int = nodes_arr.size()
				nodes_arr.append(Vector3(0.36 * side, -0.10, z + 0.08))
				radii_arr.append(0.02); tags_arr.append(["tibia"])
				edges_arr.append([kix, fix])
	elif preset == "insect_legs":
		# Body axis + 6 three-segment legs (coxa-femur-tibia).
		var body_len: float = float(g_cfg.get("body_length", 0.9))
		var leg_len: float = float(g_cfg.get("leg_length", 0.45))
		var head_idx: int = nodes_arr.size()
		nodes_arr.append(Vector3(0, 0.18, -body_len * 0.5))
		radii_arr.append(0.10); tags_arr.append(["head"])
		var thorax_idx: int = nodes_arr.size()
		nodes_arr.append(Vector3(0, 0.18, 0))
		radii_arr.append(0.13); tags_arr.append(["thorax"])
		edges_arr.append([head_idx, thorax_idx])
		var abdomen_idx: int = nodes_arr.size()
		nodes_arr.append(Vector3(0, 0.18, body_len * 0.6))
		radii_arr.append(0.14); tags_arr.append(["abdomen"])
		edges_arr.append([thorax_idx, abdomen_idx])
		# Six legs anchored to thorax at three z-offsets.
		var z_offsets: Array = [-0.18, 0.0, 0.18]
		for zi in range(z_offsets.size()):
			for side in [-1.0, 1.0]:
				var anchor_idx: int = nodes_arr.size()
				nodes_arr.append(Vector3(0.10 * side, 0.18, z_offsets[zi]))
				radii_arr.append(0.05); tags_arr.append(["coxa"])
				edges_arr.append([thorax_idx, anchor_idx])
				var knee_idx: int = nodes_arr.size()
				nodes_arr.append(Vector3(0.32 * side, 0.10, z_offsets[zi] + 0.05))
				radii_arr.append(0.04); tags_arr.append(["femur"])
				edges_arr.append([anchor_idx, knee_idx])
				var foot_idx: int = nodes_arr.size()
				nodes_arr.append(Vector3(0.42 * side, -0.05, z_offsets[zi] + 0.10))
				radii_arr.append(0.025); tags_arr.append(["tibia"])
				edges_arr.append([knee_idx, foot_idx])
	else:
		# Literal graph from JSON.
		for n in g_cfg.get("nodes", []):
			if n is Array and n.size() >= 3:
				nodes_arr.append(Vector3(float(n[0]), float(n[1]), float(n[2])))
			elif n is Vector3:
				nodes_arr.append(n)
		for r in g_cfg.get("radii", []):
			radii_arr.append(float(r))
		for e in g_cfg.get("edges", []):
			if e is Array and e.size() >= 2:
				edges_arr.append([int(e[0]), int(e[1])])
		for t in g_cfg.get("node_tags", []):
			tags_arr.append(t if t is Array else [])
	var segments: int = int(g_cfg.get("segments", 8))
	var skin_mode: String = String(g_cfg.get("skin_mode", "node_caps"))
	# Pad missing tag slots so skin_graph indexing is safe.
	while tags_arr.size() < nodes_arr.size():
		tags_arr.append([])
	# Convert tag entries to PackedStringArray for skin_graph.
	var packed_tags: Array = []
	for t in tags_arr:
		var p := PackedStringArray()
		for s in t:
			p.append(String(s))
		packed_tags.append(p)
	print("[render_mesh_grammar] graph seed: %d nodes, %d edges, segments=%d, mode=%s" % [
		nodes_arr.size(), edges_arr.size(), segments, skin_mode])
	return MeshDataClass.skin_graph(nodes_arr, radii_arr, edges_arr, packed_tags, segments, skin_mode)


## Scene-path seed — load any scene from Ada's primitive library (or anywhere),
## walk for the first MeshInstance3D, extract its ArrayMesh, convert to MeshData.
## Enables mesh-grammar to seed from any primitive without per-shape boilerplate.
func _load_scene_seed_mesh(scene_path: String):
	if not ResourceLoader.exists(scene_path):
		push_warning("render_mesh_grammar: scene not found: %s" % scene_path)
		return null
	var packed: PackedScene = load(scene_path)
	if packed == null:
		push_warning("render_mesh_grammar: could not load scene: %s" % scene_path)
		return null
	var instance: Node = packed.instantiate()
	if instance == null: return null
	# Add to tree briefly so _ready() runs — many primitives build geometry there.
	root.add_child(instance)
	await process_frame
	var mi = _first_mesh_instance(instance)
	var md = null
	if mi and mi.mesh is ArrayMesh:
		md = MeshDataClass.from_array_mesh(mi.mesh as ArrayMesh)
		print("render_mesh_grammar: scene seed %s -> %d verts, %d faces" % [
			scene_path, md.vertices.size(), md.faces.size()])
	elif mi and mi.mesh != null:
		# Convert non-ArrayMesh (e.g. PrimitiveMesh subclass) via surface arrays
		var am := ArrayMesh.new()
		var arrays: Array = mi.mesh.surface_get_arrays(0)
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		md = MeshDataClass.from_array_mesh(am)
		print("render_mesh_grammar: scene seed %s (primitive→array) -> %d verts, %d faces" % [
			scene_path, md.vertices.size(), md.faces.size()])
	else:
		push_warning("render_mesh_grammar: no MeshInstance3D found in %s" % scene_path)
	instance.queue_free()
	return md


func _first_mesh_instance(node: Node):
	if node is MeshInstance3D and node.mesh != null:
		return node
	for child in node.get_children():
		var found = _first_mesh_instance(child)
		if found != null: return found
	return null


## Godot built-in mesh → MeshData. For shapes Ada's primitive library doesn't
## have a .tscn for (cylinder, torus, capsule, prism, cone).
func _build_from_builtin_mesh(name: String, scale_val: float):
	var mesh: PrimitiveMesh = null
	match name:
		"cylinder":
			var cm := CylinderMesh.new()
			cm.top_radius = scale_val * 0.5; cm.bottom_radius = scale_val * 0.5
			cm.height = scale_val; cm.radial_segments = 12; cm.rings = 1
			mesh = cm
		"cone":
			var co := CylinderMesh.new()
			co.top_radius = 0.0; co.bottom_radius = scale_val * 0.5
			co.height = scale_val; co.radial_segments = 12
			mesh = co
		"torus":
			var tm := TorusMesh.new()
			tm.inner_radius = scale_val * 0.25; tm.outer_radius = scale_val * 0.5
			tm.rings = 16; tm.ring_segments = 10
			mesh = tm
		"capsule":
			var cap := CapsuleMesh.new()
			cap.radius = scale_val * 0.3; cap.height = scale_val
			cap.radial_segments = 12; cap.rings = 6
			mesh = cap
		"prism":
			var pm := PrismMesh.new()
			pm.size = Vector3(scale_val, scale_val, scale_val)
			mesh = pm
		_:
			return null
	if mesh == null: return null
	var am := ArrayMesh.new()
	var arrays: Array = mesh.surface_get_arrays(0)
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var md = MeshDataClass.from_array_mesh(am)
	print("render_mesh_grammar: builtin seed %s -> %d verts, %d faces" % [
		name, md.vertices.size(), md.faces.size()])
	return md
