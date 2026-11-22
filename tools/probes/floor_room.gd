extends SceneTree
## Where is there room on the floor the game starts on? A one-metre map of the slab: a cell is taken when a
## body stands in it (a box query, 0.2 to 1.8 m above the floor) or when something drawn stands in it (the
## bounds of every mesh and of every MultiMesh instance between 0.15 and 5.5 m; plates wider than 60 m2 are the
## floor and ceiling and are left out). Prints the map and the widest free strips, and takes pictures from the
## arrival and from two corners. With --row=<id> it also reports that row's own footprint and what it touches.
##
##   python tools/run_floor_probe.py <Map> floor_room.gd floor_room.json <folder> --no-opening --opera-quiet [--row=<id>]

const X0 := -22
const X1 := 22
const Z0 := -8
const Z1 := 8

var game: Node
var folder := "res://ada_run/floor_room"
var result := {}
var eye: Camera3D


func _initialize() -> void:
	run.call_deferred()


func _picture(file: String, from: Vector3, at: Vector3) -> void:
	eye.global_position = from
	eye.look_at(at, Vector3.UP)
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(file))


func _boxes(node: Node, out: Array) -> void:
	if node is MultiMeshInstance3D and (node as MultiMeshInstance3D).multimesh != null and (node as MultiMeshInstance3D).is_visible_in_tree():
		var many := (node as MultiMeshInstance3D).multimesh
		if many.mesh != null:
			var own := many.mesh.get_aabb()
			var count := many.visible_instance_count if many.visible_instance_count >= 0 else many.instance_count
			for i in mini(count, 4000): out.append((node as Node3D).global_transform * many.get_instance_transform(i) * own)
	elif node is GeometryInstance3D and (node as GeometryInstance3D).is_visible_in_tree():
		out.append((node as Node3D).global_transform * (node as GeometryInstance3D).get_aabb())
	for child in node.get_children(): _boxes(child, out)


func run() -> void:
	var row := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--row="): row = arg.trim_prefix("--row=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var index := int(game.checkpoint)
	result = {"floor": index, "checks": [], "passed": true}
	for i in 900: await physics_frame
	eye = root.get_camera_3d()
	var arrival := eye.global_position
	var looking := -eye.global_basis.z
	var floor_y: float = arrival.y - 1.6
	game.body.set_physics_process(false)
	game.body.set_process(false)
	var content: Node3D = game.building.content.roots[index] as Node3D
	var frame := content.global_transform
	result["arrival"] = [snappedf(content.to_local(arrival).x, 0.1), snappedf(content.to_local(arrival).z, 0.1)]
	# what each row covers
	var rows := {}
	for key: String in game.building.content.exhibits:
		if not key.begins_with("%d/" % index): continue
		var mount := game.building.content.exhibits[key] as Node3D
		if not is_instance_valid(mount): continue
		var boxes: Array = []
		_boxes(mount, boxes)
		var low := Vector2(INF, INF)
		var high := Vector2(-INF, -INF)
		var top := 0.0
		for box: AABB in boxes:
			if box.size.x * box.size.z > 60.0 or box.end.y - floor_y < 0.15 or box.position.y - floor_y > 5.5: continue
			var a := content.to_local(box.position)
			var b := content.to_local(box.end)
			low = Vector2(minf(low.x, minf(a.x, b.x)), minf(low.y, minf(a.z, b.z)))
			high = Vector2(maxf(high.x, maxf(a.x, b.x)), maxf(high.y, maxf(a.z, b.z)))
			top = maxf(top, box.end.y - floor_y)
		if low.x < INF: rows[key.get_slice("/", 1)] = [snappedf(low.x, 0.1), snappedf(low.y, 0.1), snappedf(high.x, 0.1), snappedf(high.y, 0.1), snappedf(top, 0.1)]
	result["rows_x0_z0_x1_z1_top"] = rows
	# the map
	var drawn: Array = []
	_boxes(content, drawn)
	var space := eye.get_world_3d().direct_space_state
	var probe := BoxShape3D.new()
	probe.size = Vector3(0.9, 1.6, 0.9)
	var lines := []
	var free := {}
	for z in range(Z0, Z1 + 1):
		var line := ""
		for x in range(X0, X1 + 1):
			var centre := frame * Vector3(x, 0, z)
			centre.y = floor_y + 1.0
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = probe
			query.transform = Transform3D(Basis.IDENTITY, centre)
			query.collision_mask = 0xFFFFFFFF
			query.exclude = [game.body.get_rid()] if game.body is CollisionObject3D else []
			var solid := not space.intersect_shape(query, 1).is_empty()
			var seen := false
			if not solid:
				for box: AABB in drawn:
					if box.size.x * box.size.z > 60.0 or box.end.y - floor_y < 0.15 or box.position.y - floor_y > 5.5: continue
					if box.position.x < centre.x + 0.5 and box.end.x > centre.x - 0.5 and box.position.z < centre.z + 0.5 and box.end.z > centre.z - 0.5:
						seen = true
						break
			line += "#" if solid else ("+" if seen else ".")
			if not solid and not seen: free[Vector2i(x, z)] = true
		lines.append(line)
	result["map_x_%d_to_%d_rows_z_%d_to_%d" % [X0, X1, Z0, Z1]] = lines
	# the widest free strips, three metres deep
	var strips := []
	for z in range(Z0 + 1, Z1):
		var start := X0
		while start <= X1:
			var x := start
			while x <= X1 and free.has(Vector2i(x, z - 1)) and free.has(Vector2i(x, z)) and free.has(Vector2i(x, z + 1)): x += 1
			if x - start >= 6: strips.append({"z": z, "x0": start, "x1": x - 1, "long_m": x - start})
			start = x + 1
	strips.sort_custom(func(a, b): return a.long_m > b.long_m)
	result["free_strips_3m_deep"] = strips.slice(0, 12)
	if row != "" and rows.has(row):
		var own: Array = rows[row]
		var touches := []
		for other: String in rows:
			if other == row: continue
			var o: Array = rows[other]
			if own[0] < o[2] and own[2] > o[0] and own[1] < o[3] and own[3] > o[1]: touches.append(other)
		result["row"] = {"id": row, "footprint": own, "overlaps": touches}
	await _picture("arrival.png", arrival, arrival + looking * 6.0)
	await _picture("from_west.png", frame * Vector3(-20, 0, 6) + Vector3.UP * (floor_y + 1.7 - (frame * Vector3(-20, 0, 6)).y), frame * Vector3(0, 0, 0) + Vector3.UP * (floor_y + 2.2 - (frame * Vector3.ZERO).y))
	await _picture("from_east.png", frame * Vector3(20, 0, -6) + Vector3.UP * (floor_y + 1.7 - (frame * Vector3(20, 0, -6)).y), frame * Vector3(0, 0, 0) + Vector3.UP * (floor_y + 2.2 - (frame * Vector3.ZERO).y))
	var file := FileAccess.open(folder.path_join("floor_room.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()
