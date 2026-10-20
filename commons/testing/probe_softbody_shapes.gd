extends SceneTree
## WHICH COLLIDER SHAPES CAN A SOFT BODY ACTUALLY TOUCH?
##
## The funnel's ball has now ignored a bead ring entirely (fell 490 m through
## six fat SphereShape3D beads AND a thick BoxShape3D tray beneath them), while
## the same ball rested politely on a lone box floor in probe_softbody_bench.
## That pattern smells like a SUPPORT MATRIX, not a tuning problem: GodotPhysics
## may simply not generate soft-body contacts for some shape types.
##
## One ball, one shape under it, ten seconds, four cells: box, sphere, capsule,
## cylinder. Whatever the ball falls through is a shape the funnel must not be
## built from. (The tray mystery rides on this too: if the ball reaches 490 m it
## never met the tray box either -- unless the ball DIES on the bead contact
## instead of colliding. The bench says per shape.)

func _ball() -> SoftBody3D:
	var b := SoftBody3D.new()
	var sm := SphereMesh.new()
	sm.radius = 0.075
	sm.height = 0.15
	sm.radial_segments = 24
	sm.rings = 12
	b.mesh = sm
	b.linear_stiffness = 0.9
	b.pressure_coefficient = 10.0
	b.damping_coefficient = 0.08
	b.total_mass = 0.5
	b.simulation_precision = 8
	b.position = Vector3(0, 0.2, 0)
	return b


func _cell(label: String, shape: Shape3D) -> void:
	var root := Node3D.new()
	get_root().add_child(root)
	var sb := StaticBody3D.new()
	var cs := CollisionShape3D.new()
	cs.shape = shape
	cs.position = Vector3(0, -0.2, 0)
	sb.add_child(cs)
	root.add_child(sb)
	var ball := _ball()
	root.add_child(ball)
	for i in range(300):
		await physics_frame
	var bb: AABB = PhysicsServer3D.call("soft_body_get_bounds", ball.get_physics_rid())
	var bottom := bb.position.y
	var held := bottom > -0.5
	print("%-10s bottom=%.3f m  -> %s" % [label, bottom, "HOLDS" if held else "FALLS THROUGH"])
	root.queue_free()
	await process_frame


func _init() -> void:
	Engine.time_scale = 1.0

	var box := BoxShape3D.new()
	box.size = Vector3(0.6, 0.2, 0.6)
	await _cell("box", box)

	var sph := SphereShape3D.new()
	sph.radius = 0.3
	await _cell("sphere", sph)

	var cap := CapsuleShape3D.new()
	cap.radius = 0.15
	cap.height = 0.6
	await _cell("capsule", cap)

	var cyl := CylinderShape3D.new()
	cyl.radius = 0.3
	cyl.height = 0.2
	await _cell("cylinder", cyl)

	print("probe_softbody_shapes: done")
	quit(0)
