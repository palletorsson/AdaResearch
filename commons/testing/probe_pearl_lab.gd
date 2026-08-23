extends SceneTree
## The PEARL DRESS LAB, booted headless (2026-08-23): beads spawn real, a
## dressed bead carries its plinth, and the write path round-trips (+0.1 then
## -0.1 on a plinth = the same token; the map is byte-restored regardless).
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_pearl_lab.gd

const OUT := "res://ada_run/pearl_lab_probe.txt"
const MAP := "res://commons/maps/Point_One/map_data.json"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var fails: Array = []
	var original := FileAccess.get_file_as_string(MAP)
	var lab: Node3D = (load("res://commons/scenes/pearl_dress_lab.tscn") as PackedScene).instantiate() as Node3D
	lab.set("map_name", "Point_One")
	get_root().add_child(lab)
	await create_timer(2.0).timeout

	var beads: Array = lab.get("_beads")
	if beads.size() < 8:
		fails.append("only %d beads on the string" % beads.size())
	# the DRESSING ROOM shows ONE pearl: the selected bead is spawned
	var sel0: int = lab.get("_sel")
	if sel0 < 0 or (beads[sel0] as Dictionary).get("node") == null:
		fails.append("no pearl standing in the dressing room after boot")

	# select a plinthed bead: it must arrive WITH its pedestal, close up
	var pi := -1
	for i in range(beads.size()):
		if str((beads[i] as Dictionary).get("tok", "")).find("#plinth:") >= 0:
			pi = i
	if pi < 0:
		fails.append("no plinthed bead to exercise the write path")
	else:
		lab.call("_select", pi)
		await create_timer(0.3).timeout
		beads = lab.get("_beads")
		var pb: Dictionary = beads[pi]
		if pb.get("plinth_node") == null or not is_instance_valid(pb.get("plinth_node")):
			fails.append("the dressed pearl stands without its pedestal")
		var tok0 := str((beads[pi] as Dictionary).get("tok"))
		lab.call("_select", pi)
		lab.call("_bump_plinth", 0.1)
		await create_timer(0.2).timeout
		lab.call("_bump_plinth", -0.1)
		await create_timer(0.2).timeout
		var tok1 := str(((lab.get("_beads") as Array)[pi] as Dictionary).get("tok"))
		# compare VALUES, not bytes — the writer's %.2f turns 1.0 into 1.00
		var p0 := float(str(tok0.split("#plinth:")[1]).split(",")[0].split("#")[0])
		var p1 := float(str(tok1.split("#plinth:")[1]).split(",")[0].split("#")[0])
		var rest0 := tok0.split("#plinth:")[0]
		var rest1 := tok1.split("#plinth:")[0]
		if absf(p0 - p1) > 0.001 or rest0 != rest1:
			fails.append("write round-trip drifted: %s -> %s" % [tok0, tok1])

	var rf: FileAccess = null
	for attempt in range(20):
		rf = FileAccess.open(MAP, FileAccess.WRITE)
		if rf != null:
			break
		OS.delay_msec(100)
	if rf == null:
		fails.append("RESTORE FAILED — map left dirty, git checkout it")
	else:
		rf.store_string(original)
		rf.close()

	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_string("PASS" if fails.is_empty() else "FAIL: " + "; ".join(PackedStringArray(fails)))
	out.close()
	print("PEARL LAB: " + ("PASS" if fails.is_empty() else "FAIL " + "; ".join(PackedStringArray(fails))))
	quit(0 if fails.is_empty() else 1)
