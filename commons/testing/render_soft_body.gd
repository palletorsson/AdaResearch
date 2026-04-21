extends SceneTree

## Render a soft body config to a PNG after N simulation steps.
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/render_soft_body.gd -- \
##     --config=<path.json> --out=user://sb_gallery/<id>.png --size=640

const SoftBodyShapesScript = preload("res://commons/soft_body/soft_body_shapes.gd")
const SoftBodySimScript    = preload("res://commons/soft_body/soft_body_sim.gd")
const LSystemSimScriptSB   = preload("res://commons/lsystem_grammar/lsystem_sim.gd")
const LSystemTurtleScriptSB= preload("res://commons/lsystem_grammar/lsystem_turtle.gd")
const CAPruneOpScriptSB    = preload("res://commons/graph_grammar/operations/ca_prune_op.gd")
const NoiseDisplaceSB      = preload("res://commons/noise_grammar/noise_displace.gd")
const RDSimSB              = preload("res://commons/rd_grammar/rd_sim.gd")

var _config_path: String = ""
var _output_path: String = "user://sb_gallery/out.png"
var _size: int = 640
var _wait: float = 0.5


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty():
		push_error("render_soft_body: --config required")
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
		txt = FileAccess.get_file_as_string(ProjectSettings.globalize_path(_config_path))
	if txt.is_empty():
		push_error("render_soft_body: empty config"); quit(1); return
	var j := JSON.new()
	if j.parse(txt) != OK or not (j.data is Dictionary):
		push_error("render_soft_body: bad JSON"); quit(1); return
	var cfg: Dictionary = j.data

	# Scene
	var scene := Node3D.new()
	scene.name = "SBRender"
	root.add_child(scene)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	var bg_arr = cfg.get("background", [0.92, 0.92, 0.88])
	env.background_color = Color(float(bg_arr[0]), float(bg_arr[1]), float(bg_arr[2]))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.95, 0.95, 0.92)
	env.ambient_light_energy = 0.7
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	var we := WorldEnvironment.new(); we.environment = env
	scene.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, -28, 0)
	key.light_energy = 1.3
	key.shadow_enabled = true
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 130, 0)
	fill.light_energy = 0.35
	scene.add_child(fill)

	# Ground
	var ground := MeshInstance3D.new()
	var gm := PlaneMesh.new(); gm.size = Vector2(20, 20)
	ground.mesh = gm
	ground.position.y = float(cfg.get("floor_y", -2.0))
	var gmat := StandardMaterial3D.new()
	gmat.albedo_color = Color(0.85, 0.85, 0.82)
	gmat.roughness = 0.9
	ground.material_override = gmat
	scene.add_child(ground)

	# Verlet path — deterministic RefCounted simulator
	var sim = _build_sim(cfg)
	if sim == null:
		push_error("render_soft_body: bad topology"); quit(1); return
	var steps: int = int(cfg.get("steps", 240))
	var dt: float = float(cfg.get("dt", 0.0166667))
	sim.simulate(steps, dt)
	# Universal post-ops: noise displace acts on sim.positions post-simulation
	var post_ops: Array = cfg.get("post_ops", [])
	if post_ops.size() > 0:
		sim.positions = NoiseDisplaceSB.apply_post_ops(sim.positions, post_ops)
		print("render_soft_body: applied %d post_ops" % post_ops.size())
	var render_cfg: Dictionary = cfg.get("render", {})
	var node: Node3D = SoftBodyShapesScript.to_node3d(sim, render_cfg)
	scene.add_child(node)
	await process_frame
	await process_frame

	# Camera
	var aabb := _combined_aabb(node)
	var center: Vector3 = aabb.get_center()
	var max_dim: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	var dist: float = maxf(max_dim * 2.2, 2.0)
	var cam := Camera3D.new()
	cam.current = true; cam.fov = 40
	scene.add_child(cam)
	var yaw: float = float(cfg.get("camera_yaw", 0.5))
	var pitch: float = float(cfg.get("camera_pitch", 0.2))
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
		push_error("render_soft_body: no viewport image"); quit(1); return
	var abs_out := ProjectSettings.globalize_path(_output_path)
	var od := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(od):
		DirAccess.make_dir_recursive_absolute(od)
	var err := img.save_png(abs_out)
	if err != OK:
		push_error("render_soft_body: save failed"); quit(1); return
	print("render_soft_body: saved %s" % abs_out)
	quit(0)


func _build_sim(cfg: Dictionary):
	var topology: String = String(cfg.get("topology", "cloth_grid"))
	var origin_arr = cfg.get("origin", [0, 0, 0])
	var origin := Vector3(float(origin_arr[0]), float(origin_arr[1]), float(origin_arr[2]))
	var stiffness: float = float(cfg.get("stiffness", 0.8))
	var sim = null
	match topology:
		"cloth_grid":
			var cols: int = int(cfg.get("cols", 14))
			var rows: int = int(cfg.get("rows", 14))
			var cell: float = float(cfg.get("cell_size", 0.18))
			var pin: String = String(cfg.get("pin_mode", "top_corners"))
			sim = SoftBodyShapesScript.make_cloth(cols, rows, cell, pin, stiffness, origin)
		"jelly_box":
			var size: float = float(cfg.get("size", 1.2))
			sim = SoftBodyShapesScript.make_jelly_box(size, stiffness, origin)
		"jelly_grid_3d":
			var nx: int = int(cfg.get("nx", 4))
			var ny: int = int(cfg.get("ny", 4))
			var nz: int = int(cfg.get("nz", 4))
			var cell: float = float(cfg.get("cell", 0.3))
			sim = SoftBodyShapesScript.make_jelly_grid(nx, ny, nz, cell, stiffness, origin)
		"lsystem":
			# DNA bridge: L-system → spring-mass topology.
			# The turtle walk becomes particles + springs, one pinned at root.
			sim = _build_lsystem_sim(cfg, stiffness, origin)
		"ca_grid":
			# DNA bridge: cellular automaton → spring-mass grid.
			# Run CA, one particle per alive cell, springs to alive neighbors.
			sim = _build_ca_sim(cfg, stiffness, origin)
		"rd_field":
			# DNA bridge: Gray-Scott RD → spring-mass cloth.
			# Above-threshold cells become particles; 4-neighbors become springs.
			sim = _build_rd_sim(cfg, stiffness, origin)
		"glass_blow":
			# FROZEN PROCESSED FORM — sphere under gravity + top pin + optional
			# pre-inflation. After N settle steps, the frozen pose IS the vessel.
			# The bottle shape is the record of gravity × stiffness × duration.
			sim = _build_glass_blow_sim(cfg, stiffness, origin)
		_:
			return null
	if sim == null: return null

	# Env overrides
	if cfg.has("gravity"):
		var g = cfg["gravity"]
		sim.gravity = Vector3(float(g[0]), float(g[1]), float(g[2]))
	if cfg.has("damping"):
		sim.damping = float(cfg["damping"])
	if cfg.has("floor_y"):
		sim.floor_y = float(cfg["floor_y"])
	if cfg.has("constraint_passes"):
		sim.constraint_passes = int(cfg["constraint_passes"])
	return sim


## L-system seed for soft body simulation.
## Rewrites axiom + walks turtle, extracts graph, converts to particles+springs.
## Pins the lowest particle (root) so the tree stands before gravity pulls it.
func _build_lsystem_sim(cfg: Dictionary, stiffness: float, origin: Vector3):
	var ls_cfg: Dictionary = cfg.get("lsystem", {})
	var axiom: String = String(ls_cfg.get("axiom", "F"))
	var rules: Dictionary = ls_cfg.get("rules", {})
	var iters: int = int(ls_cfg.get("iterations", 3))
	var seed_val: int = int(ls_cfg.get("seed", 0))
	var has_stoch := false
	for k in rules.keys():
		if rules[k] is Array: has_stoch = true; break
	var s: String
	if has_stoch:
		s = LSystemSimScriptSB.rewrite_stochastic(axiom, rules, iters, seed_val)
	else:
		s = LSystemSimScriptSB.rewrite(axiom, rules, iters)
	var walk: Dictionary = LSystemTurtleScriptSB.walk(s, {
		"angle_deg":   float(ls_cfg.get("angle_deg", 25.7)),
		"step_len":    float(ls_cfg.get("step_len", 0.15)),
		"step_shrink": float(ls_cfg.get("step_shrink", 0.72)),
		"seed":        seed_val,
	})
	var topo: Dictionary = LSystemTurtleScriptSB.to_softbody_topology(walk)
	var positions: PackedVector3Array = topo["positions"]
	var springs: Array = topo["springs"]

	var sim = SoftBodySimScript.new()
	sim.topology = "generic"
	sim.stiffness = stiffness
	# Add particles offset by origin; pin the lowest-y particle (base of tree).
	var lowest: int = 0
	for i in positions.size():
		if positions[i].y < positions[lowest].y: lowest = i
	for i in positions.size():
		sim.add_particle(positions[i] + origin, i == lowest)
	for e in springs:
		sim.add_spring(e[0], e[1])
	print("render_soft_body: lsystem -> %d particles, %d springs" % [
		positions.size(), springs.size()])
	return sim


## CA-grid seed — DNA bridge: cellular automaton state → spring-mass cloth.
## Run CA on NxN grid, place a particle at every alive cell, connect
## alive 4-neighbors with springs. Pin the top row so the cloth hangs.
func _build_ca_sim(cfg: Dictionary, stiffness: float, origin: Vector3):
	var ca: Dictionary = cfg.get("ca", {})
	var rule_name: String = String(ca.get("rule", "conway"))
	var N: int = int(ca.get("grid_size", 20))
	var iters: int = int(ca.get("iterations", 8))
	var density: float = float(ca.get("density", 0.45))
	var seed_val: int = int(ca.get("seed", 7))
	var cell_size: float = float(ca.get("cell_size", 0.12))
	var pin_mode: String = String(ca.get("pin_mode", "top_row"))

	var CA_RULES := {
		"conway":             {"B": [3],       "S": [2, 3]},
		"highlife":           {"B": [3, 6],    "S": [2, 3]},
		"seeds":              {"B": [2],       "S": []},
		"life_without_death": {"B": [3],       "S": [0, 1, 2, 3, 4, 5, 6, 7, 8]},
		"day_and_night":      {"B": [3, 6, 7, 8], "S": [3, 4, 6, 7, 8]},
	}
	var r_def: Dictionary = CA_RULES.get(rule_name, CA_RULES["conway"])
	var grid: PackedInt32Array = CAPruneOpScriptSB._simulate_ca(
		N, r_def["B"], r_def["S"], iters, density, seed_val)

	var sim = SoftBodySimScript.new()
	sim.topology = "generic"
	sim.stiffness = stiffness

	# Map grid idx -> particle idx (-1 if dead)
	var idx_of := PackedInt32Array()
	idx_of.resize(N * N)
	for i in idx_of.size():
		idx_of[i] = -1

	# Cloth oriented vertically: Y = grid row inverted, X = grid col.
	for row in N:
		for col in N:
			if grid[row * N + col] == 0: continue
			var x: float = (float(col) - float(N - 1) * 0.5) * cell_size
			var y: float = -float(row) * cell_size  # hang down
			var pos := origin + Vector3(x, y, 0)
			var pinned := false
			match pin_mode:
				"top_row":     pinned = (row == 0)
				"top_corners": pinned = (row == 0 and (col == 0 or col == N - 1))
				"none":        pinned = false
			idx_of[row * N + col] = sim.add_particle(pos, pinned)

	# 4-neighbor springs between alive cells
	var edges := 0
	for row in N:
		for col in N:
			var a: int = idx_of[row * N + col]
			if a < 0: continue
			if col + 1 < N:
				var b: int = idx_of[row * N + col + 1]
				if b >= 0: sim.add_spring(a, b); edges += 1
			if row + 1 < N:
				var b2: int = idx_of[(row + 1) * N + col]
				if b2 >= 0: sim.add_spring(a, b2); edges += 1
			# Diagonal shear for stability
			if col + 1 < N and row + 1 < N:
				var b3: int = idx_of[(row + 1) * N + col + 1]
				if b3 >= 0: sim.add_spring(a, b3); edges += 1
	print("render_soft_body: ca_grid -> %d alive cells, %d springs (rule=%s)" % [
		sim.positions.size(), edges, rule_name])
	return sim


## RD-field soft-body seed. Same as CA path but uses Gray-Scott V threshold.
func _build_rd_sim(cfg: Dictionary, stiffness: float, origin: Vector3):
	var rd: Dictionary = cfg.get("rd", {})
	var N: int = int(rd.get("grid_size", 64))
	var threshold: float = float(rd.get("threshold", 0.25))
	var cell_size: float = float(rd.get("cell_size", 0.09))
	var pin_mode: String = String(rd.get("pin_mode", "top_row"))

	var field: PackedFloat32Array = RDSimSB.simulate(rd)

	var sim = SoftBodySimScript.new()
	sim.topology = "generic"
	sim.stiffness = stiffness

	var idx_of := PackedInt32Array(); idx_of.resize(N * N)
	for i in idx_of.size(): idx_of[i] = -1

	for row in N:
		for col in N:
			if field[row * N + col] <= threshold: continue
			var x: float = (float(col) - float(N - 1) * 0.5) * cell_size
			var y: float = -float(row) * cell_size
			var pos := origin + Vector3(x, y, 0)
			var pinned := false
			match pin_mode:
				"top_row":     pinned = (row == 0)
				"top_corners": pinned = (row == 0 and (col == 0 or col == N - 1))
			idx_of[row * N + col] = sim.add_particle(pos, pinned)

	var edges := 0
	for row in N:
		for col in N:
			var a: int = idx_of[row * N + col]
			if a < 0: continue
			if col + 1 < N:
				var b: int = idx_of[row * N + col + 1]
				if b >= 0: sim.add_spring(a, b); edges += 1
			if row + 1 < N:
				var b2: int = idx_of[(row + 1) * N + col]
				if b2 >= 0: sim.add_spring(a, b2); edges += 1
			if col + 1 < N and row + 1 < N:
				var b3: int = idx_of[(row + 1) * N + col + 1]
				if b3 >= 0: sim.add_spring(a, b3); edges += 1
	print("render_soft_body: rd_field -> %d alive cells, %d springs" % [
		sim.positions.size(), edges])
	return sim


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
			if c is Node3D: stack.append(c)
	if first:
		return AABB(Vector3(-1, 0, -1), Vector3(2, 2, 2))
	return total


## FROZEN PROCESSED FORM — glass-vessel blowing.
##
## Build a sphere mesh, pin a ring of top vertices (the blowpipe attachment),
## optionally pre-inflate (simulate internal pressure by pushing verts outward
## from centroid), then let gravity + spring tension settle for N steps. The
## frozen pose is the vessel — a drooping bulb, a hanging drop, a sagging
## bottle. Different stiffness × gravity × duration = different vessel.
func _build_glass_blow_sim(cfg: Dictionary, stiffness: float, origin: Vector3):
	var radius: float = float(cfg.get("radius", 0.5))
	var rings: int = int(cfg.get("rings", 12))
	var segments: int = int(cfg.get("segments", 20))
	# Which fraction of the top rings to pin (the blowpipe attachment):
	var pin_top_fraction: float = float(cfg.get("pin_top_fraction", 0.15))
	# Pre-inflation: push all non-pinned verts outward by this factor BEFORE sim.
	# Simulates an initial pressure pulse.
	var preinflate: float = float(cfg.get("preinflate", 0.3))

	# Build sphere vertices (ring-and-segment parameterization).
	var verts := PackedVector3Array()
	var ring_ys: PackedFloat32Array = PackedFloat32Array()
	ring_ys.resize(rings + 1)
	for i in rings + 1:
		var phi: float = PI * float(i) / float(rings)   # 0 at top pole → PI at bottom
		ring_ys[i] = cos(phi) * radius
		var r_ring: float = sin(phi) * radius
		for j in segments:
			var theta: float = TAU * float(j) / float(segments)
			verts.append(Vector3(r_ring * cos(theta), ring_ys[i], r_ring * sin(theta)))

	var sim = SoftBodySimScript.new()
	sim.topology = "generic"
	sim.stiffness = stiffness

	# Pin: any vertex whose y is above (1 - pin_top_fraction) of the radius
	var pin_y: float = radius * (1.0 - pin_top_fraction * 2.0)
	for i in verts.size():
		var v: Vector3 = verts[i]
		# Pre-inflate non-pinned verts outward from centroid (which is origin of sphere).
		var pinned: bool = v.y > pin_y
		if not pinned and preinflate > 0.0:
			var dir: Vector3 = v
			if dir.length() > 1e-6:
				v = dir * (1.0 + preinflate)
		sim.add_particle(v + origin, pinned)

	# Springs: for each quad of the sphere grid, add 4 edges + 1 diagonal for shear.
	var stride: int = segments
	for i in rings:
		for j in segments:
			var jn: int = (j + 1) % segments
			var a: int = i * stride + j
			var b: int = i * stride + jn
			var c: int = (i + 1) * stride + j
			var d: int = (i + 1) * stride + jn
			sim.add_spring(a, b)
			sim.add_spring(a, c)
			sim.add_spring(a, d)   # diagonal shear
	# Close the bottom ring by connecting ring_n segments horizontally:
	var bot_ring_start: int = rings * stride
	for j in segments:
		var jn: int = (j + 1) % segments
		sim.add_spring(bot_ring_start + j, bot_ring_start + jn)

	print("render_soft_body: glass_blow -> %d particles (pinned top ring), %d springs, preinflate=%.2f" % [
		verts.size(), sim.springs.size(), preinflate
	])
	return sim
