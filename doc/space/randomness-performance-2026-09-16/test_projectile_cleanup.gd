extends SceneTree
func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var world := Node3D.new()
	root.add_child(world);current_scene=world
	var spawner: Node3D=load("res://commons/primitives/cubes/cube_spawner.tscn").instantiate()
	spawner.auto_start=false
	world.add_child(spawner)
	spawner.is_active=true
	spawner.call("_spawn_projectile")
	spawner.call("_spawn_projectile")
	var projectiles: Array=spawner.active_projectiles.duplicate()
	if projectiles.size()!=2:
		push_error("Fixture did not spawn two cubes");quit(2);return
	var original_positions: Array=[]
	for projectile in projectiles:
		original_positions.append(str(projectile.global_position))
		if projectile.get_parent()!=world:
			push_error("World-space projectile placement changed");quit(2);return
	spawner.queue_free()
	await process_frame
	await process_frame
	await process_frame
	var survivors:=0
	for projectile in projectiles:
		if is_instance_valid(projectile): survivors+=1
	print("[projectile-cleanup] spawned=2 survivors=",survivors," positions=",original_positions)
	quit(0 if survivors==0 else 1)
