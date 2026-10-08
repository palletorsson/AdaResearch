extends SceneTree
## A longer physics run without readbacks: verify bounded repeated production.
func _initialize() -> void: run.call_deferred()
func run() -> void:
	var room := Node3D.new(); root.add_child(room)
	var floor_body := StaticBody3D.new(); room.add_child(floor_body)
	var floor_shape := CollisionShape3D.new(); var box := BoxShape3D.new()
	box.size = Vector3(12,0.2,12); floor_shape.shape = box; floor_body.add_child(floor_shape)
	floor_body.position.y = -0.1
	var net = load("res://commons/infoboards_3d/visualizations/polyhedron_nets_cube.tscn").instantiate()
	net.apply_grid_config({"fall_cycle":true,"edge_length":0.7,"fold_duration":0.2,"think_hold":0.5})
	room.add_child(net)
	var cycle = net._fall_controller
	var frames := 0; var unsafe := false; var settled: Dictionary = {}
	while cycle.completed_cycles<26 and frames<18000:
		await physics_frame; frames+=1
		if cycle.phase == "THINK": settled[cycle.body.get_instance_id()] = true
		for item in cycle.dropped_cubes:
			unsafe = unsafe or item.global_position.y < -0.1
	var result := {"cycles":cycle.completed_cycles,"settled_drops":settled.size(),"retained":cycle.dropped_cubes.size(),"no_bodies_below_floor":not unsafe}
	result.passed = cycle.completed_cycles==26 and settled.size()==26 and cycle.dropped_cubes.size()==24 and not unsafe
	print("[cube-collection] ",JSON.stringify(result))
	FileAccess.open("res://ada_run/cube-net-cycle/collection-stress.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
