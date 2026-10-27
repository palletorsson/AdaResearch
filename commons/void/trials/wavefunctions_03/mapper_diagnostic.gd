extends SceneTree
func _initialize():run.call_deferred()
func run():
	var fm=load("res://algorithms/wavefunctions/mariocontrol/DualBallFMController.tscn").instantiate()
	fm.position=Vector3(0,-6,3)
	fm.set_meta("config_stand","desks")
	for key in ["Ball1_Carrier","Ball2_Modulator"]:
		fm.get_node(key).set_script(load("res://commons/void/mapper_3d_physics.gd"))
	root.add_child(fm)
	for i in 30:await process_frame
	fm.set_baseline()
	for i in 25:
		await process_frame
		var p=fm.carrier_ball
		print("POSE ",i," local=",p.position," global=",p.global_position," physics=",PhysicsServer3D.body_get_state(p.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM).origin," frozen=",p.freeze," held=",p.is_picked_up()," freq=",fm.carrier_freq)
	fm.queue_free()
	await process_frame
	quit()
