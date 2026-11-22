extends SceneTree
## Primitives_Columns, floor 9 of the tower: the columns of the row "hall" as they stand - which family of
## outlines, which finish, what the plaques call them - with pictures from the arrival, from inside the grove
## and along the outline row, and the narrowest way between two grove columns at walking height.
##
##   python tools/run_floor_probe.py Primitives_Columns columns_outline.gd columns_outline.json <folder> --no-opening --opera-quiet [--expect-family=1 --expect-finish=black]

var game: Node
var folder := "res://ada_run/columns_outline"
var result := {}
var eye: Camera3D


func _initialize() -> void:
	run.call_deferred()


func _check(what: String, ok: bool, more := {}) -> bool:
	var entry := {"check": what, "ok": ok}
	entry.merge(more)
	(result.checks as Array).append(entry)
	return ok


func _picture(file: String, from: Vector3, at: Vector3) -> void:
	eye.global_position = from
	eye.look_at(at, Vector3.UP)
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(file))


## The widest the column is between two heights above the floor, from its own triangles.
func _widest(column: Node3D, low: float, high: float) -> float:
	var mesh := column.get("column_mesh") as ArrayMesh
	var widest := 0.0
	if mesh == null: return widest
	for surface in mesh.get_surface_count():
		var vertices: PackedVector3Array = mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]
		for vertex in vertices:
			var world := column.to_global(vertex)
			var above: float = world.y - float(result.floor_y)
			if above >= low and above <= high:
				widest = maxf(widest, Vector2(vertex.x, vertex.z).length() * column.global_basis.get_scale().x)
	return widest


func _done() -> void:
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("columns_outline.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()


func run() -> void:
	var expect_family := -1
	var expect_finish := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--expect-family="): expect_family = int(arg.trim_prefix("--expect-family="))
		if arg.begins_with("--expect-finish="): expect_finish = arg.trim_prefix("--expect-finish=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	result = {"floor": int(game.checkpoint), "checks": [], "passed": false}
	for i in 900: await physics_frame
	eye = root.get_camera_3d()
	var arrival := eye.global_position
	var looking := -eye.global_basis.z
	result["floor_y"] = arrival.y - 1.6
	var mount := game.building.content.exhibits.get("%d/hall" % int(game.checkpoint)) as Node3D
	var hall := mount.get_node_or_null("Artifact") as Node3D if is_instance_valid(mount) else null
	if not _check("the row hall stands on the floor", hall != null):
		_done(); return
	game.body.set_physics_process(false)
	game.body.set_process(false)
	var columns := hall.find_children("Column", "Node3D", true, false)
	var families := {}
	var finishes := {}
	var profiles := {}
	for column in columns:
		families[int(column.get("outline_family")) if column.get("outline_family") != null else 0] = true
		finishes[str(column.get("finish")) if column.get("finish") != null else "authored"] = true
		profiles[str(column.get_meta("profile", ""))] = true
	result["columns"] = columns.size()
	result["families"] = families.keys()
	result["finishes"] = finishes.keys()
	result["profiles"] = profiles.keys()
	var plaques := {}
	for label in hall.find_children("*", "Label3D", true, false):
		for line in (label as Label3D).text.split("\n"):
			if line.contains(" M") and line.contains(" / "): plaques[line.get_slice(" / ", 0).strip_edges()] = true
	result["plaque_names"] = plaques.keys()
	if expect_family >= 0:
		_check("every column is of the asked family and finish", families.keys() == [expect_family] and finishes.keys() == [expect_finish] and columns.size() > 30,
			{"columns": columns.size(), "families": families.keys(), "finishes": finishes.keys(), "profiles": profiles.keys()})
		var materials := {}
		for column in columns:
			var mesh := column.get("column_mesh") as ArrayMesh
			for surface in mesh.get_surface_count():
				var material := mesh.surface_get_material(surface) as StandardMaterial3D
				materials[material.albedo_color.to_html(false)] = true
		_check("each is one black body", materials.size() == 1 and Color.from_string(str(materials.keys()[0]), Color.WHITE).get_luminance() < 0.06, {"colours": materials.keys()})
		var old_names := plaques.keys().filter(func(name): return name in ["VESSEL", "REED", "BELL", "SPINDLE", "CAIRN"])
		var new_names := plaques.keys().filter(func(name): return name in ["PLUG", "TAPER", "BEADS", "RIPPLE", "TWIN"])
		_check("the plaques name the new outlines and none of the old", old_names.is_empty() and new_names.size() == 5, {"names": new_names, "old": old_names})
	# the narrowest way between two grove columns, where a body walks (0.3 to 1.9 m)
	var grove := hall.get_children().filter(func(n): return n is Node3D and n.has_meta("grove_column"))
	var narrowest := INF
	var between := ""
	var widths := {}
	for group in grove:
		var column := (group as Node3D).get_node_or_null("Column") as Node3D
		widths[group] = _widest(column, 0.3, 1.9) if column != null else 0.0
	for i in grove.size():
		for j in range(i + 1, grove.size()):
			var a := grove[i] as Node3D
			var b := grove[j] as Node3D
			var gap: float = Vector2(a.global_position.x - b.global_position.x, a.global_position.z - b.global_position.z).length() - float(widths[a]) - float(widths[b])
			if gap < narrowest:
				narrowest = gap
				between = "%s / %s" % [a.name, b.name]
	result["narrowest_way_m"] = snappedf(narrowest, 0.01)
	result["narrowest_between"] = between
	_check("a body walks between any two grove columns", narrowest >= 0.8, {"narrowest_way_m": snappedf(narrowest, 0.01), "between": between})
	await _picture("1_arrival.png", arrival, arrival + looking * 6.0)
	await _picture("2_grove.png", hall.to_global(Vector3(-7.6, 1.6, 3.6)), hall.to_global(Vector3(1.0, 2.3, -1.0)))
	await _picture("3_outline_row.png", hall.to_global(Vector3(-13.6, 1.6, 0.0)), hall.to_global(Vector3(-18.5, 2.6, 0.0)))
	await _picture("4_sides_row.png", hall.to_global(Vector3(0.0, 1.6, 0.6)), hall.to_global(Vector3(0.0, 2.6, -5.5)))
	_done()
