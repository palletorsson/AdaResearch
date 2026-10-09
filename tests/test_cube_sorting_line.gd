extends Node
## Physical integration checks and optional native screenshots for the sorter.
## Run: python tools/run_cube_sorting_line.py [--capture]

const GAME := "res://commons/artifacts/cube_sorting_line/cube_sorting_line.tscn"
var checks: Array[Dictionary] = []
var world: Node3D
var game: Node3D
var camera: Camera3D
var pointer: Node3D
var screenshots: Array[String] = []


func _ready() -> void:
	_run.call_deferred()


func _check(ok: bool, label: String, detail: Variant = null) -> void:
	checks.append({"passed": ok, "check": label, "details": detail})
	print("%s: %s%s" % ["PASS" if ok else "FAIL", label, " " + str(detail) if detail != null else ""])


func _frames(count: int) -> void:
	for unused in count:
		await get_tree().physics_frame
		await get_tree().process_frame


func _build_world() -> void:
	world = Node3D.new()
	add_child(world)
	var floor_body := StaticBody3D.new()
	floor_body.position.y = -0.1
	world.add_child(floor_body)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30.0, 0.2, 30.0)
	shape.shape = box
	floor_body.add_child(shape)
	var mesh := MeshInstance3D.new()
	var floor_mesh := BoxMesh.new()
	floor_mesh.size = box.size
	mesh.mesh = floor_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("737d76")
	mat.roughness = 0.85
	mesh.material_override = mat
	floor_body.add_child(mesh)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("d8d3c5")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.35
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	world.add_child(env)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-52, -25, 0)
	light.light_energy = 0.45
	light.shadow_enabled = true
	world.add_child(light)
	camera = Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(7.8, 5.8, 9.0)
	camera.look_at(Vector3(0.0, 1.05, 0.0))
	camera.current = true
	camera.fov = 48.0
	pointer = load("res://commons/scenes/DesktopInteractionPointer.gd").new()
	world.add_child(pointer)
	# Exercise the real carry/drop hooks, without input or aim updating a fixture.
	pointer.set_process(false)


func _new_game(bounds: Rect2 = Rect2(-4.0, -3.5, 8.0, 7.0), height: float = 2.4) -> void:
	if is_instance_valid(game):
		game.queue_free()
		await _frames(3)
	game = load(GAME).instantiate()
	game.auto_start = false
	game.backlog_bounds = bounds
	game.backlog_height = height
	world.add_child(game)
	await _frames(4)


func _ledger(label: String) -> void:
	var state: Dictionary = game.get_state()
	var expected := int(state.active) + int(state.stored) + int(state.sorting) + int(state.sorted)
	_check(int(state.produced) == expected, label + ": every produced cube remains accounted for", state)


func _cube_at(at: Vector3, kind: int = 0) -> RigidBody3D:
	var cube: RigidBody3D = game.spawn_cube()
	if not is_instance_valid(cube): return null
	cube.position = at
	cube.linear_velocity = Vector3.ZERO
	cube.angular_velocity = Vector3.ZERO
	if kind >= 0: game.stamp_cube(cube, kind)
	return cube


func _edge(cube: RigidBody3D) -> float:
	for shape in cube.find_children("*", "CollisionShape3D", true, false):
		if shape.shape is BoxShape3D: return float(shape.shape.size.x) * shape.scale.x
	return -1.0


func _visual_edge(cube: RigidBody3D) -> float:
	var visual := cube.get_node_or_null("Visual") as Node3D
	return visual.scale.x if visual else -1.0


func _conveyor_and_printer() -> void:
	await _new_game()
	game.running = true
	game.spawn_interval = 999.0
	var cube: RigidBody3D = game.spawn_cube()
	_check(is_instance_valid(cube), "feed creates a grabbable physical cube")
	if not is_instance_valid(cube): return
	_check(not bool(cube.printed), "cube drops from the net before receiving its preset texture")
	var start_x := cube.position.x
	await _frames(450)
	_check(is_instance_valid(cube) and cube.position.x > start_x + 1.0,
		"moving conveyor physically carries the dropped cube toward its end",
		{"start_x": start_x, "end_x": cube.position.x if is_instance_valid(cube) else null})
	_check(is_instance_valid(cube) and bool(cube.printed) and int(cube.kind) in [0, 1],
		"passing through the printer assigns one of the two prefab textures")
	_check(is_instance_valid(cube) and cube.position.y >= 0.0, "overflow cube remains above the room floor")
	_ledger("conveyor")
	game.act("PAUSE")
	var produced_before := int(game.produced)
	game.spawn_interval = 0.05
	await _frames(30)
	_check(int(game.produced) == produced_before, "pause stops the feeder")


func _basket_rules_and_shrink() -> void:
	await _new_game()
	var wrong := _cube_at(game.to_local(game.baskets[1].global_position), 0)
	await _frames(8)
	_check(is_instance_valid(wrong) and not bool(wrong.sorting) and int(game.sorted_counts[0]) == 0,
		"wrong basket leaves the cube available for another attempt")
	_check(not game.try_sort(wrong, 1), "wrong texture cannot be submitted directly")
	var raw := _cube_at(Vector3(0.0, 2.0, 3.0), -1)
	_check(not game.try_sort(raw, 0), "unprinted cube cannot score")
	var held := _cube_at(Vector3(0.0, 2.0, 3.0), 1)
	pointer._grab_held(held)
	held.position = game.to_local(game.baskets[1].global_position)
	await _frames(8)
	_check(bool(held.is_held()) and not bool(held.sorting) and not game.try_sort(held, 1),
		"carried cube does not sort until released inside the correct basket")
	pointer._drop_held()
	held.position = game.to_local(game.baskets[1].global_position)
	var original_edge := _edge(held)
	var original_visual := _visual_edge(held)
	await _frames(12)
	_check(is_instance_valid(held) and bool(held.sorting), "basket entry starts the visible shrink receipt")
	if is_instance_valid(held):
		_check(_edge(held) > 0.0 and _edge(held) < original_edge,
			"collider shrinks with the cube", {"before": original_edge, "during": _edge(held)})
		_check(_visual_edge(held) > 0.0 and _visual_edge(held) < original_visual,
			"rendered cube visibly shrinks", {"before": original_visual, "during": _visual_edge(held)})
		_check(not game.try_sort(held, 1), "same cube cannot score twice during shrink")
		_check(is_equal_approx(_edge(wrong), original_edge), "shrinking one cube does not resize another cube's collider")
	_ledger("shrink in progress")
	await _frames(40)
	_check(int(game.sorted_counts[1]) == 1 and game.mini_transforms[1].size() == 1,
		"sorted cube remains in its basket as a miniature")
	if game.mini_transforms[1].size() == 1:
		# The headless Dummy renderer does not retain MultiMesh GPU transforms.
		# Check the submitted receipt there, and its rendered instance in captures.
		var miniature: Transform3D = game.mini_transforms[1][0]
		if DisplayServer.get_name() != "headless":
			miniature = game.sorted_displays[1].multimesh.get_instance_transform(0)
		var basket: Area3D = game.baskets[1]
		var local_mini := basket.to_local(game.to_global(miniature.origin))
		_check(absf(local_mini.x) < 0.37 and absf(local_mini.z) < 0.37,
			"sorted miniature remains inside the relocated basket", local_mini)
	_check(is_instance_valid(wrong), "wrongly sorted cube is not silently consumed")
	_ledger("completed receipt")


func _unattended_production() -> void:
	await _new_game(Rect2(2.7, -1.2, 3.2, 2.4), 2.4)
	game.active_limit = 4
	game.spawn_interval = 1.0
	game.running = true
	var largest_live_pool := 0
	var ledger_balanced := true
	for sample in 25:
		await _frames(60)
		var state: Dictionary = game.get_state()
		largest_live_pool = maxi(largest_live_pool, int(state.active))
		ledger_balanced = ledger_balanced and int(state.produced) == int(state.active) + int(state.stored) + int(state.sorting) + int(state.sorted)
	var final: Dictionary = game.get_state()
	_check(int(final.produced) > game.active_limit and int(final.stored) > 0,
		"unattended belt overflow settles into floor stock and production continues", final)
	_check(largest_live_pool <= game.active_limit,
		"unattended production stays within its live physics budget", largest_live_pool)
	_check(ledger_balanced, "unattended production never loses an unsorted cube")
	_ledger("unattended production")


func _upper_layer_settling() -> void:
	await _new_game(Rect2(3.8, -0.2, 0.4, 0.4), 2.0)
	for index in 3:
		var base := _cube_at(Vector3(3.96, 0.16 + index * 0.32, -0.04), index % 2)
		game.archive_cube(base)
	await _frames(4)
	var top := _cube_at(Vector3(3.96, 1.9, -0.04), 1)
	await _frames(220)
	_check(int(game.backlog.count()) == 4 and not is_instance_valid(top),
		"cube physically landing on three retained cubes joins the floor pile", game.get_state())
	var landed_on_stock := false
	for entry: Dictionary in game.backlog.get("_entries").values():
		var pose: Transform3D = entry.pose
		if absf(pose.origin.y - 1.12) < 0.03: landed_on_stock = true
	_check(landed_on_stock, "stored box colliders support the falling cube at its real settled height")
	_ledger("upper layer settling")


func _xr_basket_lifecycle() -> void:
	await _new_game()
	var origin := XROrigin3D.new()
	world.add_child(origin)
	var controller := XRController3D.new()
	controller.tracker = "right_hand"
	controller.pose = "aim"
	origin.add_child(controller)
	controller.owner = world
	var hand: Node3D = load("res://commons/body/hands/right_hand.tscn").instantiate()
	hand.set_script(load("res://addons/godot-xr-tools/hands/hand.gd"))
	hand.hand_blend_tree = load("res://addons/godot-xr-tools/hands/animations/right/hand_blend_tree.tres")
	hand.default_pose = load("res://addons/godot-xr-tools/hands/poses/pose_default_right.tres")
	controller.add_child(hand)
	hand.owner = world
	var pickup: Node3D = load("res://addons/godot-xr-tools/functions/function_pickup.gd").new()
	controller.add_child(pickup)
	pickup.owner = world
	controller.position = Vector3(0.0, 1.5, 2.5)
	await _frames(3)
	var cube := _cube_at(game.to_local(pickup.global_position + Vector3(0.10, 0, 0)), 0)
	await _frames(3)
	pickup._pick_up_object(cube)
	await _frames(8)
	_check(pickup.picked_up_object == cube and cube.is_held() and not pickup.picked_up_ranged,
		"actual XRTools near pickup holds a sorter cube")
	var offset := cube.global_position - controller.global_position
	controller.global_position = game.baskets[0].global_position - offset
	await _frames(10)
	_check(not cube.sorting and not game.try_sort(cube, 0) and int(game.sorted_counts[0]) == 0,
		"XR held cube cannot score inside its matching basket")
	pickup.drop_object()
	cube.global_position = game.baskets[0].global_position
	cube.linear_velocity = Vector3.ZERO
	cube.angular_velocity = Vector3.ZERO
	_check(not cube.is_held() and pickup.picked_up_object == null,
		"XR release clears the grab driver and the held flag")
	await _frames(50)
	_check(int(game.sorted_counts[0]) == 1 and game.mini_transforms[0].size() == 1,
		"XR released cube shrinks into its matching basket")
	_check(hand._pose_overrides.is_empty() and hand._target_overrides.is_empty(),
		"XR sorting leaves no stale hand pose or surface target")
	_ledger("XR sorting")
	origin.queue_free()
	await _frames(3)


func _backlog_and_reclaim() -> void:
	await _new_game(Rect2(3.25, -1.05, 1.8, 2.1), 1.28)
	game.rotation.y = deg_to_rad(270.0)
	game.active_limit = 4
	var expected: Array[Dictionary] = []
	for index in 12:
		# Each box already has a separate floor footprint; archiving must not
		# invent a stack or rearrange positions to make this fixture fit.
		var at := Vector3(3.50 + (index % 3) * 0.55 + sin(index * 2.1) * 0.025,
			0.16, -0.72 + floori(index / 3.0) * 0.49 + cos(index * 1.7) * 0.02)
		var cube := _cube_at(at, index % 2)
		_check(is_instance_valid(cube), "backlog fixture creates cube %d" % index)
		if is_instance_valid(cube):
			cube.rotation = Vector3(0.14 if index == 0 else 0.0, 0.17 + index * 0.11, -0.10 if index == 0 else 0.0)
			var basis: Basis = cube.basis
			cube.position.y = 0.16 * (absf(basis.x.y) + absf(basis.y.y) + absf(basis.z.y))
			expected.append({"kind": index % 2, "pose": cube.transform})
			_check(game.archive_cube(cube), "settled cube %d enters retained floor storage" % index)
	await _frames(4)
	_check(int(game.backlog.count()) == 12 and int(game.produced) == 12,
		"storage preserves every cube beyond the live physics budget")
	_ledger("retained backlog")
	var before: Dictionary = game.backlog.get_state()
	_check(int(before.footprint_cells) > 0 and int(before.max_layers) == 4,
		"floor-volume capacity remains bounded without arranging stored cubes", before)
	var entries: Dictionary = game.backlog.get("_entries")
	var bodies: Array[Node] = game.backlog.find_children("*", "StaticBody3D", true, false)
	var stock_body: StaticBody3D = bodies[0] if not bodies.is_empty() else null
	var exact_poses := entries.size() == expected.size()
	var matched_originals: Dictionary = {}
	var exact_collisions := is_instance_valid(stock_body)
	var rendered_poses := true
	for entry: Dictionary in entries.values():
		var found := false
		var pose: Transform3D = entry.pose
		for original_index in expected.size():
			var original: Dictionary = expected[original_index]
			if int(original.kind) == int(entry.kind) and pose.is_equal_approx(original.pose):
				found = true
				matched_originals[original_index] = true
		exact_poses = exact_poses and found
		if is_instance_valid(stock_body):
			var owner_id := int(entry.owner)
			exact_collisions = exact_collisions and stock_body.shape_owner_get_transform(owner_id).is_equal_approx(pose)
			var shape: BoxShape3D = stock_body.shape_owner_get_shape(owner_id, 0) as BoxShape3D
			exact_collisions = exact_collisions and shape != null and shape.size.is_equal_approx(Vector3.ONE * game.cube_size)
		if DisplayServer.get_name() != "headless":
			var batch: MultiMeshInstance3D = game.backlog.get_node("RetainedKind%d" % int(entry.kind))
			var wanted := pose * Transform3D(Basis.from_scale(Vector3.ONE * game.cube_size), Vector3.ZERO)
			var rendered := false
			for instance_index in batch.multimesh.instance_count:
				if batch.multimesh.get_instance_transform(instance_index).is_equal_approx(wanted): rendered = true
			rendered_poses = rendered_poses and rendered
	_check(exact_poses and matched_originals.size() == expected.size(),
		"mixed missed cubes retain their exact irregular positions and tilted orientations")
	_check(exact_collisions, "every retained box collider matches its saved pose and cube dimensions")
	if DisplayServer.get_name() != "headless":
		_check(rendered_poses, "batched missed cubes render at the same poses as their colliders")
	_check(int(game.sorted_counts[0]) == 0 and int(game.sorted_counts[1]) == 0,
		"archiving mixed missed cubes never sorts either kind")
	# Move the actual viewport camera into reach so public play behavior exposes a top cube.
	camera.position = game.to_global(Vector3(4.05, 1.3, 0.0))
	await _frames(30)
	var proxies: Array[Node] = game.backlog.find_children("BacklogTop_*", "RigidBody3D", false, false)
	_check(not proxies.is_empty(), "nearby top cube becomes grabbable again")
	if not proxies.is_empty():
		var proxy: RigidBody3D = proxies[0]
		# Prefer the tilted fixture so proxy/reclaim covers all rotation axes.
		var tilted_proxy := false
		for candidate: RigidBody3D in proxies:
			if candidate.transform.is_equal_approx(expected[0].pose):
				proxy = candidate
				tilted_proxy = true
		_check(tilted_proxy, "the tilted floor cube remains reachable and grabbable at its original pose")
		var old_kind := int(proxy.kind)
		var proxy_pose := proxy.transform
		var original_pose := false
		for original: Dictionary in expected:
			if int(original.kind) == old_kind and proxy_pose.is_equal_approx(original.pose): original_pose = true
		_check(original_pose, "reachable proxy appears at the original retained pose without snapping")
		var held_global := proxy.global_transform
		pointer._grab_held(proxy)
		await _frames(2)
		_check(game.active.has(proxy) and int(game.backlog.count()) == 11,
			"grabbing floor stock restores one live cube and removes exactly one stored cube")
		_check(int(proxy.kind) == old_kind and proxy.is_held(), "reclaimed cube retains texture and held state")
		_check(proxy.global_transform.is_equal_approx(held_global), "reclaim preserves the cube's exact world pose")
		_ledger("reclaimed cube")
		game.reset_game()
		await _frames(3)
		_check(not is_instance_valid(proxy), "reset cleans up a held reclaimed cube")
		_check(not pointer.is_holding(), "reset releases the actual desktop pointer before freeing its held cube")
	else:
		game.reset_game()
		await _frames(3)
	_check(int(game.produced) == 0 and game.active.is_empty() and int(game.backlog.count()) == 0,
		"reset clears active cubes, retained stock, and counters")
	_check(game.mini_transforms[0].is_empty() and game.mini_transforms[1].is_empty(),
		"reset clears basket miniatures")
	_ledger("reset")


func _room_full() -> void:
	await _new_game(Rect2(3.0, -1.0, 0.4, 0.4), 0.64)
	var capacity := int(game.backlog.get_state().capacity)
	_check(capacity > 0, "small test room has a measurable capacity", capacity)
	for index in capacity:
		var cube := _cube_at(Vector3(3.16, 0.16 + index * 0.32, -0.84), index % 2)
		game.archive_cube(cube)
	await _frames(4)
	_check(bool(game.backlog.is_full()) and bool(game.get_state().room_full),
		"stack reaching the room capacity ends the run")
	var count_before := int(game.produced)
	await _frames(60)
	_check(int(game.produced) == count_before, "room full stops further production")
	_ledger("full room")
	game.act("RESET")
	await _frames(4)
	_check(not bool(game.get_state().room_full) and int(game.produced) == 0,
		"restart clears the loss state and starts a fresh room")


func _support_removal_budget_recovery() -> void:
	await _new_game(Rect2(3.8, -0.2, 0.4, 0.4), 2.0)
	game.active_limit = 2
	for index in 4:
		var cube := _cube_at(Vector3(3.96, 0.16 + index * 0.32, -0.04), index % 2)
		game.archive_cube(cube)
	await _frames(4)
	camera.position = game.to_global(Vector3(3.0, 0.17, -0.04))
	await _frames(30)
	var support: RigidBody3D
	for candidate: RigidBody3D in game.backlog.find_children("BacklogTop_*", "RigidBody3D", false, false):
		if absf(candidate.position.y - 0.16) < 0.01: support = candidate
	_check(is_instance_valid(support), "the lowest exposed support can be reclaimed from the side")
	if not is_instance_valid(support): return
	pointer._grab_held(support)
	await _frames(24)
	_check(game.active.size() == 2 and int(game.backlog.count()) == 2,
		"removing a support wakes only as many cubes as the active budget permits", game.get_state())
	var awakened_ids: Dictionary = {}
	for release in 3:
		var awakened: RigidBody3D
		for candidate: RigidBody3D in game.active:
			if candidate != support: awakened = candidate
		var newly_awakened := is_instance_valid(awakened) and not awakened_ids.has(awakened.get_instance_id())
		_check(newly_awakened and not awakened.freeze,
			"unsupported cube %d wakes when physics capacity is available" % (release + 1))
		if not newly_awakened: break
		awakened_ids[awakened.get_instance_id()] = true
		_check(game.active.size() <= game.active_limit,
			"support recovery stays within the active physics budget")
		_ledger("support recovery %d" % (release + 1))
		if release < 2:
			# Let this cube land, then store it through the public transfer API.
			# The newly free slot must wake another old unsupported cube.
			await _frames(60)
			_check(game.archive_cube(awakened), "settled awakened cube releases a physics slot")
			await _frames(24)
	_check(awakened_ids.size() == 3, "all three cubes above the removed support eventually resume physics")
	game.reset_game()
	await _frames(24)
	_check(game.active.is_empty() and int(game.backlog.count()) == 0 and not pointer.is_holding(),
		"reset clears recovered stock and the held support")


func _map_placement() -> void:
	var source := FileAccess.get_file_as_string("res://commons/maps/Point_Animatedcube/map_data.json")
	_check(source.count("cube_sorting_line:") == 1, "animated cube map places exactly one sorting station")
	_check(source.count("prefab_box_library:") == 1,
		"animated cube map keeps exactly one original box library beside the sorting station")


func _shot(name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := OS.get_environment("ADA_CUBE_SORTER_CAPTURE").path_join(name + ".png")
	var result := get_viewport().get_texture().get_image().save_png(path)
	_check(result == OK, "native scene screenshot: " + name)
	if result == OK: screenshots.append(path)


func _capture_demo() -> void:
	await _new_game(Rect2(2.0, -2.4, 3.2, 5.2), 2.0)
	get_viewport().msaa_3d = Viewport.MSAA_4X
	var mushroom_hud := get_node_or_null("/root/MushroomHand")
	if mushroom_hud:
		mushroom_hud.process_mode = Node.PROCESS_MODE_DISABLED
		for canvas in mushroom_hud.find_children("*", "CanvasLayer", true, false): canvas.visible = false
	camera.position = Vector3(3.5, 3.0, 7.5)
	camera.fov = 42.0
	camera.look_at(Vector3(0.2, 1.2, 0.4))
	for kind in 2:
		for index in 5:
			var cube := _cube_at(game.to_local(game.baskets[kind].global_position), kind)
			game.try_sort(cube, kind)
	await _frames(45)
	game.running = true
	game.spawn_interval = 999.0
	game.spawn_cube()
	await _frames(90)
	game.spawn_cube()
	await _frames(90)
	game.spawn_cube()
	game._clock = game.spawn_interval * 0.50
	await _frames(4)
	await _shot("sorting-line")
	var tumble := RandomNumberGenerator.new()
	tumble.seed = 461005
	for batch in 6:
		for index in 8:
			var cube := _cube_at(Vector3(tumble.randf_range(3.05, 3.55),
				1.35 + index * 0.65, tumble.randf_range(-0.32, 0.32)), (batch + index) % 2)
			if not is_instance_valid(cube): continue
			cube.rotation = Vector3(tumble.randf_range(-1.2, 1.2), tumble.randf_range(-PI, PI), tumble.randf_range(-1.2, 1.2))
			cube.linear_velocity = Vector3(tumble.randf_range(-0.15, 0.35), 0, tumble.randf_range(-0.3, 0.3))
			cube.angular_velocity = Vector3(tumble.randf_range(-1.0, 1.0), tumble.randf_range(-1.0, 1.0), tumble.randf_range(-1.0, 1.0))
		await _frames(120)
	await _frames(360)
	_check(int(game.backlog.count()) > 0, "capture pile tumbles and settles through normal physics", game.get_state())
	_check(int(game.sorted_counts[0]) == 5 and int(game.sorted_counts[1]) == 5,
		"missed capture cubes remain unsorted after accumulating")
	_ledger("physical capture pile")
	camera.position = Vector3(7.5, 4.8, 9.0)
	camera.look_at(Vector3(1.2, 1.0, 0.1))
	await _shot("sorting-line-backlog")
	var cube := _cube_at(game.to_local(game.baskets[0].global_position), 0)
	game.try_sort(cube, 0)
	camera.position = game.baskets[0].global_position + Vector3(1.8, 1.5, 2.0)
	camera.look_at(game.baskets[0].global_position)
	await _frames(14)
	await _shot("sorting-line-basket")


func _run() -> void:
	await _frames(3)
	_build_world()
	var package: PackedScene = load(GAME)
	var instance := package.instantiate() if package else null
	var scene_ready: bool = is_instance_valid(instance) and instance.has_method("spawn_cube")
	if is_instance_valid(instance): instance.free()
	_check(scene_ready, "sorter scene loads with its gameplay script")
	if not scene_ready:
		_finish()
		return
	await _conveyor_and_printer()
	await _basket_rules_and_shrink()
	await _unattended_production()
	await _upper_layer_settling()
	await _xr_basket_lifecycle()
	await _backlog_and_reclaim()
	await _room_full()
	await _support_removal_budget_recovery()
	_map_placement()
	if not OS.get_environment("ADA_CUBE_SORTER_CAPTURE").is_empty():
		await _capture_demo()
	_finish()


func _finish() -> void:
	var passed := true
	for check in checks: passed = passed and bool(check.passed)
	var result := {"passed": passed, "checks": checks, "screenshots": screenshots,
		"scope": "Native Godot physics, real desktop pointer and XRTools pickup with a simulated controller; headset hardware and comfort are not measured."}
	var path := OS.get_environment("ADA_CUBE_SORTER_REPORT")
	if path.is_empty(): path = "user://cube-sorter-regression.json"
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(result, "  ") + "\n")
		file.close()
	print("CUBE SORTER: %s (%d checks)" % ["PASS" if passed else "FAIL", checks.size()])
	get_tree().quit(0 if passed else 1)
