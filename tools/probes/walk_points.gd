extends SceneTree
## CAN A BODY WALK THIS WAY (the Void, 2026-11-12)
## The tower's own walker is put on the arrival point and walks to each point of a list in turn, in a straight line
## to each. Read: how close it came to every point and how high its feet stood there. For a claim a caption makes
## ("the way in is four metres to your right") before the caption is written.
##
##   godot --path <stage> --script res://tools/probes/walk_points.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir> --points=4.4,7.0;4.4,5.0 [--within=0.4]
##
## walk.json: one row a point, and passed when every point was reached. walked.png from behind the body at the end.
var game: Node3D


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	var folder := ""
	var points: Array[Vector2] = []
	var within := 0.4
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--within="): within = float(arg.trim_prefix("--within="))
		if arg.begins_with("--points="):
			for pair in arg.trim_prefix("--points=").split(";", false):
				var xz := pair.split(",")
				if xz.size() == 2: points.append(Vector2(float(xz[0]), float(xz[1])))
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	for i in 600: await physics_frame
	var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
	var body: CharacterBody3D = game.body
	for layer in root.find_children("*", "CanvasLayer", true, false):
		if layer.get_viewport() == root: layer.hide()
	var rows := []
	var all_reached := true
	for point in points:
		var best := INF
		for i in 900:
			var d := Vector2(body.global_position.x, body.global_position.z).distance_to(point)
			best = minf(best, d)
			if d < 0.15: break
			body.look_at(Vector3(point.x, body.global_position.y, point.y), Vector3.UP)
			body.drive = Vector2(0, -0.5)
			await physics_frame
		body.drive = Vector2.ZERO
		for i in 20: await physics_frame
		var reached: bool = best <= within
		if not reached: all_reached = false
		rows.append({"point": [point.x, point.y], "came_within_m": snappedf(best, .01), "feet_m": snappedf(body.global_position.y - level, .01), "reached": reached,
			"stands_at": [snappedf(body.global_position.x, .01), snappedf(body.global_position.z, .01)]})
		if not reached: break
	var cam := Camera3D.new()
	cam.fov = 80
	root.add_child(cam)
	cam.global_position = body.global_position + Vector3(0.6, 2.6, 2.6)
	cam.look_at(body.global_position + Vector3(0, 0.8, -1.0), Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(folder.path_join("walked.png"))
	var result := {"floor": floor, "map": str(record.map), "passed": all_reached and not points.is_empty(), "checks": [{"check": "the walker reaches every point of the list in turn", "ok": all_reached and not points.is_empty(), "points": rows}]}
	var file := FileAccess.open(folder.path_join("walk.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[walk_points] ", "PASSED" if result.passed else "FAILED")
	quit()
