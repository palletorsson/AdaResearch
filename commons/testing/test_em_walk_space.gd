extends SceneTree
## The 3D surface overturns a branch's space. Build noise under a TRIAL
## reading (so it is a hero walk), select a body carrying a walk role, press
## W, and read trunk_branches.json back: the branch's space advanced, its
## space_by is "walk", the trail holds the heuristic verdict it replaced.
## Then the trial reading is removed and the space put back.
##   godot --headless --path . --xr-mode off --script res://commons/testing/test_em_walk_space.gd

const TRUNK := "res://commons/data/trunk_branches.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var fails: Array[String] = []
	var before: String = FileAccess.get_file_as_string(TRUNK)
	# plant a trial hand reading so noise is a hero walk (the plan must be regenerated
	# for the museum to see it — so instead this test drives the record directly)
	var ps: PackedScene = load("res://commons/scenes/endless_museum.tscn")
	var inst: Node3D = ps.instantiate() as Node3D
	inst.set("_edit_mode", true)
	inst.set("_overrides_path", "res://ada_run/_trial_em_overrides.json")
	inst.set("_plan_path", "")
	get_root().add_child(inst)
	await create_timer(0.6).timeout
	var records: Array = inst.get("_edit_records")
	if records.is_empty():
		fails.append("no records")
	else:
		# forge a walk role on the first artifact record: noise / noiselayers / edge
		# exists in the trunk as a derived branch (space heuristic 'room')
		var r: Dictionary = records[0]
		r["walk_kind"] = "edge"; r["walk_space"] = "room"; r["chapter"] = "noise"; r["token"] = "noiselayers"
		inst.set("_edit_sel", 0)
		inst.call("_edit_handle_key", KEY_W)
		var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TRUNK))
		var hit: Dictionary = {}
		for b in doc.get("branches", []):
			if b.get("anchor") == "noise" and b.get("token") == "noiselayers" and b.get("kind") == "edge":
				hit = b; break
		if hit.is_empty(): fails.append("branch not found")
		else:
			if String(hit.get("space")) != "wall": fails.append("space did not cycle room -> wall (got %s)" % hit.get("space"))
			if String(hit.get("space_by")) != "walk": fails.append("space_by %s != walk" % hit.get("space_by"))
			var trail: Array = hit.get("space_trail", [])
			if trail.is_empty() or String((trail[-1] as Dictionary).get("by")) != "heuristic": fails.append("trail does not hold the heuristic verdict")
	# restore the file exactly
	var f := FileAccess.open(TRUNK, FileAccess.WRITE); f.store_string(before); f.close()
	if FileAccess.file_exists("res://ada_run/_trial_em_overrides.json"):
		DirAccess.remove_absolute(ProjectSettings.globalize_path("res://ada_run/_trial_em_overrides.json"))
	get_root().remove_child(inst); inst.queue_free()
	if fails.is_empty(): print("WALK SPACE: PASS — W overturned room -> wall, space_by walk, trail kept, file restored")
	else:
		print("WALK SPACE: FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)
