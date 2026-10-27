## colour_bench.gd — the warm Godot render bench behind /spatial-lab's colour family.
##
## Palle, 2026-10-27: "we should use a system like this for fast color test" + "one lab".
## The browser cannot show colour truth (no multiply glass, different tonemap and
## vertex-colour handling), so the colour family's receipt is a native picture on the
## renderer the Quest runs (Mobile). Booting Godot per test costs 10-25 s; this bench boots
## once and renders each request in about a second.
##
## It is a SceneTree that watches an inbox folder. tools/colour_bench.py writes one request
## JSON at a time (holding tools/void_native_slot.py while it waits), this script builds the
## recipe's artifact in a fixed fixture, shoots its views, samples pixels if the recipe has an
## oracle, writes the PNGs and a result JSON, and goes back to waiting.
##
##   godot --path <stage> --xr-mode off --rendering-method mobile --resolution 640x400 \
##     --script res://commons/testing/colour_bench.gd -- --no-bridges \
##     --inbox=<abs dir> --outbox=<abs dir> [--idle=600]
##
## Request:  {"id", "recipe": <the recipe object from commons/modular/lab_colour.json>,
##            "params": {...}, "views": [..], "out_dir": <abs dir>, "prefix": "<hash>"}
## Result:   {"id", "ok", "error", "views": {name: file}, "oracle": {...} | null,
##            "readback": {...}, "timing": {...}, "renderer", "adapter"}
##
## The oracle reuses the Albers glass probe's own statics (achieved, box_rect,
## full_box_vertices), the ones verified against an independent palette solve on both
## renderers. The bench adds no colour maths of its own.
extends SceneTree

const Probe := preload("res://commons/testing/probe_albers_glass_render.gd")

const PICTURE_SIZE := Vector2i(1600, 1000)
const ORACLE_PX_PER_M := 390.0

var _inbox: String = ""
var _outbox: String = ""
var _idle_s: float = 600.0
var _last_work_ms: int = 0
var _busy: bool = false


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--inbox="):
			_inbox = a.trim_prefix("--inbox=")
		elif a.begins_with("--outbox="):
			_outbox = a.trim_prefix("--outbox=")
		elif a.begins_with("--idle="):
			_idle_s = float(a.trim_prefix("--idle="))
	if _inbox == "" or _outbox == "":
		print("colour_bench: needs --inbox=<dir> --outbox=<dir>")
		quit(2)
		return
	DirAccess.make_dir_recursive_absolute(_inbox)
	DirAccess.make_dir_recursive_absolute(_outbox)
	_last_work_ms = Time.get_ticks_msec()
	_write_json(_outbox.path_join("_ready.json"), {"pid": OS.get_process_id(),
		"renderer": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name(), "t_ms": Time.get_ticks_msec()})
	print("COLOUR_BENCH_READY renderer=%s" % RenderingServer.get_current_rendering_method())
	_loop.call_deferred()


func _loop() -> void:
	while true:
		if FileAccess.file_exists(_inbox.path_join("quit")):
			DirAccess.remove_absolute(_inbox.path_join("quit"))
			break
		var next: String = _next_request()
		if next != "":
			_busy = true
			await _handle(next)
			_busy = false
			_last_work_ms = Time.get_ticks_msec()
		elif Time.get_ticks_msec() - _last_work_ms > int(_idle_s * 1000.0):
			print("colour_bench: idle %.0f s, exiting" % _idle_s)
			break
		await create_timer(0.05).timeout
	quit(0)


func _next_request() -> String:
	var d := DirAccess.open(_inbox)
	if d == null:
		return ""
	var names: PackedStringArray = []
	for f in d.get_files():
		if f.ends_with(".json"):
			names.append(f)
	if names.is_empty():
		return ""
	names.sort()
	return _inbox.path_join(names[0])


func _handle(path: String) -> void:
	var t0: int = Time.get_ticks_msec()
	var req: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	DirAccess.remove_absolute(path)
	if not (req is Dictionary):
		return
	var r: Dictionary = req
	var id: String = String(r.get("id", path.get_file().get_basename()))
	var result: Dictionary = {"id": id, "ok": false, "error": "", "views": {}, "oracle": null,
		"renderer": RenderingServer.get_current_rendering_method(),
		"adapter": RenderingServer.get_video_adapter_name()}
	var recipe: Dictionary = r.get("recipe", {})
	var params: Dictionary = r.get("params", {})
	var out_dir: String = String(r.get("out_dir", _outbox))
	var prefix: String = String(r.get("prefix", id))
	DirAccess.make_dir_recursive_absolute(out_dir)

	# ---- fixture: one SubViewport with its own world, rebuilt per request
	var sv := SubViewport.new()
	sv.size = PICTURE_SIZE
	sv.own_world_3d = true
	sv.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	sv.msaa_3d = Viewport.MSAA_4X
	sv.use_hdr_2d = false
	root.add_child(sv)
	var we := WorldEnvironment.new()
	we.environment = _picture_env()
	sv.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-48, 32, 0)
	sun.light_energy = 1.1
	sun.light_color = Color("ffe9d6")
	sv.add_child(sun)
	var floor_mi := MeshInstance3D.new()
	var fm := PlaneMesh.new()
	fm.size = Vector2(40, 40)
	floor_mi.mesh = fm
	var fmat := StandardMaterial3D.new()
	fmat.albedo_color = Color(0.62, 0.61, 0.63)
	fmat.roughness = 0.95
	floor_mi.material_override = fmat
	sv.add_child(floor_mi)
	var cam := Camera3D.new()
	sv.add_child(cam)
	cam.make_current()

	# ---- the artifact, configured as a map token or a Void record would configure it
	var scene_path: String = String(recipe.get("scene", ""))
	var ps := load(scene_path) as PackedScene
	if ps == null:
		result["error"] = "scene did not load: %s" % scene_path
		_finish(result, sv, out_dir, prefix, t0)
		return
	var art: Node3D = ps.instantiate() as Node3D
	var readback: Dictionary = {}
	var specs: Dictionary = recipe.get("parameters", {})
	for key in params:
		var spec: Dictionary = specs.get(key, {})
		var value: Variant = params[key]
		if String(spec.get("type", "")) == "int":
			value = int(value)
		elif String(spec.get("type", "")) == "float":
			value = float(value)
		else:
			value = String(value)
		if String(spec.get("kind", "")) == "config":
			art.set_meta("config_%s" % key, value)
		else:
			art.set(key, value)
			# a typed set() of the wrong type is refused in silence: read it back
			var got: Variant = art.get(key)
			readback[key] = got
			if typeof(got) != typeof(value) or (value is float and absf(float(got) - float(value)) > 1e-6) or (not (value is float) and got != value):
				result["error"] = "parameter %s was refused: sent %s, artifact holds %s" % [key, value, got]
	var tb: int = Time.get_ticks_msec()
	sv.add_child(art)
	if art.has_method("apply_grid_config"):
		var cfg: Dictionary = {}
		for key in params:
			if String((specs.get(key, {}) as Dictionary).get("kind", "")) == "config":
				cfg[key] = art.get_meta("config_%s" % key)
		if not cfg.is_empty():
			art.call("apply_grid_config", cfg)
	for key in params:
		if String((specs.get(key, {}) as Dictionary).get("kind", "")) == "config" and String(key) in art:
			readback[key] = art.get(key)
	result["readback"] = readback
	if result["error"] != "":
		_finish(result, sv, out_dir, prefix, t0)
		return
	await _drawn(2)
	var build_ms: int = Time.get_ticks_msec() - tb

	# ---- views, framed on the artifact's measured bounds
	var box: AABB = _bounds(art)
	var shots: Dictionary = {}
	var t_views: int = Time.get_ticks_msec()
	for v in r.get("views", recipe.get("views", ["front"])):
		var view: String = String(v)
		_aim(cam, box, view)
		await _drawn(3)
		var img: Image = sv.get_texture().get_image()
		var file: String = "%s-%s.png" % [prefix, view]
		img.save_png(out_dir.path_join(file))
		shots[view] = file
	result["views"] = shots
	var views_ms: int = Time.get_ticks_msec() - t_views

	# ---- oracle
	var t_or: int = Time.get_ticks_msec()
	var oracle_name: Variant = recipe.get("oracle", null)
	if oracle_name == "albers_layers":
		result["oracle"] = await _oracle_albers(sv, we, sun, floor_mi, cam, art, out_dir, prefix,
			float(r.get("tolerance_255", 3.0)))
	else:
		result["oracle"] = {"kind": null, "note": "this recipe declares no oracle: pictures only"}
	result["ok"] = true
	result["timing"] = {"build_ms": build_ms, "views_ms": views_ms,
		"oracle_ms": Time.get_ticks_msec() - t_or}
	_finish(result, sv, out_dir, prefix, t0)


func _finish(result: Dictionary, sv: SubViewport, out_dir: String, prefix: String, t0: int) -> void:
	var timing: Dictionary = result.get("timing", {})
	timing["bench_total_ms"] = Time.get_ticks_msec() - t0
	result["timing"] = timing
	if sv != null:
		sv.queue_free()
	_write_json(_outbox.path_join("%s.json" % String(result["id"])), result)
	print("COLOUR_BENCH_DONE %s ok=%s %d ms" % [result["id"], result["ok"], timing["bench_total_ms"]])


## Albers glass: every canvas's outer band and innermost centre against the product of the
## light table and the face colours read back from the mesh (A_k), the probe's verified
## expectation, in a linear-tonemap orthographic shot of the whole wall. Paint has no oracle:
## it is the reference.
func _oracle_albers(sv: SubViewport, we: WorldEnvironment, sun: DirectionalLight3D,
		floor_mi: MeshInstance3D, cam: Camera3D, gal: Node3D, out_dir: String, prefix: String,
		tol: float) -> Dictionary:
	var medium: String = String(gal.get("medium"))
	if medium != "relief" and medium != "cubes":
		return {"kind": "albers_layers", "skipped": "paint is the reference medium: no glass to check"}
	var gmi := gal.get_node_or_null("GlassHomages") as MeshInstance3D
	var bmi := gal.get_node_or_null("GlassBacking") as MeshInstance3D
	if gmi == null or bmi == null:
		return {"kind": "albers_layers", "pass": false, "error": "no GlassHomages / GlassBacking"}
	var n: int = int(gal.get("squares_per_canvas"))
	var count: int = int(gal.get("total_canvases"))
	var passes: int = 2 if medium == "cubes" else 1
	var garr: Array = gmi.mesh.surface_get_arrays(0)
	var gverts: PackedVector3Array = garr[Mesh.ARRAY_VERTEX]
	var gcol: PackedColorArray = garr[Mesh.ARRAY_COLOR]
	var vb: int = Probe.full_box_vertices() if medium == "cubes" else gcol.size() / (count * n)
	var table: Color = (bmi.mesh.surface_get_arrays(0)[Mesh.ARRAY_COLOR] as PackedColorArray)[0]

	# the probe's oracle fixture: linear tonemap, nothing lit, nothing in front
	var saved_env: Environment = we.environment
	we.environment = _oracle_env()
	sun.visible = false
	floor_mi.visible = false
	var box: AABB = _bounds(gal)
	var px := Vector2i(ceili(box.size.x * ORACLE_PX_PER_M), ceili(box.size.y * ORACLE_PX_PER_M))
	sv.size = px
	sv.msaa_3d = Viewport.MSAA_DISABLED
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.keep_aspect = Camera3D.KEEP_HEIGHT
	cam.size = box.size.y
	cam.near = 0.05
	cam.far = 6.0
	var c: Vector3 = box.get_center()
	cam.global_transform = Transform3D(Basis.IDENTITY, Vector3(c.x, c.y, box.end.z + 1.0))
	var drawn: int = await _drawn(6)
	if drawn < 6:
		return {"kind": "albers_layers", "pass": false, "error": "no frames drawn (headless?)"}
	var img: Image = sv.get_texture().get_image()
	var linear_read: bool = [Image.FORMAT_RGBAH, Image.FORMAT_RGBAF, Image.FORMAT_RGBH, Image.FORMAT_RGBF].has(img.get_format())
	var srgb_blend: bool = RenderingServer.get_current_rendering_method() == "gl_compatibility"
	var ppm: float = float(img.get_height()) / box.size.y
	var gpos: Vector3 = gal.global_position
	var to_px := func(w: Vector2) -> Vector2i:
		return Vector2i(roundi(img.get_width() * 0.5 + (w.x - c.x) * ppm), roundi(img.get_height() * 0.5 - (w.y - c.y) * ppm))
	var worst: float = 0.0
	var fails: Array = []
	var rows: Array = []
	var detail: Array = []
	var quant_used: int = 0
	var wrong_pass: int = 0
	for ci in count:
		var rects: Array = []
		for k in n:
			rects.append(Probe.box_rect(gverts, vb, ci * n + k))
		var r0: Rect2 = rects[0]
		var r1: Rect2 = rects[1]
		var rn: Rect2 = rects[n - 1]
		var faces: Array = []
		for k in n:
			faces.append(gcol[(ci * n + k) * vb])
		var a: Array = Probe.achieved_srgb_space(table, faces, passes) if srgb_blend else Probe.achieved(table, faces, passes)
		# the WRONG physics, for discrimination: relief crossed twice, cubes crossed once
		var wrong_passes: int = 1 if passes == 2 else 2
		var aw: Array = Probe.achieved_srgb_space(table, faces, wrong_passes) if srgb_blend else Probe.achieved(table, faces, wrong_passes)
		var band_w := Vector2((r0.position.x + r1.position.x) * 0.5, r1.get_center().y) + Vector2(gpos.x, gpos.y)
		var centre_w := rn.get_center() + Vector2(gpos.x, gpos.y)
		var g_band: Color = _sample(img, to_px.call(band_w), linear_read)
		var g_centre: Color = _sample(img, to_px.call(centre_w), linear_read)
		var e_band: float = _err(g_band, a[0])
		var e_centre: float = _err(g_centre, a[n - 1])
		var e: float = maxf(e_band, e_centre)
		worst = maxf(worst, e)
		# a patch passes within tol (sRGB /255), or within one buffer step per crossing in
		# linear light: crossings = layers seen x passes per shell
		var ok_band: bool = _ok(g_band, a[0], tol, passes, srgb_blend)
		var ok_centre: bool = _ok(g_centre, a[n - 1], tol, n * passes, srgb_blend)
		if (ok_band and e_band > tol) or (ok_centre and e_centre > tol):
			quant_used += 1
		if _ok(g_band, aw[0], tol, passes, srgb_blend):
			wrong_pass += 1
		if _ok(g_centre, aw[n - 1], tol, n * passes, srgb_blend):
			wrong_pass += 1
		rows.append([ci, snappedf(e_band, 0.01), snappedf(e_centre, 0.01)])
		detail.append({"canvas": ci, "err": e, "band": {"expected": Probe.b255(a[0]), "got": Probe.b255(g_band), "ok": ok_band},
			"centre": {"expected": Probe.b255(a[n - 1]), "got": Probe.b255(g_centre), "ok": ok_centre}})
		if not (ok_band and ok_centre):
			fails.append(ci)
	var oracle_file: String = "%s-oracle.png" % prefix
	img.save_png(out_dir.path_join(oracle_file))
	# put the picture fixture back for anything that follows
	we.environment = saved_env
	sun.visible = true
	floor_mi.visible = true
	return {"kind": "albers_layers", "medium": medium, "canvases": count, "patches": count * 2,
		"tolerance_255": tol, "max_err_255": snappedf(worst, 0.01), "failing_canvases": fails,
		"pass": fails.is_empty() and wrong_pass * 10 < count * 2, "image": oracle_file, "per_canvas": rows,
		"worst": _worst(detail, 6),
		"rule": "a patch passes within %s/255 in sRGB, or within one 10-bit buffer step (1/1023) per glass crossing in linear light" % tol,
		"patches_passed_by_quantisation_bound": quant_used,
		"wrong_physics_patches_passing": wrong_pass,
		"discriminates": wrong_pass * 10 < count * 2,
		"passes_per_shell": passes, "blend_space": "srgb" if srgb_blend else "linear",
		"glass_mul_gain": gal.get_meta("glass_mul_gain", null),
		"clamped_squares": gal.get_meta("glass_clamped_squares", null),
		"clamped_channels": gal.get_meta("glass_clamped", null),
		"expected_from": "light table x read-back face colours (probe_albers_glass_render.gd achieved())"}


func _worst(detail: Array, k: int) -> Array:
	var s: Array = detail.duplicate()
	s.sort_custom(func(x, y): return float(x["err"]) > float(y["err"]))
	var out: Array = []
	for i in mini(k, s.size()):
		var d: Dictionary = s[i]
		d["err"] = snappedf(float(d["err"]), 0.01)
		out.append(d)
	return out


func _sample(img: Image, p: Vector2i, linear_read: bool) -> Color:
	var sum := Vector3.ZERO
	var k: int = 0
	for dy in range(-1, 2):
		for dx in range(-1, 2):
			var q := Vector2i(clampi(p.x + dx, 0, img.get_width() - 1), clampi(p.y + dy, 0, img.get_height() - 1))
			var col: Color = img.get_pixelv(q)
			if linear_read:
				col = Color(Probe.t_srgb(col.r), Probe.t_srgb(col.g), Probe.t_srgb(col.b))
			sum += Vector3(col.r, col.g, col.b)
			k += 1
	sum /= float(k)
	return Color(sum.x, sum.y, sum.z)


## Pass within tol in sRGB, or within one 10-bit step per crossing in linear light (the
## Mobile buffer rounds every multiply; dark channels magnify that step in sRGB).
func _ok(got: Color, expected: Color, tol: float, crossings: int, srgb_blend: bool) -> bool:
	if _err(got, expected) <= tol:
		return true
	var step: float = float(maxi(crossings, 1)) / 1023.0
	for ch in 3:
		var g: float = got[ch] if srgb_blend else Probe.t_lin(got[ch])
		var e: float = expected[ch] if srgb_blend else Probe.t_lin(expected[ch])
		if absf(g - e) > step:
			return false
	return true


func _err(got: Color, expected: Color) -> float:
	var e: float = 0.0
	for ch in 3:
		e = maxf(e, absf(got[ch] - expected[ch]) * 255.0)
	return e


func _bounds(n: Node) -> AABB:
	var box := AABB()
	var have := false
	var stack: Array = [n]
	while not stack.is_empty():
		var cur: Node = stack.pop_back()
		if cur is MeshInstance3D and (cur as MeshInstance3D).mesh != null and (cur as VisualInstance3D).visible:
			var mi: MeshInstance3D = cur
			var b: AABB = mi.global_transform * mi.get_aabb()
			box = b if not have else box.merge(b)
			have = true
		for ch in cur.get_children():
			stack.append(ch)
	return box if have else AABB(Vector3(-1, 0, -1), Vector3(2, 2, 2))


## front: square on, whole artifact in frame. oblique: 35 degrees from the left third.
## eye: a visitor's eye (1.65 m) close in, looking along the work.
func _aim(cam: Camera3D, box: AABB, view: String) -> void:
	cam.projection = Camera3D.PROJECTION_PERSPECTIVE
	cam.near = 0.05
	cam.far = 200.0
	var c: Vector3 = box.get_center()
	var w: float = maxf(box.size.x, 0.5)
	var h: float = maxf(box.size.y, 0.5)
	var front_z: float = box.end.z
	var wide: bool = w > h * 1.3
	if view == "plan":
		# a floor or a field read from above: 60 degrees down, fitted on the footprint
		cam.fov = 45.0
		var foot: float = maxf(w, maxf(box.size.z, 0.5))
		var reach: float = foot / (2.0 * tan(deg_to_rad(cam.fov * 0.5))) * 1.2
		_look(cam, c + Vector3(0.0, sin(deg_to_rad(60.0)), cos(deg_to_rad(60.0))) * reach, c)
		return
	if not wide and view in ["oblique", "eye"]:
		# tall or compact works (a 4.4 m stack is 1.1 m wide): orbit, fitted on the height
		var fov: float = 50.0 if view == "oblique" else 70.0
		cam.fov = fov
		var extent: float = maxf(h, maxf(w, box.size.z))
		var dist: float = extent / (2.0 * tan(deg_to_rad(fov * 0.5))) * (1.15 if view == "oblique" else 0.75)
		var yaw: float = deg_to_rad(35.0 if view == "oblique" else 20.0)
		var eye_y: float = c.y if view == "oblique" else 1.65
		var from := Vector3(c.x - sin(yaw) * dist, eye_y, c.z + cos(yaw) * dist)
		_look(cam, from, c)
		return
	match view:
		"oblique":
			cam.fov = 55.0
			var from := Vector3(box.position.x - w * 0.05, minf(1.65, c.y + h * 0.1), front_z + maxf(2.5, w * 0.32))
			_look(cam, from, Vector3(c.x + w * 0.15, c.y, box.position.z))
		"eye":
			cam.fov = 70.0
			var from := Vector3(c.x - w * 0.2, 1.65, front_z + maxf(1.6, w * 0.22))
			_look(cam, from, Vector3(c.x + w * 0.15, minf(1.65, c.y), box.position.z))
		_:
			cam.fov = 45.0
			var fit: float = maxf(w / (2.0 * tan(deg_to_rad(cam.fov * 0.5)) * 1.6), h / (2.0 * tan(deg_to_rad(cam.fov * 0.5))))
			_look(cam, Vector3(c.x, c.y, front_z + fit * 1.08), c)


func _look(cam: Camera3D, from: Vector3, at: Vector3) -> void:
	cam.global_transform = Transform3D(Basis.IDENTITY, from)
	cam.look_at(at, Vector3.UP)


func _picture_env() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.15, 0.14, 0.18)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("c4add7")
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_exposure = 1.0
	env.fog_enabled = false
	env.glow_enabled = false
	return env


func _oracle_env() -> Environment:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color.BLACK
	env.ambient_light_source = Environment.AMBIENT_SOURCE_DISABLED
	env.reflected_light_source = Environment.REFLECTION_SOURCE_DISABLED
	env.tonemap_mode = Environment.TONE_MAPPER_LINEAR
	env.tonemap_exposure = 1.0
	env.tonemap_white = 1.0
	env.fog_enabled = false
	env.glow_enabled = false
	env.ssao_enabled = false
	env.ssil_enabled = false
	env.ssr_enabled = false
	env.sdfgi_enabled = false
	env.adjustment_enabled = false
	return env


func _drawn(n: int) -> int:
	var f0: int = Engine.get_frames_drawn()
	var guard: int = 0
	while Engine.get_frames_drawn() - f0 < n and guard < 600:
		await process_frame
		guard += 1
	await RenderingServer.frame_post_draw
	return Engine.get_frames_drawn() - f0


func _write_json(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if f == null:
		return
	f.store_string(JSON.stringify(data, " "))
	f.close()
	DirAccess.rename_absolute(path + ".tmp", path)
