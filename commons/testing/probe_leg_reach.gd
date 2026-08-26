extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var stage := Node3D.new(); get_root().add_child(stage)
	var rig: Node3D = (load("res://commons/hazards/octapod_crawler/csg_four_leg_walker.tscn") as PackedScene).instantiate() as Node3D
	stage.add_child(rig)
	await create_timer(0.9).timeout
	var lines: Array = []
	for sk in rig.find_children("*", "Skeleton3D", true, false):
		var s3 := sk as Skeleton3D
		var reach := 0.0
		for b in range(s3.get_bone_count() - 1):
			reach += s3.get_bone_global_rest(b).origin.distance_to(s3.get_bone_global_rest(b + 1).origin)
		lines.append("%s bones=%d rest_chain=%.3f" % [s3.get_parent().get_parent().name, s3.get_bone_count(), reach])
	# and where the shoulders actually are
	for i in range(4):
		var n: Node = rig.get_node_or_null("IK_leg_%d" % i)
		if n is Node3D:
			lines.append("IK_leg_%d at %s" % [i, str((n as Node3D).position)])
		var sa: Node = rig.get_node_or_null("SpringArm3D_%d" % i)
		if sa is Node3D:
			lines.append("SpringArm_%d at %s len=%.2f" % [i, str((sa as Node3D).position), float(sa.get("spring_length"))])
	var f := FileAccess.open("res://ada_run/leg_reach.txt", FileAccess.WRITE)
	f.store_string("\n".join(PackedStringArray(lines)) + "\n"); f.close()
	print("\n".join(PackedStringArray(lines)))
	quit(0)
