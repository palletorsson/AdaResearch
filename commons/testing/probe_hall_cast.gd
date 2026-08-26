extends SceneTree
## DOES THIS HALL SHOW ITS MAP'S CAST? (2026-08-26, Palle: "force place the
## missing artifact for now"). tools/em_content_parity.py answers this from
## the files - what the map declares against what the bench claims. This
## answers it from the BUILT HALL, which is the only place the claim can fail:
## a body the placer could not fit is left behind, and no static check sees it.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_hall_cast.gd -- --chapter=color --map=Pattern_Foundry

const OUT := "res://ada_run/hall_cast.txt"


func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb


func _run() -> void:
	var map_name := _arg("map", "Pattern_Foundry")
	var chapter := _arg("chapter", "color")
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", "res://ada_run/_trial_hc_control.json")
	inst.set("_overrides_path", "res://ada_run/em_overrides.json")
	inst.set("_hand_path", "res://ada_run/necklace_hand.json")
	inst.set("start_chapter", chapter)
	inst.set("start_map", map_name)
	var ctl := FileAccess.open("res://ada_run/_trial_hc_control.json", FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": chapter, "first_map": map_name,
		"dollhouse": 0, "grid_pack": 0}, " "))
	ctl.close()
	get_root().add_child(inst)
	await create_timer(3.5).timeout
	inst.call("flush_stamps")
	await create_timer(2.0).timeout

	# what the map declares
	var want: Dictionary = {}
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://commons/maps/%s/map_data.json" % map_name))
	if doc is Dictionary:
		for row in (((doc as Dictionary)["layers"] as Dictionary).get("interactables", []) as Array):
			for cell in (row as Array):
				var t := String(cell).strip_edges()
				if t == "" or t.begins_with("#"):
					continue
				var tok := t.split("#")[0].split(":")[0]
				want[tok] = int(want.get(tok, 0)) + 1
	# what the hall has
	var seg: Node3D = null
	for s_v in inst.get("_segments"):
		var sd: Dictionary = s_v
		if String(sd.get("map", "")) == map_name:
			seg = sd.get("node")
	var got: Dictionary = {}
	if seg != null:
		for n in seg.find_children("*", "Node3D", true, false):
			if not n.has_meta("artifact_lookup_name"):
				continue
			var tok2 := String(n.get_meta("artifact_lookup_name"))
			if ":" in tok2:
				continue
			got[tok2] = int(got.get(tok2, 0)) + 1
	var rep := "THE HALL'S CAST — %s · %s\n" % [chapter, map_name]
	if seg == null:
		rep += "  FAIL the hall never built\n"
	else:
		var declared := 0
		var shown := 0
		var missing: Array = []
		for k in want:
			declared += int(want[k])
			var have: int = int(got.get(k, 0))
			shown += mini(have, int(want[k]))
			if have < int(want[k]):
				missing.append("%s (%d of %d)" % [k, have, int(want[k])])
		missing.sort()
		rep += "  declared %d, standing %d  (%.0f%%)\n" % [declared, shown,
			100.0 * float(shown) / maxf(1.0, float(declared))]
		if missing.is_empty():
			rep += "  PASS every artifact the map declares is in the hall\n"
		else:
			rep += "  MISSING %d:\n" % missing.size()
			for m in missing:
				rep += "    %s\n" % m
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(rep)
	f.close()
	print(rep)
	quit(0)
