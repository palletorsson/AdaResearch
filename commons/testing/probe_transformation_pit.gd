extends "res://commons/testing/probe_transformation_opening.gd"
## Reuses the real museum boot/isolation from the opening-hall probe.

func _initialize() -> void:
	map_name = "Trans_Pit"
	_run.call_deferred()

func check_crossings(grid: Node3D) -> void:
	if map_name == "Trans_Body":
		for suffix in ["/approach_wall.gd","/carve_grid.gd","/approach_scale.gd"]:
			check("body threshold retained " + suffix, by_script(grid,suffix).size() == 1)
		for row in [22.0,23.0,24.0]:
			var height := floor_y(grid,5.0,row)
			check("body exit continuous floor at row " + str(row), absf(height - grid.global_position.y - 0.5) < 0.002,height)
		return
	var growers := by_script(grid, "/grower_block.gd")
	var pushers := by_script(grid, "/pusher_block.gd")
	check("three configured growers in museum", growers.size() == 3)
	check("three configured pushers in museum", pushers.size() == 3)
	if growers.size() != 3 or pushers.size() != 3: return
	var floor_baselines: Array[float] = []
	for grower in growers:
		check("grower receives authored config " + str(grower.name), grower.anchor == "floor" and is_equal_approx(grower.min_scale,0.3) and is_equal_approx(grower.max_scale,3.5) and is_equal_approx(grower.grow_speed,0.15))
		floor_baselines.append(grower.global_position.y)
		grower._time = 0.0
		grower._update_size()
	for pusher in pushers:
		var at := grid.to_local(pusher.global_position)
		var expected := Vector3.FORWARD if at.z > 4.0 else Vector3.BACK
		check("pusher configured axis reaches cached path " + str(pusher.name), (pusher._end_pos - pusher._start_pos).is_equal_approx(expected * 2.0), str(pusher._end_pos - pusher._start_pos))
		var arrow: Node3D = pusher._body.get_node("DirectionArrow")
		check("pusher arrow follows configured direction " + str(pusher.name), arrow.position.normalized().is_equal_approx(expected))
		pusher._t = 0.0
		pusher._direction = 1.0
		pusher._paused = false
		pusher._body.global_position = pusher._start_pos
	var max_floor_error := 0.0
	var max_mesh_error := 0.0
	var max_pusher_floor_error := 0.0
	var min_size := INF
	var max_size := 0.0
	var moved_forward: Array[bool] = [false,false,false]
	var observed_pause: Array[bool] = [false,false,false]
	for step in 405:
		await tick()
		for i in growers.size():
			var grower = growers[i]
			var shape: CollisionShape3D = grower._col_shape
			var mesh: MeshInstance3D = grower._mesh
			var bounds: AABB = shape.global_transform * shape.shape.get_debug_mesh().get_aabb()
			var visible: AABB = mesh.global_transform * mesh.get_aabb()
			max_floor_error = maxf(max_floor_error,absf(bounds.position.y - floor_baselines[i]))
			max_mesh_error = maxf(max_mesh_error,bounds.position.distance_to(visible.position)+bounds.size.distance_to(visible.size))
			min_size = minf(min_size,bounds.size.y)
			max_size = maxf(max_size,bounds.size.y)
		for i in pushers.size():
			var pusher = pushers[i]
			var along: float = (pusher._body.global_position - pusher._start_pos).dot(pusher.push_axis.normalized())
			max_pusher_floor_error = maxf(max_pusher_floor_error, absf(pusher._body.global_position.y - pusher.block_size * 0.49 - grid.global_position.y - 0.5))
			moved_forward[i] = moved_forward[i] or along > 1.99
			observed_pause[i] = observed_pause[i] or (pusher._paused and along > 1.99)
	check("pusher collider bottom stays on deck throughout cycle", max_pusher_floor_error < 0.002, max_pusher_floor_error)
	check("grower collider floor fixed throughout cycle", max_floor_error < 0.002,max_floor_error)
	check("grower mesh matches collider throughout cycle", max_mesh_error < 0.002,max_mesh_error)
	check("grower reaches small authored size", absf(min_size-0.3)<0.002,min_size)
	check("grower reaches large authored size", absf(max_size-3.5)<0.002,max_size)
	for i in pushers.size():
		check("pusher actually reaches configured endpoint " + str(i),moved_forward[i])
		check("pusher pauses at configured endpoint " + str(i),observed_pause[i])
	measurements["grower_max_floor_error_m"] = max_floor_error
	measurements["grower_min_size_m"] = min_size
	measurements["grower_max_size_m"] = max_size
	measurements["floor_baselines"] = floor_baselines
	var legacy = load("res://commons/hazards/transformation_blocks/grower_block.tscn").instantiate()
	root.add_child(legacy)
	legacy.set_physics_process(false)
	legacy._time = 0.0
	legacy._update_size()
	check("legacy default remains centre anchored", legacy.anchor == "center" and legacy._body.position.is_zero_approx())
	check("legacy default keeps midpoint start", is_equal_approx(legacy._box_shape.size.x,1.3),legacy._box_shape.size.x)
	legacy.queue_free()
	var legacy_pusher = load("res://commons/hazards/transformation_blocks/pusher_block.tscn").instantiate()
	root.add_child(legacy_pusher)
	legacy_pusher.set_physics_process(false)
	check("legacy pusher keeps default X path", (legacy_pusher._end_pos-legacy_pusher._start_pos).is_equal_approx(Vector3.RIGHT*3.0))
	legacy_pusher._t = 0.4
	legacy_pusher.apply_grid_config({"speed":2.5})
	check("speed-only update keeps pusher progress", is_equal_approx(legacy_pusher._t,0.4))
	legacy_pusher.queue_free()
