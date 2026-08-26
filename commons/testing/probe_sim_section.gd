extends SceneTree
## One cross-section through a simulation hall: what does a downward ray meet
## at every x, from the courtyard margin through the pool to the far margin?
## Answers "the margin reads 0.00 — what IS that?" with a number per cell.
const OUT := "res://ada_run/sim_section.txt"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_sec_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_sec_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_sec_hand.json")
	inst.set("start_chapter", "transformation")
	inst.set("start_map", "")
	var ctl := FileAccess.open("res://ada_run/_trial_sec_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "transformation", "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(1.0).timeout
	inst.set("MIN_SEGMENTS", 99)
	inst.set("KEEP_AHEAD_M", 99999.0)
	inst.set("KEEP_BEHIND_M", 99999.0)
	for i in range(3):
		if (inst.get("_segments") as Array).size() >= 3:
			break
		inst.call("_build_segment")
		await create_timer(0.3).timeout
	inst.call("flush_stamps")
	await create_timer(2.5).timeout
	var w3d: World3D = inst.get_world_3d()
	var txt := "SIM SECTION\n"
	for s_v in (inst.get("_segments") as Array):
		var s: Dictionary = s_v
		var pearl := str(s.get("pearl", "?"))
		if not pearl.contains("translation") and not pearl.contains("axisdecomposition"):
			continue
		var z0: float = float(s["z0"])
		var wid: int = int(s.get("w", 9))
		txt += "\n%s (w %d, z0 %.0f) at map row 8:\n" % [pearl, wid, z0]
		for x in range(-4, wid + 4):
			var wx: float = x + 0.5
			var wz: float = z0 + 4.0 + 8.0 + 0.5
			var q := PhysicsRayQueryParameters3D.create(Vector3(wx, 14.0, wz), Vector3(wx, -30.0, wz))
			var hit: Dictionary = w3d.direct_space_state.intersect_ray(q)
			var y := -999.0
			var who := "(nothing)"
			if not hit.is_empty():
				y = float(hit["position"].y)
				var c: Variant = hit.get("collider")
				if c is Node:
					who = str((c as Node).name)
					var pnt: Node = (c as Node).get_parent()
					if pnt != null:
						who = str(pnt.name) + "/" + who
			txt += "  x %3d -> y %7.2f   %s\n" % [x, y, who]
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(txt)
	f.close()
	print(txt)
	quit(0)
