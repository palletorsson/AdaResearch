extends SceneTree
## PROBE: the pearl's stage — raised deck, wedges, walk cells, bodies on top
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_first_chapter", "primitives")
	m.set("start_map", "Point_Triangle_Context")
	get_root().add_child(m)
	await create_timer(5.0).timeout
	var wedges: Array = m.find_children("StageWedge*", "Node3D", true, false)
	print("STAGE wedges: %d" % wedges.size())
	for w in wedges:
		print("   %s world %s yaw %.0f scale %s" % [w.name, (w as Node3D).global_position, (w as Node3D).rotation_degrees.y, (w as Node3D).scale])
	# bodies whose cell is inside the stage rect stand on it
	var inv: Array = m.get("_inventory")
	for rec_v in inv:
		var rec: Dictionary = rec_v
		var c: Array = rec.get("cell", [])
		if c.size() >= 2 and int(c[0]) >= 2 and int(c[0]) < 8 and int(c[1]) >= 6 and int(c[1]) < 10:
			print("ON STAGE: %s cell %s world y %.2f (kind %s)" % [rec.get("token"), str(c), float((rec.get("world") as Array)[1]), rec.get("kind")])
	quit(0)
