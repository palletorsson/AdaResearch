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
	# the string spans EVERY spine map + the registry tail
	if beads.size() < 500:
		fails.append("only %d beads on the string (wanted spine+registry scale)" % beads.size())
	var maps_seen: Dictionary = {}
	for b_v2 in beads:
		maps_seen[String((b_v2 as Dictionary)["map"])] = true
	if maps_seen.size() < 50:
		fails.append("only %d distinct maps on the string" % maps_seen.size())
	# the DRESSING ROOM shows ONE pearl: the selected bead is spawned
	var sel0: int = lab.get("_sel")
	if sel0 < 0 or (beads[sel0] as Dictionary).get("node") == null:
		fails.append("no pearl standing in the dressing room after boot")

	# select a plinthed bead IN POINT_ONE (the map this probe restores):
	# it must arrive WITH its pedestal, close up
	var pi := -1
	for i in range(beads.size()):
		if String((beads[i] as Dictionary).get("map", "")) == "Point_One" \
				and str((beads[i] as Dictionary).get("tok", "")).find("#plinth:") >= 0:
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
		# compare AS A SET, values not bytes — the writer re-appends the edited
		# key (order moves) and %.2f turns 1.0 into 1.00; config is a set
		var same: bool = tok0.split("#")[0] == tok1.split("#")[0]
		var c0: Dictionary = lab.call("_tok_cfg", tok0)
		var c1: Dictionary = lab.call("_tok_cfg", tok1)
		same = same and c0.size() == c1.size()
		if same:
			for ck in c0:
				var p0s := str(c0[ck]).split(",")
				var p1s := str(c1.get(ck, "<gone>")).split(",")
				if p0s.size() != p1s.size():
					same = false
					continue
				for j in range(p0s.size()):
					var s0 := str(p0s[j]).strip_edges()
					var s1 := str(p1s[j]).strip_edges()
					if s0.is_valid_float() and s1.is_valid_float():
						if absf(float(s0) - float(s1)) > 0.001:
							same = false
					elif s0 != s1:
						same = false
		if not same:
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
