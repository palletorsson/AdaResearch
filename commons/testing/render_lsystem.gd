extends SceneTree

## Render an L-system config to a PNG.
## DNA = axiom + rules + iterations + interpretation mode.
## The SAME L-system string can render via lines, tubes, graph, or softbody —
## each mode is a bridge to another substrate. That's the DNA connection.
##
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/render_lsystem.gd -- \
##     --config=<path.json> --out=user://ls_gallery/<id>.png --size=640

const LSystemSim    = preload("res://commons/lsystem_grammar/lsystem_sim.gd")
const LSystemTurtle = preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

var _config_path: String = ""
var _output_path: String = "user://ls_gallery/out.png"
var _size: int = 640
var _wait: float = 0.5


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty():
		push_error("render_lsystem: --config required")
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
		push_error("render_lsystem: empty config"); quit(1); return
	var j := JSON.new()
	if j.parse(txt) != OK or not (j.data is Dictionary):
		push_error("render_lsystem: bad JSON"); quit(1); return
	var cfg: Dictionary = j.data

	# Scene
	var scene := Node3D.new()
	scene.name = "LSRender"
	root.add_child(scene)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	var bg_arr = cfg.get("background", [0.96, 0.95, 0.90])
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
	key.light_energy = 1.2
	key.shadow_enabled = true
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-20, 130, 0)
	fill.light_energy = 0.4
	scene.add_child(fill)

	# Rewrite axiom with rules
	var axiom: String = String(cfg.get("axiom", "F"))
	var rules: Dictionary = cfg.get("rules", {})
	var iterations: int = int(cfg.get("iterations", 4))
	var seed: int = int(cfg.get("seed", 0))
	var s: String
	if _has_stochastic(rules):
		s = LSystemSim.rewrite_stochastic(axiom, rules, iterations, seed)
	else:
		s = LSystemSim.rewrite(axiom, rules, iterations)

	var fp: Dictionary = LSystemSim.fingerprint(s)
	print("render_lsystem: len=%d max_depth=%d" % [fp["length"], fp["max_depth"]])

	# Walk with turtle
	var turtle_params := {
		"angle_deg":    float(cfg.get("angle_deg", 25.7)),
		"step_len":     float(cfg.get("step_len", 0.1)),
		"step_shrink":  float(cfg.get("step_shrink", 0.72)),
		"base_width":   float(cfg.get("base_width", 0.02)),
		"width_shrink": float(cfg.get("width_shrink", 0.75)),
		"perturb":      float(cfg.get("perturb", 0.0)),
		"seed":         seed,
	}
	var walk: Dictionary = LSystemTurtle.walk(s, turtle_params)

	# Dispatch by interpretation mode — each is a DNA bridge to another substrate.
	var mode: String = String(cfg.get("interpretation", "lines"))
	var color_trunk := _color(cfg.get("color_trunk", [0.45, 0.28, 0.12]))
	var color_tip   := _color(cfg.get("color_tip",   [0.2, 0.65, 0.15]))
	var node: Node3D = null

	match mode:
		"tubes":
			node = LSystemTurtle.to_tubes(walk, color_trunk, color_tip,
				int(cfg.get("tube_sides", 6)))
		"graph":
			# Render graph as nodes + edges — bridge to graph_grammar
			node = _render_graph(walk, color_trunk, color_tip, cfg)
		"softbody":
			# Simulate spring topology from turtle walk — bridge to soft_body_sim
			node = _render_softbody(walk, color_trunk, color_tip, cfg)
		"primitives":
			# Place primitives at branch points — bridge to primitive_stack
			node = _render_primitives(walk, color_trunk, color_tip, cfg)
		_:  # "lines" / default
			node = LSystemTurtle.to_lines(walk, color_trunk, color_tip)

	scene.add_child(node)

	await process_frame
	await process_frame

	# Camera — frame AABB
	var aabb: AABB = _combined_aabb(node, walk)
	var center: Vector3 = aabb.get_center()
	var max_dim: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	var dist: float = maxf(max_dim * 1.6, 1.5)
	var cam := Camera3D.new()
	cam.current = true; cam.fov = 40
	scene.add_child(cam)
	var yaw: float = float(cfg.get("camera_yaw", 0.4))
	var pitch: float = float(cfg.get("camera_pitch", 0.1))
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
		push_error("render_lsystem: no image"); quit(1); return
	var abs_out := ProjectSettings.globalize_path(_output_path)
	var od := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(od):
		DirAccess.make_dir_recursive_absolute(od)
	var err := img.save_png(abs_out)
	if err != OK:
		push_error("render_lsystem: save failed"); quit(1); return
	print("render_lsystem: saved %s" % abs_out)
	quit(0)


func _has_stochastic(rules: Dictionary) -> bool:
	for k in rules.keys():
		if rules[k] is Array: return true
	return false


func _color(a) -> Color:
	if a is Array and a.size() >= 3:
		return Color(float(a[0]), float(a[1]), float(a[2]))
	return Color.WHITE


# ─── Graph interpretation — DNA bridge to graph_grammar ───

func _render_graph(walk: Dictionary, ct: Color, cp: Color, cfg: Dictionary) -> Node3D:
	var root_n := Node3D.new()
	var g: Dictionary = LSystemTurtle.to_graph(walk)
	var positions: PackedVector3Array = g["positions"]
	var edges: Array = g["edges"]
	# Nodes as spheres
	var radius: float = float(cfg.get("node_radius", 0.015))
	var mmi := MeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var sph := SphereMesh.new(); sph.radius = radius; sph.height = radius * 2.0
	sph.radial_segments = 10; sph.rings = 6
	mm.mesh = sph
	mm.instance_count = positions.size()
	for i in positions.size():
		var t := Transform3D.IDENTITY
		t.origin = positions[i]
		mm.set_instance_transform(i, t)
		var y: float = positions[i].y
		var tt: float = clampf((y - 0.0) / 2.0, 0.0, 1.0)
		mm.set_instance_color(i, ct.lerp(cp, tt))
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true; mat.roughness = 0.4
	mmi.material_override = mat; mmi.multimesh = mm
	root_n.add_child(mmi)
	# Edges as lines
	var lines := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	var lmat := StandardMaterial3D.new()
	lmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lmat.albedo_color = Color(0.18, 0.14, 0.1)
	lines.material_override = lmat
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for e in edges:
		im.surface_add_vertex(positions[e[0]])
		im.surface_add_vertex(positions[e[1]])
	im.surface_end()
	lines.mesh = im
	root_n.add_child(lines)
	return root_n


# ─── Softbody interpretation — DNA bridge to soft_body_sim ───

func _render_softbody(walk: Dictionary, ct: Color, cp: Color, cfg: Dictionary) -> Node3D:
	var root_n := Node3D.new()
	# Build sim from turtle topology, then simulate N steps.
	var SB = preload("res://commons/soft_body/soft_body_sim.gd")
	var sim = SB.new()
	sim.topology = "generic"
	sim.stiffness = float(cfg.get("sb_stiffness", 0.7))
	if cfg.has("sb_gravity"):
		var g = cfg["sb_gravity"]
		sim.gravity = Vector3(float(g[0]), float(g[1]), float(g[2]))
	var topo: Dictionary = LSystemTurtle.to_softbody_topology(walk)
	var positions: PackedVector3Array = topo["positions"]
	var springs: Array = topo["springs"]
	# Pin the root (lowest y particle) so tree doesn't fall over
	var lowest: int = 0
	for i in positions.size():
		if positions[i].y < positions[lowest].y: lowest = i
	for i in positions.size():
		sim.add_particle(positions[i], i == lowest)
	for e in springs:
		sim.add_spring(e[0], e[1])
	var steps: int = int(cfg.get("sb_steps", 120))
	sim.simulate(steps)
	# Render deformed positions as lines
	var lines := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	lines.material_override = mat
	im.surface_begin(Mesh.PRIMITIVE_LINES)
	for i in springs.size():
		var e = springs[i]
		var a: Vector3 = sim.positions[e[0]]
		var b: Vector3 = sim.positions[e[1]]
		var col := ct.lerp(cp, clampf((a.y + 1.0) * 0.5, 0.0, 1.0))
		im.surface_set_color(col); im.surface_add_vertex(a)
		im.surface_set_color(col); im.surface_add_vertex(b)
	im.surface_end()
	lines.mesh = im
	root_n.add_child(lines)
	return root_n


# ─── Primitives interpretation — DNA bridge to primitive_stack ───

func _render_primitives(walk: Dictionary, ct: Color, cp: Color, cfg: Dictionary) -> Node3D:
	var root_n := Node3D.new()
	# Place small primitives at every branch point, leaf, and segment midpoint.
	var seg_radius: float = float(cfg.get("primitive_size", 0.04))
	var shape: String = String(cfg.get("primitive_shape", "sphere"))
	var segments: Array = walk["segments"]
	var leaves: Array = walk["leaves"]
	var branch_pts: Array = walk["branch_points"]

	var count := segments.size() + leaves.size() + branch_pts.size()
	var mmi := MeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var mesh: Mesh
	match shape:
		"cube":
			var bm := BoxMesh.new(); bm.size = Vector3(seg_radius * 2, seg_radius * 2, seg_radius * 2)
			mesh = bm
		"cylinder":
			var cm := CylinderMesh.new()
			cm.top_radius = seg_radius; cm.bottom_radius = seg_radius; cm.height = seg_radius * 2
			mesh = cm
		_:
			var sph := SphereMesh.new(); sph.radius = seg_radius; sph.height = seg_radius * 2
			sph.radial_segments = 8; sph.rings = 4
			mesh = sph
	mm.mesh = mesh
	mm.instance_count = count

	var max_depth := 1
	for seg in segments:
		max_depth = max(max_depth, int(seg[2]))

	var idx := 0
	for seg in segments:
		var mid: Vector3 = (seg[0] + seg[1]) * 0.5
		var t := Transform3D.IDENTITY; t.origin = mid
		mm.set_instance_transform(idx, t)
		var d: int = int(seg[2])
		var tt: float = clampf(float(d) / float(max_depth), 0.0, 1.0)
		mm.set_instance_color(idx, ct.lerp(cp, tt))
		idx += 1
	for lp in leaves:
		var t2 := Transform3D.IDENTITY; t2.origin = lp
		mm.set_instance_transform(idx, t2)
		mm.set_instance_color(idx, cp)
		idx += 1
	for bp in branch_pts:
		var t3 := Transform3D.IDENTITY; t3.origin = bp
		mm.set_instance_transform(idx, t3)
		mm.set_instance_color(idx, ct)
		idx += 1

	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true; mat.roughness = 0.55
	mmi.material_override = mat; mmi.multimesh = mm
	root_n.add_child(mmi)
	return root_n


# ─── Camera AABB (segments don't live on mesh for all modes) ───

func _combined_aabb(node: Node3D, walk: Dictionary) -> AABB:
	var segments: Array = walk["segments"]
	if segments.is_empty():
		return AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	for seg in segments:
		var a: Vector3 = seg[0]; var b: Vector3 = seg[1]
		mn = mn.min(a).min(b); mx = mx.max(a).max(b)
	return AABB(mn, mx - mn)
