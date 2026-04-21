extends SceneTree

## Render a trajectory config to a PNG.
## DNA = force equation + params + initial conditions + duration.
## Renders the integrated trajectory as tube / ribbon / particles / lines.
##
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/render_trajectory.gd -- \
##     --config=<path.json> --out=user://trajectory_gallery/<id>.png --size=640

const TrajSimScript = preload("res://commons/trajectory_grammar/trajectory_sim.gd")

var _config_path: String = ""
var _output_path: String = "user://trajectory_gallery/out.png"
var _size: int = 640
var _wait: float = 0.6


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty():
		push_error("render_trajectory: --config required"); quit(1); return
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


func _run() -> void:
	var txt := FileAccess.get_file_as_string(_config_path)
	if txt.is_empty():
		txt = FileAccess.get_file_as_string(ProjectSettings.globalize_path(_config_path))
	if txt.is_empty():
		push_error("render_trajectory: empty config"); quit(1); return
	var j := JSON.new()
	if j.parse(txt) != OK:
		push_error("render_trajectory: bad JSON"); quit(1); return
	var cfg: Dictionary = j.data

	var result: Dictionary = TrajSimScript.simulate(cfg)
	var trails: Array = result["trajectories"]
	print("render_trajectory: %d trail(s), %d samples each" % [
		trails.size(), result["sample_count"]])

	# Scene
	var scene := Node3D.new()
	scene.name = "TrajRender"
	root.add_child(scene)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	var bg_arr = cfg.get("background", [0.12, 0.12, 0.15])
	env.background_color = Color(float(bg_arr[0]), float(bg_arr[1]), float(bg_arr[2]))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.6, 0.6, 0.65)
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	var we := WorldEnvironment.new(); we.environment = env
	scene.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-42, -28, 0)
	key.light_energy = 1.2
	scene.add_child(key)

	var color_start := _color(cfg.get("color_start", [0.2, 0.3, 0.5]))
	var color_end   := _color(cfg.get("color_end",   [0.9, 0.55, 0.2]))
	var interpretation: String = String(cfg.get("interpretation", "tube"))

	var node: Node3D = null
	match interpretation:
		"tube":     node = _render_tubes(trails, color_start, color_end,
			float(cfg.get("tube_radius", 0.025)), int(cfg.get("tube_sides", 6)))
		"ribbon":   node = _render_tubes(trails, color_start, color_end,
			float(cfg.get("tube_radius", 0.04)), 4)
		"particles": node = _render_particles(trails, color_start, color_end,
			float(cfg.get("particle_radius", 0.035)))
		_:           node = _render_lines(trails, color_start, color_end)
	scene.add_child(node)

	await process_frame
	await process_frame

	# Camera — frame the AABB of all trails
	var aabb := _trails_aabb(trails)
	var center: Vector3 = aabb.get_center()
	var max_dim: float = maxf(maxf(aabb.size.x, aabb.size.y), aabb.size.z)
	var dist: float = maxf(max_dim * 1.5, 2.0)
	var cam := Camera3D.new()
	cam.current = true; cam.fov = 42
	scene.add_child(cam)
	var yaw: float = float(cfg.get("camera_yaw", 0.6))
	var pitch: float = float(cfg.get("camera_pitch", 0.25))
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
		push_error("render_trajectory: no image"); quit(1); return
	var abs_out := ProjectSettings.globalize_path(_output_path)
	var od := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(od):
		DirAccess.make_dir_recursive_absolute(od)
	var err := img.save_png(abs_out)
	if err != OK:
		push_error("render_trajectory: save failed"); quit(1); return
	print("render_trajectory: saved %s" % abs_out)
	quit(0)


func _color(a) -> Color:
	if a is Array and a.size() >= 3:
		return Color(float(a[0]), float(a[1]), float(a[2]))
	return Color.WHITE


# ─── Render modes ─────────────────────────────────────────────

func _render_lines(trails: Array, cs: Color, ce: Color) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var im := ImmediateMesh.new()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mi.material_override = mat
	mi.mesh = im
	for trail in trails:
		var pts: PackedVector3Array = trail
		if pts.size() < 2: continue
		im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for i in pts.size():
			var t: float = float(i) / float(pts.size() - 1)
			im.surface_set_color(cs.lerp(ce, t))
			im.surface_add_vertex(pts[i])
		im.surface_end()
	return mi


func _render_tubes(trails: Array, cs: Color, ce: Color,
		radius: float, sides: int) -> MultiMeshInstance3D:
	# Count total segments
	var total := 0
	for trail in trails:
		var pts: PackedVector3Array = trail
		if pts.size() >= 2: total += pts.size() - 1
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0; cm.bottom_radius = 1.0; cm.height = 1.0
	cm.radial_segments = sides
	cm.rings = 1
	mm.mesh = cm
	mm.instance_count = total

	var idx := 0
	for trail in trails:
		var pts: PackedVector3Array = trail
		var n: int = pts.size()
		if n < 2: continue
		for i in range(n - 1):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var mid: Vector3 = (a + b) * 0.5
			var v: Vector3 = b - a
			var h: float = v.length()
			if h < 1e-6:
				idx += 1
				continue
			var axis: Vector3 = v / h
			var y := Vector3.UP
			var basis := Basis()
			var dot := y.dot(axis)
			if dot > 0.9999: basis = Basis.IDENTITY
			elif dot < -0.9999: basis = Basis(Vector3.RIGHT, PI)
			else:
				basis = Basis(y.cross(axis).normalized(), acos(clampf(dot, -1.0, 1.0)))
			basis = basis.scaled(Vector3(radius, h, radius))
			mm.set_instance_transform(idx, Transform3D(basis, mid))
			var t: float = float(i) / float(n - 1)
			mm.set_instance_color(idx, cs.lerp(ce, t))
			idx += 1

	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.6
	mmi.material_override = mat
	return mmi


func _render_particles(trails: Array, cs: Color, ce: Color, radius: float) -> MultiMeshInstance3D:
	var total := 0
	for trail in trails: total += (trail as PackedVector3Array).size()
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var sph := SphereMesh.new()
	sph.radius = radius; sph.height = radius * 2.0
	sph.radial_segments = 8; sph.rings = 4
	mm.mesh = sph
	mm.instance_count = total
	var idx := 0
	for trail in trails:
		var pts: PackedVector3Array = trail
		var n: int = pts.size()
		for i in n:
			var t := Transform3D.IDENTITY
			t.origin = pts[i]
			mm.set_instance_transform(idx, t)
			var f: float = float(i) / float(max(n - 1, 1))
			mm.set_instance_color(idx, cs.lerp(ce, f))
			idx += 1
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true; mat.roughness = 0.5
	mmi.material_override = mat
	return mmi


func _trails_aabb(trails: Array) -> AABB:
	var mn := Vector3(INF, INF, INF)
	var mx := Vector3(-INF, -INF, -INF)
	var empty := true
	for trail in trails:
		for p in trail:
			if p is Vector3 and p.is_finite():
				empty = false
				mn = mn.min(p); mx = mx.max(p)
	if empty: return AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	return AABB(mn, mx - mn)
