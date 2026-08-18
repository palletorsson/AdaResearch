extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(4.0).timeout
	for r in (m.get("_edit_records") as Array):
		var rd: Dictionary = r
		if String(rd.get("token", "")) == "origin":
			var n: Node3D = rd.get("node")
			var box: AABB = m.call("_extent_of", n)
			print("ORIGIN %s kind=%s pos %s  aabb %s .. %s  scale %s" % [n.name, rd.get("kind"), n.global_position, box.position, box.end, n.scale])
	quit(0)
