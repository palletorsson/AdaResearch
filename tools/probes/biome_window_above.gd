extends SceneTree
## THE BIOME SEEN FROM THE FLOOR ABOVE (the Void; Palle, 2026-11-13: "...and open the shaft above the biome to 12")
## A biome box in its window form is a clear glass floor set in a shaft's six-metre opening. One floor down stands a
## biome box in the slanted form: a twelve-metre ground two metres up. The question this answers with the tower's own
## walker and rays: does the six-metre opening have to be cut wider for the whole ground to be seen from above?
##   the floor holds a window, and the floor below a biome box that builds when the window asks it to (the floor
##   under a body is paused: the box's own sensor is out of physics there);
##   a body walks out onto the glass from the slab and stands on it, on this floor;
##   from an eye 1.6 m over the middle of the glass, a ray to each corner of the ground below (and to the middle of
##   each edge) reaches it without meeting the slab;
##   from an eye at the rim, how many of those eight points are in view.
##
##   godot --path <stage> --script res://tools/probes/biome_window_above.gd -- --no-bridges
##       --void-start-floor=<floor with the window> --out=<dir>
##
## window.json: checks with what was read. arrival.png, down.png (from the middle of the glass), rim.png.
const WINDOW := "biome-window"
const BOX := "biome-box"
var game: Node3D


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.FORWARD if absf(at.x - target.x) + absf(at.z - target.z) < 0.01 else Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 600, speed: float = 0.5) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.15: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 20: await physics_frame
	return best


## The points of the ground below a ray is sent to: its four corners and the middle of its four edges, at the ground's level.
func _marks(low: Node3D) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var half: float = float(low.cells) * 0.5
	var middle: Vector3 = low.biome().global_position
	for pair in [[-1, -1], [1, -1], [1, 1], [-1, 1], [0, -1], [1, 0], [0, 1], [-1, 0]]:
		out.append(middle + Vector3(float(pair[0]) * half, 0.0, float(pair[1]) * half))
	return out


## How many of the marks an eye sees: a ray that meets nothing, or meets something at or below the mark's own height.
func _seen(eye: Vector3, marks: Array[Vector3], skip: Array[RID]) -> Array:
	var seen := 0
	var blocked := []
	for mark in marks:
		var query := PhysicsRayQueryParameters3D.create(eye, mark)
		query.exclude = skip
		var hit: Dictionary = root.get_world_3d().direct_space_state.intersect_ray(query)
		if hit.is_empty() or (hit.position as Vector3).distance_to(mark) < 2.2: seen += 1      # the ground's own hills and the glass round it stand in front of a corner: that is the ground, seen
		else: blocked.append([snappedf(mark.x - eye.x, .1), snappedf(mark.z - eye.z, .1), str((hit.collider as Node).name)])
	return [seen, blocked]


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, WINDOW]) and game.building.content.exhibits.has("%d/%s" % [floor + 1, BOX]): break
		await physics_frame
	var up_mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, WINDOW])
	var low_mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor + 1, BOX])
	var pane: Node3D = up_mount.get_node_or_null("Artifact") if up_mount != null else null
	var low: Node3D = low_mount.get_node_or_null("Artifact") if low_mount != null else null
	var have: bool = pane != null and low != null and pane.has_method("state") and bool(pane.state().window)
	checks.append({"check": "the floor holds a window and the floor below a biome box", "ok": have})
	if have:
		var built := false
		for i in 1200:
			if bool(low.state().built): built = true; break
			await physics_frame
		for i in 240: await physics_frame
		var st: Dictionary = low.state()
		checks.append({"check": "the biome one floor down is built while the body stands up here", "ok": built, "build_ms": int(st.build_ms), "trees": int(st.trees), "below_is_drawn": low.is_visible_in_tree()})
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):
			if layer.get_viewport() == root: layer.hide()
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		var at: Vector3 = pane.global_position
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(0, 0.4, 0), folder.path_join("arrival.png"))
		# out onto the glass from the slab
		game.place_player(at + Vector3(-4.6, 0.3, 0.4))
		for i in 40: await physics_frame
		await _go(body, at + Vector3(0, 0, 0.4), 500, 0.34)
		var feet: float = body.global_position.y - level
		var out_m: float = Vector2(body.global_position.x - at.x, body.global_position.z - at.z).length()
		checks.append({"check": "a body walks out onto the glass from the slab and stands on it, on this floor", "ok": out_m < 0.8 and absf(feet) < 0.12 and int(game.checkpoint) == floor, "feet_m": snappedf(feet, .01), "from_the_middle_m": snappedf(out_m, .01)})
		# what an eye sees of the ground below
		var skip: Array[RID] = [body.get_rid()]
		for n in pane.find_children("*", "StaticBody3D", true, false): skip.append((n as StaticBody3D).get_rid())
		if not built:
			var early := FileAccess.open(folder.path_join("window.json"), FileAccess.WRITE)
			early.store_string(JSON.stringify(result, "\t"))
			early.close()
			print("[biome_window_above] FAILED: the biome below is not built")
			quit()
			return
		var marks := _marks(low)
		var middle: Array = _seen(at + Vector3(0, 1.6, 0), marks, skip)
		checks.append({"check": "from the middle of the glass a ray reaches all four corners and all four edges of the ground below", "ok": int(middle[0]) == marks.size(), "seen": int(middle[0]), "of": marks.size(), "blocked": middle[1],
			"ground_side_m": float(low.cells), "ground_below_the_eye_m": snappedf(at.y + 1.6 - low.biome().global_position.y, .01)})
		var rim: Array = _seen(at + Vector3(-3.2, 1.6, 0), marks, skip)
		checks.append({"check": "from the west rim of the opening, how much of it is in view (reported, not required)", "ok": true, "seen": int(rim[0]), "of": marks.size(), "blocked": rim[1]})
		await _shot(cam, at + Vector3(0, 1.6, 0), low.biome().global_position, folder.path_join("down.png"))
		await _shot(cam, at + Vector3(-3.4, 1.6, 2.6), low.biome().global_position + Vector3(2.0, 0.6, -1.0), folder.path_join("rim.png"))
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("window.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[biome_window_above] ", "PASSED" if result.passed else "FAILED")
	quit()
