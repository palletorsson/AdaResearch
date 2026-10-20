extends SceneTree
## Input -> actual projectile -> actual tile collider. No direct reaction calls.
const OUT := "res://ada_run/biome_transform_tiles/"
var checks: Array[Dictionary] = []
var sent: Array[Node3D] = []
var world: Node3D
var arena: Node3D
var ability: Node3D
var current_stage := 0

func _initialize() -> void: run.call_deferred()
func check(label: String, ok: bool) -> void:
	label = "Stage %d / %s" % [current_stage, label]
	checks.append({"label": label, "pass": ok})
	print("[tiles] ", "PASS " if ok else "FAIL ", label)

func click(button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button; event.pressed = true
	event.position = root.get_visible_rect().size * 0.5
	root.push_input(event)
	event = event.duplicate(); event.pressed = false; root.push_input(event)

func aim(at: Vector3, target: Vector3) -> void:
	world.walker.position = at; world.walker.head.look_at(target)
	await create_timer(0.4).timeout

func shoot(target: Vector3) -> Node3D:
	await aim(Vector3(0, 0.12, 8.2), target)
	var count := sent.size(); click()
	check("Real input sends a ball", sent.size() == count + 1)
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
	await aim(Vector3(0.3, 0.12, 8.2), Vector3(0, 0.15, 1.5))
	for tick in range(6): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT + name + ".png")

func run() -> void:
	create_timer(150).timeout.connect(func(): push_error("Tile probe timed out"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	var capacity := root.get_node("CatalystCapabilityManager")
	capacity.progression_file = OUT + "isolated-capacity.json"
	var earned: bool = capacity.has_first_catalyst()
	ability = capacity.first_catalyst
	ability.form_sent.connect(func(shot): sent.append(shot))
	world = load("res://commons/hazards/biome_ladder/ladder_world.tscn").instantiate()
	root.add_child(world); current_scene = world
	for tick in range(600):
		await process_frame
		if world.is_map_ready(): break
	check("World and desktop adapter ready", world.is_map_ready() and is_instance_valid(ability.desktop_source))
	world.walker.set_physics_process(false); world.walker.camera.make_current()
	for stage in [1, 2, 3]: await exercise_stage(stage)
	current_stage = 0
	world.change_stage(0); await physics_frame; await physics_frame
	arena = world.arena
	await shoot(Vector3(1, 0, 5))
	check("Primitives retains its original unchanging floor", arena.floor_tile_hits.is_empty() and arena.floor_marks.is_empty())
	world.queue_free(); await process_frame; await physics_frame
	check("Exit restores saved museum unlock", ability.unlocked == earned and capacity.has_first_catalyst() == earned)
	check("Exit removes the local ability callback", ability.form_sent.get_connections().size() == 1)
	var failed := checks.filter(func(c): return not c.pass).size()
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failed, "total": checks.size(), "checks": checks, "rendered": DisplayServer.get_name() != "headless", "source_sha256": FileAccess.get_sha256("res://commons/hazards/biome_ladder/ladder_encounter.gd")}, "\t"))
	print("TRANSFORM TILES ", checks.size() - failed, "/", checks.size())
	quit(0 if failed == 0 else 1)

func exercise_stage(stage: int) -> void:
	current_stage = stage
	world.change_stage(stage); await physics_frame; await physics_frame
	arena = world.arena; arena.set_process(false); arena.clock = 8.0
	check("72 individually colliding tiles persist", arena.floor_tiles.size() == 72 and arena.floor_tile_bodies.size() == 72)
	await capture("before" if stage == 1 else "arrays-before" if stage == 2 else "colour-before")
	var result := floor_at(Vector3(1, 0, 5))
	check("Original tile surface and collider agree", result.get("collider") == arena.floor_tile_bodies[51] and is_equal_approx(result.position.y, 0.04))
	var shot := await shoot(Vector3(1, 0.04, 5))
	var tile: MeshInstance3D = arena.floor_tiles[51]
	check("First impact changes only the hit tile", arena.floor_tile_hits.size() == 1 and arena.floor_tile_hits.get(51) == 1)
	check("First impact scales to 0.8", tile.scale.is_equal_approx(Vector3.ONE * 0.8))
	check("First impact turns 22.5 degrees around Y", is_equal_approx(tile.rotation.y, deg_to_rad(22.5)))
	if stage < 3:
		check("Projectile remains black and white", is_instance_valid(shot) and is_equal_approx(shot._mesh_instance.material_override.albedo_color.r, shot._mesh_instance.material_override.albedo_color.g))
	else:
		check("Same hit also paints the transformed tile", arena.floor_marks.has(51) and tile.material_override.albedo_color.is_equal_approx(shot.color_primary))
	await physics_frame
	result = floor_at(Vector3(1, 0, 5))
	check("Scaled collider follows the drawn surface", result.get("collider") == arena.floor_tile_bodies[51] and is_equal_approx(result.position.y, 0.032))
	check("Neighbour tile stays unchanged", arena.floor_tiles[50].scale.is_equal_approx(Vector3.ONE) and arena.floor_tiles[50].rotation.is_zero_approx())
	arena.clock += 8.0; arena._update_floor()
	shot = await shoot(Vector3(1, 0.032, 5))
	if stage == 3:
		check("Repeated hit recolours the same rotating tile", tile.material_override.albedo_color.is_equal_approx(shot.color_primary))
	check("Repeated hit multiplies scale again (0.64)", tile.scale.is_equal_approx(Vector3.ONE * 0.64))
	check("Repeated hit adds another turn (45 degrees)", is_equal_approx(tile.rotation.y, deg_to_rad(45)) and arena.floor_tile_hits.get(51) == 2)
	await physics_frame
	result = floor_at(Vector3(1.8, 0, 5.8))
	check("Revealed gap has solid backing at floor level", result.get("collider") == arena.floor_body and is_equal_approx(result.position.y, 0.0))
	var kept_marks: Dictionary = arena.floor_marks.duplicate()
	shot = await shoot(Vector3(1.8, 0, 5.8))
	check("A backing hit cannot recolour a tile through the gap", arena.floor_marks == kept_marks)
	check("A shot into the gap cannot hit the old invisible tile", is_instance_valid(shot) and shot.has_hit and arena.floor_tile_hits.get(51) == 2 and arena.floor_tile_hits.size() == 1)
	await aim(Vector3(0, 0.12, 8.2), Vector3(2.2, 1.1, 6.5)); click()
	await create_timer(0.65).timeout
	check("Cover impacts do not transform tiles beneath them", sent.back().has_hit and arena.floor_tile_hits.get(51) == 2 and arena.floor_tile_hits.size() == 1)
	arena.rest()
	check("REST keeps the transformed tile", tile.scale.is_equal_approx(Vector3.ONE * 0.64))
	# Fall onto a revealed gap with the real desktop player body.
	world.walker.position = Vector3(1.8, 0.8, 5.8)
	world.walker.set_physics_process(true)
	await create_timer(0.8).timeout
	check("Player can stand in the revealed gap", world.walker.is_on_floor() and world.walker.position.y >= -0.05)
	world.walker.set_physics_process(false)
	# Existing held catalyst follows the same interaction.
	arena.catalyst.form_sent.connect(func(p): sent.append(p))
	await aim(Vector3(-1.5, 0, 10.8), arena.catalyst.global_position)
	click(MOUSE_BUTTON_RIGHT); await create_timer(0.3).timeout
	check("Existing catalyst can still be grabbed", is_instance_valid(world.walker.desktop_pointer.get("_held")))
	await shoot(Vector3(-1, 0.04, 5))
	check("Held catalyst also transforms the tile it hits", arena.floor_tile_hits.get(50) == 1 and arena.floor_tiles[50].scale.is_equal_approx(Vector3.ONE * 0.8))
	click(MOUSE_BUTTON_RIGHT); await physics_frame
	await shoot(Vector3(-1, 0.04, 3))
	await shoot(Vector3(1, 0.04, 3))
	await shoot(Vector3(1, 0.032, 3))
	await create_timer(1.2).timeout
	arena.clock = 8.0; arena._update_floor()
	await capture("after" if stage == 1 else "arrays-after" if stage == 2 else "colour-after")
	arena.reset_round(); await physics_frame
	check("RESET clears tile hit history and marks", arena.floor_tile_hits.is_empty() and arena.floor_marks.is_empty())
	check("RESET restores all tile poses", arena.floor_tiles.all(func(t): return t.scale.is_equal_approx(Vector3.ONE) and t.rotation.is_zero_approx() and is_equal_approx(t.position.y, 0.02)))
	result = floor_at(Vector3(1.8, 0, 5.8))
	check("RESET restores the tile collider over the former gap", result.get("collider") == arena.floor_tile_bodies[51] and is_equal_approx(result.position.y, 0.04))
