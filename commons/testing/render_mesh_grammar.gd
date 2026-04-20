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
	ground.position = Vector3(0, -0.01, 0)
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

	# Frame camera on the result
	var aabb := _combined_aabb(mg_node)
	var center: Vector3 = aabb.get_center()
	var max_dim: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	var dist: float = maxf(max_dim * 2.2, 1.5)
	var yaw: float = float(config.get("camera_yaw", 0.55))
	var pitch: float = float(config.get("camera_pitch", 0.35))   # positive = looking down from above
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	cam.global_position = center + offset
	cam.look_at(center, Vector3.UP)

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
