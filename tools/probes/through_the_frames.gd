extends SceneTree
## The opera's view frames as a research camera. On the floor the game starts on, finds every view frame the
## floor publishes (commons/void/opera_view_frame.gd under a framed song field), stands the visitor's own
## camera behind each one, looks through it, and saves what is there: the picture a visitor has at the moment
## the frame lights and its song may start. Changes nothing.
##
##   godot --path . --xr-mode off --resolution 1280x800 --script res://tools/probes/through_the_frames.gd -- \
##       --void-start-floor=<n> --no-opening --opera-quiet --out=<dir> [--back=<m behind the frame>]
##
## <dir>/through_the_frames.json and one picture for each frame, named by its caption.

var game: Node
var folder := "res://ada_run/through_the_frames"
var back := 1.0
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _v(p: Vector3) -> Array:
	return [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)]


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--back="): back = float(arg.trim_prefix("--back="))
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var checks := []
	result = {"floor": int(game.checkpoint), "window": str(root.size), "metres_behind_the_frame": back, "frames": [], "checks": checks, "passed": false}
	for i in 900: await physics_frame
	var eye := root.get_camera_3d()
	var floor_y: float = eye.global_position.y - 1.6
	var frames: Array[Node] = []
	for node in root.find_children("OperaFrame", "Node3D", true, false):
		if absf((node as Node3D).global_position.y - floor_y) < 4.0: frames.append(node)
	game.body.set_physics_process(false)
	game.body.set_process(false)
	for node in frames:
		var frame := node as Node3D
		var field := frame.get_parent()
		for i in 20: await physics_frame
		var row := {"caption": str(frame.get("caption")), "field": str(field.name), "frame_at": _v(frame.global_position), "shown": frame.is_visible_in_tree()}
		if frame.is_visible_in_tree():
			# behind the frame on the side that faces the visitor, looking through its middle
			eye.global_position = frame.to_global(Vector3(0, 0, back))
			eye.look_at(frame.to_global(Vector3(0, 0, -4.0)), Vector3.UP)
			for i in 30: await physics_frame
			for i in 6: await process_frame
			await RenderingServer.frame_post_draw
			var file := "through_%s.png" % str(frame.get("caption")).to_lower().replace(" ", "_").replace("/", "-")
			root.get_texture().get_image().save_png(folder.path_join(file))
			var target: Node3D = null
			if field.get("floor_root") != null and field.get("target_path") != null:
				target = (field.get("floor_root") as Node).get_node_or_null(field.get("target_path")) as Node3D
			row["picture"] = file
			row["eye"] = _v(eye.global_position)
			row["lit_from_here"] = bool(frame.get("lit"))
			row["target"] = str(field.get("target_path"))
			if target != null:
				var aim: Vector3 = target.to_global(field.get("target_offset"))
				row["metres_from_the_eye_to_the_aim"] = snappedf(eye.global_position.distance_to(aim), 0.01)
		result.frames.append(row)
	checks.append({"check": "the floor publishes at least one view frame", "ok": not frames.is_empty(), "found": frames.size()})
	checks.append({"check": "every shown frame lights for a camera standing behind it and looking through", "ok": result.frames.all(func(r): return not r.shown or r.get("lit_from_here", false))})
	result.passed = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("through_the_frames.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit(0 if result.passed else 1)
