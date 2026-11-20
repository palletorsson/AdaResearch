extends SceneTree
## Point_Zero, the roof: can a visitor who has stepped out of the arrival crate turn back and see the other
## units through its open face? For the opening text, which may only say so if the roof shows it.
##
## Breaks the panel as a strike does. Stands the visitor's own camera at eye height a few metres from the bays on each of the crate's four sides, looks
## at the bays, records what the line of sight meets first, and keeps the four pictures.
##
##   godot --path . --xr-mode off --resolution 1280x800 --script res://tools/probes/roof_look_back.gd -- \
##       --void-start-floor=0 --no-opening --opera-quiet --out=<dir>
##
## <dir>/roof_look_back.json, from_north.png, from_south.png, from_east.png, from_west.png

var game: Node
var folder := "res://ada_run/roof_look_back"


func _initialize() -> void:
	run.call_deferred()


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	for i in 700: await physics_frame
	var host: Node3D = game.building.content.roots[0]
	var bays := host.get_node_or_null("care-units-crate/Artifact") as Node3D
	var checks := []
	var result := {"floor": 0, "map": "Point_Zero", "checks": checks, "passed": false, "views": {}}
	if bays == null:
		checks.append({"check": "the bays of the other units stand on the roof", "ok": false})
	else:
		var eye := root.get_camera_3d()
		var eye_height: float = eye.global_position.y - host.global_position.y
		game.body.set_physics_process(false)
		game.body.set_process(false)
		var aim := bays.global_position + Vector3.UP * 1.1
		var space := host.get_world_3d().direct_space_state
		result["bays_at"] = [snappedf(host.to_local(bays.global_position).x, 0.01), snappedf(host.to_local(bays.global_position).z, 0.01)]
		result["eye_height_m"] = snappedf(eye_height, 0.01)
		# break the panel the way the visitor's strike does, and let the boards settle
		var crate := host.get_node_or_null("Prop_arrival-crate/Prefab")
		if crate != null and crate.has_method("break_panel"):
			crate.call("break_panel", false)
			for i in 90: await physics_frame
			result["panel_broken_for_this_look"] = true
		var seen_from := []
		for side in [["north", Vector3(0, 0, -1)], ["south", Vector3(0, 0, 1)], ["east", Vector3(1, 0, 0)], ["west", Vector3(-1, 0, 0)]]:
			var at: Vector3 = Vector3(aim.x, host.global_position.y + eye_height, aim.z) + (side[1] as Vector3) * (5.2 if side[0] == "north" else 3.6)
			eye.global_position = at
			eye.look_at(aim, Vector3.UP)
			for i in 12: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(folder.path_join("from_%s.png" % side[0]))
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(at, aim))
			var first := "nothing" if hit.is_empty() else str(host.get_path_to(hit.collider)).left(70)
			var reaches: bool = hit.is_empty() or bays.is_ancestor_of(hit.collider)
			result.views[side[0]] = {"line_of_sight_meets_first": first, "metres": -1.0 if hit.is_empty() else snappedf(at.distance_to(hit.position), 0.01), "reaches_the_bays": reaches}
			if reaches: seen_from.append(side[0])
		result["bays_seen_from"] = seen_from
		checks.append({"check": "from at least one side, three metres out at eye height, the line of sight reaches the bays", "ok": not seen_from.is_empty(), "sides": seen_from})
	result.passed = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("roof_look_back.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit(0 if result.passed else 1)
