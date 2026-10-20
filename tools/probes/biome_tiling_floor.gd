extends SceneTree
## Real input and real projectile collisions. No direct pattern-handler calls.
const OUT := "res://ada_run/biome_tiling_floor/"
const COPIES := [1, 3, 5, 13, 15, 17, 25, 27, 29, 37, 39, 41, 49, 51, 53, 61, 63, 65]
var checks: Array[Dictionary] = []
var sent: Array[Node3D] = []
var world: Node3D
var arena: Node3D
var ability: Node3D
var actual_hit: Node3D

func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	checks.append({"label": label, "pass": ok})
	print("[tiling] ", "PASS " if ok else "FAIL ", label)

func click(button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button; event.pressed = true
	event.position = root.get_visible_rect().size * 0.5
	root.push_input(event)
	event = event.duplicate(); event.pressed = false; root.push_input(event)

func aim(at: Vector3, target: Vector3) -> void:
	world.walker.position = at; world.walker.head.look_at(target)
	await create_timer(0.4).timeout

func shoot(target: Vector3, from: Vector3 = Vector3(0, 0.12, 8.2)) -> Node3D:
	await aim(from, target)
	var count := sent.size(); click()
	check("Input sends exactly one real ball", sent.size() == count + 1)
	if sent.size() == count: return null
	var shot: Node3D = sent.back()
	for tick in range(150):
		await physics_frame
		if not is_instance_valid(shot) or shot.has_hit: break
	return shot

func floor_at(at: Vector3) -> Dictionary:
	var ray := PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.3, at + Vector3.DOWN * 0.3, 1)
	return world.get_world_3d().direct_space_state.intersect_ray(ray)

func capture(name: String) -> void:
	await aim(Vector3(0.3, 0.12, 8.2), Vector3(0, 0.05, 0))
	for tick in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func run() -> void:
	create_timer(100).timeout.connect(func(): push_error("Tiling probe timed out"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	var capacity := root.get_node("CatalystCapabilityManager")
	capacity.progression_file = OUT + "isolated-capacity.json"
	var earned: bool = capacity.has_first_catalyst()
	ability = capacity.first_catalyst
	ability.form_sent.connect(func(shot):
		sent.append(shot)
		actual_hit = null
		shot.projectile_hit.connect(func(body, _at): actual_hit = body))
	world = load("res://commons/hazards/biome_ladder/ladder_world.tscn").instantiate()
	root.add_child(world); current_scene = world
	for tick in range(600):
		await process_frame
		if world.is_map_ready(): break
	check("World and desktop adapter ready", world.is_map_ready() and is_instance_valid(ability.desktop_source))
	world.walker.set_physics_process(false); world.walker.camera.make_current()
	# The new fifth stage must actually be reachable through the in-world console.
	await aim(Vector3(3.8, 0, 11.0), Vector3(3.8, 1.17, 9.6))
	check("Desktop pointer reaches stage 5 control", world.walker.desktop_pointer.has_hover_target())
	click(); await physics_frame; await physics_frame
	arena = world.arena
	check("Stage control loads Tiling without firing", arena.stage == 4 and sent.is_empty())
	if arena.stage != 4: quit(1); return
	arena.set_process(false); arena.clock = 24.0; arena._update_floor()
	check("Tiling inherits 72 colliding tiles and moving cover", arena.floor_tiles.size() == 72 and arena.floor_tile_bodies.size() == 72 and arena.motions.size() == 8)
	await capture("before")
	var shot := await shoot(Vector3(1, 0.04, 5))
	var tint: Color = shot.color_primary
	check("One impact repeats onto exactly 18 tiles", arena.floor_tile_hits.size() == 18 and arena.floor_marks.size() == 18)
	check("Copies occupy the same address in every 2 x 2 group", COPIES.all(func(i): return arena.floor_tile_hits.get(i) == 1))
	check("Every copy inherits scale, rotation and the ball colour", COPIES.all(func(i): return arena.floor_tiles[i].scale.is_equal_approx(Vector3.ONE * 0.8) and is_equal_approx(arena.floor_tiles[i].rotation.y, deg_to_rad(22.5)) and arena.floor_tiles[i].material_override.albedo_color.is_equal_approx(tint)))
	check("Other motif addresses remain unchanged", arena.floor_tiles[50].scale == Vector3.ONE and arena.floor_tiles[44].scale == Vector3.ONE and arena.floor_tiles[45].scale == Vector3.ONE and not arena.floor_marks.has(50))
	await physics_frame
	var hit := floor_at(Vector3(1, 0, 1))
	check("A distant copy collider follows its 0.8 scale", hit.get("collider") == arena.floor_tile_bodies[39] and is_equal_approx(hit.position.y, 0.032))
	await capture("one-shot")
	arena.clock = 32.0; arena._update_floor()
	shot = await shoot(Vector3(1, 0.032, 1))
	tint = shot.color_primary
	check("Hitting another copy updates the same motif once", arena.floor_tile_hits.size() == 18 and COPIES.all(func(i): return arena.floor_tile_hits.get(i) == 2))
	check("All copies reach 0.64 scale, 45 degrees and the new colour", COPIES.all(func(i): return arena.floor_tiles[i].scale.is_equal_approx(Vector3.ONE * 0.64) and is_equal_approx(arena.floor_tiles[i].rotation.y, deg_to_rad(45)) and arena.floor_marks[i].is_equal_approx(tint)))
	await physics_frame
	hit = floor_at(Vector3(1.8, 0, 5.8))
	check("Pattern gaps retain solid backing", hit.get("collider") == arena.floor_body and is_equal_approx(hit.position.y, 0.0))
	var kept_marks: Dictionary = arena.floor_marks.duplicate()
	# Shoot down into the gap: the old diagonal flight could hit the former cover box.
	shot = await shoot(Vector3(1.8, 0, 5.8), Vector3(1.8, 1.4, 6.0))
	check("Backing impact cannot create a hidden pattern", shot.has_hit and actual_hit == arena.floor_body and arena.floor_marks == kept_marks and COPIES.all(func(i): return arena.floor_tile_hits.get(i) == 2))
	var refuge: Node3D = arena.get_node("PrimitiveCover_0_Right")
	await aim(refuge.position + Vector3(0, -refuge.position.y + 0.12, 2.5), refuge.position); click()
	await create_timer(0.65).timeout
	check("Cover impact does not repeat through the floor", sent.back().has_hit and actual_hit == refuge and arena.floor_marks == kept_marks and arena.floor_tile_hits.size() == 18)
	arena.rest()
	check("REST keeps the repeated pattern", arena.floor_marks == kept_marks and arena.floor_tile_hits.size() == 18)
	world.walker.position = Vector3(1.8, 0.8, 5.8); world.walker.set_physics_process(true)
	await create_timer(0.8).timeout
	check("Real player can stand between pattern tiles", world.walker.is_on_floor() and world.walker.position.y >= -0.05)
	world.walker.set_physics_process(false)
	# The held catalyst uses exactly the same source/copy response.
	arena.catalyst.form_sent.connect(func(p): sent.append(p))
	await aim(Vector3(-1.5, 0, 10.8), arena.catalyst.global_position)
	click(MOUSE_BUTTON_RIGHT); await create_timer(0.3).timeout
	check("Existing sphere can still be picked up", is_instance_valid(world.walker.desktop_pointer.get("_held")))
	arena.clock = 4.0; arena._update_floor()
	shot = await shoot(Vector3(-1, 0.04, 5))
	check("Held sphere adds a second independent motif address", arena.floor_tile_hits.size() == 36 and arena.floor_tile_hits.get(50) == 1 and arena.floor_tile_hits.get(48) == 1 and arena.floor_tile_hits.get(0) == 1 and arena.floor_tile_hits.get(51) == 2)
	check("Second address uses its own colour", arena.floor_marks[50].is_equal_approx(shot.color_primary) and not arena.floor_marks[50].is_equal_approx(arena.floor_marks[51]))
	click(MOUSE_BUTTON_RIGHT); await physics_frame
	await create_timer(1.2).timeout
	arena.clock = 24.0; arena._update_floor()
	await capture("after")
	# Extra oblique view shows the complete 3 x 6 repetition; geometry is untouched.
	var camera := Camera3D.new(); world.add_child(camera)
	camera.position = Vector3(10, 12, 16); camera.look_at(Vector3(0, 0, -1)); camera.make_current()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + "overview.png")
	world.walker.camera.make_current(); camera.queue_free()
	arena.reset_round(); await physics_frame
	check("RESET clears every copied hit and mark", arena.floor_tile_hits.is_empty() and arena.floor_marks.is_empty())
	check("RESET restores all poses", arena.floor_tiles.all(func(t): return t.scale.is_equal_approx(Vector3.ONE) and t.rotation.is_zero_approx() and is_equal_approx(t.position.y, 0.02)))
	hit = floor_at(Vector3(1.8, 0, 5.8))
	check("RESET restores collider over former gap", hit.get("collider") == arena.floor_tile_bodies[51] and is_equal_approx(hit.position.y, 0.04))
	# Inherited head paint is still local; it can interrupt our pattern.
	arena.start_round()
	arena.set_physics_process(false) # Isolate this flight from the shared volley scheduler.
	for head in arena.heads: head.set_physics_process(false)
	var head: Node3D = arena.heads[7]
	head.begin_telegraph(Vector3(0.25, 0.8, 5.0))
	var ball: Node3D = head.throw_ball()
	actual_hit = null
	ball.surface_hit.connect(func(body, _at): actual_hit = body)
	var hostile_tint: Color = ball.tint
	for tick in range(240):
		await physics_frame
		if not is_instance_valid(ball): break
	var hit_index: int = arena.floor_tile_bodies.find(actual_hit) if actual_hit is StaticBody3D else -1
	check("Skull impact retains local colour without triggering player pattern", hit_index >= 0 and arena.floor_marks.size() == 1 and arena.floor_marks.get(hit_index) == hostile_tint and arena.floor_tile_hits.is_empty())
	arena.rest(); await shoot(Vector3(1, 0.04, 5))
	arena.start_round()
	check("New START also restores the floor", arena.floor_marks.is_empty() and arena.floor_tile_hits.is_empty())
	arena.rest()
	world.change_stage(3); await physics_frame; await physics_frame
	arena = world.arena
	await shoot(Vector3(1, 0.04, 5))
	check("Colour remains local: one hit, one tile", arena.floor_tile_hits.size() == 1 and arena.floor_marks.size() == 1)
	world.queue_free(); await process_frame; await physics_frame
	check("Exit restores saved museum unlock", ability.unlocked == earned and capacity.has_first_catalyst() == earned)
	check("Exit removes encounter callback", ability.form_sent.get_connections().size() == 1)
	var failed := checks.filter(func(c): return not c.pass).size()
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failed, "total": checks.size(), "checks": checks, "rendered": DisplayServer.get_name() != "headless", "source_sha256": FileAccess.get_sha256("res://commons/hazards/biome_ladder/ladder_encounter.gd")}, "\t"))
	print("TILING FLOOR ", checks.size() - failed, "/", checks.size())
	quit(0 if failed == 0 else 1)
