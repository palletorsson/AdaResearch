extends SceneTree
## The grid-zone wall, removed from the museum — proven on the REAL scene.
##
## The rig's PlayerBoundsCheck ships a 10 m box around the world origin,
## which is right for grid maps and wrong for a museum at x 0..15 extending
## endlessly in +z: walking anywhere yanked the player back. The museum's VR
## setup reshapes it (x ±20, y ±10, z unbounded) and keeps it active as the
## net under a player who escapes every catch slab. This trial instantiates
## endless_museum_staged.tscn — the scene the menu actually loads, rig
## included — forces the VR path, and asserts the reshape landed.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_bounds.gd

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array[String] = []
	var ps: PackedScene = load("res://commons/scenes/endless_museum_staged.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	var museum: Node = inst.get_node_or_null("Museum")
	if museum == null:
		fails.append("staged scene has no Museum child")
	else:
		museum.set("_force_vr", true)
		museum.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	for i in range(6):
		await create_timer(0.25).timeout

	var bounds: Node = inst.find_child("PlayerBoundsCheck", true, false)
	if bounds == null:
		fails.append("no PlayerBoundsCheck in the staged scene's rig")
	else:
		var bb: Vector3 = bounds.get("box_bounds")
		if bb.x != 20.0 or bb.y != 10.0 or bb.z < 1.0e9:
			fails.append("box_bounds %s — the museum reshape did not land" % str(bb))
		if int(bounds.get("check_type")) != 0:
			fails.append("check_type %s != BOX" % str(bounds.get("check_type")))
		if not bool(bounds.get("active")):
			fails.append("bounds check was DISABLED — the net should stay, reshaped")
		# the walk itself must be legal: a player deep in the museum at
		# z 500 is inside bounds now, and the old 10 m box would have failed
		var deep := Vector3(7.5, 1.7, 500.0)
		if absf(deep.x) > bb.x or absf(deep.y) > bb.y or absf(deep.z) > bb.z:
			fails.append("z=500 would still reset — bounds not museum-shaped")

	get_root().remove_child(inst)
	inst.queue_free()
	if fails.is_empty():
		print("EM BOUNDS: PASS — the grid wall is gone, the net remains (x ±20, y ±10, z open)")
	else:
		print("EM BOUNDS: FAIL %d" % fails.size())
		for f in fails:
			print("  - " + f)
	quit(0 if fails.is_empty() else 1)
