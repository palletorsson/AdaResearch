extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var ride := find_scene("/random_return.gd")
	check("sphere installed",ride != null)
	if ride == null:return
	ride.set_physics_process(false)
	ride.restart(42)
	await snapshot("sphere-centre",ride.to_global(Vector3(3.7,1.75,-3.2)),ride.to_global(Vector3(0,1.0,0)),62)
	ride.advance(ride.WAIT_SECONDS+ride.LEG_SECONDS)
	await snapshot("sphere-out",ride.to_global(Vector3(3.7,1.75,-3.2)),ride.to_global(Vector3(0,1.0,0)),62)
	# Check ordinary desktop props still follow the camera after the opt-in hook.
	var body: CharacterBody3D = museum.get("_player")
	var hand: Node3D = body.get_node("DesktopHand")
	var prop := RigidBody3D.new()
	prop.freeze = true
	root.add_child(prop)
	prop.global_position = hand.global_position+Vector3(2,0,0)
	var start := prop.global_position
	hand.call("_grab_held",prop)
	hand.call("_process",0.016)
	check("ordinary carried props still follow the desktop hand",not prop.global_position.is_equal_approx(start))
	hand.call("_drop_held")
	prop.queue_free()

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"passed":failures.is_empty()},"  "))
	quit(0 if failures.is_empty() else 1)
