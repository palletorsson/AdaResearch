extends SceneTree
## Actual input and projectile flights; painting callbacks are never invoked by the test.
const OUT := "res://ada_run/biome_colour_floor/"
var checks: Array[Dictionary] = []
var sent: Array[Node3D] = []
var world: Node3D
var arena: Node3D
var ability: Node3D

func _initialize() -> void: run.call_deferred()

func check(label: String, ok: bool) -> void:
	checks.append({"label": label, "pass": ok})
	print("[colour] ", "PASS " if ok else "FAIL ", label)

func click(button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button; event.pressed = true
	event.position = root.get_visible_rect().size * 0.5
	root.push_input(event)
	event = event.duplicate(); event.pressed = false; root.push_input(event)

func aim(at: Vector3, target: Vector3) -> void:
	world.walker.position = at
	world.walker.head.look_at(target)
	await create_timer(0.4).timeout

func shot_seen(shot: Node3D) -> void: sent.append(shot)

func shoot_floor(at: Vector3) -> Node3D:
	await aim(Vector3(0, 0.12, 8.2), at)
	var count := sent.size()
	click()
	check("Mouse sends a real hand projectile", sent.size() == count + 1)
	if sent.size() == count: return null
	var shot: Node3D = sent.back()
	for tick in range(150):
		await physics_frame
		if not is_instance_valid(shot) or shot.has_hit: break
	return shot

func capture(name: String) -> void:
	await aim(Vector3(0.3, 0.12, 8.2), Vector3(0, 0.6, -1))
	for tick in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func run() -> void:
	create_timer(100).timeout.connect(func(): push_error("Colour floor probe timed out"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	var capacity := root.get_node("CatalystCapabilityManager")
	capacity.progression_file = OUT + "isolated-capacity.json"
	var earned: bool = capacity.has_first_catalyst()
	ability = capacity.first_catalyst
	ability.form_sent.connect(shot_seen)
	world = load("res://commons/hazards/biome_ladder/ladder_world.tscn").instantiate()
	root.add_child(world); current_scene = world
	for tick in range(600):
		await process_frame
		if world.is_map_ready(): break
	check("World ready with actual desktop adapter", world.is_map_ready() and is_instance_valid(ability.desktop_source))
	world.walker.set_physics_process(false)
	world.walker.camera.make_current()
	for stage in range(3):
		world.change_stage(stage); await physics_frame; await physics_frame
		arena = world.arena
		var shot := await shoot_floor(Vector3(1, 0, 5))
		check("Stage %d floor hit has no colour mark" % stage, is_instance_valid(shot) and shot.has_hit and arena.floor_marks.is_empty())
		check("Stage %d projectile remains monochrome" % stage, is_instance_valid(shot) and is_equal_approx(shot._mesh_instance.material_override.albedo_color.r, shot._mesh_instance.material_override.albedo_color.g))
		arena.rest()
	world.change_stage(3); await physics_frame; await physics_frame
	arena = world.arena
	arena.set_process(false); arena.clock = 8.0; arena._update_floor()
	arena.catalyst.form_sent.connect(shot_seen)
	await capture("before")
	var shot := await shoot_floor(Vector3(1, 0, 5))
	check("Hand ball paints exactly its receiving tile", arena.floor_marks.size() == 1 and arena.floor_marks.has(51))
	var first_colour: Color = shot.color_primary if is_instance_valid(shot) else Color.BLACK
	check("Floor matches the ball's visible colour", arena.floor_tiles[51].material_override.albedo_color.is_equal_approx(first_colour))
	check("Another tile sharing the disco palette remains unmarked", arena.floor_tiles[46].material_override == arena.floor_materials[11])
	var untouched: Color = arena.floor_tiles[46].material_override.albedo_color
	arena.clock += 8.0; arena._update_floor()
	check("Untouched disco continues to change", not arena.floor_tiles[46].material_override.albedo_color.is_equal_approx(untouched))
	check("Marked tile keeps its colour through disco cycles", arena.floor_tiles[51].material_override.albedo_color.is_equal_approx(first_colour))
	arena.rest(); await physics_frame
	check("REST retains the mark", arena.floor_marks.has(51))
	shot = await shoot_floor(Vector3(1, 0, 5))
	check("A later real hit recolours the same tile", arena.floor_marks.size() == 1 and not arena.floor_tiles[51].material_override.albedo_color.is_equal_approx(first_colour))
	# Hit an actual standing refuge: the ground beneath it must remain untouched.
	var mark_count: int = arena.floor_marks.size()
	await aim(Vector3(0, 0.12, 8.2), Vector3(2.2, 1.1, 6.5))
	click(); await create_timer(0.65).timeout
	check("A cover hit does not paint the floor below", sent.back().has_hit and arena.floor_marks.size() == mark_count)
	# The held sphere uses its existing grab and trigger path, too.
	await aim(Vector3(-1.5, 0, 10.8), arena.catalyst.global_position)
	click(MOUSE_BUTTON_RIGHT); await create_timer(0.3).timeout
	check("Existing sphere can be picked up", is_instance_valid(world.walker.desktop_pointer.get("_held")))
	await aim(Vector3(0, 0.12, 8.2), Vector3(-1, 0, 5))
	var count := sent.size(); click(); await create_timer(0.7).timeout
	check("Held sphere emits its real projectile", sent.size() == count + 1)
	check("Held sphere floor hit also leaves colour", arena.floor_marks.has(50))
	click(MOUSE_BUTTON_RIGHT); await physics_frame
	# Actual head firing, aimed at empty floor. Isolate from automatic attacks.
	var retained: Dictionary = arena.floor_marks.duplicate()
	arena.start_round()
	for head in arena.heads: head.set_physics_process(false)
	check("START keeps previous marks", arena.floor_marks == retained)
	arena.reset_round(); arena.start_round()
	var head: Node3D = arena.heads[1]
	# The stored list now announces an explicit landing on the tile at (1, -3).
	head.begin_telegraph(Vector3(0.25, 0.8, -2))
	var ball: Node3D = head.throw_ball()
	var hostile_colour: Color = ball.tint
	for tick in range(600):
		await physics_frame
		if not is_instance_valid(ball): break
	check("A real skull ball paints its announced floor landing", arena.floor_marks.has(27))
	check("Skull mark matches that ball's tint", arena.floor_tiles[27].material_override.albedo_color.is_equal_approx(hostile_colour))
	# Head impacts should still defeat a head, without projecting colour onto the floor.
	mark_count = arena.floor_marks.size()
	await aim(Vector3(-0.8, 0.12, 0.2), head.global_position)
	click(); await create_timer(0.7).timeout
	check("Catalyst still defeats an active head", head.destroyed)
	check("Head impact leaves the floor unchanged", arena.floor_marks.size() == mark_count)
	arena.rest()
	# Preserve actual player-made and head-made marks for the native capture.
	for pos in [Vector3(-1, 0, 5), Vector3(1, 0, 5), Vector3(-1, 0, 3), Vector3(1, 0, 1)]:
		arena.clock += 8.0; arena._update_floor()
		await shoot_floor(pos)
	await create_timer(1.2).timeout
	arena.clock = 8.0; arena._update_floor()
	await capture("after")
	check("All marks survive REST and projectile cleanup", arena.floor_marks.size() >= 5)
	# Translate the encounter: floor addressing must use its own reference frame.
	arena.reset_round(); arena.position.x = 20.0
	head = arena.heads[1]; head.set_active(true)
	head.begin_telegraph(Vector3(0.25, 0.8, -2)); ball = head.throw_ball()
	for tick in range(600):
		await physics_frame
		if not is_instance_valid(ball): break
	check("Translated arena marks the correct local tile", arena.floor_marks.size() == 1 and arena.floor_marks.has(27))
	arena.position.x = 0.0
	arena.reset_round(); await physics_frame
	check("RESET clears every mark", arena.floor_marks.is_empty())
	check("RESET restores original shared palette materials", arena.floor_tiles[33].material_override == arena.floor_materials[8] and arena.floor_tiles[51].material_override == arena.floor_materials[11])
	world.change_stage(0); await physics_frame; await physics_frame
	check("Leaving Colour removes the ability's colour callback", ability.form_sent.get_connections().size() == 1)
	world.change_stage(3); await physics_frame; await physics_frame
	check("Re-entering Colour starts with a clean floor", world.arena.floor_marks.is_empty())
	world.queue_free(); await process_frame; await physics_frame
	check("Exit restores saved museum ability", ability.unlocked == earned and capacity.has_first_catalyst() == earned)
	check("Exit releases colour callback", ability.form_sent.get_connections().size() == 1)
	var failed := checks.filter(func(c): return not c.pass).size()
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failed, "total": checks.size(), "rendered": DisplayServer.get_name() != "headless", "checks": checks, "source_sha256": FileAccess.get_sha256("res://commons/hazards/biome_ladder/ladder_encounter.gd")}, "\t"))
	print("COLOUR FLOOR ", checks.size() - failed, "/", checks.size())
	quit(0 if failed == 0 else 1)
