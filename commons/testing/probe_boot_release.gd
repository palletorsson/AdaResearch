extends SceneTree
## WHY IS THE VISITOR STILL IN THE LOADING CELL? (2026-08-26, Palle: "it is
## inside the app, when the project is loading and it says loading... on a wall
## work" — the boot cell never goes away.)
##
## _finish_initial_loading is what frees that little room, and _process calls it
## on exactly one condition:
##     if not _museum_ready and _stamp_queue.is_empty() and _cartridge_pending_nodes.is_empty()
## So the cell staying up means one of those two lists never empties. This boots
## the museum in the VR lane — the lane the headset runs, which takes different
## branches from desktop — and prints both counts every second until it either
## clears or gives up, so the answer is a number rather than a guess.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_boot_release.gd -- --seconds=90

const OUT := "res://ada_run/boot_release.txt"


func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb


func _run() -> void:
	var budget := float(_arg("seconds", "90"))
	var lane := _arg("lane", "vr")
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_br_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	inst.set("_force_patient", true)
	if lane == "vr":
		inst.set("_force_vr", true)
	var ctl := FileAccess.open("res://ada_run/_trial_br_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": "", "first_map": "",
		"dollhouse": 0, "grid_pack": 0}, " "))
	ctl.close()
	get_root().add_child(inst)
	# the VR lane needs an eye or it will not stream at all; build the same rig
	# vrStaging hands it, so this measures the museum and not a missing camera
	if lane == "vr":
		var origin := XROrigin3D.new()
		var cam := XRCamera3D.new()
		cam.position = Vector3(3.0, 1.6, 1.0)
		origin.add_child(cam)
		get_root().add_child(origin)

	var rep := "WHY IS THE VISITOR STILL IN THE LOADING CELL? (lane=%s)\n\n" % lane
	var t := 0.0
	var freed_at := -1.0
	var last := ""
	while t < budget:
		await create_timer(1.0).timeout
		t += 1.0
		var ready: bool = bool(inst.get("_museum_ready"))
		var q: Array = inst.get("_stamp_queue")
		var cart: Array = inst.get("_cartridge_pending_nodes")
		var owed: Array = inst.get("_repair_owed")
		var segs: Array = inst.get("_segments")
		var line := "  %3ds  ready=%s  stamp_queue=%d  cartridge_pending=%d  repair_owed=%d  segments=%d" % [
			int(t), str(ready), q.size() if q != null else -1,
			cart.size() if cart != null else -1, owed.size() if owed != null else -1,
			segs.size() if segs != null else -1]
		if line.substr(7) != last:
			rep += line + "\n"
			print(line)
			last = line.substr(7)
		if ready and freed_at < 0.0:
			freed_at = t
			rep += "\n  the loading cell cleared at %ds\n" % int(t)
			print("  the loading cell cleared at %ds" % int(t))
			break
	if freed_at < 0.0:
		var q2: Array = inst.get("_stamp_queue")
		rep += "\n  STILL IN THE CELL after %ds.\n" % int(budget)
		# name what is left in the queue: the thing that will not finish
		var kinds: Dictionary = {}
		if q2 != null:
			for it_v in q2:
				var it: Dictionary = it_v
				var k := "%s:%s" % [String(it.get("kind", "stamp")), String(it.get("lookup", "?"))]
				kinds[k] = int(kinds.get(k, 0)) + 1
		var rows: Array = kinds.keys()
		rows.sort_custom(func(a, b): return int(kinds[a]) > int(kinds[b]))
		for i in range(mini(12, rows.size())):
			rep += "    %-52s x%d\n" % [String(rows[i]), int(kinds[rows[i]])]
		if rows.is_empty():
			rep += "    the stamp queue is EMPTY — the block is elsewhere\n"
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0 if freed_at >= 0.0 else 1)
