extends SceneTree
## Floor Trans_Body: walk one body (0.6 m wide, 1.7 m tall) straight from the south through the slat wall, the
## shrinking blocks and the lattice, and read what the floor's own LOOK BACK panel says afterwards. For a writer:
## the exact words, the number of cells one straight passage cuts, and a picture of the cut from the far side.
##
##   python tools/run_floor_probe.py Trans_Body body_floor_walk.gd body_walk.json <folder> --no-opening --opera-quiet

var folder := "res://ada_run/body_floor_walk"
var eye: Camera3D
var content: Node3D
var floor_y := 0.0


func _initialize() -> void:
	run.call_deferred()


func _picture(file: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(file))


func _at(x: float, h: float, z: float) -> Vector3:
	var p := content.to_global(Vector3(x, 0, z))
	return Vector3(p.x, floor_y + h, p.z)


func _panels(readouts: Node) -> Dictionary:
	var out := {}
	for label in readouts.find_children("*", "Label3D", true, false):
		out[str(label.get_parent().name)] = (label as Label3D).text
	return out


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	var game: Node = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var index := int(game.checkpoint)
	var result := {"floor": index, "checks": [], "passed": false, "walk": []}
	for i in 900: await physics_frame
	eye = root.get_camera_3d()
	var arrival := eye.global_position
	content = game.building.content.roots[index] as Node3D
	var ground := eye.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(arrival, arrival + Vector3.DOWN * 4.0, 1))
	floor_y = float(ground.position.y) if not ground.is_empty() else arrival.y - 1.6
	game.body.set_physics_process(false)
	game.body.set_process(false)
	# park the visitor's own body out of the works' reach: only the walker below is the passage
	game.body.global_position = _at(18.0, 0.1, 7.5)
	var readouts := (game.building.content.exhibits.get("%d/body-boundary-readouts" % index) as Node3D)
	result["before"] = _panels(readouts)
	var walker := CharacterBody3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.3
	capsule.height = 1.7
	var shape := CollisionShape3D.new()
	shape.shape = capsule
	walker.add_child(shape)
	walker.collision_layer = 1
	walker.collision_mask = 1
	walker.motion_mode = CharacterBody3D.MOTION_MODE_FLOATING
	walker.add_to_group("em_walker")      # the three works answer visitors only (approach_wall._is_visitor)
	root.add_child(walker)
	walker.global_position = _at(0.0, 0.9, 7.6)
	var stops := [["before the slats", 5.6], ["in the slats", 4.2], ["between slats and blocks", 2.2], ["among the blocks", 0.0], ["between blocks and lattice", -2.4], ["in the lattice", -4.7], ["beyond the lattice", -7.4]]
	for stop: Array in stops:
		var to := _at(0.0, 0.9, float(stop[1]))
		var arrived := false
		for i in int(60.0 * 14.0):
			var left := to - walker.global_position
			left.y = 0.0
			if left.length() < 0.1:
				arrived = true
				break
			walker.velocity = left.normalized() * 1.1
			walker.move_and_slide()
			await physics_frame
		for i in 20: await physics_frame
		var here := content.to_local(walker.global_position)
		# the eye rides just behind and above the walker's shoulder, looking where it goes
		eye.global_position = _at(here.x + 0.45, 1.75, here.z + 1.5)
		eye.look_at(_at(here.x, 1.2, here.z - 2.5), Vector3.UP)
		await _picture("%d_%s.png" % [(result.walk as Array).size() + 1, str(stop[0]).replace(" ", "_")])
		(result.walk as Array).append({"stop": stop[0], "arrived": arrived, "z": snappedf(here.z, 0.01), "panels": _panels(readouts)})
	# stand well clear, let everything settle, look back
	for i in 240: await physics_frame
	result["after"] = _panels(readouts)
	eye.global_position = _at(0.0, 1.65, -8.3)
	eye.look_at(_at(0.0, 1.0, -4.7), Vector3.UP)
	await _picture("8_looking_back_at_the_cut.png")
	eye.global_position = _at(2.2, 1.6, -8.4)
	eye.look_at(_at(3.37, 1.1, -6.95), Vector3.UP)
	await _picture("9_the_look_back_panel.png")
	eye.global_position = _at(0.0, 1.65, 7.6)
	eye.look_at(_at(0.0, 1.3, 4.2), Vector3.UP)
	await _picture("10_the_slats_from_the_south_again.png")
	var passed_all := (result.walk as Array).all(func(s): return s.arrived)
	(result.checks as Array).append({"check": "one body walks straight through slats, blocks and lattice", "ok": passed_all})
	(result.checks as Array).append({"check": "afterwards the slats are shut, the blocks full size, and the lattice keeps the cut", "ok": str(result.after.get("LookbackReadout", "")).contains("SHUT") and str(result.after.get("LookbackReadout", "")).contains("FULL SIZE") and not str(result.after.get("LookbackReadout", "")).contains(" 0 CELLS"), "panel": result.after.get("LookbackReadout", "")})
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("body_walk.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()
