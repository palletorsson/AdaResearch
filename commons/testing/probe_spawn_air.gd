extends SceneTree
## "for some reason I'm jumping out in the air above the museum" — reproduce
## it: boot grid_pack exactly like Palle's launch, let physics run, and write
## down the walker's position second by second, plus every body standing
## within 4 m of the spawn.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_spawn_air.gd

const OUT := "res://ada_run/spawn_air_probe.txt"
const CTL := "res://ada_run/_doll_trial_control.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "",
		"dollhouse": 0, "gate_open": 1, "grid_pack": 1}, " "))
	f.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("EM_CONTROL", CTL)
	inst.set("_overrides_path", "res://ada_run/_doll_trial_overrides.json")
	get_root().add_child(inst)
	var lines: Array = []
	var pl: CharacterBody3D = null
	for s in range(9):
		await create_timer(1.0).timeout
		pl = inst.get("_player")
		if pl != null and is_instance_valid(pl):
			lines.append("t=%ds  pos (%.2f, %.2f, %.2f)  on_floor=%s  catches=%s" % [
				s + 1, pl.position.x, pl.position.y, pl.position.z,
				str(pl.is_on_floor()), str(inst.get("_catches"))])
	# what stands near the spawn?
	if pl != null:
		for r_v in (inst.get("_edit_records") as Array):
			var n: Node3D = (r_v as Dictionary).get("node")
			if n != null and is_instance_valid(n) \
					and Vector2(n.global_position.x - 7.5, n.global_position.z - 1.5).length() < 4.0:
				lines.append("NEAR SPAWN: %s at (%.1f, %.1f, %.1f)" % [
					(r_v as Dictionary).get("token"), n.global_position.x, n.global_position.y, n.global_position.z])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_doll_trial_overrides.json"))
	var f3 := FileAccess.open(OUT, FileAccess.WRITE)
	f3.store_string("\n".join(lines))
	f3.close()
	print("SPAWN AIR:\n" + "\n".join(lines))
	quit(0)
