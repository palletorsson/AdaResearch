extends SceneTree

var checks: Array[Dictionary] = []
var observations: Dictionary = {}
var preview: Node3D
var output: String

func _initialize() -> void:
	call_deferred("run")

func check(label: String, ok: bool) -> void:
	checks.append({"name": label, "passed": ok})
	if not ok:
		push_error(label)

func run() -> void:
	output = OS.get_cmdline_user_args()[0]
	preview = load("res://commons/context/cellular_spaces/cellular_spaces_preview.tscn").instantiate()
	root.add_child(preview)
	preview.walker.set_physics_process(false)
	await physics_frame
	await physics_frame
	var womb = preview.spaces[0]
	var cells = preview.spaces[1]
	for room in preview.spaces:
		var arrays: Array = room.membrane_mesh.surface_get_arrays(0)
		var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
		var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		observations[str(room.name)] = {"vertices": vertices.size(), "triangles": indices.size() / 3, "build_ms": room.build_msec}
		check(str(room.name) + " has bounded 3D mesh", vertices.size() > 1000 and indices.size() / 3 < 200000)
		var finite := true
		var min_y := INF
		var max_y := -INF
		for v in vertices:
			finite = finite and v.is_finite()
			min_y = minf(min_y, v.y)
			max_y = maxf(max_y, v.y)
		check(str(room.name) + " finite curved walls and ceiling", finite and max_y > 7 and min_y < 0)
		check(str(room.name) + " smooth normals supplied", normals.size() == vertices.size())
		var world: PhysicsDirectSpaceState3D = room.get_world_3d().direct_space_state
		var floor_hit := world.intersect_ray(PhysicsRayQueryParameters3D.create(room.get_spawn_position() + Vector3.UP, room.get_spawn_position() - Vector3.UP))
		check(str(room.name) + " entrance supported at y=0", not floor_hit.is_empty() and absf(floor_hit.position.y) < 0.02)
		var ceiling := world.intersect_ray(PhysicsRayQueryParameters3D.create(room.to_global(Vector3(0, 1.6, 0)), room.to_global(Vector3(0, 11, 0))))
		check(str(room.name) + " real ceiling above standing height", not ceiling.is_empty() and ceiling.position.y > 5.0)
		check(str(room.name) + " capsule enters without an invisible wall", clear_route(room, Vector3(0, 0, 12.8), Vector3.ZERO))
		check(str(room.name) + " outside wall blocks capsule", not clear_route(room, Vector3.ZERO, Vector3(13.2, 0, 0)))
		check(str(room.name) + " central floor carries player", floor_below(room, Vector3.ZERO))
	var routes_clear := true
	for site in cells.floor_sites:
		var destination: Vector3 = Vector3(site.x, 0, site.z)
		routes_clear = routes_clear and clear_route(cells, Vector3.ZERO, destination)
		routes_clear = routes_clear and floor_below(cells, destination)
	check("all 16 ground cells reachable by standing capsule", routes_clear and cells.floor_sites.size() == 16)
	check("second layer makes volumetric cell faces", cells.sites.size() == 20 and cells.sites[19].y > 9)
	var missing_walls := 0
	var radius: float = cells.clearing_radius
	for z in range(-4, 5):
		for x in range(-4, 5):
			if Vector2(x, z).length() > 3.9:
				continue
			var p := Vector3(x, 4, z)
			var open_field: float = cells.sample_solid(p)
			cells.clearing_radius = 0
			var partitioned: float = cells.sample_solid(p)
			cells.clearing_radius = radius
			if open_field > 0 and partitioned < 0:
				missing_walls += 1
	check("central clearing actually removes cell walls (negative control)", missing_walls > 0)
	observations.removed_wall_samples = missing_walls
	var saved: PackedVector3Array = cells.sites.duplicate()
	cells._make_sites()
	check("same seed replays exact feature positions", saved == cells.sites)
	cells.seed_value += 1
	cells._make_sites()
	check("different seed changes cells", saved != cells.sites)
	cells.seed_value -= 1
	cells._make_sites()
	# Navigation uses transformed room spawn, preserving old terrain behaviour.
	var manager = load("res://commons/context/walkgrids/TopologyManager.gd").new()
	manager.create_sine_space = false
	manager.create_noise_space = false
	manager.create_voronoi_space = false
	manager.create_random_space = false
	manager.create_fractal_space = false
	root.add_child(manager)
	manager.spaces.append(cells)
	check("manager teleports to entrance, not roof", manager.teleport_to_space(0).is_equal_approx(cells.get_spawn_position()))
	var legacy := Node3D.new()
	manager.add_child(legacy)
	legacy.position = Vector3(70, 0, 0)
	manager.spaces.append(legacy)
	check("existing terrain teleport remains unchanged", manager.teleport_to_space(1).is_equal_approx(Vector3(70, 5, 0)))
	check("both runtime keys registered", manager.SPACE_REGISTRY.has("cellular_womb") and manager.SPACE_REGISTRY.has("cellular_atrium"))
	# Rigid-body navigation test: move the actual demo walker through the entrance.
	preview.enter_space(0)
	for i in range(150):
		await physics_frame
		preview.walker.velocity = Vector3(0, -1, -5)
		preview.walker.move_and_slide()
	check("actual walker crosses womb entrance", preview.walker.position.z < 3 and absf(preview.walker.position.y) < 0.1)
	preview.enter_space(1)
	check("space selector resets walker to second entrance", preview.walker.global_position.is_equal_approx(cells.get_spawn_position()))
	if "--capture" in OS.get_cmdline_user_args():
		await capture("womb-interior", womb.to_global(Vector3(0, 1.65, 7)), womb.to_global(Vector3(-2, 3.5, -5)))
		await capture("cells-centre", cells.to_global(Vector3(0, 1.65, 3.4)), cells.to_global(Vector3(4.5, 2.8, -6)))
		await capture("cells-room", cells.to_global(Vector3(7, 1.65, 2.5)), cells.to_global(Vector3(0, 2.4, 0)))
	var passed := true
	for item in checks:
		passed = passed and item.passed
	var file := FileAccess.open(output.path_join("checks.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "checks": checks, "observations": observations}, "  "))
	file.close()
	print("CELLULAR_SPACES: ", checks.size(), " checks; passed=", passed, "; ", JSON.stringify(observations))
	quit(0 if passed else 1)

func clear_route(room: Node3D, start: Vector3, end: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.3
	shape.height = 1.8
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.exclude = [preview.walker.get_rid()]
	query.transform.origin = room.to_global(start + Vector3(0, 0.94, 0))
	query.motion = room.global_basis * (end - start)
	var world := room.get_world_3d().direct_space_state
	if not world.intersect_shape(query).is_empty():
		return false
	var result := world.cast_motion(query)
	return result[0] > 0.999

func floor_below(room: Node3D, at: Vector3) -> bool:
	var hit := room.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(room.to_global(at + Vector3.UP * 0.5), room.to_global(at - Vector3.UP)))
	return not hit.is_empty() and absf(hit.position.y) < 0.02

func capture(title: String, eye: Vector3, target: Vector3) -> void:
	var camera: Camera3D = preview.walker.eyes
	camera.global_position = eye
	camera.look_at(target)
	preview.caption.get_parent().hide()
	for i in range(4):
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(output.path_join(title + ".png"))
