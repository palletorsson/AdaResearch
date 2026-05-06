extends SceneTree

## Long-running capture daemon.
##
## Boots once: instantiates DesktopMapTester + CaptureRig, pays the
## ~15s autoload tax, then loops watching `commons/primitive_grammar/_queue/`
## for config files. For each config:
##   1. Load the map (skipped if already loaded — big savings for batches)
##   2. Run all shots (smart-frame, hide HUD, freeze _process, snapshot)
##   3. Write `<id>.done` next to the config so the API knows it's ready
##
## API uses this when a PID file is present. Otherwise it falls back to
## the per-call spawn (capture_in_player_pos.gd).
##
## Stop: write `_stop` file in the queue dir, daemon quits cleanly.
##
## Lifecycle:
##   - PID file: ada_run/capture_daemon.pid
##   - Queue dir: commons/primitive_grammar/_queue/
##   - Each job: <id>.json (config) → <id>.done (when finished)

const QUEUE_DIR := "res://commons/primitive_grammar/_queue/"
const PID_FILE := "res://ada_run/capture_daemon.pid"
const STOP_FILE := "_stop"

var _tester: Node = null
var _rig: Node3D = null
var _current_map: String = ""
var _player: Node3D = null
var _processed: Dictionary = {}  # filename → true
var _shutdown := false


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# Boot scene infra once.
	var tester_scene := load("res://commons/scenes/desktop_map_tester.tscn") as PackedScene
	if tester_scene == null:
		push_error("desktop_map_tester.tscn missing"); quit(1); return
	_tester = tester_scene.instantiate()
	_tester.set("auto_load_on_ready", false)
	get_root().add_child(_tester)
	await create_timer(0.2).timeout

	# Disable player polling/visibility (we use our rig).
	_player = _tester.get_node_or_null("DesktopPlayer") as Node3D
	if _player:
		_player.global_position = Vector3(0, -1000, 0)
		_player.visible = false
		_player.set_process(false)
		_player.set_physics_process(false)
		_player.set_process_input(false)
		_player.set_process_unhandled_input(false)

	# Spawn capture rig.
	var rig_scene := load("res://commons/testing/capture_rig.tscn") as PackedScene
	_rig = rig_scene.instantiate() as Node3D
	get_root().add_child(_rig)
	if _rig.has_method("set_clean_render"):
		_rig.set_clean_render()

	# Make sure the queue dir exists.
	var abs_queue := ProjectSettings.globalize_path(QUEUE_DIR)
	DirAccess.make_dir_recursive_absolute(abs_queue)

	# Write PID file so the API knows we're alive.
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ada_run/"))
	var pf := FileAccess.open(PID_FILE, FileAccess.WRITE)
	if pf:
		pf.store_string(str(OS.get_process_id()))
		pf.close()
	print("capture_daemon: ready (pid=%d) watching %s" % [OS.get_process_id(), abs_queue])

	# Main loop.
	while not _shutdown:
		await create_timer(0.5).timeout
		_poll_queue()

	# Clean shutdown.
	if FileAccess.file_exists(PID_FILE):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(PID_FILE))
	print("capture_daemon: shutting down")
	quit(0)


func _poll_queue() -> void:
	var d := DirAccess.open(QUEUE_DIR)
	if d == null: return
	d.list_dir_begin()
	var f := d.get_next()
	while f != "":
		if f == STOP_FILE:
			_shutdown = true
			DirAccess.remove_absolute(ProjectSettings.globalize_path(QUEUE_DIR + STOP_FILE))
			break
		if f.ends_with(".json") and not _processed.has(f):
			# Skip if we've already produced its .done marker.
			var done_name := f.replace(".json", ".done")
			if FileAccess.file_exists(QUEUE_DIR + done_name):
				_processed[f] = true
			else:
				_processed[f] = true
				await _process_job(f)
		f = d.get_next()


func _process_job(fname: String) -> void:
	var cfg_path := QUEUE_DIR + fname
	var done_path := QUEUE_DIR + fname.replace(".json", ".done")
	print("capture_daemon: processing %s" % fname)
	var cfg = _read_json(cfg_path)
	if not (cfg is Dictionary):
		_write_done(done_path, {"error": "bad config"})
		return

	var map_name: String = String(cfg.get("map", "Study_Room"))
	var wait_total: float = float(cfg.get("wait", 4.0))
	var auto_frame: bool = bool(cfg.get("auto_frame", false))
	var anchor: Array = cfg.get("anchor", [8, 8])

	# Switch map only if needed.
	var t0 := Time.get_ticks_msec()
	if map_name != _current_map:
		print("capture_daemon: loading map %s (was %s)" % [map_name, _current_map])
		if _tester.has_method("load_map"):
			_tester.load_map(map_name)
		_current_map = map_name
		# Wait for grid build.
		var t := 0.0
		while t < wait_total:
			await create_timer(0.05).timeout
			t += 0.05
	else:
		print("capture_daemon: reusing loaded map %s" % map_name)
		await create_timer(0.4).timeout

	# AABB.
	var artifact_aabb := AABB()
	var have_aabb := false
	if auto_frame and anchor.size() >= 2:
		artifact_aabb = _aabb_at_cell(int(anchor[0]), int(anchor[1]), 1.6)
		have_aabb = artifact_aabb.size.length_squared() > 0.0001

	# Each shot.
	var results: Array = []
	for sh in cfg.get("shots", []):
		var sh_cam = sh.get("camera", {})
		var sh_fov: float = float(sh_cam.get("fov", 60.0))
		var sh_out: String = String(sh.get("out", "user://capture_daemon_out.png"))
		var sh_pos: Vector3
		var sh_look: Vector3
		if have_aabb and sh_cam.has("direction"):
			var dir := _to_vec3(sh_cam.get("direction", [4, 2, 4]))
			if dir.length_squared() < 0.0001: dir = Vector3(0, 4, 4)
			dir = dir.normalized()
			var padding: float = float(sh_cam.get("padding", 1.15))
			var min_dist: float = float(sh_cam.get("min_distance", 1.5))
			var fov_rad: float = deg_to_rad(sh_fov) * 0.5
			var max_half: float = max(artifact_aabb.size.x,
				max(artifact_aabb.size.y, artifact_aabb.size.z)) * 0.5
			var distance: float = max(min_dist, max_half / max(0.05, tan(fov_rad)) * padding)
			var center: Vector3 = artifact_aabb.get_center()
			sh_pos = center + dir * distance
			sh_look = center
		else:
			sh_pos = _to_vec3(sh_cam.get("position", [8, 1.7, 8]))
			sh_look = _to_vec3(sh_cam.get("look_at", [8, 1.0, 8]))

		if _rig.has_method("aim"):
			_rig.aim(sh_pos, sh_look, sh_fov)
		if _rig.has_method("activate"):
			_rig.activate()

		await create_timer(0.3).timeout

		var prev_scale := Engine.time_scale
		Engine.time_scale = 0.0
		_hide_all_canvas_pollution(get_root())
		_disable_grid_wireframes(get_root())
		await process_frame
		await process_frame

		var img := get_root().get_texture().get_image()
		Engine.time_scale = prev_scale
		if img == null:
			results.append({"shot": sh.get("name","?"), "error": "no image"})
			continue
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(sh_out.get_base_dir()))
		img.save_png(sh_out)
		results.append({"shot": sh.get("name","?"), "out": sh_out})

	var dt := Time.get_ticks_msec() - t0
	_write_done(done_path, {"ok": true, "took_ms": dt, "shots": results})
	print("capture_daemon: done %s in %dms" % [fname, dt])


func _read_json(path: String) -> Variant:
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null: return null
	var j := JSON.new()
	if j.parse(f.get_as_text()) != OK: return null
	return j.data


func _write_done(path: String, data: Dictionary) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data, "  "))
		f.close()


func _to_vec3(a) -> Vector3:
	if a is Array and a.size() >= 3:
		return Vector3(float(a[0]), float(a[1]), float(a[2]))
	return Vector3.ZERO


# -- shared helpers (mirror capture_in_player_pos.gd) ---------------

func _hide_all_canvas_pollution(root: Node) -> void:
	var stack: Array = [root]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n == null: continue
		for c in n.get_children():
			stack.push_back(c)
		if n is CanvasLayer:
			(n as CanvasLayer).visible = false
		elif n is Control:
			(n as Control).visible = false


func _disable_grid_wireframes(root: Node) -> void:
	var stack: Array = [root]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n == null: continue
		for c in n.get_children():
			stack.push_back(c)
		if not (n is MultiMeshInstance3D): continue
		var mmi := n as MultiMeshInstance3D
		var mats: Array = []
		if mmi.material_override: mats.append(mmi.material_override)
		if mmi.multimesh and mmi.multimesh.mesh:
			var msh = mmi.multimesh.mesh
			for i in range(msh.get_surface_count()):
				var sm = msh.surface_get_material(i)
				if sm: mats.append(sm)
		for mat in mats:
			if mat is ShaderMaterial:
				var sm := mat as ShaderMaterial
				sm.set_shader_parameter("wireframeColor", Color(0,0,0,0))
				sm.set_shader_parameter("width", 0.0)
				sm.set_shader_parameter("emission_strength", 0.0)


func _aabb_at_cell(cellX: int, cellZ: int, radius: float = 1.6,
				   max_footprint: float = 8.0) -> AABB:
	var center2d := Vector2(float(cellX), float(cellZ))
	var combined := AABB()
	var has_any := false
	var stack: Array = [get_root()]
	while stack.size() > 0:
		var n = stack.pop_back()
		if n == null: continue
		for c in n.get_children():
			stack.push_back(c)
		if not (n is VisualInstance3D): continue
		var vi := n as VisualInstance3D
		var local := vi.get_aabb()
		if local.size.length_squared() < 0.0001: continue
		var world: AABB = vi.global_transform * local
		var footprint: float = Vector2(world.size.x, world.size.z).length()
		if footprint > max_footprint: continue
		var wc: Vector3 = world.get_center()
		var c2 := Vector2(wc.x, wc.z)
		if c2.distance_to(center2d) > radius: continue
		if not has_any:
			combined = world
			has_any = true
		else:
			combined = combined.merge(world)
	if not has_any: return AABB()
	return combined
