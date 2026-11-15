extends SceneTree
## WHAT THE HAND OFFERS, WHAT THE BODY USES on its floor (QFEP_Sandbox; the pass, 2026-11-15)
## A rail whose value is offered, a gate that stands open by the value it uses, a route between them that can be
## made and cut. Read in the running tower with its own walker:
##   at rest: the route is cut, 0.50 is offered, the gate uses 0.10 and stands 0.24 m open;
##   cut, the walker goes along the rail to 0.9: the puck follows, the gate does not, and the gate holds a body;
##   CONNECT: the gate takes 0.9 and stands 2.2 m open, and the walker goes through it;
##   connected, the rail walked back to 0.1: the gate uses 0.1;
##   CUT, and the rail walked to 0.9 again: the gate still uses 0.1 and still holds a body;
##   CONNECT and OTHER MAPPING: the same 0.9 used, the gate 0.24 m open instead of 2.16;
##   the second gate has moved by itself, and nothing the walker did reached it.
##
##   godot --path <stage> --script res://tools/probes/offered_used_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## offered.json: checks with what was read (written after every check). arrival.png, overview.png, cut.png,
## open.png, memory.png.
const ID := "offered-used"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport
var cam: Camera3D
var folder := ""
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("offered.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, ticks: int = 1200) -> void:
	for i in ticks:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -(0.5 if d > 0.5 else 0.25))
		await physics_frame
	body.drive = Vector2.ZERO


func _stand(ticks: int = 90) -> void:
	for i in ticks: await physics_frame


func _local(x: float, z: float) -> Vector3:
	return work.to_global(Vector3(x, 0, z))


## To a plate from the south of the plates, having stepped off whatever was stood on.
func _press(key: String) -> void:
	await _go(_local(work.to_local(body.global_position).x, 3.6))
	await _go(_local(work.to_local(work.plate_point(key)).x, 3.6))
	await _go(work.plate_point(key))
	await _stand()


## Onto the rail at a value, by its nearer end, and along it.
func _rail(value: float) -> void:
	var here: Vector3 = work.to_local(body.global_position)
	if absf(here.z - 1.0) > 0.5:
		await _go(_local(clampf(here.x, -2.4, 2.4), 1.9))
		await _go(_local(clampf(here.x, -2.4, 2.4), 1.0))
	await _go(work.rail_point(value))
	for i in 8: await physics_frame


## From the rail's side straight at the middle of the gate; returns how far south of the gate the walker ends.
func _at_the_gate() -> float:
	var here: Vector3 = work.to_local(body.global_position)
	if absf(here.z - 1.0) < 0.6: await _go(_local(here.x, 0.2))        # straight off the rail: walking along it would offer another value
	await _go(work.gate_point(2.0))
	await _go(work.gate_point(-1.2), 360)
	for i in 10: await physics_frame
	return work.to_local(body.global_position).z + 1.6


func run() -> void:
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
	result = {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("rail_point"):
		for i in 200: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		cam = Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		game.place_player(Vector3(13.5, level + 0.3, 7.6))        # out of its own arrival picture
		for i in 30: await physics_frame
		await _shot(Vector3(0, level + 1.65, 7.8), Vector3(0, level + 1.5, 0), "arrival.png")
		await _shot(Vector3(6.6, level + 4.6, 2.4), Vector3(0.6, level + 0.6, -4.8), "overview.png")
		work.apply_grid_config({"route": "connected"})
		work.apply_grid_config({"route": "cut"})
		var s: Dictionary = work.state()
		var first_neighbour: float = float(s.neighbour_open_m)
		checks.append({"check": "at rest: the route is cut, 0.50 is offered, the gate uses 0.10 and stands 0.24 m open", "ok": str(s.route) == "cut" and is_equal_approx(float(s.offered), 0.5) and is_equal_approx(float(s.used), 0.1)
			and is_equal_approx(float(s.open_m), 0.24) and not bool(s.strip_lit), "lines": s.lines, "build_ms": int(s.build_ms)})
		_save()
		# cut
		game.place_player(_local(0.0, 3.6) + Vector3(0, 0.3, 0))
		for i in 30: await physics_frame
		await _rail(0.9)
		var cut: Dictionary = work.state()
		var held: float = await _at_the_gate()
		await _shot(_local(-2.6, 4.6) + Vector3(0, 2.4, 0), _local(0.2, -1.4) + Vector3(0, 1.0, 0), "cut.png")
		checks.append({"check": "cut, the walker goes along the rail to 0.9: the puck follows, the gate does not, and the gate holds a body", "ok": absf(float(cut.offered) - 0.9) < 0.03 and is_equal_approx(float(cut.used), 0.1)
			and absf(float(cut.puck_x) - (float(cut.offered) * 5.2 - 2.6)) < 0.01 and held > 0.2 and str(cut.status).begins_with("THE HAND HAS MOVED"), "offered": float(cut.offered), "used": float(cut.used),
			"stopped_m_south_of_the_gate": snappedf(held, 0.01), "status": str(cut.status)})
		_save()
		# connect, and through
		await _press("route")
		var made: Dictionary = work.state()
		var through: float = await _at_the_gate()
		await _shot(_local(-2.6, 4.6) + Vector3(0, 2.4, 0), _local(0.2, -1.4) + Vector3(0, 1.0, 0), "open.png")
		checks.append({"check": "CONNECT: the gate takes 0.9 and stands 2.2 m open, and the walker goes through it", "ok": str(made.route) == "connected" and absf(float(made.used) - float(made.offered)) < 0.001 and float(made.open_m) > 2.0
			and bool(made.strip_lit) and through < -1.0, "used": float(made.used), "open_m": float(made.open_m), "walker_m_beyond_the_gate": snappedf(-through, 0.01)})
		_save()
		await _go(work.gate_point(2.0))
		await _rail(0.1)
		var low: Dictionary = work.state()
		checks.append({"check": "connected, the rail walked back to 0.1: the gate uses 0.1", "ok": absf(float(low.offered) - 0.1) < 0.03 and is_equal_approx(float(low.used), float(low.offered)) and float(low.open_m) < 0.35,
			"used": float(low.used), "open_m": float(low.open_m)})
		_save()
		# cut, and the memory
		await _press("route")
		var kept: Dictionary = work.state()
		await _rail(0.9)
		var memory: Dictionary = work.state()
		var again: float = await _at_the_gate()
		await _shot(_local(-2.6, 4.6) + Vector3(0, 2.4, 0), _local(0.2, -1.4) + Vector3(0, 1.0, 0), "memory.png")
		checks.append({"check": "CUT, and the rail walked to 0.9 again: the gate still uses 0.1 and still holds a body", "ok": str(memory.route) == "cut" and absf(float(memory.offered) - 0.9) < 0.03 and is_equal_approx(float(memory.used), float(kept.used)) and absf(float(kept.used) - 0.1) < 0.03
			and again > 0.2 and str(memory.status).contains("KEEPS THE LAST VALUE"), "offered": float(memory.offered), "used": float(memory.used), "stopped_m_south_of_the_gate": snappedf(again, 0.01)})
		_save()
		# the other mapping
		await _go(work.gate_point(2.0))
		await _press("route")
		var joined: Dictionary = work.state()
		await _press("mapping")
		var turned: Dictionary = work.state()
		checks.append({"check": "CONNECT and OTHER MAPPING: the same 0.9 used, the gate 0.24 m open instead of 2.16", "ok": is_equal_approx(float(turned.used), float(joined.used)) and absf(float(joined.open_m) - 2.4 * float(joined.used)) < 0.01
			and absf(float(turned.open_m) - 2.4 * (1.0 - float(turned.used))) < 0.01 and not bool(turned.wider) and str(turned.status).contains("SOMEONE WROTE BOTH"), "used": float(turned.used), "open_m": [float(joined.open_m), float(turned.open_m)]})
		_save()
		var last: Dictionary = work.state()
		checks.append({"check": "the second gate has moved by itself, and nothing the walker did reached it", "ok": absf(float(last.neighbour_open_m) - first_neighbour) > 0.02, "neighbour_open_m": [first_neighbour, float(last.neighbour_open_m)]})
		_save()
		work.apply_grid_config({"route": "connected"})
		work.apply_grid_config({"route": "cut"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[offered_used_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
