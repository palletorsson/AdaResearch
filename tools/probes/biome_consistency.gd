extends SceneTree
## B22: state continuity, readable warnings and finite shots. Native evidence, not headset play.
const Route := preload("res://commons/hazards/biome_ladder/route.gd")
const OUT := "res://ada_run/biome_consistency/"
var world: Node3D
var arena: Node3D
var checks: Array[Dictionary] = []
var prefix := "after"
var shots: Array[Node3D] = []
var impacts: Array[Dictionary] = []

func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"label": label, "pass": ok})
	print("[consistency] ", "PASS " if ok else "FAIL ", label)

func capture(file: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + prefix + "-" + file + ".png")

func stage(index: int) -> void:
	world.change_stage(index)
	await physics_frame; await physics_frame
	arena = world.arena
	arena.set_process(false); arena.set_physics_process(false)
	for head in arena.heads: head.set_physics_process(false)
	world.walker.set_physics_process(false)
	world.walker.position = arena.arrival
	world.walker.head.rotation = Vector3.ZERO
	world.walker.camera.make_current()
	await process_frame

func run() -> void:
	create_timer(160).timeout.connect(func(): push_error("Consistency probe timeout"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	root.get_node("CatalystCapabilityManager").progression_file = OUT + "isolated.json"
	prefix = "before" if "--before" in OS.get_cmdline_user_args() else "after"
	Route.selected_stage = 0
	world = load(Route.SCENE).instantiate(); root.add_child(world); current_scene = world
	for f in range(600):
		await process_frame
		if world.is_map_ready(): break
	check("World ready", world.is_map_ready())
	for index in range(6):
		await stage(index)
		await capture("stage-%d" % index)
	await stage(2)
	arena.start_round(); arena._begin_array_volley()
	await capture("row-warning")
	arena.rest(); arena.start_round(); arena.volley_step = 4; arena._begin_array_volley()
	await capture("column-warning")
	arena.rest()
	if prefix == "after": await verify()
	world.queue_free(); await process_frame; await physics_frame
	var passed := checks.filter(func(c): return c.pass).size()
	FileAccess.open(OUT + prefix + "-report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": passed, "total": checks.size(), "checks": checks}, "\t"))
	print("CONSISTENCY ", passed, "/", checks.size())
	quit(0 if passed == checks.size() else 1)

func verify() -> void:
	var ability: Node3D = root.get_node("CatalystCapabilityManager").first_catalyst
	ability.form_sent.connect(func(s): shots.append(s))
	for index in range(6):
		await stage(index)
		if index > 0:
			world.walker.position = Vector3(1, 2, 10)
			world.walker.head.look_at(Vector3(1, 0.04, 9))
			await create_timer(0.3).timeout
			var count := shots.size()
			var event := InputEventMouseButton.new(); event.button_index = MOUSE_BUTTON_LEFT; event.pressed = true
			root.push_input(event); event = event.duplicate(); event.pressed = false; root.push_input(event)
			for f in range(180):
				await physics_frame
				if not arena.floor_tile_hits.is_empty(): break
			check("Stage %d: actual desktop shot prepares the floor" % index, shots.size() == count + 1 and not arena.floor_tile_hits.is_empty())
		var hits: Dictionary = arena.floor_tile_hits.duplicate()
		var marks: Dictionary = arena.floor_marks.duplicate()
		var transforms: Array = arena.floor_tiles.map(func(t): return t.transform)
		world.walker.position = arena.arrival; world.walker.head.rotation = Vector3.ZERO
		arena.start_button._relay()
		check("Stage %d: START preserves the prepared floor" % index, arena.running and arena.floor_tile_hits == hits and arena.floor_marks == marks and arena.floor_tiles.map(func(t): return t.transform) == transforms)
		arena.heads[0].hit_by_catalyst_mode(Color.WHITE, "form")
		arena._on_ball_hit_player(world.walker)
		if index > 0: arena.pickups[0].body_entered.emit(world.walker)
		arena.hit_cooldown = 0
		arena._on_ball_hit_player(world.walker)
		var damage: int = arena.player_hits
		var health: float = root.get_node("GameManager").player_health
		var head: Node3D = arena.heads[1]
		head.begin_telegraph(arena.to_local(world.walker.camera.global_position))
		head.throw_ball()
		arena.rest_button._relay()
		await process_frame
		check("Stage %d: REST removes all shots and warnings" % index, not arena.running and arena.heads.all(func(h): return h.projectiles.is_empty() and not is_instance_valid(h.path_preview)) and ability.projectiles.is_empty())
		check("Stage %d: REST keeps floor, vacancy, health and pickups" % index, arena.floor_tile_hits == hits and arena.floor_marks == marks and arena.heads[0].destroyed and arena.player_hits == damage and (index == 0 or not arena.pickups[0].visible))
		check("Stage %d: resting button says RESUME" % index, arena.start_button.label == "RESUME" and arena.start_button.get_children().any(func(c): return c is Label3D and c.text == "RESUME"))
		arena.start_button._relay()
		check("Stage %d: RESUME retains work and earned round state" % index, arena.running and arena.floor_tile_hits == hits and arena.floor_marks == marks and arena.heads[0].destroyed and not arena.heads[0].active and arena.player_hits == damage and (index == 0 or (arena.collected == 1 and not arena.pickups[0].visible)))
		check("Stage %d: resume does not heal through GameManager" % index, is_equal_approx(root.get_node("GameManager").player_health, health))
		if index == 4:
			world.walker.head.look_at(Vector3(0, 0, 4))
			await capture("prepared-and-running")
		for h in arena.heads: h.hit_by_catalyst_mode(Color.WHITE, "form")
		arena.start_button._relay()
		check("Stage %d: CLEAR cannot silently respawn heads" % index, arena.completed and not arena.running and arena.heads.all(func(h): return h.destroyed))
		arena.reset_button._relay()
		check("Stage %d: RESET restores fresh state" % index, not arena.running and not arena.completed and arena.player_hits == 0 and arena.collected == 0 and arena.heads.all(func(h): return not h.destroyed) and arena.pickups.all(func(p): return p.visible) and arena.floor_tile_hits.is_empty() and arena.floor_marks.is_empty() and arena.start_button.label == "START")
	await projectile_checks()
	await live_clutter_check()

func projectile_checks() -> void:
	await stage(3)
	world.walker.position.x = -4.35
	var target := Marker3D.new(); world.add_child(target); target.position = Vector3(0, 1.72, 10.5)
	await physics_frame; await physics_frame
	for head in arena.heads:
		head.target_override = target; head.set_active(true)
		head.begin_telegraph(target.position)
		var path: PackedVector3Array = head.pending_path.duplicate()
		check("Slot %d: warning includes target then floor landing" % head.slot, path.size() == 6 and path[4].is_equal_approx(target.position) and path[5].y < 0.0)
		check("Slot %d: warning is a world-width mesh" % head.slot, head.path_preview.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() == (path.size() - 1) * 48)
		var ball: Node3D = head.throw_ball(); ball.set_physics_process(false)
		check("Slot %d: flight follows the exact announced list" % head.slot, ball.waypoints == path)
		ball.surface_hit.connect(func(body, at): impacts.append({"body": body, "at": at}))
		var initial := impacts.size()
		for f in range(400):
			ball._physics_process(0.05)
			if ball.spent: break
		check("Slot %d: missed shot hits an actual floor tile" % head.slot, impacts.size() == initial + 1 and impacts.back().body in arena.floor_tile_bodies)
		var drawing: Node3D = ball.get_node("StoredPositionPath")
		await process_frame
		check("Slot %d: impact removes ball and drawing together" % head.slot, not is_instance_valid(ball) and not is_instance_valid(drawing))
	check("Skull impacts leave coloured floor marks", not arena.floor_marks.is_empty())
	world.walker.position = arena.arrival
	world.walker.head.look_at(Vector3(1, 0, 10.8))
	await capture("skull-floor-landing")
	# Elevated evidence view: the console otherwise hides the final landing leg.
	var observer := Camera3D.new(); world.add_child(observer)
	observer.position = Vector3(-6.3, 4.5, 13.8)
	observer.look_at(Vector3(0, 1.8, 7)); observer.fov = 66; observer.make_current()
	arena.heads[1].begin_telegraph(target.position)
	await capture("landing-path")
	world.walker.camera.make_current(); observer.queue_free()
	# Owner-local bounds also work in a translated/rotated arena.
	arena.rest(); arena.position.x = 20; arena.rotation.y = 0.4
	var ball: Node3D = load("res://commons/hazards/biome_ladder/ladder_ball.gd").new()
	ball.arena_frame = arena; ball.position = Vector3(0, 5, 12.4)
	ball.direction = arena.basis * Vector3.BACK
	arena.add_child(ball); ball.set_physics_process(false); ball._physics_process(0.2)
	check("Miss leaving transformed arena bounds is spent", ball.spent and ball.is_queued_for_deletion())
	await process_frame
	arena.position.x = 0; arena.rotation = Vector3.ZERO
	ball = load("res://commons/hazards/biome_ladder/ladder_ball.gd").new()
	ball.position = Vector3(0, 30, 0)
	ball.waypoints = PackedVector3Array([ball.position, Vector3(0, 30, 0.5)])
	world.add_child(ball); ball.set_physics_process(false); ball._physics_process(1.0)
	check("Finite path ends without extrapolating beyond final position", ball.spent and ball.position.is_equal_approx(Vector3(0, 30, 0.5)))
	await process_frame
	target.queue_free()

func live_clutter_check() -> void:
	await stage(2)
	world.walker.position.x = -4.35
	var target := Marker3D.new(); world.add_child(target); target.position = Vector3(0, 1.72, 10.5)
	var sent_count := [0]
	for head in arena.heads:
		head.target_override = target
		head.ball_sent.connect(func(_shot): sent_count[0] += 1)
		head.set_physics_process(true)
	arena.set_process(true); arena.set_physics_process(true); arena.start_round()
	var max_balls := 0; var max_lines := 0
	var previous_scale := Engine.time_scale; Engine.time_scale = 3
	for f in range(640):
		await physics_frame
		var balls := arena.get_children().filter(func(c): return c.get_script() == load("res://commons/hazards/biome_ladder/ladder_ball.gd") and not c.is_queued_for_deletion()).size()
		var warnings: int = arena.heads.filter(func(h): return is_instance_valid(h.path_preview) and not h.path_preview.is_queued_for_deletion()).size()
		max_balls = maxi(max_balls, balls); max_lines = maxi(max_lines, balls + warnings)
	Engine.time_scale = previous_scale
	check("Normal volleys continue while misses resolve", sent_count[0] >= 18)
	check("Misses no longer accumulate three generations of guides", max_balls <= 6 and max_lines <= 6)
	print("[clutter] max balls ", max_balls, ", paths ", max_lines, ", sent ", sent_count[0])
	arena.rest(); target.queue_free()
