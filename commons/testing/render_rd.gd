extends SceneTree

## Render a Reaction-Diffusion config to a PNG.
## DNA = preset or (F, K) + grid_size + iterations + seed + render_mode.
## Render modes:
##   heightmap — V concentration as Z-height on a PlaneMesh
##   plate     — flat textured plate (V mapped to color)
##   pillars   — one pillar per above-threshold cell
##
## Usage:
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/render_rd.gd -- \
##     --config=<path.json> --out=user://rd_gallery/<id>.png --size=640

const RDSimScript = preload("res://commons/rd_grammar/rd_sim.gd")

var _config_path: String = ""
var _output_path: String = "user://rd_gallery/out.png"
var _size: int = 640
var _wait: float = 0.5


func _initialize() -> void:
	_parse_args()
	if _config_path.is_empty():
		push_error("render_rd: --config required")
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


func _run() -> void:
	var txt := FileAccess.get_file_as_string(_config_path)
	if txt.is_empty():
		txt = FileAccess.get_file_as_string(ProjectSettings.globalize_path(_config_path))
	if txt.is_empty():
		push_error("render_rd: empty config"); quit(1); return
	var j := JSON.new()
	if j.parse(txt) != OK:
		push_error("render_rd: bad JSON"); quit(1); return
	var cfg: Dictionary = j.data

	var scene := Node3D.new()
	scene.name = "RDRender"
	root.add_child(scene)

	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	var bg_arr = cfg.get("background", [0.94, 0.93, 0.88])
	env.background_color = Color(float(bg_arr[0]), float(bg_arr[1]), float(bg_arr[2]))
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.95, 0.95, 0.92)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.ssao_enabled = true
	var we := WorldEnvironment.new(); we.environment = env
	scene.add_child(we)

	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-55, -30, 0)
	key.light_energy = 1.3
	key.shadow_enabled = true
	scene.add_child(key)
	var fill := DirectionalLight3D.new()
	fill.rotation_degrees = Vector3(-15, 120, 0)
	fill.light_energy = 0.4
	scene.add_child(fill)

	# Simulate RD
	var N: int = int(cfg.get("grid_size", 96))
	print("render_rd: simulating %d^2 cells..." % N)
	var field: PackedFloat32Array = RDSimScript.simulate(cfg)

	var mode: String = String(cfg.get("render_mode", "heightmap"))
	var color_lo := _color(cfg.get("color_lo", [0.15, 0.2, 0.3]))
	var color_hi := _color(cfg.get("color_hi", [0.9, 0.8, 0.5]))
	var world_size: float = float(cfg.get("world_size", 3.0))
	var height_amp: float = float(cfg.get("height_amp", 0.8))

	var node: Node3D = null
	match mode:
		"plate":    node = _build_plate(field, N, color_lo, color_hi, world_size)
		"pillars":  node = _build_pillars(field, N, color_lo, color_hi, world_size,
			float(cfg.get("threshold", 0.25)))
		_:          node = _build_heightmap(field, N, color_lo, color_hi, world_size, height_amp)
	scene.add_child(node)

	await process_frame
	await process_frame

	var cam := Camera3D.new()
	cam.current = true; cam.fov = 38
	scene.add_child(cam)
	var yaw: float = float(cfg.get("camera_yaw", 0.5))
	var pitch: float = float(cfg.get("camera_pitch", 0.6))
	var dist: float = world_size * 1.6
	var offset := Vector3(sin(yaw) * cos(pitch), sin(pitch), cos(yaw) * cos(pitch)) * dist
	cam.global_position = Vector3(0, 0, 0) + offset
	cam.look_at(Vector3.ZERO, Vector3.UP)

	root.content_scale_size = Vector2i(_size, _size)
	root.size = Vector2i(_size, _size)

	await create_timer(_wait).timeout
	await process_frame
	await process_frame

	var img: Image = root.get_texture().get_image()
	if img == null:
		push_error("render_rd: no viewport image"); quit(1); return
	var abs_out := ProjectSettings.globalize_path(_output_path)
	var od := abs_out.get_base_dir()
	if not DirAccess.dir_exists_absolute(od):
		DirAccess.make_dir_recursive_absolute(od)
	var err := img.save_png(abs_out)
	if err != OK:
		push_error("render_rd: save failed"); quit(1); return
	print("render_rd: saved %s" % abs_out)
	quit(0)


func _color(a) -> Color:
	if a is Array and a.size() >= 3:
		return Color(float(a[0]), float(a[1]), float(a[2]))
	return Color.WHITE


# ─── Heightmap mesh — V field as Z displacement on a grid plane ───

func _build_heightmap(field: PackedFloat32Array, N: int,
		color_lo: Color, color_hi: Color, world_size: float, amp: float) -> MeshInstance3D:
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var cell: float = world_size * 2.0 / float(N - 1)
	for iy in N:
		for ix in N:
			var x: float = -world_size + float(ix) * cell
			var z: float = -world_size + float(iy) * cell
			var h: float = field[iy * N + ix] * amp
			verts.append(Vector3(x, h, z))
			var t: float = clampf(field[iy * N + ix] * 2.0, 0.0, 1.0)
			colors.append(color_lo.lerp(color_hi, t))
	for iy in N - 1:
		for ix in N - 1:
			var i0: int = iy * N + ix
			var i1: int = iy * N + ix + 1
			var i2: int = (iy + 1) * N + ix + 1
			var i3: int = (iy + 1) * N + ix
			indices.append_array([i0, i1, i2, i0, i2, i3])

	# Normals
	var normals := PackedVector3Array()
	normals.resize(verts.size())
	for i in normals.size(): normals[i] = Vector3.ZERO
	for k in indices.size() / 3:
		var ia: int = indices[k * 3]
		var ib: int = indices[k * 3 + 1]
		var ic: int = indices[k * 3 + 2]
		var n: Vector3 = (verts[ib] - verts[ia]).cross(verts[ic] - verts[ia])
		if n.length_squared() > 1e-12: n = n.normalized()
		normals[ia] = normals[ia] + n
		normals[ib] = normals[ib] + n
		normals[ic] = normals[ic] + n
	for i in normals.size():
		normals[i] = normals[i].normalized() if normals[i].length_squared() > 1e-12 else Vector3.UP

	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_COLOR]  = colors
	arrays[Mesh.ARRAY_INDEX]  = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)

	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.55
	mi.material_override = mat
	return mi


# ─── Plate — flat textured quad, V as color only ───

func _build_plate(field: PackedFloat32Array, N: int,
		color_lo: Color, color_hi: Color, world_size: float) -> MeshInstance3D:
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	var cell: float = world_size * 2.0 / float(N - 1)
	for iy in N:
		for ix in N:
			var x: float = -world_size + float(ix) * cell
			var z: float = -world_size + float(iy) * cell
			verts.append(Vector3(x, 0, z))
			var t: float = clampf(field[iy * N + ix] * 2.0, 0.0, 1.0)
			colors.append(color_lo.lerp(color_hi, t))
	for iy in N - 1:
		for ix in N - 1:
			var i0: int = iy * N + ix
			var i1: int = iy * N + ix + 1
			var i2: int = (iy + 1) * N + ix + 1
			var i3: int = (iy + 1) * N + ix
			indices.append_array([i0, i1, i2, i0, i2, i3])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR]  = colors
	arrays[Mesh.ARRAY_INDEX]  = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = mat
	return mi


# ─── Pillars — one vertical cylinder per above-threshold cell ───

func _build_pillars(field: PackedFloat32Array, N: int,
		color_lo: Color, color_hi: Color, world_size: float, thresh: float) -> MultiMeshInstance3D:
	var cells: Array = []
	for iy in N:
		for ix in N:
			if field[iy * N + ix] > thresh:
				cells.append([ix, iy, field[iy * N + ix]])
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.5; cyl.bottom_radius = 0.5; cyl.height = 1.0
	cyl.radial_segments = 6
	mm.mesh = cyl
	mm.instance_count = cells.size()
	var cell: float = world_size * 2.0 / float(N - 1)
	for i in cells.size():
		var c = cells[i]
		var ix: int = c[0]; var iy: int = c[1]; var v: float = c[2]
		var x: float = -world_size + float(ix) * cell
		var z: float = -world_size + float(iy) * cell
		var h: float = 0.05 + v * 0.5
		var t := Transform3D(Basis().scaled(Vector3(cell * 0.45, h, cell * 0.45)),
			Vector3(x, h * 0.5, z))
		mm.set_instance_transform(i, t)
		mm.set_instance_color(i, color_lo.lerp(color_hi, clampf(v * 2.0, 0.0, 1.0)))
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.55
	mmi.material_override = mat
	return mmi
