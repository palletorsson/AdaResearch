extends SceneTree
## Stand the visitor's eye before chosen works of one floor and save what it sees: the floor as it stands today,
## for a writer who has to check a sentence against it (Voice decision, 11 October: "always check text against the
## existing maps").
##
##   python tools/run_floor_probe.py <Map> look_at_rows.gd look.json <folder> --no-opening --opera-quiet \
##       --rows=<row id>[:<metres back>],...   --views=<name>:x,h,z>x,h,z;...
##
## --rows   each row is photographed from the side its floor's arrival is on, at eye height, looking at its middle
## --views  free standpoints in the floor's own metres (x east, z south, h above the floor): eye > looked-at point
## Always saves 0_arrival.png (from where the visitor lands). look.json lists each row's token, size and place.

var folder := "res://ada_run/look"
var game: Node
var eye: Camera3D
var content: Node3D
var floor_y := 0.0


func _initialize() -> void:
	run.call_deferred()


func _picture(file: String) -> void:
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(file))


func _at(x: float, h: float, z: float) -> Vector3:
	var p := content.to_global(Vector3(x, 0, z))
	return Vector3(p.x, floor_y + h, p.z)


func _box(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for part in node.find_children("*", "VisualInstance3D", true, false):
		var v := part as VisualInstance3D
		if v is Light3D or v is Decal or not v.is_visible_in_tree(): continue
		if v is Label3D: continue
		var b: AABB = v.global_transform * v.get_aabb()
		if b.size.length() < 0.001 or b.size.length() > 80.0: continue
		box = b if first else box.merge(b)
		first = false
	return box


func run() -> void:
	var rows: PackedStringArray = []
	var views: PackedStringArray = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--rows="): rows = arg.trim_prefix("--rows=").split(",", false)
		if arg.begins_with("--views="): views = arg.trim_prefix("--views=").split(";", false)
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var index := int(game.checkpoint)
	var result := {"floor": index, "checks": [], "passed": false, "rows": {}}
	for i in 900: await physics_frame
	eye = root.get_camera_3d()
	var arrival := eye.global_position
	content = game.building.content.roots[index] as Node3D
	var ground := eye.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(arrival, arrival + Vector3.DOWN * 4.0, 1))
	floor_y = float(ground.position.y) if not ground.is_empty() else arrival.y - 1.6
	result["arrival"] = [snappedf(content.to_local(arrival).x, 0.01), snappedf(arrival.y - floor_y, 0.01), snappedf(content.to_local(arrival).z, 0.01)]
	await _picture("0_arrival.png")
	game.body.set_physics_process(false)
	game.body.set_process(false)
	var here := content.to_local(arrival)
	for spec in rows:
		var id := spec.get_slice(":", 0)
		var back := float(spec.get_slice(":", 1)) if spec.contains(":") else 0.0
		var mount := (game.building.content.exhibits.get("%d/%s" % [index, id]) if game.building.content.exhibits.has("%d/%s" % [index, id]) else game.building.content.props.get("%d/%s" % [index, id])) as Node3D
		if mount == null or not is_instance_valid(mount):
			(result.checks as Array).append({"check": "row %s stands on the floor" % id, "ok": false})
			continue
		var box := _box(mount)
		var mid := box.get_center()
		var local := content.to_local(mid)
		# from the arrival's side; a work at the arrival itself is seen from the south
		var from := Vector3(here.x - local.x, 0, here.z - local.z)
		if from.length() < 1.0: from = Vector3(0, 0, 1)
		from = from.normalized()
		var reach := maxf(box.size.x, box.size.z)
		var distance := back if back > 0.0 else clampf(reach * 0.75 + 1.7, 2.0, 9.0)
		var stand := local + from * distance
		eye.global_position = _at(stand.x, 1.65, stand.z)
		eye.look_at(Vector3(mid.x, clampf(mid.y, floor_y + 0.5, floor_y + 2.4), mid.z), Vector3.UP)
		await _picture("%s.png" % id)
		result.rows[id] = {"token": str(mount.get_meta("artifact_token", "")), "middle": [snappedf(local.x, 0.01), snappedf(mid.y - floor_y, 0.01), snappedf(local.z, 0.01)],
			"size": [snappedf(box.size.x, 0.01), snappedf(box.size.y, 0.01), snappedf(box.size.z, 0.01)], "seen_from": [snappedf(stand.x, 0.01), snappedf(stand.z, 0.01)]}
		(result.checks as Array).append({"check": "row %s stands on the floor" % id, "ok": true})
	for spec in views:
		var name := spec.get_slice(":", 0)
		var both := spec.get_slice(":", 1).split(">")
		if both.size() != 2: continue
		var a := both[0].split_floats(",")
		var b := both[1].split_floats(",")
		if a.size() != 3 or b.size() != 3: continue
		eye.global_position = _at(a[0], a[1], a[2])
		eye.look_at(_at(b[0], b[1], b[2]), Vector3.UP)
		await _picture("view_%s.png" % name)
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("look.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()
