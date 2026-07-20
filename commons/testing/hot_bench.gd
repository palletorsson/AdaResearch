## hot_bench.gd — a persistent, hot-reloading single-artifact viewer.
##
## The bench (tools/cabinet_bench.py) still costs one Godot BOOT per pass. This
## costs zero: one window stays open and re-renders an artifact the instant its
## .gd changes on disk — no reboot. It also saves a fresh PNG each reload so an
## agent can read the result without a headless capture.
##
## Two audiences, one window:
##   • a person watches it live and tweaks the .gd; it reloads on save.
##   • tools/hot_reload.py pokes it (switch artifact / force reshoot) and waits
##     for the fresh PNG at res://ada_run/hot_current.png.
##
## Launch:
##   Godot --path . --xr-mode off res://commons/testing/HotBench.tscn -- --artifact=galton_board
##
## Reload is triggered by EITHER a change to the watched .gd's mtime OR a bumped
## reload_ts in res://ada_run/hot_reload.json {artifact, reload_ts}.

extends Node3D

const CONTROL := "res://ada_run/hot_reload.json"
const DONE := "res://ada_run/hot_reload_done.json"
const ALIVE := "res://ada_run/hot_reload_alive.txt"
const SHOT := "res://ada_run/hot_current.png"
const CANON := "res://commons/data/cabinet_grammar.json"
const REGISTRY_DIR := "res://commons/artifacts/registry/"

const POLL := 0.3
const FOV := 34.0
const YAW := 0.62
const PITCH := -0.26
const PAD := 1.9

var _cam: Camera3D
var _inst: Node = null
var _artifact := ""
var _scene_path := ""
var _gd_path := ""
var _gd_mtime := 0
var _last_reload_ts := 0.0
var _poll_accum := 0.0
var _members: Array = []


func _ready() -> void:
	_members = _load_json(CANON).get("members", [])
	_build_stage()
	var initial := "galton_board"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--artifact="):
			initial = a.substr(11)
	# ignore any stale control message from a previous session
	var ctl := _load_json(CONTROL)
	if ctl.has("reload_ts"):
		_last_reload_ts = float(ctl["reload_ts"])
	_load_artifact(initial)


func _build_stage() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.055, 0.055, 0.070)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.62, 0.65, 0.72)
	env.ambient_light_energy = 0.55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)

	var key := DirectionalLight3D.new()
	key.light_energy = 1.25
	key.rotation_degrees = Vector3(-42, -35, 0)
	key.shadow_enabled = true
	add_child(key)
	var fill := DirectionalLight3D.new()
	fill.light_energy = 0.45
	fill.rotation_degrees = Vector3(-20, 130, 0)
	add_child(fill)

	_cam = Camera3D.new()
	_cam.fov = FOV
	_cam.current = true
	add_child(_cam)


func _process(delta: float) -> void:
	_poll_accum += delta
	if _poll_accum < POLL:
		return
	_poll_accum = 0.0

	# heartbeat so the companion knows the window is alive
	var hb := FileAccess.open(ALIVE, FileAccess.WRITE)
	if hb:
		hb.store_string("%d" % Time.get_ticks_msec())
		hb.close()

	# control file: switch artifact or forced reshoot
	var ctl := _load_json(CONTROL)
	if ctl.has("reload_ts") and float(ctl["reload_ts"]) > _last_reload_ts:
		_last_reload_ts = float(ctl["reload_ts"])
		var want := str(ctl.get("artifact", _artifact))
		_load_artifact(want)
		return

	# source watch: reload the SAME artifact when its .gd is saved
	if _gd_path != "" and FileAccess.file_exists(_gd_path):
		var mt := FileAccess.get_modified_time(_gd_path)
		if mt != _gd_mtime and _gd_mtime != 0:
			_gd_mtime = mt
			_reload_current()
		elif _gd_mtime == 0:
			_gd_mtime = mt


## Resolve an artifact's scene path (canon member first, then a registry scan),
## then load and frame it.
func _load_artifact(name: String) -> void:
	var scene := _resolve_scene(name)
	if scene == "":
		_write_done(name, false, "not found in canon or registries")
		return
	_artifact = name
	_scene_path = scene
	_gd_path = scene.trim_suffix(".tscn") + ".gd"
	if not FileAccess.file_exists(_gd_path):
		# scene name and script name can differ in case — scan the folder
		_gd_path = _sibling_gd(scene)
	_gd_mtime = FileAccess.get_modified_time(_gd_path) if _gd_path != "" and FileAccess.file_exists(_gd_path) else 0
	_reload_current()


## Free the instance, force-recompile its script from disk, re-instantiate,
## frame it, and save a fresh shot.
func _reload_current() -> void:
	if _inst != null and is_instance_valid(_inst):
		_inst.queue_free()
		_inst = null
		await get_tree().process_frame

	# Force the cached GDScript to recompile from the current file, so a scene
	# that references it instantiates the NEW code (the running game does not
	# auto-reload scripts the way the editor does).
	if _gd_path != "" and FileAccess.file_exists(_gd_path):
		var gd = load(_gd_path)
		if gd is GDScript:
			gd.source_code = FileAccess.get_file_as_string(_gd_path)
			var err: int = gd.reload(true)
			if err != OK:
				_write_done(_artifact, false, "compile error (%d) — see console" % err)
				return

	var packed = ResourceLoader.load(_scene_path, "PackedScene", ResourceLoader.CACHE_MODE_REPLACE_DEEP)
	if packed == null:
		_write_done(_artifact, false, "scene load failed")
		return
	_inst = (packed as PackedScene).instantiate()
	add_child(_inst)

	# procedural _ready + physics settle
	await get_tree().create_timer(1.1).timeout
	_frame()
	# let the framed view render, then grab the window
	await RenderingServer.frame_post_draw
	await get_tree().process_frame
	var img := get_viewport().get_texture().get_image()
	img.save_png(SHOT)
	_write_done(_artifact, true, "ok")


func _frame() -> void:
	if not _cam or _inst == null:
		return
	var aabb := _subtree_aabb(_inst)
	var c := aabb.get_center()
	var radius: float = maxf(aabb.size.length() * 0.5, 0.2)
	var dist: float = radius / tan(deg_to_rad(FOV * 0.5)) * PAD
	var dir := Vector3(sin(YAW) * cos(PITCH), -sin(PITCH), cos(YAW) * cos(PITCH))
	_cam.global_position = c + dir * dist
	_cam.look_at(c, Vector3.UP)


func _resolve_scene(name: String) -> String:
	for m in _members:
		if str(m.get("artifact", "")) == name:
			return str(m.get("scene", ""))
	# registry scan: name -> scene_path
	var dir := DirAccess.open(REGISTRY_DIR)
	if dir:
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if f.ends_with(".json"):
				var data := _load_json(REGISTRY_DIR + f)
				var arts: Dictionary = data.get("artifacts", {})
				if arts.has(name):
					var sp := str(arts[name].get("scene_path", arts[name].get("scene", "")))
					if sp != "":
						dir.list_dir_end()
						return sp
			f = dir.get_next()
		dir.list_dir_end()
	return ""


func _sibling_gd(scene_path: String) -> String:
	var folder := scene_path.get_base_dir()
	var dir := DirAccess.open(folder)
	if dir:
		dir.list_dir_begin()
		var f := dir.get_next()
		while f != "":
			if f.ends_with(".gd"):
				dir.list_dir_end()
				return folder + "/" + f
			f = dir.get_next()
		dir.list_dir_end()
	return ""


func _subtree_aabb(root_node: Node) -> AABB:
	var acc := AABB()
	var have := false
	var stack: Array = [root_node]
	while not stack.is_empty():
		var n = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			var wab: AABB = mi.global_transform * mi.get_aabb()
			acc = wab if not have else acc.merge(wab)
			have = true
		for ch in n.get_children():
			stack.append(ch)
	return acc if have else AABB(Vector3(-0.5, 0, -0.5), Vector3.ONE)


func _write_done(name: String, ok: bool, msg: String) -> void:
	var f := FileAccess.open(DONE, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({
			"artifact": name, "ok": ok, "msg": msg,
			"ts": Time.get_ticks_msec(), "shot": SHOT,
		}))
		f.close()
	print("hot_bench: %s — %s" % [name, msg])


func _load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var f := FileAccess.open(path, FileAccess.READ)
	var parsed: Variant = JSON.parse_string(f.get_as_text())
	f.close()
	return parsed if parsed is Dictionary else {}
