extends SceneTree
## Are the museum's pickables grabbable? Counts every XRToolsPickable the
## first segment builds and prints the state a FunctionPickup needs: enabled
## (not process-disabled), collision layer on the grab mask, freeze, scale.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_force_vr", true)
	get_root().add_child(m)
	await create_timer(4.0).timeout
	var GRAB_MASK: int = 0b0000_0000_0000_0100_0000_0000_0000_0100
	var stack: Array = [m]
	var n_pick: int = 0
	var rows: Array = []
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		if n.has_method("pick_up") and n.has_method("let_go") and n is RigidBody3D:
			n_pick += 1
			var rb: RigidBody3D = n as RigidBody3D
			var enabled: bool = n.can_process()
			var on_mask: bool = (rb.collision_layer & GRAB_MASK) != 0
			var tok: String = ""
			var a: Node = n
			while a != null and tok == "":
				if a.has_meta("artifact_lookup_name"): tok = String(a.get_meta("artifact_lookup_name"))
				a = a.get_parent()
			rows.append("%-28s %-22s enabled=%s layer=%d on_mask=%s freeze=%s scale=%.2f mode=%d visible=%s enabled_export=%s" % [tok, n.name, enabled, rb.collision_layer, on_mask, rb.freeze, rb.global_transform.basis.get_scale().x, n.process_mode, (n as Node3D).is_visible_in_tree(), n.get("enabled")])
	print("EM PICKABLES: %d" % n_pick)
	for r in rows: print("  " + r)
	quit(0)
