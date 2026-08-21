extends SceneTree
## The second air hypothesis: not the spawn but the WALK — hold W through the
## first halls of the grid-pack museum and watch y and the catch counter for
## a floor gap at a segment seam.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_walk_air.gd

const OUT := "res://ada_run/walk_air_probe.txt"
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
	await create_timer(3.0).timeout
	var ev := InputEventKey.new()
	ev.keycode = KEY_W
	ev.physical_keycode = KEY_W
	ev.pressed = true
	Input.parse_input_event(ev)      # hold W — the walker walks
	var lines: Array = []
	var worst_y := 0.0
	for s in range(40):
		await create_timer(0.5).timeout
		var pl: CharacterBody3D = inst.get("_player")
		if pl == null or not is_instance_valid(pl):
			continue
		worst_y = maxf(worst_y, absf(pl.position.y))
		if s % 4 == 0 or absf(pl.position.y) > 0.6:
			lines.append("t=%4.1fs  pos (%.1f, %.2f, %.1f)  floor=%s  catches=%s" % [
				(s + 1) * 0.5, pl.position.x, pl.position.y, pl.position.z,
				str(pl.is_on_floor()), str(inst.get("_catches"))])
	lines.append("worst |y| seen: %.2f · catches: %s" % [worst_y, str(inst.get("_catches"))])
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_doll_trial_overrides.json"))
	var f3 := FileAccess.open(OUT, FileAccess.WRITE)
	f3.store_string("\n".join(lines))
	f3.close()
	print("WALK AIR:\n" + "\n".join(lines))
	quit(0)
