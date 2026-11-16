extends SceneTree
## THE WAY ROUND on its floor (SpeculativeComputation_Rhizome_Network; the pass, 2026-11-16)
## A plank footbridge into the cave's near mouth, a panel gangway from its far mouth back round its east side, and
## a last panel that plates lay and lift. Read in the running tower with its own walker:
##   at rest: the panel is up, one way; nothing lies across the gap at the east wing, and the gangway beyond it
##     holds;
##   the walker crosses the footbridge and stands inside the near mouth, on the cave's floor;
##   it walks the cave's ground passages from the near mouth to the far mouth; the tower counts a place in the
##     upper passage as this floor;
##   out of the far mouth and round the outside to the gangway's end: 1.7 m from the floor, and no way on;
##   it stands on the gangway's plate: the panel is laid, two ways; it walks on over the panel onto the east wing;
##   it stands on the floor's plate: the panel is lifted again; nothing lies across the gap;
##   the axis: `laid` is found with the panel down and two ways; `up` restores.
##
##   godot --path <stage> --script res://tools/probes/way_round_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## way.json: checks with what was read (written after every check). arrival.png, edge.png, mouth.png,
## outside.png, gap.png.
const ID := "way-round"
const CAVE := "f2_rhizome_cave_demo_15_18"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var passages: Node3D
var eye: SubViewport
var cam: Camera3D
var folder := ""
var result := {}
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("way.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 12: await physics_frame
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, ticks: int = 2400) -> void:
	for i in ticks:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.09: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -(0.5 if d > 0.5 else 0.25))
		await physics_frame
	body.drive = Vector2.ZERO


func _apart(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()


## Does anything of the work lie under a place, within a metre and a half below floor level?
func _held(at: Vector3) -> bool:
	var query := PhysicsRayQueryParameters3D.create(Vector3(at.x, level + 1.0, at.z), Vector3(at.x, level - 1.5, at.z))
	query.exclude = [body.get_rid()]
	var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
	return not hit.is_empty()


func _press(key: String) -> Dictionary:
	await _go(work.plate_point(key))
	for i in 100: await physics_frame
	return work.state()


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
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]) and game.building.content.exhibits.has("%d/%s" % [floor, CAVE]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	var cave_mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, CAVE])
	var cave: Node = cave_mount.get_node_or_null("Artifact") if cave_mount != null else null
	if work != null and work.has_method("ways") and cave != null:
		for i in 2400:
			passages = cave.get_node_or_null("InhabitableRhizome")
			if passages != null and bool(passages.get("ready_to_walk")) and bool(work.state().gangway_done): break
			await physics_frame
		for i in 120: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		cam = Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		game.place_player(Vector3(-13.5, level + 0.3, 7.6))        # out of its own arrival picture
		for i in 30: await physics_frame
		await _shot(Vector3(0, level + 1.65, 7.8), Vector3(0, level + 1.5, 0), "arrival.png")
		await _shot(Vector3(0, level + 1.65, -6.0), Vector3(0, level + 1.4, -16.0), "edge.png")
		await _shot(Vector3(24.0, level + 9.0, -6.0), Vector3(6.0, level + 0.5, -28.0), "outside.png")
		work.apply_grid_config({"panel": "laid"})
		work.apply_grid_config({"panel": "up"})
		var s: Dictionary = work.state()
		var gap := Vector3(16.0, 0, -10.0)
		checks.append({"check": "at rest: the panel is up, one way; nothing lies across the gap at the east wing, and the gangway beyond it holds", "ok": passages != null and str(s.panel) == "up" and int(s.ways) == 1
			and not bool(s.last_panel_solid) and not _held(gap) and _held(Vector3(16.0, 0, -13.0)) and _held(Vector3(8.0, 0, -44.7)), "parts": int(s.parts), "gangway_done": bool(s.gangway_done), "build_ms": int(s.build_ms)})
		_save()
		# the footbridge
		game.place_player(Vector3(0, level + 0.3, -7.6))
		for i in 30: await physics_frame
		var inside := Vector3(0, 0, -16.9)
		await _go(inside)
		for i in 20: await physics_frame
		var at_mouth: float = _apart(body.global_position, inside)
		var feet: float = body.global_position.y - level
		await _shot(Vector3(0.9, level + 1.6, -11.5), Vector3(0, level + 1.3, -19.0), "mouth.png")
		checks.append({"check": "the walker crosses the footbridge and stands inside the near mouth, on the cave's floor", "ok": at_mouth < 0.15 and absf(feet) < 0.5, "from_the_place_m": snappedf(at_mouth, 0.01), "feet_above_floor_m": snappedf(feet, 0.01)})
		_save()
		# through the cave, on its ground passages: the places 0, 2, 4, 7, 8 of its own list
		var points: Array = passages.get("points")
		var reached := []
		for index in [0, 2, 4, 7, 8]:
			var place: Vector3 = passages.to_global(points[index])
			await _go(place)
			reached.append(snappedf(_apart(body.global_position, place), 0.01))
			_save()
		var upper: Vector3 = passages.to_global(points[12]) + Vector3(0, 1.0, 0)
		var counted: int = game.floor_stream.floor_at_position(upper) if game.get("floor_stream") != null else -1
		checks.append({"check": "it walks the cave's ground passages from the near mouth to the far mouth; the tower counts a place in the upper passage as this floor", "ok": reached.all(func(d): return d < 0.2)
			and absf(body.global_position.y - level) < 0.6 and counted == floor, "short_of_each_place_m": reached, "upper_passage_counted_as_floor": counted, "upper_passage_at": [snappedf(upper.x, 0.1), snappedf(upper.y - level, 0.1), snappedf(upper.z, 0.1)]})
		_save()
		# out of the far mouth and round the outside
		for place in [Vector3(0, 0, -44.7), Vector3(16.0, 0, -44.7), Vector3(16.0, 0, -11.0)]:
			await _go(place)
			_save()
		var end: float = _apart(body.global_position, Vector3(16.0, 0, -11.0))
		await _shot(Vector3(16.0, level + 1.65, -13.5), Vector3(16.0, level + 0.6, -8.0), "gap.png")
		checks.append({"check": "out of the far mouth and round the outside to the gangway's end: 1.7 m from the floor, and no way on", "ok": end < 0.15 and absf(body.global_position.y - level) < 0.5 and not _held(gap)
			and str(work.state().panel) == "up", "from_the_gangway_end_m": snappedf(end, 0.01), "to_the_floor_edge_m": snappedf(absf(body.global_position.z + 9.0), 0.01)})
		_save()
		# the plate on the gangway lays the panel
		var laid: Dictionary = await _press("gangway")
		await _go(Vector3(16.0, 0, -8.2))
		var over: float = _apart(body.global_position, Vector3(16.0, 0, -8.2))
		checks.append({"check": "it stands on the gangway's plate: the panel is laid, two ways; it walks on over the panel onto the east wing", "ok": str(laid.panel) == "laid" and int(laid.ways) == 2 and bool(laid.last_panel_solid)
			and _held(gap) and over < 0.15 and absf(body.global_position.y - level) < 0.3, "ways": int(laid.ways), "from_the_wing_place_m": snappedf(over, 0.01), "status": str(laid.status)})
		_save()
		var lifted: Dictionary = await _press("floor")
		checks.append({"check": "it stands on the floor's plate: the panel is lifted again; nothing lies across the gap", "ok": str(lifted.panel) == "up" and int(lifted.ways) == 1 and not _held(gap), "status": str(lifted.status)})
		_save()
		work.apply_grid_config({"panel": "laid"})
		var found: Dictionary = work.state()
		var held_then: bool = _held(gap)
		work.apply_grid_config({"panel": "up"})
		var back: Dictionary = work.state()
		checks.append({"check": "the axis: `laid` is found with the panel down and two ways; `up` restores", "ok": str(found.panel) == "laid" and int(found.ways) == 2 and bool(found.last_panel_shown) and str(back.panel) == "up" and not bool(back.last_panel_shown),
			"laid_holds": held_then})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work and the cave", "ok": false})
	_save()
	print("[way_round_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
