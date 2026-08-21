extends SceneTree
## Seed /transplant's data: boot the museum in grid-pack mode on a TRIAL
## control file, walk the eye forward so several halls build, and quit. The
## transplant writes ada_run/em_pack_report.json as each hall packs; the
## as-built writer records the floors. Never touches the live em_control.
##   godot --headless --path . --xr-mode off --script res://commons/testing/boot_pack_report.gd

const CTL := "res://ada_run/_doll_trial_control.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "",
		"dollhouse": 0, "grid_pack": 1}, " "))
	f.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("_plan_path", "res://ada_run/em_plan.json")
	inst.set("EM_CONTROL", CTL)
	inst.set("_overrides_path", "res://ada_run/_doll_trial_overrides.json")
	get_root().add_child(inst)
	await create_timer(1.5).timeout
	# walk the eye down the WHOLE spine: keep stepping until the pack report
	# stops growing (the pool is circular — a dozen quiet steps means every
	# pearl has packed and the corridor is repeating itself). Progress lands
	# in _pack_walk.txt each step so the watchdog sees a heartbeat.
	var pl: CharacterBody3D = inst.get("_player")
	var last_n := 0
	var stale := 0
	for step in range(420):
		if pl != null and is_instance_valid(pl):
			pl.position.z += 26.0
		for i in range(300):
			if (inst.get("_stamp_queue") as Array).is_empty():
				break
			await process_frame
		await create_timer(0.4).timeout
		var now_n: int = (inst.get("_pack_report") as Dictionary).size()
		var fw := FileAccess.open("res://ada_run/_pack_walk.txt", FileAccess.WRITE)
		fw.store_string("step %d · %d hall(s) packed\n" % [step, now_n])
		fw.close()
		if now_n == last_n:
			stale += 1
		else:
			stale = 0
			last_n = now_n
		if stale >= 12:
			break
	var n: int = (inst.get("_pack_report") as Dictionary).size()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_doll_trial_overrides.json"))
	var fr := FileAccess.open("res://ada_run/_pack_seed_done.txt", FileAccess.WRITE)
	fr.store_string("%d halls packed" % n)
	fr.close()
	print("PACK SEED: %d halls" % n)
	quit(0)
