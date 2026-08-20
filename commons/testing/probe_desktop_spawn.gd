extends SceneTree
## Where does the desktop walker actually stand in the first seconds?
## Traces player position + on_floor + catches; flags any airborne stretch.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_desktop_spawn.gd

const OUT := "res://ada_run/desktop_spawn_probe.txt"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	get_root().add_child(inst)
	var lines: Array = []
	for step in range(50):
		for i in range(6):
			await physics_frame
		var pl: CharacterBody3D = inst.get("_player")
		if pl == null:
			lines.append("step %2d: no player yet" % step)
			continue
		lines.append("step %2d: pos (%.1f, %.2f, %.1f) on_floor=%s catches=%d" % [
			step, pl.position.x, pl.position.y, pl.position.z,
			pl.is_on_floor(), int(inst.get("_catches")) if "_catches" in inst else -1])
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string("\n".join(lines))
	f.close()
	print("\n".join(lines.slice(0, 10)))
	quit(0)
