extends SceneTree
## SEVEN BRIDGES TO WALK on their floor (GT_Foundations; the pass, 2026-11-13)
## A city on the floor whose bridges are the lesson's own table (konigsberg3d.gd, axis `parity`). Read in the running
## tower with its own walker, which walks the routes the bench found (tools/probes/seven_bridges_bench.py):
##   the city is built from the spatial lab's prefabs through the lab's own adapter, and the High Bridge is climbed;
##   blocked  the lesson's seven bridges, 5 / 3 / 3 / 3 at the four lands; water holds a body off; from the way in the
##            walker crosses six bridges once and the seventh cannot be had without crossing one twice;
##   circuit  nine bridges, 6 / 4 / 4 / 4: all nine once, and back on the land it began on;
##   walk     eight bridges, 5 / 3 / 4 / 4: from the way in seven of eight; then it stands on Altstadt's plate, the
##            count begins again there, and all eight are crossed once, ending on Loebenicht;
##   severed  four bridges: all four once, and Loebenicht is never reached;
##   standing on the blue plate changes the city.
##
##   godot --path <stage> --script res://tools/probes/seven_bridges_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## bridges.json: checks with what was read. arrival.png, above.png, high.png, island.png, circuit.png.
const ID := "seven-bridges"
var game: Node3D
var body: CharacterBody3D
var city: Node3D
var eye: SubViewport
var highest := 0.0


func _initialize() -> void:
	run.call_deferred()


## A picture through the probe's own viewport on the same world: the game's camera and what the game draws over its
## own view (a recorder frame appeared there on 2026-11-13) stay out of it.
func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 6: await process_frame
	eye.get_texture().get_image().save_png(path)


func _go(target: Vector3, ticks_max: int = 700, speed: float = 0.34) -> void:
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		highest = maxf(highest, body.global_position.y)
		if d < 0.12: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 12: await physics_frame


## To a point on the land the body stands on, the way a visitor goes: the High Bridge's wedges stand a metre onto the
## south bank and onto the island, so along the south bank the body keeps to the lane behind the wedge's foot, and on
## the island it passes through the middle.
func _on_land(land: int, target: Vector3) -> void:
	var here: Vector3 = city.to_local(body.global_position)
	var goal: Vector3 = city.to_local(target)
	if land == 3 and absf(here.x - goal.x) > 0.3:
		await _go(city.to_global(Vector3(here.x, 0, 6.35)))
		await _go(city.to_global(Vector3(goal.x, 0, 6.35)))
	elif land == 0:
		await _go(city.to_global(Vector3(-1.1, 0, 0.9)))
	await _go(target)


## Walk a route of bridges from the land the body stands on; returns the land it ends on.
func _walk(route: Array, land: int) -> int:
	for slot in route:
		var ends: Array = city.SLOTS[slot]["ends"]
		var points: Array = city.bridge_ends(int(slot))
		var low_first: bool = int(ends[0]) == land
		await _on_land(land, points[0] if low_first else points[1])
		await _go(points[1] if low_first else points[0])
		land = int(ends[1]) if low_first else int(ends[0])
	return land


func _set_city(name: String) -> void:
	city.apply_grid_config({"parity": name})
	for i in 20: await physics_frame
	var way: Array = city.way_in()
	game.place_player((way[1] as Vector3) + Vector3(0, 0.3, 0))
	for i in 40: await physics_frame
	city.begin_at(3)


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
	city = mount.get_node_or_null("Artifact") if mount != null else null
	var have: bool = city != null and city.has_method("bridge_ends")
	if have:
		for i in 300: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):
			if layer.get_viewport() == root: layer.hide()
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		var cam := Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		var at: Vector3 = city.global_position
		var s: Dictionary = city.state()
		checks.append({"check": "the floor holds the city, and its bridges are the lesson's seven: 5, 3, 3, 3 at the four lands", "ok": str(s.parity) == "blocked" and (s.bridges as Array).size() == 7 and s.degrees == [5, 3, 3, 3],
			"bridges": s.bridges, "degrees": s.degrees, "names": s.names})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(0, 0.6, 0), folder.path_join("arrival.png"))
		await _shot(cam, at + Vector3(-4.5, 5.0, 12.0), at + Vector3(0.5, 0, -1.5), folder.path_join("above.png"))
		await _shot(cam, city.to_global(Vector3(-2.2, 1.6, 9.0)), city.to_global(Vector3(0.6, 0.6, 3.5)), folder.path_join("high.png"))
		var prefabs := 0
		var kinds := {}
		for n in city.find_children("*", "Node3D", true, false):
			if n.has_meta("prefab") and n.has_meta("source_scene"):
				prefabs += 1
				kinds[str(n.get_meta("prefab"))] = int(kinds.get(str(n.get_meta("prefab")), 0)) + 1
		checks.append({"check": "the city is built from the spatial lab's prefabs, each through the lab's own adapter with its source scene", "ok": prefabs >= 90 and kinds.size() >= 9 and int(s.bridges_standing) == 7,
			"prefabs_in_the_tree": prefabs, "kinds": kinds, "built_in_all": int(s.prefab_parts), "build_ms": int(s.build_ms), "bridges_standing": int(s.bridges_standing)})
		# in by the one way in; the water holds
		var way: Array = city.way_in()
		game.place_player((way[0] as Vector3) + Vector3(0, 0.3, 0))
		for i in 40: await physics_frame
		await _go(way[1])
		var inside: Vector3 = city.to_local(body.global_position)
		await _go(city.to_global(Vector3(1.9, 0, 6.0)))
		await _go(city.to_global(Vector3(1.9, 0, -0.5)), 240, 0.5)
		var held: Vector3 = city.to_local(body.global_position)
		checks.append({"check": "a body comes in by the way in on the south bank, and the water holds it off", "ok": inside.z < 7.0 and absf(inside.x) < 1.0 and held.z > 4.8 and int(city.state().once) == 0,
			"inside_at": [snappedf(inside.x, .01), snappedf(inside.z, .01)], "stopped_at_z": snappedf(held.z, .01), "the_shore_is_at_z": 4.8})
		highest = -INF
		# blocked: six of seven, then the seventh costs a second crossing
		var land: int = await _walk([2, 0, 1, 3, 6, 4], 3)
		var b6: Dictionary = city.state()
		checks.append({"check": "the High Bridge is climbed: over its two wedges the body stands about a metre up", "ok": highest - level > 0.8 and highest - level < 1.2, "highest_feet_m": snappedf(highest - level, .01)})
		await _shot(cam, body.global_position + Vector3(0, 1.6, 0), at + Vector3(3.0, 0.6, 2.0), folder.path_join("island.png"))
		land = await _walk([4], land)
		var b7: Dictionary = city.state()
		checks.append({"check": "blocked: from the way in six bridges once, one not yet; going on means crossing a bridge twice, and the lands then show their counts", "ok": int(b6.once) == 6 and int(b6.not_yet) == 1 and not bool(b6.done) and not bool(b6.revealed)
			and int(b7.twice_or_more) == 1 and bool(b7.revealed) and not bool(b7.done), "after_six": [int(b6.once), int(b6.twice_or_more), int(b6.not_yet)], "after_the_next": [int(b7.once), int(b7.twice_or_more), int(b7.not_yet)], "ended_on": land})
		# circuit
		await _set_city("circuit")
		var c0: Dictionary = city.state()
		land = await _walk([2, 0, 1, 3, 6, 4, 8, 5, 7], 3)
		var c9: Dictionary = city.state()
		await _shot(cam, at + Vector3(-4.5, 5.0, 12.0), at + Vector3(0.5, 0, -1.5), folder.path_join("circuit.png"))
		checks.append({"check": "circuit: nine bridges, 6, 4, 4, 4; all nine crossed once, ending on the land the walk began on", "ok": (c0.bridges as Array).size() == 9 and c0.degrees == [6, 4, 4, 4] and bool(c9.done) and int(c9.once) == 9 and int(c9.at_land) == 3 and land == 3,
			"degrees": c0.degrees, "once": int(c9.once), "ended_on": int(c9.at_land)})
		# walk: not from the way in; from Altstadt, yes
		await _set_city("walk")
		var w0: Dictionary = city.state()
		land = await _walk([2, 0, 1, 3, 6, 5, 7], 3)
		var w7: Dictionary = city.state()
		land = await _walk([2], land)      # over to Altstadt, a second time on that bridge
		await _on_land(0, city.plate_of(0))
		for i in 90: await physics_frame
		var wb: Dictionary = city.state()
		land = await _walk([0, 1, 2, 3, 4, 5, 7, 6], 0)
		var w8: Dictionary = city.state()
		checks.append({"check": "walk: eight bridges, 5, 3, 4, 4; from the way in seven of eight; standing on Altstadt's plate begins the count there, and all eight are crossed once, ending on Loebenicht", "ok": (w0.bridges as Array).size() == 8 and w0.degrees == [5, 3, 4, 4]
			and int(w7.once) == 7 and not bool(w7.done) and int(wb.began_at) == 0 and int(wb.once) == 0 and int(wb.twice_or_more) == 0 and bool(w8.done) and int(w8.at_land) == 1,
			"from_the_way_in": [int(w7.once), int(w7.not_yet)], "after_the_plate": [int(wb.began_at), int(wb.once), int(wb.twice_or_more)], "from_altstadt": [int(w8.once), bool(w8.done), int(w8.at_land)]})
		# severed
		await _set_city("severed")
		var v0: Dictionary = city.state()
		land = await _walk([2, 0, 1, 3], 3)
		var v4: Dictionary = city.state()
		checks.append({"check": "severed: four bridges, 4, 0, 2, 2; all four once, and Loebenicht is never reached", "ok": (v0.bridges as Array).size() == 4 and v0.degrees == [4, 0, 2, 2] and bool(v4.done) and not (v4.visited as Array).has(1),
			"degrees": v0.degrees, "done": bool(v4.done), "visited": v4.visited})
		# the blue plate
		game.place_player((city.city_plate() as Vector3) + Vector3(0.9, 0.3, 0.9))
		for i in 40: await physics_frame
		await _go(city.city_plate())
		for i in 90: await physics_frame
		checks.append({"check": "standing on the blue plate changes the city", "ok": str(city.state().parity) == "blocked", "now": str(city.state().parity)})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the city", "ok": false})
	var file := FileAccess.open(folder.path_join("bridges.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[seven_bridges_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
