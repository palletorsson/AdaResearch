extends "res://doc/book/iterations/2026-09-19-transformation-review/probes/late/probe_transformation_opening.gd"
## Real museum audit. Default Body; use -- --map=Trans_Pit for the timed study.

func _initialize() -> void:
	map_name = "Trans_Body"
	_run.call_deferred()

func check_crossings(grid: Node3D) -> void:
	if map_name == "Trans_Body": await _body_check(grid)
	else: await _pit_check(grid)

func _body_check(grid: Node3D) -> void:
	var carve = by_script(grid,"/carve_grid.gd")[0]
	var field = by_script(grid,"/approach_scale.gd")[0]
	var height := 0.0
	for centre in carve._centre:
		height = maxf(height,centre.y+carve._half)
	check("lattice is low and open above a 1.7 m eye height",height>1.2 and height<1.4,height)
	measurements["lattice_top_m"] = height
	var body := CharacterBody3D.new()
	body.add_to_group("em_walker")
	body.collision_layer = 1
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.26
	capsule.height = 1.7
	shape.shape = capsule
	shape.position.y = 0.85
	body.add_child(shape)
	root.add_child(body)
	body.global_position = grid.to_global(Vector3(5,0.5,10.0))
	for i in 45: await tick()
	var removed: int = carve._carved
	check("natural body proximity removes live cells",removed>0,removed)
	body.global_position = grid.to_global(Vector3(5,0.5,21.0))
	for i in 90: await tick()
	var nearby: float = _smallest_factor(field._shown)
	check("field is still responding beside old closure caption",nearby<0.99,nearby)
	check("cut persists after leaving lattice",carve._carved==removed)
	body.global_position = grid.to_global(Vector3(5,0.5,23.0))
	for i in 150: await tick()
	var clear: float = _smallest_factor(field._shown)
	check("field returns after body clears its reach",clear>0.99,clear)
	measurements["scale_near_old_caption_factor"] = nearby
	measurements["scale_after_step_clear_factor"] = clear
	measurements["carved_cells"] = removed
	body.queue_free()

func _pit_check(grid: Node3D) -> void:
	var pushers := by_script(grid,"/pusher_block.gd")
	var growers := by_script(grid,"/grower_block.gd")
	check("three separate pusher lanes remain",pushers.size()==3)
	check("three common-tempo growers remain",growers.size()==3)
	var query_shape := BoxShape3D.new()
	query_shape.size = Vector3.ONE * 0.978
	var space := grid.get_world_3d().direct_space_state
	for pusher in pushers:
		var start: Vector3 = pusher._start_pos
		var finish_at: Vector3 = pusher._end_pos
		measurements["pusher_start_" + str(pusher.name)] = str(grid.to_local(start))
		check("pusher uses two-metre authored travel " + str(pusher.name),is_equal_approx(start.distance_to(finish_at),2.0),str(finish_at-start))
		var clear := true
		var blockers: Array = []
		for i in 81:
			var point := start.lerp(finish_at,float(i)/80.0)
			# Full block volume, inset 1 mm per face to exclude its support contact.
			var q := PhysicsShapeQueryParameters3D.new()
			q.shape = query_shape
			q.transform = Transform3D(Basis.IDENTITY,point)
			q.collision_mask = 1
			q.exclude = [pusher._body.get_rid()]
			var hits := space.intersect_shape(q,8)
			if not hits.is_empty():
				clear = false
				for hit in hits: blockers.append(str(hit.collider.get_path()))
				break
		check("full swept pusher box stays clear of walls " + str(pusher.name),clear,blockers)
	var route: Array[Vector3] = []
	for i in 41: route.append(Vector3(8,0.9,2+float(i)*0.1))
	for i in 11: route.append(Vector3(8-float(i)*0.1,0.9,6))
	for i in 26: route.append(Vector3(7,0.9,6+float(i)*0.1))
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.26
	capsule.height = 1.7
	var route_clear := true
	for point in route:
		var q := PhysicsShapeQueryParameters3D.new()
		q.shape = capsule
		q.transform = Transform3D(Basis.IDENTITY,grid.to_global(point+Vector3.UP*0.5))
		q.collision_mask = 1
		if not space.intersect_shape(q,1).is_empty():
			route_clear = false
			measurements["bypass_blocked_at"] = str(point)
			break
	check("a 52 cm capsule can use the eastern pusher bypass",route_clear)
	for grower in growers:
		check("grower shares the authored period " + str(grower.name),is_equal_approx(grower.grow_speed,0.15))
	measurements["common_grower_period_s"] = 1.0/0.15
	measurements["pusher_collision_sweep_samples"] = 81
	measurements["bypass_width_probe_m"] = 0.52

func _smallest_factor(values: PackedFloat32Array) -> float:
	var smallest := 1.0
	for value in values:
		smallest = minf(smallest, value)
	return smallest
