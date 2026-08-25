extends SceneTree
## THE THREE CROSSINGS, COUNTED (2026-08-24, Palle: "I do not see the
## transport cube, scale cube and rotate cube that in three different ways
## bridge the baseline pool space"). The proof camera keeps composing on
## artifact corners, so this asks the built hall directly: which utility
## nodes stand in trans introduction, and where.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_intro_crossings.gd

const OUT := "res://ada_run/intro_crossings.txt"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_ic_control.json")
	inst.set("_overrides_path", "res://ada_run/_trial_ic_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_ic_hand.json")
	inst.set("start_chapter", "transformation")
	inst.set("start_map", "Trans_Introduction")
	var ctl := FileAccess.open("res://ada_run/_trial_ic_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "transformation",
		"first_map": "Trans_Introduction", "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(2.5).timeout
	inst.call("flush_stamps")
	await create_timer(1.5).timeout

	var segs: Array = inst.get("_segments")
	var report := "TRANS INTRODUCTION — THE CROSSINGS\n"
	var seg: Node3D = null
	for s_v in segs:
		var s: Dictionary = s_v
		if String(s.get("pearl", "")) == "trans introduction":
			seg = s.get("node")
	if seg == null:
		report += "  FAIL the hall never built\n"
	else:
		var found: Array = []
		for n in seg.find_children("*", "Node3D", true, false):
			var nm := String(n.name)
			if nm.begins_with("Utility_") or nm.begins_with("Wedge_"):
				found.append("%-26s at (%.1f, %.1f, %.1f)" % [nm,
					(n as Node3D).position.x, (n as Node3D).position.y, (n as Node3D).position.z])
		found.sort()
		report += "  %d utility node(s) standing in the hall:\n" % found.size()
		for f in found:
			report += "    %s\n" % f
		# and name what the map ASKED for, so the two lists can be compared
		var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(
			"res://commons/maps/Trans_Introduction/map_data.json"))
		if doc is Dictionary:
			var uts: Array = ((doc as Dictionary)["layers"] as Dictionary).get("utilities", [])
			report += "\n  the map asks for:\n"
			for z in range(uts.size()):
				var row: Array = uts[z]
				for x in range(row.size()):
					var v := str(row[x]).strip_edges()
					if v != "":
						report += "    %-18s at map cell (%d, %d)\n" % [v, x, z]
	var f2 := FileAccess.open(OUT, FileAccess.WRITE)
	f2.store_string(report)
	f2.close()
	print(report)
	quit(0)
