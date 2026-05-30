extends SceneTree
## Headless simulation runner for the path-and-block game.
##
## Loads a map, injects a SYNTHETIC player (group "player") so the
## builder-foe has a target and the watchdog has a start, runs the sim
## for real time with a fast build cycle, and captures a top-down
## sequence (step_0..step_N) showing the wall grow + the ribbon reroute /
## redden. Logs foe block-count + watchdog state each step.
##
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/path_game_sim.gd -- \
##     --map=Primitives_Polythedra --seconds=14 --shots=6 \
##     --build-interval=0.8 --player=0,0 [--befriend-at=10]
##
## Scenarios = vary --player (where the player stands), --build-interval
## (foe speed), --befriend-at (when the catalyst flips it).

const MAP_CATALOG_SCENE := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"

var _map: String = ""
var _seconds: float = 14.0
var _shots: int = 6
var _build_interval: float = 0.8
var _player_x: float = 0.0
var _player_z: float = 0.0
var _player_y: float = 1.0
var _befriend_at: float = -1.0
var _out_dir: String = "user://path_sim"
var _tag: String = ""


func _init() -> void:
	_parse_args()
	if _map == "":
		push_error("path_game_sim: --map=<Name> required")
		quit(1)
		return
	_run.call_deferred()


func _parse_args() -> void:
	for arg in OS.get_cmdline_user_args():
		var kv := arg.split("=")
		var key := kv[0].trim_prefix("--")
		var val := kv[1] if kv.size() > 1 else ""
		match key:
			"map": _map = val
			"seconds": _seconds = float(val)
			"shots": _shots = max(1, int(val))
			"build-interval": _build_interval = float(val)
			"befriend-at": _befriend_at = float(val)
			"out": _out_dir = val
			"tag": _tag = val
			"player":
				var p := val.split(",")
				if p.size() >= 2:
					_player_x = float(p[0]); _player_z = float(p[1])
				if p.size() >= 3:
					_player_y = float(p[2])


func _run() -> void:
	print("path_game_sim: loading map '%s'" % _map)
	if change_scene_to_file(MAP_CATALOG_SCENE) != OK:
		push_error("path_game_sim: failed to load catalog"); quit(1); return
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	if catalog == null:
		push_error("path_game_sim: no catalog scene"); quit(1); return
	_hide_overlays(catalog)

	if not bool(catalog.call("load_map_fresh", _map)):
		push_error("path_game_sim: failed to load map '%s'" % _map); quit(1); return
	await _wait_for_ready(catalog, 30.0)
	await create_timer(2.0).timeout

	# Inject the synthetic player.
	var player := Node3D.new()
	player.name = "SimPlayer"
	player.add_to_group("player")
	current_scene.add_child(player)
	player.global_position = Vector3(_player_x, _player_y, _player_z)
	print("path_game_sim: synthetic player at %s" % player.global_position)

	# Find foes + watchdog; speed the foes up for a visible sim.
	var foes: Array = get_nodes_in_group("enemy")
	for f in foes:
		if "build_interval" in f: f.set("build_interval", _build_interval)
		if "max_blocks" in f: f.set("max_blocks", 40)
	var watchdog = get_first_node_in_group("path_watchdog")
	# Observe blocked/countdown without the sim reloading itself.
	if watchdog: watchdog.set("restart_on_timeout", false)
	print("path_game_sim: %d foe(s), watchdog=%s" % [foes.size(), "yes" if watchdog else "no"])

	# Camera top-down once.
	var camera: Camera3D = catalog.get("_preview_camera") if "_preview_camera" in catalog else null
	var center: Vector3 = catalog.get("_orbit_center") if "_orbit_center" in catalog else Vector3.ZERO
	var dims := _grid_dims(catalog)
	if camera:
		var span: float = max(float(dims.x), float(dims.z)) if dims != Vector3i.ZERO else 12.0
		var h: float = (span * 0.5) / max(0.1, tan(deg_to_rad(camera.fov) * 0.5)) * 1.15 + 3.0
		camera.global_position = Vector3(center.x, center.y + h, center.z)
		camera.look_at(center, Vector3.FORWARD)

	# The player walks from its start toward the teleporter over the sim,
	# so the foe chases and trails a wall across the route.
	var walk_from := player.global_position
	var walk_to := walk_from
	var tp := _find_class_node(current_scene, "Teleport")
	if tp:
		walk_to = Vector3(tp.global_position.x, walk_from.y, tp.global_position.z)
	print("path_game_sim: player walks %s -> %s" % [walk_from, walk_to])

	# Run the sim in micro-steps (move the player smoothly); capture at
	# each shot boundary.
	var dt: float = _seconds / float(_shots)
	var sub: int = 8
	var micro: float = dt / float(sub)
	var did_befriend := false
	for i in range(_shots):
		for s in range(sub):
			await create_timer(micro).timeout
			var frac: float = float(i * sub + s + 1) / float(_shots * sub)
			# Ease the walk so the player lingers near the start a moment.
			player.global_position = walk_from.lerp(walk_to, clampf(frac, 0.0, 1.0))
		await process_frame
		var elapsed: float = dt * float(i + 1)
		if _befriend_at >= 0.0 and not did_befriend and elapsed >= _befriend_at:
			did_befriend = true
			for f in foes:
				if f.has_method("set_personality"): f.set_personality("friend")
				if f.has_signal("personality_changed"): f.personality_changed.emit("curious", "friend")
			print("path_game_sim: [t=%.1f] BEFRIENDED all foes" % elapsed)
		# Log state.
		var blocks := 0
		for f in foes:
			var placed = f.get("_placed") if "_placed" in f else null
			if placed is Array: blocks += placed.size()
		var blocked := bool(watchdog.get("_blocked")) if watchdog else false
		var countdown := float(watchdog.get("_countdown")) if watchdog else 0.0
		print("path_game_sim: [t=%5.1f] blocks=%d  path=%s  countdown=%.1f" % [
			elapsed, blocks, ("BLOCKED" if blocked else "open"), countdown])
		_save_shot("step_%d" % i)
	print("path_game_sim: done — %d shots" % _shots)
	quit(0)


# ── helpers (trimmed from capture_multi_angle) ────────────────────────

func _save_shot(name: String) -> void:
	var image: Image = root.get_texture().get_image()
	if image == null: return
	var sub := _map + ("_" + _tag if _tag != "" else "")
	var folder := ProjectSettings.globalize_path(_out_dir.path_join(sub))
	if not DirAccess.dir_exists_absolute(folder):
		DirAccess.make_dir_recursive_absolute(folder)
	image.save_png(folder.path_join(name + ".png"))


func _find_class_node(node: Node, klass: String) -> Node3D:
	if node == null:
		return null
	if node is Node3D:
		var scr = node.get_script()
		if scr != null and scr.get_global_name() == klass:
			return node
	for c in node.get_children():
		var r := _find_class_node(c, klass)
		if r != null:
			return r
	return null


func _grid_dims(catalog: Node) -> Vector3i:
	var grid = catalog.get("_grid_system") if "_grid_system" in catalog else null
	if grid == null: return Vector3i.ZERO
	var dc = grid.get("data_component") if "data_component" in grid else null
	if dc and dc.has_method("get_grid_dimensions"):
		var d = dc.call("get_grid_dimensions")
		if d is Vector3i: return d
	return Vector3i.ZERO


func _hide_overlays(catalog: Node) -> void:
	for n in ["DesktopMapSwitcherOverlay", "MapDataEditorOverlay", "MapLayerEditorOverlay",
			"ProjectDashboardOverlay", "StatusLabel", "MapBrowser3D"]:
		var node = catalog.get_node_or_null(n)
		if node is CanvasLayer: node.visible = false
		elif node is Node3D: node.visible = false
		elif node is CanvasItem: node.visible = false


func _wait_for_ready(catalog: Node, timeout: float) -> bool:
	var grid = catalog.get("_grid_system") if "_grid_system" in catalog else null
	if grid == null:
		await create_timer(min(timeout, 2.0)).timeout
		return false
	var elapsed := 0.0
	while elapsed < timeout:
		if grid.has_method("is_map_ready") and bool(grid.call("is_map_ready")):
			return true
		await create_timer(0.1).timeout
		elapsed += 0.1
	return false
