extends SceneTree
## Does the VISITOR see a work? Other probes photograph with their own camera, which sees every render layer; the
## visitor's eyes skip some (Model B's head is on layer 20 and hidden from its own camera), so a work drawn on such a
## layer is in every probe picture and invisible in the game. This counts, for one placed work, how many of its
## drawn parts are on a layer the game's own camera shows, and photographs it through that camera from where the
## visitor would stand.
##
##   godot --path . --xr-mode off --script res://tools/probes/visitor_sees_work.gd -- --void-start-floor=N
##       --work=<row id> --stand=x,z [--out=<dir>]
##
## Prints VISITOR_SEES {...}; writes <dir>/visitor_sees.json and visitor_view.png.

var game: Node


func _initialize() -> void:
	run.call_deferred()


func _drawn(n: Node, out: Array) -> void:
	if n is VisualInstance3D and (n as VisualInstance3D).is_visible_in_tree(): out.append(n)
	for c in n.get_children(): _drawn(c, out)


func run() -> void:
	var work_id := ""
	var stand := Vector2.ZERO
	var folder := "res://ada_run/visitor_sees"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--work="): work_id = a.trim_prefix("--work=")
		if a.begins_with("--stand="):
			var p := a.trim_prefix("--stand=").split(",")
			stand = Vector2(float(p[0]), float(p[1]))
		if a.begins_with("--out="): folder = a.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var mount: Node3D = null
	for i in 900:
		mount = game.building.content.exhibits.get(str(floor) + "/" + work_id)
		if mount != null: break
		await physics_frame
	for i in 240: await physics_frame
	var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
	var result := {"floor": floor, "work": work_id, "built": mount != null}
	if mount == null:
		print("VISITOR_SEES ", JSON.stringify(result))
		quit(1)
		return
	game.place_player(Vector3(stand.x, level + 0.3, stand.y))
	for i in 60: await physics_frame
	var eye := root.get_viewport().get_camera_3d()
	var target := mount.global_position + Vector3(0, 1.4, 0)
	var flat := Vector3(target.x - eye.global_position.x, 0, target.z - eye.global_position.z)
	game.body.rotation.y = atan2(-flat.x, -flat.z) - (eye.global_rotation.y - game.body.global_rotation.y)
	for i in 30: await physics_frame
	var parts := []
	_drawn(mount, parts)
	var seen := 0
	var layers := {}
	for p in parts:
		var l := (p as VisualInstance3D).layers
		layers[l] = int(layers.get(l, 0)) + 1
		if l & eye.cull_mask != 0: seen += 1
	result.merge({"camera": str(eye.get_path()), "camera_cull_mask": eye.cull_mask, "parts_drawn": parts.size(), "parts_the_visitor_sees": seen,
		"layers_of_the_parts": layers, "sees_it": parts.size() > 0 and seen * 2 >= parts.size()})
	for canvas in root.find_children("*", "CanvasLayer", true, false):
		if canvas.get_viewport() == root: canvas.hide()
	for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join("visitor_view.png"))
	var file := FileAccess.open(folder.path_join("visitor_sees.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	print("VISITOR_SEES ", JSON.stringify(result))
	quit(0 if bool(result.sees_it) else 1)
