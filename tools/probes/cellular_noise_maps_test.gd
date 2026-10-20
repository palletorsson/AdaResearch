extends SceneTree
var checks: Array = []
var failures: Array = []
var observations: Dictionary = {}
var grid: Node3D
var built := false

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	if not passed:
		failures.append(label)
		push_error(label)

func run() -> void:
	var host := Node3D.new()
	root.add_child(host)
	current_scene = host
	var camera := Camera3D.new()
	host.add_child(camera)
	camera.current = true
	var world := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("242132")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("c6becb")
	environment.ambient_light_energy = 0.35
	world.environment = environment
	host.add_child(world)
	var seq: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/sequences/noise.json"))
	var maps: Array = seq.sequences.noise.maps
	var at := maps.find("Noise_Cellular")
	check("both maps follow Inside Noise in sequence", at > 0 and maps[at-1] == "Noise_Inside_Noise" and maps[at+1] == "Noise_Box" and maps[at+2] == "Noise_Space_10")
	var declaration: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/map_authored.json"))
	check("both declared as museum halls", declaration.noise.has("Noise_Cellular") and declaration.noise.has("Noise_Box"))
	var plan: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/museum/em_plan.json"))
	for map_name in ["Noise_Cellular", "Noise_Box"]:
		var row: Dictionary = {}
		for candidate in plan.plans:
			if candidate.get("map") == map_name:
				row = candidate
		check(map_name + " museum has full-scale map placements", row.get("artifacts", []).size() == (3 if map_name == "Noise_Cellular" else 2) and row.get("room", {}).get("w") == 69)
		grid = load("res://commons/grid/grid_system.tscn").instantiate()
		grid.map_name = map_name
		grid.bare_world = true
		grid.skip_player_spawn = true
		grid.set_meta("skip_player_spawn", true)
		built = false
		grid.build_finished.connect(func(): built = true)
		host.add_child(grid)
		var started := Time.get_ticks_msec()
		while not built and Time.get_ticks_msec() - started < 45000:
			await process_frame
		check(map_name + " native grid finished building", built)
		await create_timer(1.0).timeout
		await physics_frame
		await physics_frame
		var room_count := 0
		var wire_count := 0
		var placements: Array = []
		for node in grid.find_children("*", "Node3D", true, false):
			if not node.has_meta("artifact_lookup_name"):
				continue
			var token := str(node.get_meta("artifact_lookup_name"))
			placements.append({"token": token, "position": [node.global_position.x,node.global_position.y,node.global_position.z]})
			if token == "voronoi_strands":
				wire_count += 1
				check("strands generated in actual map", node.edges.size() > 200)
				check("spider builds strands inside Cellular Noise map", node.weaver != null and (node.weaver.laid_count > 0 or node.weaver.step_distance > 0.01) and node.weaver.spider.is_visible_in_tree())
				var beside: Vector3 = node.to_global(Vector3(6,0,0))
				var base_hit: Dictionary = node.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(beside + Vector3.UP, beside - Vector3.UP))
				check("sculpture placement remains flush with gallery floor", not base_hit.is_empty() and absf(base_hit.position.y - node.global_position.y) < 0.02)
				var surfaces_real: bool = node.anchor_kinds.size() > 0
				var surface_counts := {"floor": 0, "wall": 0, "ceiling": 0}
				for id: int in node.anchor_kinds:
					var point: Vector3 = node.to_global(node.vertices[id])
					var normal: Vector3 = (node.global_basis * node.anchor_normals[id]).normalized()
					var hit: Dictionary = node.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(point + normal * 0.08, point - normal * 0.08, 1))
					surface_counts[node.anchor_kinds[id]] += 1
					surfaces_real = surfaces_real and not hit.is_empty()
					if not hit.is_empty():
						var kind := "floor" if hit.normal.y > 0.6 else ("ceiling" if hit.normal.y < -0.6 else "wall")
						surfaces_real = surfaces_real and node.anchor_kinds[id] == kind and hit.position.distance_to(point) < 0.001 and hit.collider is StaticBody3D
				check("every net anchor meets an existing map surface", surfaces_real)
				check("open-roof map uses its available floor and walls", surface_counts.floor > 0 and surface_counts.wall > 0)
				observations["net_surface_counts"] = surface_counts
				check("map net has surface fixings and no hoop", node.generated.has_node("SurfaceFixings") and not node.generated.has_node("SupportingHoop"))
				var fixed: Dictionary = {}
				for id: int in node.anchor_kinds:
					fixed[id] = node.vertices[id]
				node.weaver.finish()
				node.set_physics_process(false)
				for frame in range(180):
					node.advance_tension(1.0 / 60.0)
				var anchors_fixed := true
				var above_floor := true
				for id: int in fixed:
					anchors_fixed = anchors_fixed and fixed[id] == node.vertices[id]
				for point: Vector3 in node.vertices:
					above_floor = above_floor and point.is_finite() and point.y >= -0.001
				check("native map net simulates gravity with fixed surface anchors", node.tension_active and node.dynamics.elapsed > 2.9 and anchors_fixed)
				check("native map floor stops falling knots", above_floor)
				observations["net_dynamics"] = node.dynamics.metrics()
			elif token.ends_with("_space"):
				room_count += 1
				check(token + " uses gallery floor without overlap", not node.create_floor and not node.generated.has_node("Floor"))
				check(token + " placed at body scale", node.global_basis.get_scale().is_equal_approx(Vector3.ONE))
				check(token + " aisle, entrance and centre are clear", clear_route(node, Vector3(0,0,15), Vector3.ZERO))
				var outside: Vector3 = node.to_global(Vector3(0,0,15))
				var floor_hit: Dictionary = node.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(outside + Vector3.UP, outside - Vector3.UP))
				check(token + " room floor flush with gallery", not floor_hit.is_empty() and absf(floor_hit.position.y - node.global_position.y) < 0.02)
				var all_rooms := true
				if node.layout == 1:
					for site: Vector3 in node.floor_sites:
						all_rooms = all_rooms and clear_route(node, Vector3.ZERO, Vector3(site.x,0,site.z))
					check(token + " all 16 cell routes clear in map", all_rooms)
				if node.box_cells:
					var arrays: Array = node.membrane_mesh.surface_get_arrays(0)
					var box_normals := true
					for n: Vector3 in arrays[Mesh.ARRAY_NORMAL]:
						# Normal packing introduces ~1e-5 roundoff on zero components.
						box_normals = box_normals and absf(n.abs().dot(Vector3.ONE) - 1.0) < 0.001
					check(token + " axis-aligned square surfaces", box_normals)
					if DisplayServer.get_name() != "headless":
						camera.global_position = node.to_global(Vector3(0,1.65,7) if node.layout == 0 else Vector3(0,1.65,3.4))
						camera.look_at(node.to_global(Vector3(-2,3.5,-5) if node.layout == 0 else Vector3(4.5,2.8,-6)))
						camera.fov = 78
						for frame in range(4):
							await process_frame
						await RenderingServer.frame_post_draw
						root.get_texture().get_image().save_png(OS.get_cmdline_user_args()[0].path_join(token + ".png"))
		check(map_name + " has both native rooms", room_count == 2)
		check(map_name + " correct strand placement count", wire_count == (1 if map_name == "Noise_Cellular" else 0))
		observations[map_name] = placements
		grid.queue_free()
		await process_frame
	var output := OS.get_cmdline_user_args()[0]
	FileAccess.open(output.path_join("map-checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations},"  "))
	print("CELLULAR_MAPS: ", checks.size(), " checks; failures=", JSON.stringify(failures), "; ", JSON.stringify(observations))
	quit(0 if failures.is_empty() else 1)

func clear_route(room: Node3D, start: Vector3, end: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.28
	shape.height = 1.75
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.collision_mask = 1
	query.transform.origin = room.to_global(start + Vector3(0,0.93,0))
	query.motion = room.global_basis * (end-start)
	var state := room.get_world_3d().direct_space_state
	return state.intersect_shape(query).is_empty() and state.cast_motion(query)[0] > 0.999
