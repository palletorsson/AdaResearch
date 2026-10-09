extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	var turret=find_scene("/sentry_turret.gd")
	var dropper=find_scene("/ball_dropper.gd")
	check("museum loads its real turret and dropper",turret!=null and dropper!=null)
	if turret==null or dropper==null:return
	check("museum beam damages balls, not the visitor",turret.use_laser_damage and turret.target_balls and not turret.target_player)
	check("museum beam delivers eighty health units per second",is_equal_approx(turret.laser_damage_per_hit,80))
	check("museum target pool retains eight balls",dropper.ball_pool.size()==8)
	var wardrobe: Node=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").visible=false
	camera.set_cull_mask_value(19,false)
	dropper.auto_drop=false; dropper.clear_all(); turret.set_process(false)
	var ball=dropper.drop_ball(); await tick(); await tick()
	var rb: RigidBody3D=ball.get_node("RigidBody3D")
	# Hold one target still for a legible before/after photograph. Damage remains
	# the production turret's own update, not a probe call to the death function.
	rb.freeze=true; rb.global_position=dropper.global_position+Vector3(0,-0.6,0)
	var target: Vector3=rb.global_position
	var eye: Vector3=turret.global_position+Vector3(-2,1.0,1.7)
	await snapshot("range-before",eye,target,59)
	turret.set_process(true)
	var until=Time.get_ticks_msec()+4000
	while ball.visible and Time.get_ticks_msec()<until:await process_frame
	check("museum turret destroys the ball through normal firing",not ball.visible and float(ball.get_meta("health"))==0)
	check("hit returns ball to its own pool",dropper.available_balls.has(ball) and is_instance_valid(ball))
	var bursts=dropper.get_children().filter(func(n):return n.get_script()!=null and n.get_script().resource_path.ends_with("queer_confetti.gd"))
	check("museum death emits one confetti burst",bursts.size()==1)
	await snapshot("range-confetti",eye,target,59)
	# A second pass with a genuinely falling ball: no fixture, no freeze.
	var falling=dropper.drop_ball(); await tick(); await tick()
	check("fresh ball is physically falling",not falling.get_node("RigidBody3D").freeze)
	until=Time.get_ticks_msec()+5000
	while falling.visible and Time.get_ticks_msec()<until:await process_frame
	check("museum laser also catches the freely falling ball",not falling.visible)
	await create_timer(2.1).timeout
	bursts=dropper.get_children().filter(func(n):return n.get_script()!=null and n.get_script().resource_path.ends_with("queer_confetti.gd"))
	check("museum confetti disappears after the celebration",bursts.is_empty())
	observations["capture_note"]="One target held stationary for before/after photographs; second destruction tested on a freely falling ball. Actual museum renderer and production turret."
