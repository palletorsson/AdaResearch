extends SceneTree
## probe_albers_glass_render.gd — the RENDERED evidence for the medium axis on
## albers_wall_gallery (doc/colour/albers_glass/SPEC.md §5 steps 5 and 6).
##
## Windowed only: headless draws no frames, and this probe refuses to read a viewport
## whose frames-drawn counter did not move.
##
##   --mode=oracle --medium=relief|cubes [--force-cull-back] [--canvas=45|auto]
##                 [--gain=<g>] [--hdr2d] [--root]
##       Fixture: WorldEnvironment with LINEAR tonemap, exposure 1, black background,
##       ambient and reflections off, no fog / glow / SSAO / SSR / SDFGI / adjustments.
##       An orthographic camera square-on to Canvas_NN, 0.6 m off the wall face.
##       Samples a 5x5 patch at the outer band (between the outer and second square) and
##       at the centre of the innermost square; their positions come from the READ-BACK
##       mesh (each box's head-on rectangle). Two expectations, both computed here:
##         mesh     A_k = B * prod face^passes over the read-back vertex colours (linear):
##                  what the glass as built must show
##         palette  an independent clamp-aware solve from the palette regenerated HERE
##                  over the table byte, with no quantisation: what the physics allows
##       PASS when both samples are within 3/255 of BOTH on every channel. The Canvas
##       meta 'layers' is the artifact's own solve output, so it is reported only as
##       "meta agrees with mesh", never as an oracle.
##       --force-cull-back   the glass shader recompiled CULL_BACK after the build (read
##                           back): for cubes one crossing instead of two; the centre MUST fail
##       --gain=<g>          sets the project setting ada/albers_glass/mul_gain before the
##                           build: --gain=1 on Mobile is the machine-written negative of
##                           the gain fallback (the outer band MUST fail)
##       --hdr2d             the SubViewport renders with use_hdr_2d (another buffer format)
##       --root              render in the root window instead of a SubViewport
##       Writes ada_run/albers_glass_render/<renderer>_<medium>[...].json + .png and merges
##       the run into ada_run/albers_glass_oracle.json (summary + verdict over the runs the
##       spec needs).
##   --mode=pictures --medium=paint|relief|cubes
##       Fixture for Palle: mid-grey floor, ambient c4add7 at low energy, FILMIC tonemap (so
##       these colours are not the oracle's linear ones), MSAA / SSAA / TAA forced off by the
##       fixture. Writes doc/colour/albers_glass/<medium>_<front|oblique|close|eye>.png at
##       1600x1000 (cubes also _grazing), and per view the viewport's draw calls, objects
##       and primitives, to ada_run/albers_glass_render/pictures_<medium>.json.
##       eye: a visitor's eye 1.15 m above the wall's base, 1.9 m out (in the Void the wall
##       floats 0.5 m, so that is a 1.65 m eye), 70 degree vertical FOV.
##   --mode=identity --head-source=<absolute path to the HEAD albers_wall_gallery.gd>
##       The default wall, pixel for pixel: the same picture fixture and views built three
##       times (HEAD script, working-tree script, working-tree again as the noise control),
##       compared per view. Writes ada_run/albers_glass_render/identity/*.png and
##       ada_run/albers_glass_default_identity.json.
##
## Run (one Godot at a time, under the watchdog):
##   python tools/godot_watchdog.py --expect=ada_run/albers_glass_render/mobile_cubes.json --grace=120 -- \
##     <godot> --path . --xr-mode off --rendering-method mobile --resolution 320x200 \
##     --script res://commons/testing/probe_albers_glass_render.gd -- --no-bridges --mode=oracle --medium=cubes

const SCENE := "res://algorithms/primitives/homagetothesquare/albers_wall_gallery.tscn"
const RUN_DIR := "res://ada_run/albers_glass_render/"
const ORACLE_FILE := "res://ada_run/albers_glass_oracle.json"
const IDENTITY_FILE := "res://ada_run/albers_glass_default_identity.json"
const PIC_DIR := "res://doc/colour/albers_glass/"
const GAIN_SETTING := "ada/albers_glass/mul_gain"
const TOL_255 := 3.0
const ORACLE_PX := 1000
const ORACLE_SPAN := 0.5   # metres of wall in the orthographic frame (vertical = horizontal)

var _mode: String = "oracle"
var _medium: String = ""
var _cull_back: bool = false
var _canvas: int = 45
var _canvas_auto: bool = false
var _gain: float = 0.0
var _hdr2d: bool = false
var _root_vp: bool = false
var _head_source: String = ""
var _sv: SubViewport
var _vp: Viewport
var _world: Node
var _cam: Camera3D
var _gal: Node3D


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--mode="):
			_mode = a.split("=", 1)[1]
		elif a.begins_with("--medium="):
			_medium = a.split("=", 1)[1]
		elif a == "--force-cull-back":
			_cull_back = true
		elif a == "--canvas=auto":
			_canvas_auto = true
		elif a.begins_with("--canvas="):
			_canvas = int(a.split("=", 1)[1])
		elif a.begins_with("--gain="):
			_gain = float(a.split("=", 1)[1])
		elif a == "--hdr2d":
			_hdr2d = true
		elif a == "--root":
			_root_vp = true
		elif a.begins_with("--head-source="):
			_head_source = a.split("=", 1)[1]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(RUN_DIR))
	if _gain > 0.0:
		ProjectSettings.set_setting(GAIN_SETTING, _gain)
	match _mode:
		"oracle":
			await _run_oracle()
		"pictures":
			await _run_pictures()
		"identity":
			await _run_identity()
		_:
			print("probe_albers_glass_render: unknown --mode=%s" % _mode)
			quit(2)


func _renderer() -> String:
	return RenderingServer.get_current_rendering_method()


# ------------------------------------------------------------------ fixture

func _fixture(size: Vector2i, env: Environment, with_gallery: bool = true) -> void:
	if _root_vp:
		_vp = root
		_world = Node3D.new()
		_world.name = "ProbeWorld"
		root.add_child(_world)
	else:
		_sv = SubViewport.new()
		_sv.name = "Fixture"
		_sv.size = size
		_sv.own_world_3d = true
		_sv.transparent_bg = false
		_sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		_sv.msaa_3d = Viewport.MSAA_DISABLED
		_sv.screen_space_aa = Viewport.SCREEN_SPACE_AA_DISABLED
		_sv.use_taa = false
		_sv.use_debanding = false
		_sv.use_hdr_2d = _hdr2d
		_sv.scaling_3d_scale = 1.0
		_sv.positional_shadow_atlas_size = 4096
		root.add_child(_sv)
		_vp = _sv
		_world = _sv
	var we := WorldEnvironment.new()
	we.environment = env
	_world.add_child(we)
	if with_gallery:
		_gal = _make_gallery(null)
		_world.add_child(_gal)
	_cam = Camera3D.new()
	_cam.name = "ProbeCamera"
	_world.add_child(_cam)
	_cam.make_current()


func _make_gallery(script_override: GDScript) -> Node3D:
	var g: Node3D = (load(SCENE) as PackedScene).instantiate()
	if script_override != null:
		g.set_script(script_override)
	if _medium != "" and _medium != "paint":
		g.set_meta("config_medium", _medium)
	return g


## Wait until the engine has really drawn n more frames, then one post-draw.
## Returns the number drawn (0 means a headless run: nothing on screen to read).
func _drawn(n: int) -> int:
	var f0: int = Engine.get_frames_drawn()
	var guard: int = 0
	while Engine.get_frames_drawn() - f0 < n and guard < 900:
		await process_frame
		guard += 1
	await RenderingServer.frame_post_draw
	return Engine.get_frames_drawn() - f0


func _render_info() -> Dictionary:
	return {
		"draw_calls": _vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
		"objects": _vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_OBJECTS_IN_FRAME),
		"primitives": _vp.get_render_info(Viewport.RENDER_INFO_TYPE_VISIBLE, Viewport.RENDER_INFO_PRIMITIVES_IN_FRAME),
		"shadow_draw_calls": _vp.get_render_info(Viewport.RENDER_INFO_TYPE_SHADOW, Viewport.RENDER_INFO_DRAW_CALLS_IN_FRAME),
	}


static func t_lin(x: float) -> float:
	if x <= 0.04045:
		return x / 12.92
	return pow((x + 0.055) / 1.055, 2.4)


static func t_srgb(x: float) -> float:
	x = clampf(x, 0.0, 1.0)
	if x <= 0.0031308:
		return x * 12.92
	return 1.055 * pow(x, 1.0 / 2.4) - 0.055


static func b255(c: Color) -> Array:
	return [snappedf(c.r * 255.0, 0.01), snappedf(c.g * 255.0, 0.01), snappedf(c.b * 255.0, 0.01)]


func _write_json(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(ProjectSettings.globalize_path(path), FileAccess.WRITE)
	f.store_string(JSON.stringify(data, "  ", false))
	f.close()


## The painting's palette, regenerated from the exports (the same RNG walk as the
## artifact, written out here so the palette oracle shares no code with it).
static func regen_palette(inst: Node, index: int) -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = int(inst.get("palette_seed")) + index * 31
	var smin: float = inst.get("palette_saturation_min")
	var smax: float = inst.get("palette_saturation_max")
	var vmin: float = inst.get("palette_value_min")
	var vmax: float = inst.get("palette_value_max")
	var n: int = inst.get("squares_per_canvas")
	var base_hue := fposmod(0.61803398875 * float(index), 1.0)
	var hue_span := rng.randf_range(0.18, 0.36)
	var sat_outer := rng.randf_range(smin, smax)
	var val_outer := rng.randf_range(vmin, vmax)
	var sat_inner := rng.randf_range(max(0.4, smin), smax)
	var val_inner := rng.randf_range(max(0.7, vmin), vmax)
	var out: Array = []
	for i in n:
		var t := 0.0 if n == 1 else float(i) / float(n - 1)
		var hue := fposmod(base_hue + t * hue_span + rng.randf_range(-0.03, 0.03), 1.0)
		out.append(Color.from_hsv(hue, lerp(sat_outer, sat_inner, t), lerp(val_outer, val_inner, t)))
	return out


static func full_box_vertices() -> int:
	var b := BoxMesh.new()
	b.size = Vector3.ONE
	return (b.get_mesh_arrays()[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()


# ------------------------------------------------------------------ oracle

func _oracle_env() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.background_energy_multiplier = 1.0
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.0
	env.fog_enabled = false
	env.volumetric_fog_enabled = false
	env.glow_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.ssr_enabled = false
	env.sdfgi_enabled = false
	env.adjustment_enabled = false
	return env


## The achieved sRGB colour of layer k, A_k = B * prod_{j<=k} face_j^passes (linear).
static func achieved(table: Color, faces: Array, passes: int) -> Array:
	var a: Array = [t_lin(table.r), t_lin(table.g), t_lin(table.b)]
	var out: Array = []
	for f in faces:
		var face: Color = f
		for ch in 3:
			a[ch] = a[ch] * pow(t_lin(face[ch]), passes)
		out.append(Color(t_srgb(a[0]), t_srgb(a[1]), t_srgb(a[2]), 1.0))
	return out


## The same product taken in sRGB space (what a renderer that blends sRGB values would
## show): diagnostic for the Compatibility renderer.
static func achieved_srgb_space(table: Color, faces: Array, passes: int) -> Array:
	var a: Array = [table.r, table.g, table.b]
	var out: Array = []
	for f in faces:
		var face: Color = f
		for ch in 3:
			a[ch] = a[ch] * pow(face[ch], passes)
		out.append(Color(a[0], a[1], a[2], 1.0))
	return out


## The physics from the palette alone, unquantised: over B, each square reaches its
## palette colour unless that is lighter than what already comes through, in which case it
## keeps what comes through (glass gives no light back). min() is monotonic, so the result
## is the same in linear light and in sRGB; srgb_space only skips the round trip.
static func palette_solve(table: Color, palette: Array, srgb_space: bool = false) -> Array:
	var a: Array = [table.r, table.g, table.b] if srgb_space else [t_lin(table.r), t_lin(table.g), t_lin(table.b)]
	var out: Array = []
	for p in palette:
		var c: Color = p
		for ch in 3:
			a[ch] = minf(a[ch], c[ch] if srgb_space else t_lin(c[ch]))
		out.append(Color(a[0], a[1], a[2], 1.0) if srgb_space else Color(t_srgb(a[0]), t_srgb(a[1]), t_srgb(a[2]), 1.0))
	return out


## linear_read: the viewport hands back linear floats (use_hdr_2d), encoded here to sRGB.
func _patch(img: Image, p: Vector2i, linear_read: bool = false) -> Dictionary:
	var sum := Vector3.ZERO
	var lo := Vector3(INF, INF, INF)
	var hi := Vector3(-INF, -INF, -INF)
	var n: int = 0
	for dy in range(-2, 3):
		for dx in range(-2, 3):
			var c: Color = img.get_pixel(p.x + dx, p.y + dy)
			if linear_read:
				c = Color(t_srgb(c.r), t_srgb(c.g), t_srgb(c.b), 1.0)
			var v := Vector3(c.r, c.g, c.b) * 255.0
			sum += v
			lo = lo.min(v)
			hi = hi.max(v)
			n += 1
	var mean := sum / float(n)
	return {"px": [p.x, p.y], "centre": b255(img.get_pixel(p.x, p.y)),
		"mean": [snappedf(mean.x, 0.01), snappedf(mean.y, 0.01), snappedf(mean.z, 0.01)],
		"spread": snappedf((hi - lo)[(hi - lo).max_axis_index()], 0.01),
		"color": Color(mean.x / 255.0, mean.y / 255.0, mean.z / 255.0, 1.0)}


func _compare(got: Color, expected: Color) -> Dictionary:
	var err: float = 0.0
	var gain: Array = []
	for ch in 3:
		err = maxf(err, absf(got[ch] - expected[ch]) * 255.0)
		var le: float = t_lin(expected[ch])
		gain.append(snappedf(t_lin(got[ch]) / le, 0.0001) if le > 1e-4 else null)
	return {"expected": b255(expected), "err_255": snappedf(err, 0.01), "ok": err <= TOL_255,
		"gain_linear": gain}


## Head-on rectangle (x0, y0, x1, y1) of box b of the glass mesh, in the gallery's space.
static func box_rect(v: PackedVector3Array, vb: int, b: int) -> Rect2:
	var lo := Vector2(INF, INF)
	var hi := Vector2(-INF, -INF)
	for j in vb:
		var p: Vector3 = v[b * vb + j]
		lo = lo.min(Vector2(p.x, p.y))
		hi = hi.max(Vector2(p.x, p.y))
	return Rect2(lo, hi - lo)


func _run_oracle() -> void:
	if _medium != "relief" and _medium != "cubes":
		print("oracle needs --medium=relief|cubes")
		quit(2)
		return
	var renderer: String = _renderer()
	var env := _oracle_env()
	_fixture(Vector2i(ORACLE_PX, ORACLE_PX), env)
	await _drawn(3)
	var clamp_scan: Dictionary = {}
	if _canvas_auto:
		# The least-clamped canvas: the strongest test of the nest (every layer moves).
		var best: int = 1 << 30
		for ci in int(_gal.get("total_canvases")):
			var m := _gal.get_node_or_null("Canvas_%02d" % ci)
			if m == null:
				continue
			var cl: int = int(m.get_meta("clamped", 99))
			if cl < best:
				best = cl
				_canvas = ci
		clamp_scan = {"picked": _canvas, "clamped_channels": best}
	var key: String = "%s_%s%s%s%s%s%s" % [renderer, _medium, "_cullback" if _cull_back else "",
		"" if _canvas == 45 else "_c%02d" % _canvas,
		"" if _gain <= 0.0 else "_gain%s" % ("%.3f" % _gain).rstrip("0").rstrip(".").replace(".", "p"),
		"_hdr2d" if _hdr2d else "", "_root" if _root_vp else ""]
	var result: Dictionary = {"key": key, "renderer": renderer, "medium": _medium,
		"force_cull_back": _cull_back, "canvas": _canvas, "canvas_auto": clamp_scan,
		"gain_setting": _gain, "hdr_2d": _hdr2d, "root_viewport": _root_vp,
		"adapter": RenderingServer.get_video_adapter_name(),
		"godot": Engine.get_version_info()["string"], "tolerance_255": TOL_255,
		"probe_mtime": FileAccess.get_modified_time(ProjectSettings.globalize_path("res://commons/testing/probe_albers_glass_render.gd")),
		"artifact_mtime": FileAccess.get_modified_time(ProjectSettings.globalize_path("res://algorithms/primitives/homagetothesquare/albers_wall_gallery.gd"))}

	var gmi := _gal.get_node_or_null("GlassHomages") as MeshInstance3D
	var bmi := _gal.get_node_or_null("GlassBacking") as MeshInstance3D
	var marker := _gal.get_node_or_null("Canvas_%02d" % _canvas) as Node3D
	if gmi == null or bmi == null or marker == null:
		result["error"] = "fixture incomplete: glass=%s backing=%s marker=%s" % [gmi != null, bmi != null, marker != null]
		_finish_oracle(key, result, null)
		return
	var mat := gmi.material_override
	result["glass_material"] = mat.get_class()
	if _cull_back and mat is ShaderMaterial:
		# A cull_back copy of the shader (the artifact's cached one is left alone).
		var sm := mat as ShaderMaterial
		var g = sm.get_shader_parameter("gain")
		var sh := Shader.new()
		sh.code = sm.shader.code.replace("cull_disabled", "cull_back")
		sm.shader = sh
		sm.set_shader_parameter("gain", g)
	if mat is ShaderMaterial:
		var code: String = (mat as ShaderMaterial).shader.code
		result["glass_cull_readback"] = "cull_back" if code.contains("cull_back") else ("cull_disabled" if code.contains("cull_disabled") else "?")
		result["glass_gain_readback"] = (mat as ShaderMaterial).get_shader_parameter("gain")
		result["glass_gain_source"] = _gal.get_meta("glass_mul_gain_source", null)

	var n: int = _gal.get("squares_per_canvas")
	var wall_front: float = float(_gal.get("wall_depth")) * 0.5
	var c: Vector3 = marker.global_position

	# Geometry of this canvas from the read-back mesh: each layer's head-on rectangle.
	var passes: int = 2 if _medium == "cubes" else 1
	var garr: Array = gmi.mesh.surface_get_arrays(0)
	var gverts: PackedVector3Array = garr[Mesh.ARRAY_VERTEX]
	var gcol: PackedColorArray = garr[Mesh.ARRAY_COLOR]
	var boxes: int = int(_gal.get("total_canvases")) * n
	var vb: int = full_box_vertices() if _medium == "cubes" else gcol.size() / boxes
	var rects: Array = []
	for k in n:
		rects.append(box_rect(gverts, vb, _canvas * n + k))
	var r0: Rect2 = rects[0]
	var r1: Rect2 = rects[1]
	var rn: Rect2 = rects[n - 1]
	var gpos: Vector3 = _gal.global_position
	# outer band: halfway between the outer and the second square's left edges, at the
	# second square's vertical centre; centre: the innermost square's centre
	var band_w := Vector2((r0.position.x + r1.position.x) * 0.5, r1.get_center().y) + Vector2(gpos.x, gpos.y)
	var centre_w := rn.get_center() + Vector2(gpos.x, gpos.y)
	var table_w := Vector2(r0.get_center().x, r0.end.y + 0.02) + Vector2(gpos.x, gpos.y)
	result["sample_geometry"] = {"outer": [r0.position.x, r0.position.y, r0.end.x, r0.end.y],
		"innermost": [rn.position.x, rn.position.y, rn.end.x, rn.end.y], "vertices_per_box": vb}

	_cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	_cam.keep_aspect = Camera3D.KEEP_HEIGHT
	_cam.size = ORACLE_SPAN
	_cam.near = 0.05
	_cam.far = 3.0
	_cam.global_transform = Transform3D(Basis.IDENTITY, Vector3(c.x, c.y, wall_front + 0.6))
	var drawn: int = await _drawn(8)
	result["frames_drawn"] = drawn
	if drawn < 8:
		result["error"] = "frames drawn %d < 8: headless? this probe needs a window" % drawn
		_finish_oracle(key, result, null)
		return
	result["render_info"] = _render_info()
	result["env_readback"] = {"tonemap": env.tonemap_mode, "exposure": env.tonemap_exposure,
		"ambient": env.ambient_light_source, "fog": env.fog_enabled, "glow": env.glow_enabled,
		"bg": b255(env.background_color)}
	var img: Image = _vp.get_texture().get_image()
	result["image_size"] = [img.get_width(), img.get_height()]
	result["image_format"] = img.get_format()
	var linear_read: bool = [Image.FORMAT_RGBAH, Image.FORMAT_RGBAF, Image.FORMAT_RGBH, Image.FORMAT_RGBF].has(img.get_format())
	result["readback"] = "linear float, encoded to sRGB here" if linear_read else "sRGB 8-bit"
	# Which space the framebuffer multiplies in is the renderer's (OUTPUT_IS_SRGB is true
	# in Compatibility only), decided here, not read from the artifact.
	var srgb_blend: bool = renderer == "gl_compatibility"
	result["blend_space"] = "srgb" if srgb_blend else "linear"
	result["artifact_blend_space"] = _gal.get_meta("glass_blend_space", null)

	var ppm: float = float(img.get_height()) / ORACLE_SPAN
	var to_px := func(w: Vector2) -> Vector2i:
		return Vector2i(roundi(img.get_width() * 0.5 + (w.x - c.x) * ppm), roundi(img.get_height() * 0.5 - (w.y - c.y) * ppm))

	# Expectation 1: read-back mesh colours.
	var bcol: PackedColorArray = bmi.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR]
	var table: Color = bcol[0]
	var faces: Array = []
	for k in n:
		faces.append(gcol[(_canvas * n + k) * vb])
	var a_lin: Array = achieved(table, faces, passes)
	var a_srgb: Array = achieved_srgb_space(table, faces, passes)
	var a_mesh: Array = a_srgb if srgb_blend else a_lin
	# one crossing per shell (the CULL_BACK physics)
	var a_once: Array = achieved_srgb_space(table, faces, 1) if srgb_blend else achieved(table, faces, 1)
	# Expectation 2: the palette, regenerated here, solved here.
	var pal: Array = regen_palette(_gal, _canvas)
	var a_pal: Array = palette_solve(table, pal, srgb_blend)
	# Not an oracle: the artifact's own solve output, which must agree with its mesh.
	var cc: Color = _gal.get("canvas_color")
	var table_meta := Color(roundi(cc.r * 255.0) / 255.0, roundi(cc.g * 255.0) / 255.0, roundi(cc.b * 255.0) / 255.0, 1.0)
	var layers: PackedColorArray = marker.get_meta("layers", PackedColorArray())
	var a_meta: Array = []
	if layers.size() == n:
		a_meta = achieved_srgb_space(table_meta, Array(layers), passes) if srgb_blend else achieved(table_meta, Array(layers), passes)
	var meta_agree: float = 0.0
	if a_meta.size() == n:
		for k in n:
			for ch in 3:
				meta_agree = maxf(meta_agree, absf((a_mesh[k] as Color)[ch] - (a_meta[k] as Color)[ch]) * 255.0)
	var mesh_vs_pal: float = 0.0
	for k in n:
		for ch in 3:
			mesh_vs_pal = maxf(mesh_vs_pal, absf((a_mesh[k] as Color)[ch] - (a_pal[k] as Color)[ch]) * 255.0)
	result["expectations"] = {"passes": passes, "table_mesh": b255(table),
		"faces_mesh": faces.map(func(f): return b255(f)),
		"A_mesh": a_mesh.map(func(f): return b255(f)),
		"A_palette_solve": a_pal.map(func(f): return b255(f)),
		"A_single_crossing": a_once.map(func(f): return b255(f)),
		"A_linear_blend": a_lin.map(func(f): return b255(f)),
		"A_srgb_space_blend": a_srgb.map(func(f): return b255(f)),
		"palette": pal.map(func(f): return b255(f)),
		"mesh_vs_palette_solve_max_255": snappedf(mesh_vs_pal, 0.001),
		"meta_agrees_with_mesh_max_255": snappedf(meta_agree, 0.001),
		"canvas_clamped_channels": marker.get_meta("clamped", -1)}

	var samples: Dictionary = {}
	for pair in [["outer_band", band_w, 0], ["centre", centre_w, n - 1]]:
		var p: Dictionary = _patch(img, to_px.call(pair[1]), linear_read)
		var got: Color = p["color"]
		p.erase("color")
		var k: int = pair[2]
		var vm: Dictionary = _compare(got, a_mesh[k])
		var vp: Dictionary = _compare(got, a_pal[k])
		p["vs_mesh"] = vm
		p["vs_palette_solve"] = vp
		p["ok"] = bool(vm["ok"]) and bool(vp["ok"])
		p["vs_single_crossing"] = _compare(got, a_once[k])
		p["vs_linear_blend"] = _compare(got, a_lin[k])
		p["vs_srgb_space_blend"] = _compare(got, a_srgb[k])
		samples[pair[0]] = p
	var tp: Dictionary = _patch(img, to_px.call(table_w), linear_read)
	var tgot: Color = tp["color"]
	tp.erase("color")
	tp.merge(_compare(tgot, table))
	samples["light_table"] = tp
	result["samples"] = samples
	result["pass"] = bool(samples["outer_band"]["ok"]) and bool(samples["centre"]["ok"]) and meta_agree <= 1.0
	_finish_oracle(key, result, img)


func _finish_oracle(key: String, result: Dictionary, img: Image) -> void:
	if img != null:
		img.save_png(ProjectSettings.globalize_path(RUN_DIR + key + ".png"))
		result["capture"] = RUN_DIR + key + ".png"
	if not result.has("pass"):
		result["pass"] = false
	# Merge into the oracle file.
	var all: Dictionary = {}
	var p: String = ProjectSettings.globalize_path(ORACLE_FILE)
	if FileAccess.file_exists(p):
		var parsed = JSON.parse_string(FileAccess.get_file_as_string(p))
		if parsed is Dictionary:
			all = parsed
	var runs: Dictionary = all.get("runs", {})
	result["at"] = Time.get_datetime_string_from_system()
	runs[key] = result
	all["runs"] = runs
	var need_pass: Array = ["mobile_relief", "mobile_cubes", "forward_plus_relief", "forward_plus_cubes",
		"mobile_relief_c44", "mobile_cubes_c44", "forward_plus_relief_c44", "forward_plus_cubes_c44",
		# the gain follows the buffer, not the renderer's name; Compatibility blends sRGB
		"mobile_relief_hdr2d", "forward_plus_relief_hdr2d", "mobile_relief_root",
		"gl_compatibility_relief", "gl_compatibility_cubes"]
	# [run, the sample that MUST fail]
	var need_fail: Array = [["mobile_cubes_cullback", "centre"], ["forward_plus_cubes_cullback", "centre"],
		["mobile_cubes_cullback_c44", "centre"], ["forward_plus_cubes_cullback_c44", "centre"],
		["mobile_relief_gain1", "outer_band"], ["mobile_relief_gain2_hdr2d", "outer_band"]]
	var summary: Dictionary = {}
	var verdict := true
	for k in need_pass:
		var r: Dictionary = runs.get(k, {})
		var v: String = "missing" if r.is_empty() else ("pass" if r.get("pass", false) else "FAIL")
		summary[k] = v
		verdict = verdict and v == "pass"
	for nf in need_fail:
		var r: Dictionary = runs.get(nf[0], {})
		var v: String = "missing"
		if not r.is_empty():
			var s_ok: bool = r.get("samples", {}).get(nf[1], {}).get("ok", true)
			v = ("negative bites (%s fails)" % nf[1]) if not s_ok and not r.has("error") else "NEGATIVE DID NOT BITE"
		summary[nf[0]] = v
		verdict = verdict and v.begins_with("negative bites")
	all["summary"] = summary
	all["verdict"] = "PASS" if verdict else "INCOMPLETE OR FAIL"
	all["spec"] = "doc/colour/albers_glass/SPEC.md section 5 step 5"
	_write_json(ORACLE_FILE, all)
	_write_json(RUN_DIR + key + ".json", result)
	print("probe_albers_glass_render %s pass=%s" % [key, result["pass"]])
	quit(0)


# ------------------------------------------------------------------ pictures

func _picture_env() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.13, 0.12, 0.155)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c4add7")
	env.ambient_light_energy = 0.35
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.fog_enabled = false
	env.glow_enabled = false
	return env


func _look(from: Vector3, at: Vector3, fov: float) -> void:
	_cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	_cam.keep_aspect = Camera3D.KEEP_HEIGHT
	_cam.fov = fov
	_cam.near = 0.05
	_cam.far = 60.0
	_cam.look_at_from_position(from, at, Vector3.UP)


func _picture_fixture() -> void:
	_fixture(Vector2i(1600, 1000), _picture_env(), false)
	var floor_mi := MeshInstance3D.new()
	floor_mi.name = "ProbeFloor"
	var pm := PlaneMesh.new()
	pm.size = Vector2(40.0, 40.0)
	floor_mi.mesh = pm
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.5, 0.5, 0.5)
	fm.roughness = 0.9
	floor_mi.material_override = fm
	floor_mi.position = Vector3(0.0, -0.001, 0.0)
	_world.add_child(floor_mi)


## The views, from the gallery's exports (defaults: the same for every medium).
func _views(g: Node3D, medium: String) -> Array:
	var cs: float = g.get("canvas_size")
	var gap: float = g.get("gap")
	var margin: float = g.get("wall_margin")
	var cols: int = g.get("columns")
	var rows: int = g.get("rows")
	var w: float = cols * cs + (cols - 1) * gap + margin * 2.0
	var h: float = rows * cs + (rows - 1) * gap + margin * 2.0
	var wall_front: float = float(g.get("wall_depth")) * 0.5
	var left_third := Vector3(-w * 0.5 + w / 6.0, 1.6, wall_front)
	var right_third := Vector3(w * 0.5 - w / 6.0, 1.8, wall_front)
	# Close-up: a 3 x 2 block of canvases (columns 5..7, rows 3..4), seen from 1 m off
	# the glass, 0.3 m below the block's centre and a little to the side.
	var start_x: float = -w * 0.5 + margin + cs * 0.5
	var start_y: float = margin + cs * 0.5
	var bx: float = start_x + 6 * (cs + gap)
	var by: float = start_y + (rows - 1 - 3.5) * (cs + gap)
	var glass_front: float = wall_front + 0.05 + cs * (1.0 - 2.0 * float(g.get("border_ratio")))
	var a35: float = deg_to_rad(35.0)
	var a70: float = deg_to_rad(70.0)
	var eye := Vector3(start_x + 4 * (cs + gap), 1.15, wall_front + 1.9)
	var views: Array = [
		["front", Vector3(0.0, h * 0.5, 6.4), Vector3(0.0, h * 0.5, 0.0), 45.0],
		["oblique", left_third + Vector3(-sin(a35), 0.0, cos(a35)) * 2.5, left_third, 60.0],
		["close", Vector3(bx + 0.18, by - 0.3, glass_front + 1.0), Vector3(bx, by, wall_front), 36.0],
		["eye", eye, Vector3(eye.x + 0.6, 1.75, wall_front), 70.0],
	]
	if medium == "cubes":
		views.append(["grazing", right_third + Vector3(sin(a70), 0.0, cos(a70)) * 3.0, right_third, 55.0])
	return views


func _run_pictures() -> void:
	if not ["paint", "relief", "cubes"].has(_medium):
		print("pictures needs --medium=paint|relief|cubes")
		quit(2)
		return
	_picture_fixture()
	_gal = _make_gallery(null)
	_world.add_child(_gal)
	await _drawn(3)
	var manifest: Dictionary = {"medium": _medium, "renderer": _renderer(),
		"adapter": RenderingServer.get_video_adapter_name(), "tonemap": "filmic",
		"aa": "msaa/ssaa/taa forced off by the fixture", "views": {}}
	for v in _views(_gal, _medium):
		_look(v[1], v[2], v[3])
		var drawn: int = await _drawn(12)
		var img: Image = _vp.get_texture().get_image()
		var name: String = "%s_%s.png" % [_medium, v[0]]
		img.save_png(ProjectSettings.globalize_path(PIC_DIR + name))
		manifest["views"][v[0]] = {"file": PIC_DIR + name, "from": [v[1].x, v[1].y, v[1].z],
			"at": [v[2].x, v[2].y, v[2].z], "fov": v[3], "frames_drawn": drawn,
			"size": [img.get_width(), img.get_height()], "render_info": _render_info()}
	_write_json(RUN_DIR + "pictures_%s.json" % _medium, manifest)
	print("probe_albers_glass_render pictures %s done" % _medium)
	quit(0)


# ------------------------------------------------------------------ identity

func _shoot_all(tag: String, out_dir: String) -> Dictionary:
	var shots: Dictionary = {}
	for v in _views(_gal, "paint"):
		_look(v[1], v[2], v[3])
		var drawn: int = await _drawn(12)
		var img: Image = _vp.get_texture().get_image()
		var path: String = out_dir + "%s_%s.png" % [tag, v[0]]
		img.save_png(ProjectSettings.globalize_path(path))
		shots[v[0]] = {"image": img, "path": path, "drawn": drawn, "info": _render_info()}
	return shots


## Equality of the raw pixel bytes (a per-pixel loop over 1.6 Mpx in GDScript would stall
## the watchdog); tools/albers_glass_identity_diff.py counts the differing pixels from the
## saved PNGs when they are not equal.
static func _pixel_diff(a: Image, b: Image) -> Dictionary:
	if a.get_size() != b.get_size() or a.get_format() != b.get_format():
		return {"same_size": false, "pixel_bytes_equal": false}
	var equal: bool = a.get_data() == b.get_data()
	return {"same_size": true, "pixel_bytes_equal": equal, "differing_pixels": 0 if equal else -1,
		"pixels": a.get_width() * a.get_height()}


## Builds in the order head, tree, tree, head. Measured on the first run of this mode: the
## SECOND paint build of a session differs from the first and third by a few z-fight
## pixels (the painted quads are coplanar, CULL_DISABLED) whatever the script, so builds
## are compared at the same parity: head_1 vs tree_3 and tree_2 vs head_4 are the script's
## effect; head_1 vs head_4 and tree_2 vs tree_3 are the position noise, measured.
const IDENTITY_ORDER := ["head_1", "tree_2", "tree_3", "head_4"]
const IDENTITY_PAIRS := {"script_odd": ["head_1", "tree_3"], "script_even": ["tree_2", "head_4"],
	"control_head": ["head_1", "head_4"], "control_tree": ["tree_2", "tree_3"]}


func _run_identity() -> void:
	if _head_source == "" or not FileAccess.file_exists(_head_source):
		print("identity needs --head-source=<absolute path to the HEAD script>")
		quit(2)
		return
	_medium = "paint"
	var head := GDScript.new()
	head.source_code = FileAccess.get_file_as_string(_head_source)
	var err: int = head.reload()
	var out_dir: String = RUN_DIR + "identity/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var report: Dictionary = {"renderer": _renderer(), "adapter": RenderingServer.get_video_adapter_name(),
		"head_source": _head_source, "head_reload_error": err,
		"head_sha256": FileAccess.get_sha256(_head_source),
		"tree_sha256": FileAccess.get_sha256(ProjectSettings.globalize_path("res://algorithms/primitives/homagetothesquare/albers_wall_gallery.gd")),
		"fixture": "pictures (filmic, floor, ambient c4add7, the wall's own 4 shadowed spots)",
		"order": IDENTITY_ORDER, "pairs": IDENTITY_PAIRS,
		"at": Time.get_datetime_string_from_system()}
	if err != OK:
		report["error"] = "HEAD script did not compile"
		_write_json(IDENTITY_FILE, report)
		quit(1)
		return
	_picture_fixture()
	var builds: Dictionary = {}
	var children: Dictionary = {}
	for tag in IDENTITY_ORDER:
		_gal = _make_gallery(head if tag.begins_with("head") else null)
		_world.add_child(_gal)
		await _drawn(3)
		builds[tag] = await _shoot_all(tag, out_dir)
		children[tag] = _gal.get_child_count()
		_gal.queue_free()
		await _drawn(3)
	var views: Dictionary = {}
	var script_identical := true
	for vname in (builds["head_1"] as Dictionary).keys():
		var files: Dictionary = {}
		for tag in IDENTITY_ORDER:
			files[tag] = builds[tag][vname]["path"]
		var cmp: Dictionary = {}
		for pname in IDENTITY_PAIRS:
			var pr: Array = IDENTITY_PAIRS[pname]
			cmp[pname] = _pixel_diff(builds[pr[0]][vname]["image"], builds[pr[1]][vname]["image"])
			if pname.begins_with("script"):
				script_identical = script_identical and bool(cmp[pname].get("pixel_bytes_equal", false))
		views[vname] = {"compare": cmp, "files": files, "render_info_head": builds["head_1"][vname]["info"],
			"render_info_tree": builds["tree_3"][vname]["info"]}
	report["children"] = children
	report["views"] = views
	report["verdict"] = "PIXEL-IDENTICAL (same session parity)" if script_identical else "DIFFERS"
	_write_json(IDENTITY_FILE, report)
	print("probe_albers_glass_render identity %s" % report["verdict"])
	quit(0)
