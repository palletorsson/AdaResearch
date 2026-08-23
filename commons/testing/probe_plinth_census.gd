extends SceneTree
## WHO STANDS ON A PLANNER PLINTH in the authored halls (2026-08-23, Palle:
## "remove the em_plinths where there are artifacts on them — work as one").
## Boots the museum with trial control files and dumps every artifact record
## whose plinth came from em_plinths (not from token dress), with its height
## and map cell — the worklist for materializing planner grants into #plinth.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_plinth_census.gd

const OUT := "res://ada_run/plinth_census.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_pc_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_pc_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_pc_hand.json")
	var ctl := FileAccess.open("res://ada_run/_trial_pc_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "primitives", "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(inst)
	for i in range(60):
		await create_timer(0.5).timeout
		var have := 0
		for c in inst.get_children():
			if c is Node3D and (str(c.name).begins_with("Seg0_") or str(c.name).begins_with("Seg1_") or str(c.name).begins_with("Seg2_")):
				have += 1
		if have >= 3:
			break
	await create_timer(1.0).timeout
	var rows: Array = []
	for rv in (inst.get("_edit_records") as Array):
		var r: Dictionary = rv
		if String(r.get("kind", "")) != "":
			continue
		var seg: Node3D = _nn(r.get("seg"))
		var dmap := String(seg.get_meta("em_map")) if seg != null and seg.has_meta("em_map") else ""
		if dmap == "":
			continue
		var pl := String(r.get("plinth", ""))
		var ph := float(r.get("plinth_h", 0.0))
		var why := String(r.get("plinth_why", ""))
		if pl == "" or ph <= 0.01:
			continue
		var tc: Array = r.get("tile_cell", [0, 0])
		rows.append({"map": dmap, "token": String(r.get("token", "")),
			"tile_cell": tc, "plinth": pl, "h": ph,
			"source": "dress" if why.begins_with("dress") else "planner", "why": why})
	for f in ["_trial_pc_control.json", "_trial_pc_overrides.json", "_trial_pc_hand.json"]:
		DirAccess.remove_absolute("res://ada_run/" + f)
	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_string(JSON.stringify({"rows": rows}, " "))
	out.close()
	print("PLINTH CENSUS: %d plinthed artifact(s) in authored halls" % rows.size())
	quit(0)


func _nn(v: Variant) -> Node3D:
	return v as Node3D if v is Node3D and is_instance_valid(v) else null
