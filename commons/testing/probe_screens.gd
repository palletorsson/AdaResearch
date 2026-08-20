extends SceneTree
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_first_chapter", "primitives")
	get_root().add_child(m)
	await create_timer(6.0).timeout
	var n := 0
	for node in m.find_children("*", "Node3D", true, false):
		if String(node.get_meta("artifact_lookup_name", "")) == "science_screen" or String(node.name).to_lower().contains("science_screen"):
			if node.get("support") != null:
				n += 1
				print("SCREEN %d at %s support=%s scan=%s" % [n, node.global_position, str(node.get("support")), str(node.get("scan_radius"))])
	var lasers := 0
	for node in m.find_children("*", "Node3D", true, false):
		var nm := String(node.get_meta("artifact_lookup_name", ""))
		if nm == "laser_measure" or nm == "laser_exploding_sphere":
			lasers += 1
	print("SCREENS: %d · laser bodies: %d (want 6)" % [n, lasers])
	quit(0)
