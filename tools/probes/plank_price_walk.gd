extends SceneTree
## THE PRICE OF ONE MORE ROUTE on its floor (GT_Spanning_Trees; the pass, 2026-11-13)
## Seven lands in water, ten places for a plank bridge, a bridge costs its length (1, 2 or 4 m planks). Read in the
## running tower with its own walker, against the bench (tools/probes/plank_price_bench.py):
##   tree      six bridges, 12 m, the least; nothing spare; the work is built from the lab's prefabs;
##             the body walks the tree and stands on all seven lands;
##   break one standing still on a bridge of the map takes that bridge away: A1-A2 gone, three lands cut off from S,
##             and a body walking at the place where it was is held on A1;
##   one more  with A1-A2 and B1-B2 both laid, 16 m and one spare; A1-A2 can then be taken away and every land is
##             still reached;
##   all       ten bridges, 24 m, four spare.
##
##   godot --path <stage> --script res://tools/probes/plank_price_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## price.json: checks with what was read. arrival.png, above.png, far.png, broken.png, all.png.
const ID := "plank-price"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 6: await process_frame
	eye.get_texture().get_image().save_png(path)


func _go(target: Vector3, ticks_max: int = 700, speed: float = 0.34) -> void:
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.1: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 14: await physics_frame


## Cross a bridge from the land the body stands on.
func _cross(slot: int) -> void:
	var land: int = work.LAND_NAMES.find(str(work.state().land))
	var ends: Array = work.SLOTS[slot]["ends"]
	var points: Array = work.bridge_ends(slot)
	var low_first: bool = int(ends[0]) == land
	await _go(points[0] if low_first else points[1])
	await _go(points[1] if low_first else points[0])


func _out() -> void:
	var way: Array = work.way_in()
	await _go(way[1])
	await _go(way[0])


func _in() -> void:
	var way: Array = work.way_in()
	await _go(way[0])
	await _go(way[1])


func _press(slot: int) -> void:
	await _go(work.map_plate(slot))
	for i in 80: await physics_frame


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
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("cheapest"):
		for i in 300: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		var cam := Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		var at: Vector3 = work.global_position
		var s: Dictionary = work.state()
		var prefabs := 0
		var kinds := {}
		for n in work.find_children("*", "Node3D", true, false):
			if n.has_meta("prefab") and n.has_meta("source_scene"):
				prefabs += 1
				kinds[str(n.get_meta("prefab"))] = int(kinds.get(str(n.get_meta("prefab")), 0)) + 1
		checks.append({"check": "tree: six bridges, 12 m, the least; nothing spare; every land reached; built from the lab's prefabs", "ok": s.laid == [0, 2, 3, 5, 6, 7] and int(s.metres) == 12 and int(s.least) == 12 and int(s.spare) == 0
			and (s.reached as Array).size() == 7 and prefabs >= 60 and kinds.size() >= 5, "laid": s.laid, "metres": int(s.metres), "spare": int(s.spare), "prefabs_in_the_tree": prefabs, "kinds": kinds, "build_ms": int(s.build_ms)})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(0, 0.5, 1.0), folder.path_join("arrival.png"))
		await _shot(cam, at + Vector3(-7.5, 5.0, 11.0), at + Vector3(0.5, 0, -1.0), folder.path_join("above.png"))
		# walk the tree: every land
		var way: Array = work.way_in()
		game.place_player((way[0] as Vector3) + Vector3(0, 0.3, 0))
		for i in 40: await physics_frame
		await _go(way[1])
		for slot in [0, 3, 3, 7, 5, 6]: await _cross(slot)
		await _shot(cam, body.global_position + Vector3(0, 1.6, 0), work.to_global(Vector3(-1.0, 0.5, 2.0)), folder.path_join("far.png"))
		for slot in [6, 5, 7, 0, 2]: await _cross(slot)
		var walked: Dictionary = work.state()
		checks.append({"check": "the body walks the tree and stands on all seven lands", "ok": (walked.visited as Array).size() == 7 and str(walked.land) == "C1", "visited": walked.visited, "ends_on": str(walked.land)})
		# break one connection, from the map
		await _cross(2)
		await _out()
		await _press(7)
		var broken: Dictionary = work.state()
		await _shot(cam, at + Vector3(-7.5, 5.0, 11.0), at + Vector3(0.5, 0, -1.0), folder.path_join("broken.png"))
		await _in()
		await _cross(0)
		var ends: Array = work.bridge_ends(7)
		await _go(ends[1])
		await _go(ends[0], 300, 0.5)
		var held: Vector3 = work.to_local(body.global_position)
		checks.append({"check": "break one: standing still on A1-A2 on the map takes it away - 8 m, three lands cut off from S - and a body walking at its place is held on A1", "ok": not (broken.laid as Array).has(7) and int(broken.metres) == 8
			and (broken.reached as Array).size() == 4 and held.z > -0.3 and str(work.state().land) == "A1", "laid": broken.laid, "reached_from_S": broken.reached, "held_at_z": snappedf(held.z, .01), "on": str(work.state().land)})
		# one more route
		await _cross(0)
		await _out()
		await _press(7)
		await _press(8)
		var more: Dictionary = work.state()
		await _press(7)
		var lost: Dictionary = work.state()
		checks.append({"check": "one more: with A1-A2 and B1-B2 both laid, 16 m and one spare; A1-A2 is then taken away and every land is still reached", "ok": int(more.metres) == 16 and int(more.spare) == 1 and (more.reached as Array).size() == 7
			and int(lost.metres) == 12 and (lost.reached as Array).size() == 7 and not (lost.laid as Array).has(7), "with_both": [int(more.metres), int(more.spare)], "after_losing_one": [int(lost.metres), (lost.reached as Array).size(), lost.laid]})
		# all
		work.apply_grid_config({"planks": "all"})
		for i in 30: await physics_frame
		var all: Dictionary = work.state()
		await _shot(cam, at + Vector3(-7.5, 5.0, 11.0), at + Vector3(0.5, 0, -1.0), folder.path_join("all.png"))
		checks.append({"check": "all: ten bridges, 24 m, four spare", "ok": (all.laid as Array).size() == 10 and int(all.metres) == 24 and int(all.spare) == 4, "metres": int(all.metres), "spare": int(all.spare)})
		work.apply_grid_config({"planks": "tree"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("price.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[plank_price_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
