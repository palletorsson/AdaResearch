extends SceneTree
## Measure the gait rather than squint at it: per-leg planted-to-home distance
## over time, against the threshold that is supposed to trigger a step.
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var stage := Node3D.new(); get_root().add_child(stage)
	var crab: Node3D = (load("res://commons/hazards/head_crab/head_crab.tscn") as PackedScene).instantiate() as Node3D
	stage.add_child(crab)
	crab.global_position = Vector3.ZERO
	var w := CharacterBody3D.new(); w.name = "Walker"; w.add_to_group("em_walker")
	stage.add_child(w); w.global_position = Vector3(0, 0, -8)
	await create_timer(0.8).timeout
	var thr: float = float(crab.get("_step_threshold"))
	var ride: float = float(crab.get("_ride"))
	print("threshold %.3f m   ride %.3f m   scale %.2f" % [thr, ride, float(crab.get("crab_scale"))])
	# how long IS a leg? the authored chain, scaled
	var sk: Node = crab.get_node_or_null("Rig/IK_leg_0/Armature/Skeleton3D")
	if sk is Skeleton3D:
		var s3 := sk as Skeleton3D
		var reach: float = 0.0
		for b in range(s3.get_bone_count() - 1):
			reach += s3.get_bone_global_rest(b).origin.distance_to(s3.get_bone_global_rest(b + 1).origin)
		print("leg chain rest length %.3f (rig units) -> %.3f m at scale" % [reach, reach * float(crab.get("crab_scale"))])
	for tick in range(8):
		await create_timer(0.45).timeout
		var planted: Array = crab.get("_planted")
		var line := "t%02d  pos %5.2f  " % [tick, crab.global_position.z]
		for i in range(4):
			var home: Vector3 = crab.call("_home", i)
			line += "L%d %.2f  " % [i, (planted[i] as Vector3).distance_to(home)]
		print(line)
	var f := FileAccess.open("res://ada_run/crab_gait.txt", FileAccess.WRITE)
	f.store_string("done\n"); f.close()
	quit(0)
