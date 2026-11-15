extends SceneTree
## WHO DREW THE TREE? on its floor (QFEP_E_Term; the pass, 2026-11-15)
## Sixteen endings taped on the floor; a walked path lights and hangs a bead. Read in the running tower with its
## own walker:
##   at rest: sixteen endings, ln 16 nats, by the same rule the hall's fan reads its own leaves;
##   a walk L R R L arrives at an ending: one bead, the path named;
##   two more walks: three arrivals at two endings, the walked entropy far under the counted one;
##   PRUNE A: eight endings, four gates, the two beads behind a gate lost, and the gate holds a body;
##   PRUNE B: eight endings again and the same entropy, none of them A's eight; the third bead lost;
##   OPEN: sixteen endings, no beads, three arrivals still counted as lost;
##   a third way asked for at a last fork: seventeen endings, and the walker arrives at one nobody drew.
##
##   godot --path <stage> --script res://tools/probes/drawn_tree_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## tree.json: checks with what was read (written after every check). arrival.png, overview.png, walked.png,
## pruned.png, asked.png.
const ID := "drawn-tree"
const FAN := "f1_entropy_fan_6_5"
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
	var file := FileAccess.open(folder.path_join("tree.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, ticks: int = 900) -> void:
	for i in ticks:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -(0.5 if d > 0.5 else 0.25))
		await physics_frame
	body.drive = Vector2.ZERO


func _stand(ticks: int = 90) -> void:
	for i in ticks: await physics_frame


## From START along the forks to a place under fork `fork` of the last row: an ending (0 west, 1 east) or, with
## `stop` 3, the fork itself.
func _walk(fork: int, side: int, stop: int = 4) -> void:
	await _go(work.node_point(0, 0))
	for level in range(1, 4): await _go(work.node_point(level, fork >> (3 - level)))
	if stop == 4: await _go(work.node_point(4, fork * 2 + side))
	for i in 10: await physics_frame


func _home(fork: int) -> void:
	for level in range(3, -1, -1): await _go(work.node_point(level, fork >> (3 - level)))


func _press(key: String) -> void:
	await _go(work.plate_point(key))
	await _stand()


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
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]) and game.building.content.exhibits.has("%d/%s" % [floor, FAN]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("node_point"):
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
		await _shot(Vector3(8.5, level + 4.6, 7.5), Vector3(0, level + 0.6, -1.5), "overview.png")
		# the fan's own rule
		var fan_mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, FAN])
		var fan: Node = fan_mount.get_node_or_null("Artifact") if fan_mount != null else null
		var fan_reading := {}
		if fan != null and fan.has_method("possibility_reading"): fan_reading = fan.call("possibility_reading")
		work.apply_grid_config({"drawn": "open"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest: sixteen endings, ln 16 nats, by the same rule the hall's fan reads its own leaves", "ok": int(s.count) == 16 and absf(float(s.equal_H) - 2.7726) < 0.0002 and not fan_reading.is_empty()
			and absf(float(fan_reading.entropy_nats) - float(work.equal_entropy(int(fan_reading.leaves)))) < 0.0001 and Array(s.gates).is_empty() and Dictionary(s.tally).is_empty(),
			"equal_H": float(s.equal_H), "fan_leaves": int(fan_reading.get("leaves", -1)), "fan_nats": snappedf(float(fan_reading.get("entropy_nats", -1.0)), 0.0001), "build_ms": int(s.build_ms)})
		_save()
		# one walk: L R R L (the seventh ending from the west, under the fourth last fork)
		game.place_player(work.node_point(0, 0) + Vector3(0, 0.3, 1.2))
		for i in 30: await physics_frame
		await _walk(3, 0)
		var one: Dictionary = work.state()
		checks.append({"check": "a walk L R R L arrives at an ending: one bead, the path named", "ok": Dictionary(one.tally) == {"4/6": 1} and str(one.here).ends_with("L R R L") and int(one.beads) == 1 and str(one.at) == "4/6",
			"tally": one.tally, "here": str(one.here)})
		_save()
		await _home(3)
		await _walk(3, 0)
		await _home(3)
		await _walk(4, 1)
		var three: Dictionary = work.state()
		await _shot(work.node_point(0, 0) + Vector3(-3.2, 3.4, 2.6), work.node_point(3, 3) + Vector3(0, 0.2, 0), "walked.png")
		checks.append({"check": "two more walks: three arrivals at two endings, the walked entropy far under the counted one", "ok": Dictionary(three.tally) == {"4/6": 2, "4/9": 1} and absf(float(three.walked_H) - 0.6365) < 0.0005
			and absf(float(three.equal_H) - 2.7726) < 0.0002, "tally": three.tally, "walked_H": float(three.walked_H), "equal_H": float(three.equal_H), "says": str(three.walked_words)})
		_save()
		# prune A
		await _home(4)
		await _press("prune_a")
		var a: Dictionary = work.state()
		await _go(work.node_point(0, 0))
		await _go(work.node_point(1, 0))
		await _go(work.node_point(2, 1))
		await _go(work.node_point(3, 3), 240)
		var held: float = Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(work.node_point(3, 3).x, work.node_point(3, 3).z))
		await _shot(work.node_point(0, 0) + Vector3(3.6, 3.4, 2.4), work.node_point(3, 3) + Vector3(0, 0.2, 0), "pruned.png")
		checks.append({"check": "PRUNE A: eight endings, four gates, the two beads behind a gate lost, and the gate holds a body", "ok": int(a.count) == 8 and absf(float(a.equal_H) - 2.0794) < 0.0002 and Array(a.gates).size() == 4
			and Array(a.gates).has("3/3") and int(a.lost) == 2 and Dictionary(a.tally) == {"4/9": 1} and held > 0.4, "endings": a.endings, "gates": a.gates, "lost": int(a.lost), "stopped_m_before_the_fork": snappedf(held, 0.01)})
		_save()
		# prune B
		await _go(work.node_point(2, 1))
		await _go(work.node_point(1, 0))
		await _go(work.node_point(0, 0))
		await _press("prune_b")
		var b: Dictionary = work.state()
		var shared: Array = Array(b.endings).filter(func(id): return Array(a.endings).has(id))
		checks.append({"check": "PRUNE B: eight endings again and the same entropy, none of them A's eight; the third bead lost", "ok": int(b.count) == 8 and is_equal_approx(float(b.equal_H), float(a.equal_H)) and shared.is_empty()
			and int(b.lost) == 3 and Dictionary(b.tally).is_empty(), "endings": b.endings, "shared_with_A": shared, "lost": int(b.lost)})
		_save()
		await _press("open")
		var open: Dictionary = work.state()
		checks.append({"check": "OPEN: sixteen endings, no beads, three arrivals still counted as lost", "ok": int(open.count) == 16 and Dictionary(open.tally).is_empty() and int(open.beads) == 0 and int(open.lost) == 3
			and str(open.closed_words).contains("OPEN returns the endings, not the arrivals"), "lost": int(open.lost), "says": str(open.closed_words)})
		_save()
		# ask for a third way at the third last fork (L R L), and take it
		await _walk(2, 0, 3)
		await _stand()
		var asked: Dictionary = work.state()
		await _go(work.asked_point(2))
		for i in 10: await physics_frame
		var arrived: Dictionary = work.state()
		await _shot(work.node_point(2, 1) + Vector3(-2.2, 2.6, 1.6), work.asked_point(2) + Vector3(0, 0.3, 0), "asked.png")
		checks.append({"check": "a third way asked for at a last fork: seventeen endings, and the walker arrives at one nobody drew", "ok": Array(asked.asked) == [2] and int(asked.count) == 17 and absf(float(asked.equal_H) - 2.8332) < 0.0002
			and Dictionary(arrived.tally) == {"asked/2": 1} and str(arrived.here).ends_with("L R L +") and str(arrived.board).contains("1 branch asked for"), "count": int(asked.count), "equal_H": float(asked.equal_H),
			"tally": arrived.tally, "here": str(arrived.here)})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[drawn_tree_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
