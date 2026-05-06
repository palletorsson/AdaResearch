extends SceneTree

## Render a graph grammar config to a PNG.
## Config JSON shape:
##   {
##     "id": "tree_01",
##     "seed": {"pos": [0,0,0], "radius": 0.18},
##     "iterations": 4,
##     "rules": [
##       {"op": "spawn_branch", "selector": "leaves",
##        "params": {"count": 3, "length": 0.8, "spread_deg": 40}},
##       ...
##     ]
##   }

# Preload scripts under distinct names to avoid clashing with their class_name globals.
const GraphStateScript    = preload("res://commons/graph_grammar/graph_state.gd")
const GraphSelectorScript = preload("res://commons/graph_grammar/graph_selector.gd")
const GraphGrammarScript  = preload("res://commons/graph_grammar/graph_grammar.gd")
const GraphToMeshScript   = preload("res://commons/graph_grammar/graph_to_mesh.gd")
const SpawnBranchOpScript = preload("res://commons/graph_grammar/operations/spawn_branch_op.gd")
const SubdivideEdgeOpScript = preload("res://commons/graph_grammar/operations/subdivide_edge_op.gd")
const SpaceColonizeOpScript = preload("res://commons/graph_grammar/operations/space_colonize_op.gd")
const LeafTuftOpScript = preload("res://commons/graph_grammar/operations/leaf_tuft_op.gd")
const NoiseDisplaceOpScript = preload("res://commons/graph_grammar/operations/noise_displace_op.gd")
const NoiseRadiiOpScript = preload("res://commons/graph_grammar/operations/noise_radii_op.gd")
const SineRadiiOpScript = preload("res://commons/graph_grammar/operations/sine_radii_op.gd")
const SineDisplaceOpScript = preload("res://commons/graph_grammar/operations/sine_displace_op.gd")
const RDDisplaceOpScript = preload("res://commons/graph_grammar/operations/rd_displace_op.gd")
const ParametricDisplaceOpScript = preload("res://commons/graph_grammar/operations/parametric_displace_op.gd")
const SymmetryOpScript = preload("res://commons/graph_grammar/operations/symmetry_op.gd")
const CAPruneOpScript = preload("res://commons/graph_grammar/operations/ca_prune_op.gd")
const HullShellOpScript = preload("res://commons/graph_grammar/operations/hull_shell_op.gd")
const FractalPruneOpScript = preload("res://commons/graph_grammar/operations/fractal_prune_op.gd")
const KochEdgeOpScript = preload("res://commons/graph_grammar/operations/koch_edge_op.gd")
const ModulorFoldOpScript = preload("res://commons/graph_grammar/operations/modulor_fold_op.gd")
const LSystemSimScript    = preload("res://commons/lsystem_grammar/lsystem_sim.gd")
const LSystemTurtleScriptGG = preload("res://commons/lsystem_grammar/lsystem_turtle.gd")
const SoftBodySimScriptGG = preload("res://commons/soft_body/soft_body_sim.gd")
const NoiseDisplaceScriptGG = preload("res://commons/noise_grammar/noise_displace.gd")
const RDSimScriptGG         = preload("res://commons/rd_grammar/rd_sim.gd")
const GraphToBoxesScript = preload("res://commons/graph_grammar/graph_to_boxes.gd")
const GraphToChandelierScript = preload("res://commons/graph_grammar/graph_to_chandelier.gd")
const GraphMetaballSDFScript = preload("res://commons/graph_grammar/graph_metaball_sdf.gd")
const SDFMarchingCubesScript = preload("res://commons/morphology/sdf/sdf_marching_cubes.gd")

const SHADER_PLANT = preload("res://commons/morphology/sdf/shaders/plant.gdshader")
const SHADER_BARK  = preload("res://commons/morphology/sdf/shaders/bark.gdshader")
const SHADER_FLESH = preload("res://commons/morphology/sdf/shaders/flesh.gdshader")

var _config_path: String = ""
var _output_path: String = "user://gg_gallery/out.png"
var _size: int = 640
var _wait: float = 1.0


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty():
		push_error("render_graph_grammar: --config required")
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
	var txt := FileAccess.get_file_as_string(_config_path)
	if txt.is_empty():
		var abs_p := ProjectSettings.globalize_path(_config_path)
		txt = FileAccess.get_file_as_string(abs_p)
	if txt.is_empty():
		push_error("render_graph_grammar: empty config")
		quit(1); return
	var j := JSON.new()
	if j.parse(txt) != OK or not (j.data is Dictionary):
		push_error("render_graph_grammar: bad JSON"); quit(1); return
	var cfg: Dictionary = j.data

	# Build scene
	var scene := Node3D.new()
	scene.name = "GGRender"
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
	key.light_energy = 1.3; key.shadow_enabled = true
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 130, 0); fill.light_energy = 0.35
	scene.add_child(fill)

	var ground := MeshInstance3D.new()
	var gm := PlaneMesh.new(); gm.size = Vector2(14, 14)
	ground.mesh = gm
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.12, 0.13, 0.16); gmat.roughness = 0.95
	ground.material_override = gmat
	ground.position = Vector3(0, -0.01, 0)
	scene.add_child(ground)

	# Build graph. Single root via seed: {pos, radius} OR multiple roots
	# via seed: {roots: [{pos, radius}, ...]} — each becomes an
	# independent growth origin, and the grammar rules fire against all
	# leaves across all roots.
	var seed_cfg: Dictionary = cfg.get("seed", {})
	var g: Object = GraphStateScript.new()
	if seed_cfg.has("roots") and seed_cfg["roots"] is Array:
		# Explicit list of roots
		g.nodes.clear(); g.radii.clear(); g.parents.clear()
		g.edges.clear(); g.node_tags.clear(); g.node_depth.clear()
		for r in seed_cfg["roots"]:
			var rp := _as_vec3(r.get("pos", [0.0, 0.0, 0.0]))
			var rr := float(r.get("radius", 0.15))
			g.add_node(rp, rr, -1, PackedStringArray(["root", "leaf"]))
	elif seed_cfg.has("modulor") and seed_cfg["modulor"] is Dictionary:
		# Modulor-seeded root at rung 0 (or specified level). Anchor
		# position is origin by default. Category tag from config or auto.
		var ms: Dictionary = seed_cfg["modulor"]
		var level: int = int(ms.get("level", 0))
		var pos := _as_vec3(ms.get("pos", [0.0, 0.0, 0.0]))
		var cat: String = str(ms.get("category", "auto"))
		if cat == "auto":
			var tbl: Array = ModulorFoldOpScript.CATEGORY_TABLE
			if level >= 0 and level < tbl.size(): cat = tbl[level]
			else: cat = "default"
		var rad_factor: float = float(ms.get("radius_factor", 0.08))
		var rung_m: float = ModulorFoldOpScript.ModulorScale.red(level)
		var root_radius: float = rung_m * rad_factor
		g.nodes.clear(); g.radii.clear(); g.parents.clear()
		g.edges.clear(); g.node_tags.clear(); g.node_depth.clear()
		g.add_node(pos, root_radius, -1, PackedStringArray([
			"modulor_%d" % level, cat, "root", "leaf",
		]))
	elif seed_cfg.has("ca_scatter") and seed_cfg["ca_scatter"] is Dictionary:
		# CA-as-seeder: run a 2-state CA, drop one seed per alive cell.
		# Conceptually different from ca_prune — here the CA COMPUTES positions,
		# not filters existing ones. Patterns become the ecology directly.
		var ca: Dictionary = seed_cfg["ca_scatter"]
		var rule_name: String = str(ca.get("rule", "conway"))
		var iters: int = int(ca.get("iterations", 20))
		var N: int = int(ca.get("grid_size", 24))
		var region_size: float = float(ca.get("region_size", 2.5))
		var density: float = float(ca.get("density", 0.35))
		var seed_val: int = int(ca.get("seed", 7))
		var y_level: float = float(ca.get("y", 0.0))
		var base_r: float = float(ca.get("radius", 0.1))
		var jitter: float = float(ca.get("jitter", 0.0))
		var ca_rules: Dictionary = {
			"conway":             {"B": [3],       "S": [2, 3]},
			"highlife":           {"B": [3, 6],    "S": [2, 3]},
			"seeds":              {"B": [2],       "S": []},
			"life_without_death": {"B": [3],       "S": [0, 1, 2, 3, 4, 5, 6, 7, 8]},
			"day_and_night":      {"B": [3, 6, 7, 8], "S": [3, 4, 6, 7, 8]},
		}
		var r_def: Dictionary = ca_rules.get(rule_name, ca_rules["conway"])
		var grid := CAPruneOpScript._simulate_ca(N, r_def["B"], r_def["S"], iters, density, seed_val)
		g.nodes.clear(); g.radii.clear(); g.parents.clear()
		g.edges.clear(); g.node_tags.clear(); g.node_depth.clear()
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_val * 31 + 17
		var cell_size: float = region_size * 2.0 / float(N)
		var placed: int = 0
		for iy in N:
			for ix in N:
				if grid[iy * N + ix] == 0: continue
				var px: float = -region_size + (float(ix) + 0.5) * cell_size
				var pz: float = -region_size + (float(iy) + 0.5) * cell_size
				if jitter > 0.0:
					px += rng.randf_range(-jitter, jitter) * cell_size * 0.5
					pz += rng.randf_range(-jitter, jitter) * cell_size * 0.5
				g.add_node(Vector3(px, y_level, pz), base_r, -1,
					PackedStringArray(["root", "leaf"]))
				placed += 1
		print("render_graph_grammar: CA scatter placed %d seeds (rule=%s)" % [placed, rule_name])
	elif seed_cfg.has("scatter") and seed_cfg["scatter"] is Dictionary:
		# Poisson-like scatter: distribute N seeds in a region
		var sc: Dictionary = seed_cfg["scatter"]
		var n: int = int(sc.get("count", 8))
		var region_size: float = float(sc.get("region_size", 2.5))
		var min_dist: float = float(sc.get("min_dist", 0.5))
		var region_shape: String = str(sc.get("shape", "disk"))
		var base_r: float = float(sc.get("radius", 0.12))
		var seed_val: int = int(sc.get("seed", 7))
		var y_level: float = float(sc.get("y", 0.0))
		g.nodes.clear(); g.radii.clear(); g.parents.clear()
		g.edges.clear(); g.node_tags.clear(); g.node_depth.clear()
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_val
		var placed: Array[Vector3] = []
		var attempts: int = 0
		var max_attempts: int = n * 30
		while placed.size() < n and attempts < max_attempts:
			attempts += 1
			var x: float = rng.randf_range(-region_size, region_size)
			var z: float = rng.randf_range(-region_size, region_size)
			if region_shape == "disk" and Vector2(x, z).length() > region_size:
				continue
			var candidate := Vector3(x, y_level, z)
			var ok := true
			for p in placed:
				if p.distance_to(candidate) < min_dist:
					ok = false
					break
			if ok:
				placed.append(candidate)
				g.add_node(candidate, base_r, -1, PackedStringArray(["root", "leaf"]))
		print("render_graph_grammar: scatter placed %d / %d seeds" % [placed.size(), n])
	elif seed_cfg.has("soft_body_pose") and seed_cfg["soft_body_pose"] is Dictionary:
		# REVERSE BRIDGE: soft-body simulated pose → graph seed.
		# Run a full soft-body sim (which itself can be L-system or CA seeded),
		# then extract post-sim particle positions + springs as the graph.
		# DNA survives physics — the collapsed pose becomes the next substrate's input.
		_seed_from_soft_body_pose(g, seed_cfg["soft_body_pose"])
	elif seed_cfg.has("rd") and seed_cfg["rd"] is Dictionary:
		# DNA BRIDGE: Reaction-Diffusion → graph seed. Above-threshold RD cells
		# become nodes (optionally lifted by V concentration), connected to
		# neighbors by edges. The Gray-Scott pattern becomes a graph topology.
		_seed_from_rd(g, seed_cfg["rd"])
	elif seed_cfg.has("lsystem") and seed_cfg["lsystem"] is Dictionary:
		# L-system as graph seed — DNA bridge between substrates.
		# Rewriter + turtle from commons/lsystem_grammar/, output fed into
		# GraphState with parent tracking so graph ops (CA prune, hull shell,
		# Modulor fold, space colonize, chandelier render) can post-process.
		_seed_from_lsystem(g, seed_cfg["lsystem"])
	else:
		var seed_pos := _as_vec3(seed_cfg.get("pos", [0.0, 0.0, 0.0]))
		var seed_rad := float(seed_cfg.get("radius", 0.18))
		g.seed_single_root(seed_pos, seed_rad)

	var grammar: Object = GraphGrammarScript.new()
	grammar.set_seed(g)
	grammar.max_nodes = int(cfg.get("max_nodes", 5000))
	var rule_defs: Array = cfg.get("rules", [])
	for rdef in rule_defs:
		var rule = _build_rule(rdef)
		if rule != null:
			grammar.add_rule(rule)

	var iters: int = int(cfg.get("iterations", 1))
	grammar.apply_n(iters)

	# Universal post-ops — noise displacement, applied to all node positions
	# before the renderer runs. Every substrate accepts the same post_ops block.
	var post_ops: Array = cfg.get("post_ops", [])
	if post_ops.size() > 0:
		grammar.state.nodes = NoiseDisplaceScriptGG.apply_post_ops(
			grammar.state.nodes, post_ops)
		print("render_graph_grammar: applied %d post_ops" % post_ops.size())

	# Build materials — either one flat color, or a dict keyed by tag.
	var materials = _build_materials(cfg)

	# Render mode: "capsule" (default) or "metaball" (marching cubes of
	# smooth-unioned capsules — organic fusion at intersections).
	var render_mode: String = str(cfg.get("render_mode", "capsule"))
	var mesh_root: Node3D
	if render_mode == "metaball":
		mesh_root = _render_metaball(grammar.state, cfg, materials)
	elif render_mode == "boxes":
		mesh_root = GraphToBoxesScript.to_node3d(grammar.state, {})
	elif render_mode == "chandelier":
		var chandelier_cfg: Dictionary = cfg.get("chandelier", {})
		mesh_root = GraphToChandelierScript.to_node3d(grammar.state, chandelier_cfg)
	else:
		mesh_root = GraphToMeshScript.to_node3d(grammar.state, materials)
	scene.add_child(mesh_root)

	await process_frame
	await process_frame

	# Frame camera
	var aabb := _combined_aabb(mesh_root)
	var center: Vector3 = aabb.get_center()
	var max_dim: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	var dist: float = maxf(max_dim * 2.0, 2.0)
	var cam := Camera3D.new()
	cam.current = true; cam.fov = 45
	scene.add_child(cam)
	var yaw: float = float(cfg.get("camera_yaw", 0.55))
	var pitch: float = float(cfg.get("camera_pitch", -0.25))
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	cam.global_position = center + offset
	cam.look_at(center, Vector3.UP)

	root.content_scale_size = Vector2i(_size, _size)
	root.size = Vector2i(_size, _size)

	await create_timer(_wait).timeout
	await process_frame
	await process_frame

	var img: Image = root.get_texture().get_image()
	if img == null:
		push_error("render_graph_grammar: no viewport image"); quit(1); return
	var abs_out := ProjectSettings.globalize_path(_output_path)
	var od := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(od):
		DirAccess.make_dir_recursive_absolute(od)
	var err := img.save_png(abs_out)
	if err != OK:
		push_error("render_graph_grammar: save failed"); quit(1); return
	print("render_graph_grammar: saved %s  (%d nodes, %d edges)" % [
		abs_out, grammar.state.node_count(), grammar.state.edge_count()])
	quit(0)


## Render graph as a single smooth-union SDF via marching cubes.
## If the bake produces no surface (AABB too tight, field all outside),
## fall back to the capsule renderer so the render still produces output.
func _render_metaball(state, cfg: Dictionary, materials) -> Node3D:
	var smoothness: float = float(cfg.get("metaball_smoothness", 0.15))
	var resolution: int = clampi(int(cfg.get("metaball_resolution", 72)), 32, 160)
	var sdf = GraphMetaballSDFScript.from_graph(state, smoothness)
	var aabb: AABB = sdf.get_aabb()
	print("metaball: segs=%d aabb=%s res=%d smooth=%.2f" % [
		sdf.segments.size(), str(aabb), resolution, smoothness])
	var mesh: ArrayMesh = SDFMarchingCubesScript.bake(sdf, Vector3i(resolution, resolution, resolution))
	var root := Node3D.new()
	root.name = "GraphMetaball"
	if mesh == null:
		push_warning("metaball bake produced no surface — falling back to capsule render")
		return GraphToMeshScript.to_node3d(state, materials)
	print("metaball: mesh surface_count=%d" % mesh.get_surface_count())
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	var mat: Material = null
	if materials is Dictionary:
		mat = materials.get("default", null)
	elif materials is Material:
		mat = materials
	if mat == null:
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.72, 0.45, 0.35); m.roughness = 0.7
		mat = m
	mi.material_override = mat
	root.add_child(mi)
	return root


## Build a materials dict from config. Accepts either:
##   "color": [r, g, b]                      → flat StandardMaterial3D
##   "materials": {"default": "bark", "leaf": "plant"}  → dict keyed by node tag
## Shader names: "plant", "bark", "flesh", or "flat:r,g,b" for a StandardMaterial
func _build_materials(cfg: Dictionary):
	if cfg.has("materials"):
		var spec: Dictionary = cfg["materials"]
		var out: Dictionary = {}
		for key in spec:
			out[key] = _resolve_material(spec[key])
		return out
	# Fallback — flat color
	var mat := StandardMaterial3D.new()
	var c = cfg.get("color", [0.72, 0.55, 0.38])
	mat.albedo_color = Color(float(c[0]), float(c[1]), float(c[2]))
	mat.roughness = 0.8
	return mat


func _resolve_material(name_or_spec):
	if name_or_spec is Array:
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(float(name_or_spec[0]), float(name_or_spec[1]), float(name_or_spec[2]))
		mat.roughness = 0.8
		return mat
	var name: String = str(name_or_spec)
	match name:
		"bark":
			var m := ShaderMaterial.new()
			m.shader = SHADER_BARK
			m.set_shader_parameter("bark_color", Color(0.38, 0.25, 0.17))
			m.set_shader_parameter("crevice_color", Color(0.12, 0.08, 0.05))
			return m
		"plant":
			var m := ShaderMaterial.new()
			m.shader = SHADER_PLANT
			m.set_shader_parameter("base_color", Color(0.3, 0.55, 0.2))
			m.set_shader_parameter("edge_color", Color(0.85, 0.9, 0.5))
			m.set_shader_parameter("vein_strength", 0.2)
			return m
		"plant_bright":
			var m := ShaderMaterial.new()
			m.shader = SHADER_PLANT
			m.set_shader_parameter("base_color", Color(0.4, 0.68, 0.25))
			m.set_shader_parameter("edge_color", Color(0.95, 1.0, 0.6))
			return m
		"plant_red":
			var m := ShaderMaterial.new()
			m.shader = SHADER_PLANT
			m.set_shader_parameter("base_color", Color(0.7, 0.25, 0.25))
			m.set_shader_parameter("edge_color", Color(1.0, 0.75, 0.65))
			return m
		"flesh":
			var m := ShaderMaterial.new()
			m.shader = SHADER_FLESH
			m.set_shader_parameter("skin_color", Color(0.75, 0.55, 0.45))
			m.set_shader_parameter("interior_color", Color(0.9, 0.35, 0.3))
			return m
	# Flat fallback
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.7, 0.5, 0.35)
	mat.roughness = 0.8
	return mat


func _build_rule(rdef: Dictionary):
	var op: String = str(rdef.get("op", ""))
	var sel_str: String = str(rdef.get("selector", "leaves"))
	var params: Dictionary = rdef.get("params", {})
	var sel = _parse_selector(sel_str)
	match op:
		"spawn_branch":   return SpawnBranchOpScript.new(sel, params)
		"subdivide_edge": return SubdivideEdgeOpScript.new(sel, params)
		"space_colonize": return SpaceColonizeOpScript.new(sel, params)
		"leaf_tuft":      return LeafTuftOpScript.new(sel, params)
		"noise_displace": return NoiseDisplaceOpScript.new(sel, params)
		"noise_radii":    return NoiseRadiiOpScript.new(sel, params)
		"sine_radii":     return SineRadiiOpScript.new(sel, params)
		"sine_displace":  return SineDisplaceOpScript.new(sel, params)
		"rd_displace":    return RDDisplaceOpScript.new(sel, params)
		"parametric_displace": return ParametricDisplaceOpScript.new(sel, params)
		"symmetry":       return SymmetryOpScript.new(sel, params)
		"ca_prune":       return CAPruneOpScript.new(sel, params)
		"hull_shell":     return HullShellOpScript.new(sel, params)
		"fractal_prune":  return FractalPruneOpScript.new(sel, params)
		"koch_edge":      return KochEdgeOpScript.new(sel, params)
		"modulor_fold":   return ModulorFoldOpScript.new(sel, params)
	push_warning("Unknown graph op: %s" % op)
	return null


func _parse_selector(s: String):
	match s:
		"all":    return GraphSelectorScript.all_nodes()
		"leaves": return GraphSelectorScript.leaves()
		"roots":  return GraphSelectorScript.roots()
	if s.begins_with("tag:"):
		return GraphSelectorScript.by_tag(s.substr(4))
	if s.begins_with("depth:"):
		var rest := s.substr(6)
		if "-" in rest:
			var parts := rest.split("-")
			return GraphSelectorScript.by_depth(int(parts[0]), int(parts[1]))
		var d := int(rest)
		return GraphSelectorScript.by_depth(d, d)
	if s.begins_with("random:"):
		return GraphSelectorScript.by_random(float(s.substr(7)))
	return GraphSelectorScript.leaves()


static func _as_vec3(v) -> Vector3:
	if v is Vector3: return v
	if v is Array and v.size() >= 3:
		return Vector3(float(v[0]), float(v[1]), float(v[2]))
	return Vector3.ZERO


# DNA BRIDGE: Gray-Scott RD field → graph nodes + edges.
# Simulate Gray-Scott, threshold the V field, place one node per alive cell,
# connect 4-neighbors. Optional height by V concentration (reads as terrain).
func _seed_from_rd(g, rd_cfg: Dictionary) -> void:
	var N: int = int(rd_cfg.get("grid_size", 72))
	var threshold: float = float(rd_cfg.get("threshold", 0.25))
	var world_size: float = float(rd_cfg.get("world_size", 2.0))
	var height_amp: float = float(rd_cfg.get("height_amp", 0.6))
	var node_radius: float = float(rd_cfg.get("node_radius", 0.025))
	var origin: Vector3 = _as_vec3(rd_cfg.get("origin", [0.0, 0.0, 0.0]))

	var field: PackedFloat32Array = RDSimScriptGG.simulate(rd_cfg)

	g.nodes.clear(); g.radii.clear(); g.parents.clear()
	g.edges.clear(); g.node_tags.clear(); g.node_depth.clear()

	var idx_of := PackedInt32Array()
	idx_of.resize(N * N)
	for i in idx_of.size(): idx_of[i] = -1

	var cell: float = world_size * 2.0 / float(N - 1)
	for iy in N:
		for ix in N:
			var v: float = field[iy * N + ix]
			if v <= threshold: continue
			var x: float = -world_size + float(ix) * cell
			var z: float = -world_size + float(iy) * cell
			var y: float = v * height_amp
			idx_of[iy * N + ix] = g.add_node(origin + Vector3(x, y, z), node_radius,
				-1, PackedStringArray(["rd", "leaf"]))
	# 4-neighbor edges
	for iy in N:
		for ix in N:
			var a: int = idx_of[iy * N + ix]
			if a < 0: continue
			if ix + 1 < N:
				var b: int = idx_of[iy * N + ix + 1]
				if b >= 0: g.edges.append([a, b])
			if iy + 1 < N:
				var b2: int = idx_of[(iy + 1) * N + ix]
				if b2 >= 0: g.edges.append([a, b2])
	print("render_graph_grammar: rd seeded %d nodes, %d edges" % [
		g.node_count(), g.edge_count()])


# REVERSE BRIDGE: soft-body pose → graph. Runs a soft-body simulation,
# extracts post-sim positions + springs, seeds GraphState. This closes the
# loop so DNA can travel: L-system → softbody → graph → chandelier.
# The simulated pose is a fingerprint of the original DNA plus physics.
func _seed_from_soft_body_pose(g, sb_cfg: Dictionary) -> void:
	var topology: String = String(sb_cfg.get("topology", "lsystem"))
	var stiffness: float = float(sb_cfg.get("stiffness", 0.7))
	var steps: int = int(sb_cfg.get("steps", 100))
	var node_radius: float = float(sb_cfg.get("node_radius", 0.05))
	var origin: Vector3 = _as_vec3(sb_cfg.get("origin", [0.0, 0.0, 0.0]))

	var sim = SoftBodySimScriptGG.new()
	sim.stiffness = stiffness
	sim.topology = "generic"
	if sb_cfg.has("gravity"):
		var gv = sb_cfg["gravity"]
		sim.gravity = Vector3(float(gv[0]), float(gv[1]), float(gv[2]))
	if sb_cfg.has("damping"):
		sim.damping = float(sb_cfg["damping"])
	if sb_cfg.has("floor_y"):
		sim.floor_y = float(sb_cfg["floor_y"])

	# Build particles + springs from the inner topology spec
	match topology:
		"ca_grid":
			# Quadruple bridge: CA pattern → softbody cloth → post-sim graph.
			var ca: Dictionary = sb_cfg.get("ca", {})
			var rule_name: String = String(ca.get("rule", "conway"))
			var N: int = int(ca.get("grid_size", 18))
			var iters: int = int(ca.get("iterations", 10))
			var density: float = float(ca.get("density", 0.45))
			var seed_val: int = int(ca.get("seed", 7))
			var cell_size: float = float(ca.get("cell_size", 0.12))
			var pin_mode: String = String(ca.get("pin_mode", "top_corners"))
			var CA_RULES := {
				"conway":             {"B": [3],       "S": [2, 3]},
				"highlife":           {"B": [3, 6],    "S": [2, 3]},
				"seeds":              {"B": [2],       "S": []},
				"life_without_death": {"B": [3],       "S": [0, 1, 2, 3, 4, 5, 6, 7, 8]},
				"day_and_night":      {"B": [3, 6, 7, 8], "S": [3, 4, 6, 7, 8]},
			}
			var r_def: Dictionary = CA_RULES.get(rule_name, CA_RULES["conway"])
			var grid: PackedInt32Array = CAPruneOpScript._simulate_ca(
				N, r_def["B"], r_def["S"], iters, density, seed_val)
			var idx_of := PackedInt32Array(); idx_of.resize(N * N)
			for i in idx_of.size(): idx_of[i] = -1
			for row in N:
				for col in N:
					if grid[row * N + col] == 0: continue
					var x: float = (float(col) - float(N - 1) * 0.5) * cell_size
					var y: float = -float(row) * cell_size
					var pos := origin + Vector3(x, y, 0)
					var pinned := false
					match pin_mode:
						"top_row":     pinned = (row == 0)
						"top_corners": pinned = (row == 0 and (col == 0 or col == N - 1))
					idx_of[row * N + col] = sim.add_particle(pos, pinned)
			for row in N:
				for col in N:
					var a: int = idx_of[row * N + col]
					if a < 0: continue
					if col + 1 < N:
						var b: int = idx_of[row * N + col + 1]
						if b >= 0: sim.add_spring(a, b)
					if row + 1 < N:
						var b2: int = idx_of[(row + 1) * N + col]
						if b2 >= 0: sim.add_spring(a, b2)
					if col + 1 < N and row + 1 < N:
						var b3: int = idx_of[(row + 1) * N + col + 1]
						if b3 >= 0: sim.add_spring(a, b3)
		"lsystem":
			var ls: Dictionary = sb_cfg.get("lsystem", {})
			var axiom: String = String(ls.get("axiom", "F"))
			var rules: Dictionary = ls.get("rules", {})
			var iters: int = int(ls.get("iterations", 3))
			var s: String = LSystemSimScript.rewrite(axiom, rules, iters)
			var walk: Dictionary = LSystemTurtleScriptGG.walk(s, {
				"angle_deg":   float(ls.get("angle_deg", 25.7)),
				"step_len":    float(ls.get("step_len", 0.2)),
				"step_shrink": float(ls.get("step_shrink", 0.72)),
			})
			var topo: Dictionary = LSystemTurtleScriptGG.to_softbody_topology(walk)
			var positions: PackedVector3Array = topo["positions"]
			var springs: Array = topo["springs"]
			var lowest: int = 0
			for i in positions.size():
				if positions[i].y < positions[lowest].y: lowest = i
			for i in positions.size():
				sim.add_particle(positions[i] + origin, i == lowest)
			for e in springs:
				sim.add_spring(e[0], e[1])
		_:
			push_warning("soft_body_pose: only 'lsystem' inner topology supported for now")
			return

	# Simulate
	sim.simulate(steps)

	# Export post-sim state into GraphState
	g.nodes.clear(); g.radii.clear(); g.parents.clear()
	g.edges.clear(); g.node_tags.clear(); g.node_depth.clear()

	var N: int = sim.positions.size()
	var idx_map := PackedInt32Array(); idx_map.resize(N)
	for i in N:
		idx_map[i] = g.add_node(sim.positions[i], node_radius, -1,
			PackedStringArray(["sb_pose", "leaf"]))
	# Parent chains: pick one spring per node as its parent edge
	var parent_assigned := PackedInt32Array(); parent_assigned.resize(N)
	for i in N: parent_assigned[i] = -1
	for s in sim.springs:
		var a: int = s[0]; var b: int = s[1]
		# Prefer assigning parent to the lower-y-original node
		if parent_assigned[b] < 0 and parent_assigned[a] != b:
			parent_assigned[b] = a
		elif parent_assigned[a] < 0 and parent_assigned[b] != a:
			parent_assigned[a] = b
		g.edges.append([idx_map[a], idx_map[b]])
	for i in N:
		if parent_assigned[i] >= 0:
			g.parents[idx_map[i]] = idx_map[parent_assigned[i]]

	print("render_graph_grammar: soft_body_pose -> %d particles simulated %d steps, %d edges" % [
		N, steps, sim.springs.size()])


# L-system → graph-state seeder. Walks the rewritten string with a
# parent-tracking turtle so the resulting graph has proper edges/depth
# and can be post-processed by any graph_grammar op.
func _seed_from_lsystem(g, ls_cfg: Dictionary) -> void:
	var axiom: String = String(ls_cfg.get("axiom", "F"))
	var rules: Dictionary = ls_cfg.get("rules", {})
	var iters: int = int(ls_cfg.get("iterations", 4))
	var seed_val: int = int(ls_cfg.get("seed", 0))
	var angle_deg: float = float(ls_cfg.get("angle_deg", 25.7))
	var step_len: float = float(ls_cfg.get("step_len", 0.2))
	var step_shrink: float = float(ls_cfg.get("step_shrink", 0.72))
	var base_radius: float = float(ls_cfg.get("base_radius", 0.08))
	var radius_shrink: float = float(ls_cfg.get("radius_shrink", 0.75))
	var origin: Vector3 = _as_vec3(ls_cfg.get("origin", [0.0, 0.0, 0.0]))

	var s: String
	var has_stoch := false
	for k in rules.keys():
		if rules[k] is Array: has_stoch = true; break
	if has_stoch:
		s = LSystemSimScript.rewrite_stochastic(axiom, rules, iters, seed_val)
	else:
		s = LSystemSimScript.rewrite(axiom, rules, iters)
	print("render_graph_grammar: lsystem rewrote %d chars" % s.length())

	g.nodes.clear(); g.radii.clear(); g.parents.clear()
	g.edges.clear(); g.node_tags.clear(); g.node_depth.clear()

	var root_idx: int = g.add_node(origin, base_radius, -1,
		PackedStringArray(["root", "lsystem"]))

	var angle_rad: float = deg_to_rad(angle_deg)
	var pos: Vector3 = origin
	var heading: Vector3 = Vector3.UP
	var left: Vector3 = Vector3.LEFT
	var up: Vector3 = Vector3.FORWARD
	var cur_len: float = step_len
	var cur_rad: float = base_radius
	var cur_parent: int = root_idx
	var stack: Array = []

	for c in s:
		match c:
			"F":
				pos = pos + heading * cur_len
				var idx: int = g.add_node(pos, cur_rad, cur_parent,
					PackedStringArray(["lsystem", "leaf"]))
				cur_parent = idx
			"f":
				pos = pos + heading * cur_len
			"+":
				heading = heading.rotated(up.normalized(), angle_rad).normalized()
				left    = left.rotated(up.normalized(), angle_rad).normalized()
			"-":
				heading = heading.rotated(up.normalized(), -angle_rad).normalized()
				left    = left.rotated(up.normalized(), -angle_rad).normalized()
			"&":
				heading = heading.rotated(left.normalized(), angle_rad).normalized()
				up      = up.rotated(left.normalized(), angle_rad).normalized()
			"^":
				heading = heading.rotated(left.normalized(), -angle_rad).normalized()
				up      = up.rotated(left.normalized(), -angle_rad).normalized()
			"/":
				left = left.rotated(heading.normalized(), angle_rad).normalized()
				up   = up.rotated(heading.normalized(), angle_rad).normalized()
			"\\":
				left = left.rotated(heading.normalized(), -angle_rad).normalized()
				up   = up.rotated(heading.normalized(), -angle_rad).normalized()
			"|":
				heading = -heading
				left = -left
			"[":
				stack.append({
					"pos": pos, "h": heading, "l": left, "u": up,
					"len": cur_len, "rad": cur_rad, "parent": cur_parent,
				})
				cur_len *= step_shrink
				cur_rad *= radius_shrink
			"]":
				if stack.size() > 0:
					var st: Dictionary = stack.pop_back()
					pos = st["pos"]; heading = st["h"]; left = st["l"]; up = st["u"]
					cur_len = st["len"]; cur_rad = st["rad"]; cur_parent = st["parent"]

	print("render_graph_grammar: lsystem seeded %d nodes, %d edges" % [
		g.node_count(), g.edge_count()])


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
		return AABB(Vector3(-1, 0, -1), Vector3(2, 2, 2))
	return total
