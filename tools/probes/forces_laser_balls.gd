extends SceneTree
## Production rays and autonomous turret updates, including two independent pools.
var checks: Array = []
var failures: Array = []
var world: Node3D
func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"label":label,"passed":passed})
	if not passed: failures.append(label); push_error(label)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func pool(at: Vector3) -> Node3D:
	var d = load("res://commons/artifacts/turret_targeting/ball_dropper.gd").new()
	d.auto_drop=false; d.total_balls=2; d.spawn_spread=0; d.position=at
	world.add_child(d); return d
func ball_at(d: Node3D, at: Vector3) -> Node3D:
	var b = d.drop_ball(); await frames(3)
	var rb: RigidBody3D=b.get_node("RigidBody3D")
	rb.freeze=true; rb.global_position=at
	await frames(3); return b
func confetti(d: Node3D) -> Array:
	return d.get_children().filter(func(n): return n.get_script()!=null and n.get_script().resource_path.ends_with("queer_confetti.gd"))
func run() -> void:
	await process_frame
	world=Node3D.new(); root.add_child(world)
	var other=pool(Vector3(20,1,0)); var d=pool(Vector3(0,1,-3))
	var b=await ball_at(d,Vector3(0,1,-3))
	other.remove_ball(b)
	check("wrong pool cannot hide or recycle another pool's ball",b.visible and d.active_balls.has(b) and other.active_balls.is_empty())
	var laser=load("res://commons/primitives/laser_measure/laser_measure.gd").new()
	world.add_child(laser); laser.global_position=Vector3(0,1,0); laser.set_process(false)
	await frames(3)
	laser.perform_measurement()
	check("actual ray finds the ball's physics child",laser.raycast.get_collider()==b.get_node("RigidBody3D"))
	for i in range(60): laser.perform_measurement()
	check("measurement without burn permission leaves ball intact",b.visible and b.get_meta("health")==80.0)
	laser.burns=true; laser.burn_seconds=1.2
	for i in range(18): laser.perform_measurement()
	check("half dwell does not destroy",b.visible and confetti(d).is_empty())
	laser.rotation.y=PI/2; laser.perform_measurement(); laser.rotation.y=0
	for i in range(18): laser.perform_measurement()
	check("looking away resets accumulated dwell",b.visible)
	for i in range(20): laser.perform_measurement()
	check("continuous ray burn destroys and removes the active ball",not b.visible and d.active_balls.is_empty() and b.get_meta("health")==0.0)
	check("destroyed ball has no ghost collider",b.get_node("RigidBody3D").collision_layer==0 and b.get_node("RigidBody3D").collision_mask==0)
	check("one death produces one confetti burst",confetti(d).size()==1)
	b.trigger_explosion(); b.take_damage(100); laser.perform_measurement()
	check("repeat hits cannot duplicate confetti or pool entries",confetti(d).size()==1 and d.available_balls.size()==2)
	var burst=confetti(d)[0]; var start: Vector3=burst._base[0][0].origin
	await create_timer(0.2).timeout
	check("confetti really moves and uses four shape batches",burst._base[0][0].origin.distance_to(start)>0.01 and burst._mm.size()==4)
	check("confetti starts at the destroyed body's world location",burst.global_position.is_equal_approx(Vector3(0,1,-3)))
	await create_timer(2.0).timeout
	check("confetti cleans itself up",not is_instance_valid(burst))
	var reused=await ball_at(d,Vector3(0,1,-3))
	check("same ball returns with full health and collisions",reused==b and b.visible and b.get_meta("health")==80.0 and b.get_node("RigidBody3D").collision_layer==1)
	laser.queue_free(); d.clear_all(); await frames(2)
	check("reset does not celebrate undamaged balls",confetti(d).is_empty())
	# Autonomous firing must work far from the world's origin, as in real halls.
	var turret=load("res://commons/artifacts/sentry_turret/sentry_turret.tscn").instantiate()
	turret.position=Vector3(120,0,80); world.add_child(turret)
	turret.apply_grid_config({"target":"balls","use_laser_damage":"true","laser_damage_per_hit":80})
	check("range configured for damaging laser and no player target",turret.use_laser_damage and not turret.target_player)
	b=await ball_at(d,Vector3(120,1,83))
	await create_timer(0.25).timeout
	check("autonomous laser removes health once per tick",float(b.get_meta("health"))<80 and float(b.get_meta("health"))>40)
	await create_timer(1.0).timeout
	check("autonomous laser destroys a ball and creates confetti",not b.visible and confetti(d).size()==1)
	check("laser preserves reusable pool identities",d.ball_pool.size()==2 and d.ball_pool.all(func(n):return is_instance_valid(n)))
	turret.apply_grid_config({"use_laser_damage":"false","reload_time":0.3})
	check("false config really selects projectile mode",not turret.use_laser_damage)
	b=await ball_at(d,Vector3(120,0.5,83))
	await create_timer(4.0).timeout
	print("PROJECTILE STATE health=",b.get_meta("health")," target=",turret.current_target," muzzle=",turret.muzzle_pos.global_position," ball=",b.get_node("RigidBody3D").global_position," forward=",turret.barrel.global_basis.z)
	check("real projectiles fly out of muzzle and finish a ball",not b.visible and float(b.get_meta("health"))==0.0)
	turret.queue_free(); await frames(3)
	var classic=load("res://commons/artifacts/turret_targeting/laser_turret.gd").new()
	classic.position=Vector3(120,0,80); classic.rotation.y=PI/2; classic.target_player=false; world.add_child(classic)
	b=await ball_at(d,Vector3(120,1.2,83))
	await create_timer(4.0).timeout
	check("rotated tracking laser aims up and destroys via shared receiver",not b.visible and classic.total_kills==1)
	check("tracking laser never frees the pooled ball",is_instance_valid(b) and d.available_balls.has(b))
	classic.queue_free(); var owned: Array=d.ball_pool.duplicate(); d.queue_free(); await frames(3)
	check("unloading hall removes pooled world bodies",owned.all(func(n):return not is_instance_valid(n)))
	var report={"passed":failures.is_empty(),"checks":checks,"failures":failures,"physics":ProjectSettings.get_setting("physics/3d/physics_engine")}
	FileAccess.open("res://ada_run/forces_laser_balls.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("LASER BALLS ",checks.size()-failures.size(),"/",checks.size()); quit(0 if failures.is_empty() else 1)
