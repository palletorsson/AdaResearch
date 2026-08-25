extends SceneTree
## FIFTY CONFIGS AND ONE CLICK (2026-08-25, Palle: "can we get one room with a
## wall that has many pattern config then we click and the whole map turn that
## config. like 50 different configs"). Counts the swatches, picks one, and
## asks EVERY built hall whether it changed — the whole map is the claim, so
## one hall changing is not the test.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_pattern_wall.gd

const OUT := "res://ada_run/pattern_wall.txt"


func _initialize() -> void:
	call_deferred("_run")


## what every hall's big surfaces are wearing, hall by hall
func _skin(inst: Node3D) -> Dictionary:
	var out: Dictionary = {}
	for s_v in inst.get("_segments"):
		var sd: Dictionary = s_v
		var seg: Node3D = sd.get("node")
		if seg == null or not is_instance_valid(seg):
			continue
		var sig: Array = []
		for mm_v in seg.find_children("*", "MultiMeshInstance3D", true, false):
			var mmi := mm_v as MultiMeshInstance3D
			var m: Material = mmi.material_override
			if m == null and mmi.multimesh != null and mmi.multimesh.mesh != null:
				m = mmi.multimesh.mesh.surface_get_material(0)
			if m == null:
				continue
			sig.append("%d:%d" % [m.get_instance_id(),
				mmi.multimesh.instance_count if mmi.multimesh != null else 0])
		sig.sort()
		out[String(sd.get("map", sd.get("pearl", "?")))] = "|".join(sig)
	return out


func _run() -> void:
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_pw_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	inst.set("start_chapter", "color")
	inst.set("start_map", "Symmetry_Seventeen")
	var ctl := FileAccess.open("res://ada_run/_trial_pw_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "color", "first_map": "Symmetry_Seventeen",
		"dollhouse": 0, "grid_pack": 0}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(4.0).timeout
	inst.call("flush_stamps")
	await create_timer(1.5).timeout
	# a second hall, so "the whole map" has something to be whole about
	inst.call("_build_segment")
	await create_timer(1.0).timeout

	var rep := "THE CHOOSING WALL\n"
	var sw: Array = inst.get("_pattern_swatches")
	rep += "  swatches on the wall: %d\n" % sw.size()
	if sw.is_empty():
		rep += "  FAIL no wall — does the hall declare museum.pattern.chooser?\n"
	else:
		var cfgs: Dictionary = {}
		for s_v in sw:
			cfgs[JSON.stringify((s_v as Dictionary).get("cfg", {}))] = true
		rep += "  distinct configs: %d\n" % cfgs.size()
		var first: Dictionary = (sw[0] as Dictionary).get("cfg", {})
		var last: Dictionary = (sw[sw.size() - 1] as Dictionary).get("cfg", {})
		rep += "  first %s · %s   last %s · %s\n" % [first.get("group"), first.get("palette"),
			last.get("group"), last.get("palette")]
		var before: Dictionary = _skin(inst)
		rep += "  halls standing: %d\n" % before.size()
		# click swatch 33 — a group and palette nothing is wearing
		inst.call("_pattern_apply_all", (sw[33] as Dictionary).get("cfg", {}))
		await create_timer(1.0).timeout
		var after: Dictionary = _skin(inst)
		var changed := 0
		for k in after:
			if before.has(k) and String(after[k]) != String(before[k]):
				changed += 1
				rep += "    %-26s re-dressed\n" % k
			elif before.has(k):
				rep += "    %-26s UNCHANGED\n" % k
		rep += "  halls re-dressed: %d of %d\n" % [changed, before.size()]
		rep += "  %s\n" % ("PASS one click, the whole map" if changed == before.size() and changed > 1
			else "FAIL")
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
