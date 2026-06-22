extends SceneTree

## Runtime smoke test for the artifact review station: load the scene, let it build the
## world/camera/UI and mount the first artifact, then assert the queue is populated and an
## artifact is live, and save a screenshot as proof the 3D view + panel actually render.
##
##   godot --path . --xr-mode off --no-window \
##     --script res://commons/testing/check_review_station.gd -- [--maps=softbody] [--index=0]

var _maps: Array[String] = []
var _index: int = 0


func _initialize() -> void:
	for raw in OS.get_cmdline_user_args():
		var arg := String(raw).strip_edges()
		if arg.begins_with("--maps="):
			var v := arg.substr(7)
			_maps = []
			if v.strip_edges() != "":
				for s in v.split(","):
					_maps.append(s.strip_edges())
		elif arg.begins_with("--index="):
			var v := arg.substr(8)
			if v.is_valid_int():
				_index = int(v)
	_run.call_deferred()


func _run() -> void:
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)

	var packed := load("res://commons/scenes/desktop_artifact_review.tscn")
	if packed == null:
		_report("FAIL: could not load scene")
		quit(1)
		return
	var station = packed.instantiate()
	station.only_maps = _maps
	station.start_index = _index
	root.add_child(station)

	# let _ready (build + queue) run, then _show's internal awaits + a render
	for i in range(12):
		await process_frame

	var q: int = station._queue.size() if station._queue != null else 0
	var live: bool = is_instance_valid(station._current_inst)
	var nm := ""
	if q > 0 and station._index < q:
		nm = str(station._queue[station._index].get("name", ""))

	var img := root.get_texture().get_image()
	var shot := ProjectSettings.globalize_path("res://ada_run/review_station_check.png")
	if img:
		DirAccess.make_dir_recursive_absolute(shot.get_base_dir())
		img.save_png(shot)

	# --- walk mode: toggle, let gravity settle, confirm the player stands on the floor ---
	station._toggle_mode()
	for i in range(40):
		await physics_frame
	for i in range(3):
		await process_frame
	var walk_ok: bool = station._mode == "walk" and station._player_cam != null \
		and station._player_cam.current and is_instance_valid(station._player)
	var py: float = station._player.global_position.y if is_instance_valid(station._player) else -99.0
	var grounded: bool = py > -0.3 and py < 0.6   # capsule origin = feet → rests ~0; not fallen through
	var img2 := root.get_texture().get_image()
	var shot2 := ProjectSettings.globalize_path("res://ada_run/review_station_walk.png")
	if img2:
		img2.save_png(shot2)

	var ok: bool = q > 0 and live and walk_ok and grounded
	_report("queue=%d index=%d current='%s' live=%s | WALK mode=%s cam_current=%s player_y=%.2f grounded=%s -> %s" % [
		q, station._index, nm, str(live),
		station._mode, str(station._player_cam.current if station._player_cam else false), py, str(grounded),
		("PASS" if ok else "FAIL")])
	quit(0 if ok else 2)


func _report(s: String) -> void:
	print("CHECK_REVIEW: " + s)
	var abs := ProjectSettings.globalize_path("res://ada_run/review_station_check.txt")
	DirAccess.make_dir_recursive_absolute(abs.get_base_dir())
	var f := FileAccess.open(abs, FileAccess.WRITE)
	if f:
		f.store_string(s + "\n")
		f.close()
