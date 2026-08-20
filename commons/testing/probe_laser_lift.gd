extends SceneTree
## Are the three laser measures standing at 1 m, frozen? Counts and heights.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_laser_lift.gd

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	for i in range(30):
		await create_timer(0.1).timeout
		if (inst.get("_stamp_queue") as Array).is_empty():
			break
	# settle a beat: frozen bodies must NOT sink
	await create_timer(1.0).timeout
	var rows: Array = []
	for r in (inst.get("_vis_records") as Array):
		var n: Node3D = (r as Dictionary).get("node") as Node3D
		if n != null and is_instance_valid(n) and n.has_meta("artifact_lookup_name") \
				and String(n.get_meta("artifact_lookup_name")) == "laser_measure":
			var frozen: bool = bool(n.get("freeze")) if "freeze" in n else false
			rows.append("laser_measure at (%.1f, %.2f, %.1f) freeze=%s" % [
				n.global_position.x, n.global_position.y, n.global_position.z, frozen])
	for line in rows:
		print(line)
	var f := FileAccess.open("res://ada_run/laser_lift_probe.txt", FileAccess.WRITE)
	f.store_string("\n".join(rows))
	f.close()
	quit(0)
