extends SceneTree
## Color_Pillar, floor 32 of the tower: the row "gradient-colonnade" - the five classical column outlines moved
## from the columns floor, coloured by height. Checks that the five stand there in the classical family with the
## gradient finish, that each is black at the foot and full at the top (read from the vertex colours of the
## mesh), that its hue and saturation are the colour field's at the place it stands, that a body walks between
## two neighbours, that the tops stay under the colour ceiling, that the plaques face the open floor, and that
## the room is closed: floor and ceiling solid at both shaft squares, the dark floor and the colour ceiling
## drawn over them. Pictures from the open side, along the row and at one plaque.
##
##   python tools/run_floor_probe.py Color_Pillar gradient_colonnade.gd gradient_colonnade.json <folder> --no-opening --opera-quiet

var game: Node
var folder := "res://ada_run/gradient_colonnade"
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


func _done() -> void:
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("gradient_colonnade.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var index := int(game.checkpoint)
	result = {"floor": index, "checks": [], "passed": false}
	for i in 900: await physics_frame
	eye = root.get_camera_3d()
	var floor_y: float = eye.global_position.y - 1.6
	var content: Node3D = game.building.content.roots[index] as Node3D
	var mount := game.building.content.exhibits.get("%d/gradient-colonnade" % index) as Node3D
	var row := mount.get_node_or_null("Artifact") as Node3D if is_instance_valid(mount) else null
	if not _check("the row stands on the floor", row != null):
		_done(); return
	game.body.set_physics_process(false)
	game.body.set_process(false)
	var columns := row.find_children("Column", "Node3D", true, false)
	var report := []
	var all_gradient := columns.size() == 5
	var feet_dark := true
	var tops_full := true
	var highest := 0.0
	for column in columns:
		var mesh := column.get("column_mesh") as ArrayMesh
		var low := Color.WHITE
		var high := Color.BLACK
		var low_y := INF
		var high_y := -INF
		for surface in mesh.get_surface_count():
			var arrays := mesh.surface_get_arrays(surface)
			var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
			var colours: Variant = arrays[Mesh.ARRAY_COLOR]
			if not colours is PackedColorArray or (colours as PackedColorArray).size() != vertices.size():
				all_gradient = false
				continue
			for i in vertices.size():
				if vertices[i].y < low_y: low_y = vertices[i].y; low = colours[i]
				if vertices[i].y > high_y: high_y = vertices[i].y; high = colours[i]
		var top_above: float = (column as Node3D).to_global(Vector3(0, high_y, 0)).y - floor_y
		highest = maxf(highest, top_above)
		if int(column.get("outline_family")) != 0 or str(column.get("finish")) != "gradient": all_gradient = false
		if low.v > 0.1: feet_dark = false
		if high.v < 0.97 or high.s < 0.8: tops_full = false
		report.append({"outline": str(column.get_meta("profile", "")), "at": [snappedf(content.to_local((column as Node3D).global_position).x, 0.01), snappedf(content.to_local((column as Node3D).global_position).z, 0.01)],
			"foot": low.to_html(false), "top": high.to_html(false), "hue": snappedf(high.h, 0.01), "top_above_floor_m": snappedf(top_above, 0.01)})
	result["columns"] = report
	_check("five classical outlines, each with the gradient finish", all_gradient and report.map(func(r): return r.outline) == ["Vessel", "Reed", "Bell", "Spindle", "Cairn"], {"outlines": report.map(func(r): return r.outline)})
	_check("black at the foot, the full colour at the top", feet_dark and report.all(func(r): return Color.from_string(r.top, Color.BLACK).v > 0.97), {"feet": report.map(func(r): return r.foot), "tops": report.map(func(r): return r.top)})
	# the colour of the place: what the field answers at each column's position
	var field: Node3D
	for node in content.find_children("*", "Node3D", true, false):
		if node.has_method("sample_space") and node.get_child_count() > 0 and not row.is_ancestor_of(node) and node != row: field = node as Node3D
	var matches := field != null and bool(row.get_meta("matches_field", false))
	var asked := []
	if field != null:
		for i in columns.size():
			var want: Color = field.call("sample_space", field.to_local((columns[i] as Node3D).global_position))
			var got := Color.from_string(report[i].top, Color.BLACK)
			asked.append({"field": want.to_html(false), "column": got.to_html(false)})
			if absf(want.h - got.h) > 0.01 or absf(want.s - got.s) > 0.02: matches = false
	_check("each column is the colour of the place it stands on", matches, {"pairs": asked})
	var saturations := report.map(func(r): return snappedf(Color.from_string(r.top, Color.BLACK).s, 0.01))
	result["one_hue_five_saturations"] = {"hue": report[0].hue if not report.is_empty() else -1.0, "saturations": saturations}
	# the room is closed at both shaft squares
	var space := eye.get_world_3d().direct_space_state
	var closed := true
	var slabs := []
	for x in [-10.0, 10.0]:
		var at := content.to_global(Vector3(x, 0, 1.4))
		var down := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(at.x, floor_y + 1.0, at.z), Vector3(at.x, floor_y - 1.5, at.z), 1))
		var up := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(at.x, floor_y + 1.0, at.z), Vector3(at.x, floor_y + 7.5, at.z), 1))
		var floor_at: float = (down.position.y - floor_y) if not down.is_empty() else -9.0
		var ceiling_at: float = (up.position.y - floor_y) if not up.is_empty() else 99.0
		slabs.append({"x": x, "floor_at_m": snappedf(floor_at, 0.01), "ceiling_at_m": snappedf(ceiling_at, 0.01)})
		if absf(floor_at) > 0.05 or ceiling_at > 5.8: closed = false
	var dark := content.find_children("DarkFloor*", "MeshInstance3D", true, false).size()
	var colour_ceiling := content.find_children("ColourCeiling*", "MeshInstance3D", true, false).size()
	_check("floor and ceiling are closed at both shaft squares, and drawn over", closed and dark == 7 and colour_ceiling == 7, {"slabs": slabs, "dark_floor_panels": dark, "colour_ceiling_panels": colour_ceiling})
	_check("the tops stay under the colour ceiling", highest <= 5.5, {"highest_m": snappedf(highest, 0.01)})
	# between two neighbours: the bases are the widest thing at walking height
	var narrowest := INF
	for i in range(1, columns.size()):
		var a := (columns[i - 1] as Node3D).global_position
		var b := (columns[i] as Node3D).global_position
		var base: float = 0.86 * float(row.get("width")) * 2.0 + 0.06
		narrowest = minf(narrowest, Vector2(a.x - b.x, a.z - b.z).length() - base)
	_check("a body walks between two neighbours", narrowest >= 1.2, {"between_bases_m": snappedf(narrowest, 0.01)})
	# the plaques face the open floor (the middle of the slab)
	var plaque := row.find_child("Plaque_Column", true, false) as Node3D
	var faces: Vector3 = -plaque.global_basis.z if plaque != null else Vector3.ZERO
	var to_middle := (content.global_position - row.global_position)
	to_middle.y = 0.0
	var side := (plaque.global_position - (plaque.get_parent() as Node3D).global_position) if plaque != null else Vector3.ZERO
	side.y = 0.0
	_check("the plaques stand on the open side of the row", side.normalized().dot(to_middle.normalized()) > 0.7, {"plaque_side": [snappedf(side.x, 0.01), snappedf(side.z, 0.01)], "towards_the_middle": [snappedf(to_middle.x, 0.01), snappedf(to_middle.z, 0.01)]})
	var middle := row.global_position + Vector3.UP * 2.6
	var out := to_middle.normalized()
	# from the open bay beside the row, between it and the building's pillars
	await _picture("1_the_row.png", row.global_position + out * 2.9 + Vector3.UP * 1.7 + out.cross(Vector3.UP).normalized() * 7.6, row.global_position + Vector3.UP * 2.7 - out.cross(Vector3.UP).normalized() * 1.0)
	var along := out.cross(Vector3.UP).normalized()
	await _picture("2_along_the_row.png", row.global_position + along * 9.5 + out * 2.2 + Vector3.UP * 1.7, row.global_position + Vector3.UP * 2.4)
	await _picture("3_one_column.png", (columns[2] as Node3D).global_position + out * 3.2 + Vector3.UP * 1.6, (columns[2] as Node3D).global_position + Vector3.UP * 2.3)
	_done()
