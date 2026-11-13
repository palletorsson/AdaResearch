extends SceneTree
## CAN A BODY COME DOWN ONTO THIS FLOOR AND LEAVE IT AGAIN (the Void, 2026-11-13)
## The tower is descended by falling: from floor f a body drops through a shaft and lands on floor f+1, where two
## timber boards in one corner of that shaft (the soft landing) take it. A work that covers a shaft changes both
## ends of that. For each shaft of the start floor, with the tower's own walker:
##   ARRIVAL    the body is let go 1.2 m above the floor over this floor's landing corner: where its feet come to
##              rest, and whether it can then step off the landing onto the slab beside it;
##   DEPARTURE  the body is let go 0.4 m above the floor over the corner where the NEXT floor's landing is: whether
##              it comes to rest ONE storey lower (a shaft open for several floors below is a fall, not a way).
##
##   godot --path <stage> --script res://tools/probes/shaft_drop.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## drop.json: one row a shaft. `passed` is true when at least one shaft lets a body leave and the landing shaft the
## layout names lets a body arrive and walk out.
var game: Node3D


func _initialize() -> void:
	run.call_deferred()


func _corner(shaft_x: float, floor_index: int, spec: Dictionary) -> Vector3:
	var side := 1.0 if floor_index % 2 == 1 else -1.0
	var x_side: float = float(spec.descent.get("pad_x_sides", {}).get(str(floor_index), 1))
	return Vector3(shaft_x + x_side * (float(spec.shaft_width) / 2.0 - 0.8), 0, side * (float(spec.shaft_depth) / 2.0 - 1.1))


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
	for i in 900: await physics_frame
	var spec: Dictionary = game.building.spec
	var level: float = float(spec.levels[floor]) + game.building.global_position.y
	var body: CharacterBody3D = game.body
	var pad_shaft: String = str(spec.descent.get("pad_shafts", {}).get(str(floor), spec.descent.get("pad_shaft", "B")))
	var rows := []
	var can_leave := false
	var can_arrive := false
	for shaft in spec.shafts:
		var x: float = float(shaft.x)
		# arrival
		var here := _corner(x, floor, spec)
		game.place_player(Vector3(here.x, level + 1.2, here.z))
		for i in 150: await physics_frame
		var landed: float = body.global_position.y - level
		var x_side: float = float(spec.descent.get("pad_x_sides", {}).get(str(floor), 1))
		var out_to := Vector3(x + x_side * (float(spec.shaft_width) / 2.0 + 1.6), level, here.z)      # off the landing on its own side, not across the open shaft
		var best := INF
		for i in 500:
			var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(out_to.x, out_to.z))
			best = minf(best, d)
			if d < 0.3 or body.global_position.y - level < -3.0: break
			body.look_at(Vector3(out_to.x, body.global_position.y, out_to.z), Vector3.UP)
			body.drive = Vector2(0, -0.5)
			await physics_frame
		body.drive = Vector2.ZERO
		for i in 20: await physics_frame
		var walked_out: bool = best < 0.5 and absf(body.global_position.y - level) < 0.4
		# departure
		var below := _corner(x, floor + 1, spec)
		game.place_player(Vector3(below.x, level + 0.4, below.z))
		for i in 240: await physics_frame
		var fell: float = body.global_position.y - level
		var left: bool = fell < -5.0 and fell > -7.5      # one storey down, onto something: further is a fall no body survives
		var on := ""
		if not left:
			var query := PhysicsRayQueryParameters3D.create(body.global_position + Vector3(0, 0.3, 0), body.global_position + Vector3(0, -0.6, 0))
			query.exclude = [body.get_rid()]
			var hit: Dictionary = root.get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty(): on = str((hit.collider as Node).get_path()).get_slice("/FloorContent/", 1).left(90)
		rows.append({"shaft": str(shaft.name), "lands_m": snappedf(landed, .01), "walks_out_to_the_slab": walked_out, "leaves": left, "comes_to_rest_m": snappedf(fell, .01), "falls_through": fell <= -7.5, "stands_on": on})
		if left: can_leave = true
		if str(shaft.name) == pad_shaft and walked_out and landed > -1.0: can_arrive = true
		game.place_player(Vector3(0, level + 0.3, 7.8))
		for i in 30: await physics_frame
	var result := {"floor": floor, "map": str(record.map), "landing_shaft": pad_shaft, "passed": can_leave and can_arrive,
		"checks": [{"check": "a body can arrive by the landing shaft and walk out, and can leave by some shaft", "ok": can_leave and can_arrive, "landing_shaft": pad_shaft, "shafts": rows}]}
	var file := FileAccess.open(folder.path_join("drop.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[shaft_drop] ", "PASSED" if result.passed else "FAILED")
	quit()
