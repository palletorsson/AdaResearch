extends SceneTree
## A walker's pace must be its token, whatever its scale. leg_walker_base advanced
## the body by -basis.z * patrol_speed, and basis carries walker_scale, so a
## scale-4 body paced four times its token (VFM_09_Legs' octapod, 2026-09-02).
## Instantiates one walker twice, at scale 1 and scale 4, drives _walk for one
## second each and measures the path length. Both must be the token's 0.35 m.

func _init() -> void:
	var fails := 0
	var scene: PackedScene = load("res://commons/hazards/octapod_crawler/six_leg_critter.tscn")
	for s in ["1.0", "4.0"]:
		var inst: Node = scene.instantiate()
		root.add_child(inst)
		var body: Node3D = inst.get_node("Body")
		body.apply_grid_config({"walker_scale": s, "patrol_speed": "0.35", "driven_by_player": "false", "show_foot_markers": "false"})
		body._floor_settle = 99.0   # the floor ray reads the physics space, which is closed outside a physics tick and aborts _walk
		var last: Vector3 = body.position   # LOCAL: in a SceneTree _init the root is not live, so global_position reads zero
		var path := 0.0
		var old_formula := 0.0     # what the un-normalised advance would have moved on this same basis
		for i in 60:
			old_formula += (-body.basis.z * (1.0 / 60.0) * 0.35).length()
			body._walk(1.0 / 60.0)
			var now: Vector3 = body.position
			var d := now - last; d.y = 0.0
			path += d.length(); last = now
		print("scale %s: walker_scale read back %.2f, basis.z length %.2f, path in one second %.3f m (token says 0.35); the old -basis.z formula would have moved %.2f m" % [s, body.walker_scale, body.basis.z.length(), path, old_formula])
		if absf(path - 0.35) > 0.02:
			print("   FAIL the pace is not the token's"); fails += 1
		inst.queue_free()
	print("")
	print("PROBE %s" % ("OK" if fails == 0 else "FAILED %d" % fails))
	quit(fails)
