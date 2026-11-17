extends SceneTree
## Exercise real floor streaming -> gaze -> dwell -> shipped voice -> HUD.
## --xr uses the real XR rig without claiming physical-headset acceptance.
var game: Node3D
var folder := ""
var checks := []

func _initialize() -> void: run.call_deferred()

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	assert(not folder.is_empty())
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	game.force_xr = "--xr" in OS.get_cmdline_user_args()
	root.add_child(game)
	current_scene = game
	if not game.vr: game.body.scripted_input = true
	game.scene_loaded()
	game.scene_visible()
	for trial in [
		{"floor":1, "row":"future", "target":"Artifact/VisiblePoint", "id":"chapter_01_point_pedestal"},
		{"floor":1, "row":"solid", "target":"Artifact/VisiblePoint", "id":"chapter_01_point_solid"},
		{"floor":1, "row":"solid", "target":"Artifact/VisiblePoint", "id":"chapter_01_point_solid", "aim_offset":0.25},
		{"floor":2, "row":"held", "target":"Artifact/HeldPoint", "id":"chapter_02_point_held"},
		{"floor":14, "row":"transform-scaffold-banks", "target":"Artifact/source_sc", "id":"chapter_14_sc"}]:
		game.place_player_at_spawn(trial.floor)
		var deadline := Time.get_ticks_msec() + 45000
		while Time.get_ticks_msec() < deadline:
			await process_frame
			if game.building.content.roots.has(trial.floor) and not game.building.content.pending.any(func(job): return int(job.index) == trial.floor): break
		for tick in 30: await physics_frame
		var opera: Node = game.get_meta("inner_opera", null)
		assert(opera != null)
		opera.voice.stop()
		opera.attention.reset()
		var mount: Node3D = game.building.content.exhibits["%d/%s" % [trial.floor, trial.row]]
		var target: Node3D = mount.get_node(trial.target)
		var centre: Vector3 = target.global_position
		if target is MeshInstance3D: centre = target.global_transform * target.get_aabb().get_center()
		if trial.floor == 14: centre.y = float(game.building.spec.levels[trial.floor]) + 1.5
		game.body.set_physics_process(false)
		var eye := Vector3(centre.x, float(game.building.spec.levels[trial.floor]) + 1.65, centre.z - 3)
		game.body.global_position = eye - Vector3.UP * 1.65
		game.camera.global_position = eye
		game.camera.look_at(centre)
		game.camera.make_current()
		var heard_before: int = opera.heard.size()
		deadline = Time.get_ticks_msec() + 9000
		while Time.get_ticks_msec() < deadline:
			if trial.has("aim_offset"):
				game.camera.look_at(centre + Vector3(float(trial.aim_offset) + sin(Time.get_ticks_msec() * 0.007) * 0.01, 0, 0))
			await physics_frame
			if opera.heard.size() > heard_before: break
		var new_heard: Array = opera.heard.slice(heard_before)
		var success: bool = new_heard.any(func(entry): return entry.object == trial.id and entry.sung and entry.on_display)
		if trial.has("aim_offset"): success = success and opera._gaze_ray(game.camera, -game.camera.global_basis.z).is_empty()
		checks.append({"floor":trial.floor, "expected":trial.id, "aim_offset":trial.get("aim_offset", 0), "pass":success, "heard":new_heard,
			"looking_at":opera._looked_at(), "camera":str(game.camera.global_position), "active_camera":str(game.get_viewport().get_camera_3d().get_path()),
			"listening":opera.listening, "quiet":opera.quiet, "ready":opera.voice.streams.has(trial.id), "speaking":opera.attention.is_speaking()})
		print("OPERA_CHAPTER ", JSON.stringify(checks.back()))
		FileAccess.open(folder.path_join("chapter-play-%s.json" % ("xr" if game.vr else "desktop")), FileAccess.WRITE).store_string(JSON.stringify(checks, "  "))
	game.queue_free()
	await create_timer(0.2).timeout
	quit(0 if checks.all(func(check): return check.pass) else 1)
