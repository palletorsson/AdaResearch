extends SceneTree
## WHICH INGREDIENT EXPLODES THE SOFT BODY?
##
## droplet_cusp's ball has now blown up against three different colliders (CSG
## trimesh, a box ring, a bead ring), which says the collider was never the
## cause. This bench drops ONE SoftBody3D sphere onto ONE static box floor --
## the simplest contact that exists -- and varies the two remaining suspects:
## Engine.time_scale (the probe ran at 4 to save wall-clock) and
## pressure_coefficient (firm used 60, a number taken on faith).
##
## Four cells, factorial. Whatever survives here is a safe recipe; whatever
## dies here was never going to work in the funnel either.

func _cell(ts: float, press: float) -> String:
	Engine.time_scale = ts
	var root := Node3D.new()
	get_root().add_child(root)

	var floor_body := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = Vector3(1.0, 0.1, 1.0)
	cs.shape = bs
	cs.position = Vector3(0, -0.05, 0)
	floor_body.add_child(cs)
	root.add_child(floor_body)

	var ball := SoftBody3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.075
	sm.height = 0.15
	sm.radial_segments = 16
	sm.rings = 8
	ball.mesh = sm
	ball.linear_stiffness = 0.9
	ball.pressure_coefficient = press
	ball.damping_coefficient = 0.08
	ball.total_mass = 0.5
	ball.simulation_precision = 8
	ball.position = Vector3(0, 0.2, 0)
	root.add_child(ball)

	var verdictxt := "?"
	for i in range(240):
		await physics_frame
		if i % 60 == 59:
			var bb: AABB = PhysicsServer3D.call("soft_body_get_bounds", ball.get_physics_rid())
			var top := bb.position.y + bb.size.y
			if not is_finite(top) or absf(top) > 10.0:
				verdictxt = "EXPLODED at tick %d (top %.1e m)" % [i, top]
				break
			verdictxt = "ok, top %.3f m, bottom %.3f m" % [top, bb.position.y]
	root.queue_free()
	await process_frame
	return verdictxt


func _init() -> void:
	for cell in [[1.0, 10.0], [1.0, 60.0], [4.0, 10.0], [4.0, 60.0]]:
		var r := await _cell(cell[0], cell[1])
		print("time_scale=%.0f pressure=%.0f -> %s" % [cell[0], cell[1], r])
	Engine.time_scale = 1.0
	print("probe_softbody_bench: done")
	quit(0)
