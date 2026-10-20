extends SceneTree
## Rendered input/physics test: inject real viewport events, never call send_form.
const OUT := "res://ada_run/biome_ladder_play/desktop/"
var checks: Array[Dictionary] = []
var sent := 0
var ability: Node3D

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"label": label, "pass": passed})
	print("[desktop] ", "PASS " if passed else "FAIL ", label)

func key(code: Key) -> void:
	var event := InputEventKey.new()
	event.keycode = code; event.physical_keycode = code; event.pressed = true
	root.push_input(event)
	event = event.duplicate(); event.pressed = false
	root.push_input(event)

func click(button: MouseButton = MOUSE_BUTTON_LEFT) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = button; event.pressed = true
	event.position = root.get_visible_rect().size * 0.5
	root.push_input(event)
	event = event.duplicate(); event.pressed = false
	root.push_input(event)

func load_world(path: String) -> Node3D:
	var world: Node3D = load(path).instantiate()
	root.add_child(world); current_scene = world
	for i in range(600):
		await process_frame
		if world.is_map_ready(): break
	world.walker.set_physics_process(false)
	world.walker.camera.make_current()
	return world

func aim(world: Node3D, position: Vector3, target: Vector3) -> void:
	world.walker.position = position
	world.walker.head.look_at(target)
	await create_timer(0.3).timeout

func run() -> void:
	create_timer(60).timeout.connect(func(): push_error("Desktop probe timed out"); quit(2))
	DirAccess.make_dir_recursive_absolute(OUT)
	var capacity := root.get_node("CatalystCapabilityManager")
	capacity.progression_file = OUT + "isolated-capacity.json"
	var earned: bool = capacity.has_first_catalyst()
	ability = capacity.first_catalyst
	ability.form_sent.connect(func(_shot): sent += 1)
	var world := await load_world("res://commons/hazards/biome_ladder/ladder_world.tscn")
	check("Desktop adapter attached to ladder", is_instance_valid(ability.desktop_source))
	check("Practice supplies ability without earning it", ability.unlocked and capacity.has_first_catalyst() == earned)
	check("Rendered test has captured mouse", Input.mouse_mode == Input.MOUSE_MODE_CAPTURED)
	check("Crosshair is centred and cannot consume clicks", world.walker.crosshair.get_global_rect().get_center().distance_to(root.get_visible_rect().size * 0.5) < 1.0 and world.walker.crosshair.mouse_filter == Control.MOUSE_FILTER_IGNORE)
	for stage in range(preload("res://commons/hazards/biome_ladder/route.gd").STAGES.size()):
		world.change_stage(stage)
		await physics_frame
		key(KEY_T)
		check("Stage %d keyboard starts encounter" % stage, world.arena.running)
		for head in world.arena.heads: head.set_physics_process(false)
		var head: CharacterBody3D = world.arena.heads[0]
		# Primitives now has real cover; aim from its open central lane.
		# Fire from the open flank, outside the taller cover inherited after B11.
		var firing_position: Vector3 = Vector3(0, 0, 6) if stage == 0 else head.position + Vector3(-0.8, -1.8, 3.2)
		await aim(world, firing_position, head.position)
		check("Stage %d empty hand forms a visible point" % stage, ability.formed and ability.sphere.visible)
		if stage == 0:
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUT + "aim.png")
		var before := sent
		click()
		check("Stage %d mouse click sends shared projectile" % stage, sent == before + 1)
		click()
		check("Stage %d repeated click respects cooldown" % stage, sent == before + 1)
		await create_timer(0.7).timeout
		check("Stage %d aimed projectile really hits skull" % stage, head.destroyed and head.incoming_hits == 1)
		key(KEY_R)
		check("Stage %d keyboard resets head and clears shots" % stage, not head.destroyed and not world.arena.running and ability.projectiles.is_empty())
		key(KEY_T); key(KEY_T)
		check("Stage %d keyboard rests encounter" % stage, not world.arena.running)

	# Cursor/typing/held-object/GUI clicks must not leak shots into the world.
	var before := sent
	key(KEY_ESCAPE)
	await create_timer(0.2).timeout
	click(); key(KEY_T)
	check("Visible cursor suppresses point, firing and start shortcut", not ability.formed and sent == before and not world.arena.running)
	key(KEY_ESCAPE)
	var typing := Node.new(); root.add_child(typing); typing.add_to_group("ada_typing")
	await create_timer(0.2).timeout
	click(); key(KEY_T)
	check("Typing suppresses firing and arena shortcuts", sent == before and not world.arena.running)
	typing.free()
	world.arena.player_dead = true
	await create_timer(0.2).timeout
	click(); key(KEY_R)
	check("Death suppresses firing and reset shortcut", sent == before and world.arena.player_dead and not ability.formed)
	world.arena.player_dead = false
	world.change_stage(0)
	await physics_frame
	await aim(world, Vector3(1.2, 0, 11.0), world.arena.start_button.global_position)
	check("Desktop pointer sees START control", world.walker.desktop_pointer.has_hover_target())
	click()
	check("START click operates control without firing", world.arena.running and sent == before)
	key(KEY_R)
	await aim(world, Vector3(-1.5, 0, 10.8), world.arena.catalyst.global_position)
	click(MOUSE_BUTTON_RIGHT)
	await create_timer(0.2).timeout
	check("Right click still picks up the existing catalyst", is_instance_valid(world.walker.desktop_pointer.get("_held")))
	check("Holding an object dismisses the practice point", not ability.formed)
	click()
	check("Held tool consumes left click without extra hand shot", sent == before)
	click(MOUSE_BUTTON_RIGHT)
	await aim(world, Vector3(0, 0, 8), Vector3(0, 1.8, 0))
	check("Releasing restores hand form", ability.formed)
	# Put a very close wall across the muzzle offset, while the reticle sees past it.
	var wall := StaticBody3D.new(); wall.collision_layer = 1
	world.add_child(wall)
	wall.global_position = world.walker.camera.to_global(Vector3(0.16, -0.16, -0.4))
	var shape := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(0.16, 0.16, 0.03); shape.shape = box; wall.add_child(shape)
	await physics_frame; await physics_frame
	click()
	check("Offset muzzle cannot shoot through close cover", sent == before)
	wall.queue_free()
	world.queue_free(); await process_frame; await physics_frame
	check("Leaving releases desktop adapter and restores earned ability", not is_instance_valid(ability.desktop_source) and ability.unlocked == earned)

	world = await load_world("res://commons/hazards/catalyst_counterpart/biome_arena.tscn")
	check("Mature biome uses the same desktop adapter", is_instance_valid(ability.desktop_source))
	key(KEY_T)
	var skull: CharacterBody3D = world.arena.skull
	skull.set_physics_process(false)
	await aim(world, skull.position + Vector3(0, -1.5, 2.5), skull.position)
	before = sent
	click()
	await create_timer(0.6).timeout
	check("Desktop projectile hits mature biome skull", sent == before + 1 and skull.incoming_hits == 1)
	key(KEY_R)
	check("Mature biome reset works", skull.incoming_hits == 0 and not world.arena.running)
	world.queue_free(); await process_frame; await physics_frame
	check("Final exit releases desktop source", not is_instance_valid(ability.desktop_source))
	var failed := checks.filter(func(c): return not c.pass).size()
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed": checks.size() - failed, "total": checks.size(), "checks": checks}, "\t"))
	print("DESKTOP CATALYST ", checks.size() - failed, "/", checks.size())
	quit(0 if failed == 0 else 1)
