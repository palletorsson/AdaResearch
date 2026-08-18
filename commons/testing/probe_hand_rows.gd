extends SceneTree
## Where do the plan's hand-placed bodies actually stand after a build?
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(m)          # no flags: as Play does
	await create_timer(3.0).timeout
	var want := ["you_are_here", "fontana_puncture", "origin", "subtraction_suite", "frame_counter_display"]
	for r in (m.get("_edit_records") as Array):
		var rd: Dictionary = r
		if want.has(String(rd.get("token", ""))):
			var n: Node3D = rd.get("node") as Node3D
			print("[probe] %-24s tile_cell=%s  world=(%.1f, %.1f, %.1f)  rot=%.0f" % [
				rd.get("token"), str(rd.get("tile_cell")), n.global_position.x, n.global_position.y,
				n.global_position.z, n.rotation_degrees.y])
	quit(0)
