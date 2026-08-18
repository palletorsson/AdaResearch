extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(m)
	await create_timer(4.0).timeout
	for nm in ["Lobby_view", "Lobby_window", "Lobby_counter", "Lobby_extinguisher", "Lobby_elevator", "Lobby_pallet"]:
		var n: Node3D = m.find_child(nm, true, false)
		if n == null: print("%s: MISSING" % nm); continue
		var box: AABB = m.call("_extent_of", n)
		print("%-18s pos %s  aabb %s .. %s" % [nm, n.global_position, box.position, box.position + box.size])
	quit(0)
