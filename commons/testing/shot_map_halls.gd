extends SceneTree
## THE MAP-AUTHORED HALLS, photographed: the three first spine maps placed as
## endless-museum halls via a trial plan (tools/em_map_halls.py). One dollhouse
## top shot per hall + a verdict file with segment spacing (the negotiated
## lobby) and the first artifacts' cells. Trial files only — never the live
## plan/hand/control (the probe-isolation rule). Windowed: a shot needs a
## renderer.
##   godot --path . --xr-mode off --script res://commons/testing/shot_map_halls.gd

const CTL := "res://ada_run/_trial_map_control.json"
const HAND := "res://ada_run/_trial_map_hand.json"
const PLAN := "res://ada_run/_trial_map_plan.json"   # --live shoots the real plan instead
const OUT := "res://ada_run/map_halls_verdict.json"

func _initialize() -> void:
	call_deferred("_run")


func _defog(n: Node) -> void:
	if n is WorldEnvironment and (n as WorldEnvironment).environment != null:
		var e: Environment = (n as WorldEnvironment).environment
		e.fog_enabled = false
		e.volumetric_fog_enabled = false
	if n is Camera3D and (n as Camera3D).attributes is CameraAttributesPractical:
		((n as Camera3D).attributes as CameraAttributesPractical).auto_exposure_enabled = false
	for c in n.get_children():
		_defog(c)


func _run() -> void:
	var f := FileAccess.open(CTL, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "primitives", "first_map": "",
		"dollhouse": 1, "grid_pack": 0}, " "))
	f.close()
	var fh := FileAccess.open(HAND, FileAccess.WRITE)
	fh.store_string(JSON.stringify({"_readme": "trial: empty — the plan authors everything", "halls": {}}, " "))
	fh.close()
	# a trial CELL RULING: the interior editor's wall-at-[5,5] in the point
	# hall — the build must obey it. With --live the probe uses the REAL
	# overrides instead (the curator's own saved rulings must come back).
	var live_rules := OS.get_cmdline_user_args().has("--live")
	if not live_rules:
		var fo := FileAccess.open("res://ada_run/_trial_map_overrides.json", FileAccess.WRITE)
		fo.store_string(JSON.stringify({"schema": "adaresearch.em_overrides.v1", "overrides": [
			{"kind": "cell", "chapter": "primitives", "pearl": "point one",
				"token": "cell:point one", "from": [5, 5], "value": "4", "provenance": "hand"}]}, " "))
		fo.close()
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	var plan := PLAN
	if OS.get_cmdline_user_args().has("--live"):
		plan = "res://ada_run/em_plan.json"
	inst.set("_plan_path", plan)
	inst.set("EM_CONTROL", CTL)
	inst.set("_overrides_path", "res://ada_run/em_overrides.json" if live_rules else "res://ada_run/_trial_map_overrides.json")
	inst.set("_hand_path", HAND)
	get_root().add_child(inst)
	await create_timer(3.0).timeout
	var pl: CharacterBody3D = inst.get("_player")
	inst.set("_doll_top", true)
	inst.set("_doll_yaw", 0.0)
	# the perch's optics, forced: from the doll height the aerial fog washes
	# the frame white — kill it wherever the env module put it
	_defog(get_root())
	var segs: Array = []
	var probe_z := 8.0
	for i in range(3):
		var seg: Node3D = null
		for attempt in range(10):
			for c in inst.get_children():
				if c is Node3D and str(c.name).begins_with("Seg%d_" % i):
					seg = c
			if seg != null:
				break
			# walk the player forward until the museum builds the next segment
			probe_z += 14.0
			if pl != null:
				pl.position = Vector3(7.0, 0.0, probe_z)
			await create_timer(1.5).timeout
		if seg == null:
			segs.append({"seg": i, "missing": true})
			continue
		segs.append({"seg": i, "name": str(seg.name), "z": seg.position.z})
	# spacing: the negotiated lobby = next seg z - (this seg z + its extent)
	for i in range(segs.size() - 1):
		if not segs[i].has("z") or not segs[i + 1].has("z"):
			continue
		segs[i]["z_to_next"] = float(segs[i + 1]["z"]) - float(segs[i]["z"])
	# one dollhouse shot per hall
	var shots: Array = []
	for s_v in segs:
		var s: Dictionary = s_v
		if not s.has("z"):
			continue
		var idx: int = int(s["seg"])
		if pl != null:
			pl.position = Vector3(7.0, 0.0, float(s["z"]) + 10.0)
		inst.set("_doll_zoom", 26.0)
		_defog(get_root())
		await create_timer(3.0).timeout
		var img := get_root().get_viewport().get_texture().get_image()
		var path := "res://ada_run/map_hall_%d.png" % idx
		img.save_png(ProjectSettings.globalize_path(path))
		shots.append(path)
	# THE SEAM (Palle: "there is a gap in the floor between maps"): the strip
	# beside the 17-wide lobby, inside a 20-wide hall's span — the vestibule
	# must lay floor there now. Raycast straight down at x=18.5 in segment
	# 1's vestibule (z = seg1.z + 2): a hit is floor, empty is the gap.
	var seam := {}
	if segs.size() > 1 and segs[1].has("z"):
		await physics_frame
		var space := get_root().get_world_3d().direct_space_state
		var sz: float = float(segs[1]["z"]) + 2.0
		var q := PhysicsRayQueryParameters3D.create(Vector3(18.5, 2.0, sz), Vector3(18.5, -2.0, sz))
		var hit := space.intersect_ray(q)
		seam = {"probe": [18.5, sz], "floor": not hit.is_empty()}
	# did the cell ruling land? read the built segment's own tile
	var cell_rule := false
	var rule_x: int = 9 if live_rules else 5
	var rule_z: int = 10 if live_rules else 5
	for c3 in inst.get_children():
		if c3 is Node3D and str(c3.name).begins_with("Seg0_") and (c3 as Node).has_meta("em_tile"):
			var t0: Array = (c3 as Node).get_meta("em_tile")
			if t0.size() > rule_z and (t0[rule_z] as Array).size() > rule_x:
				cell_rule = String((t0[rule_z] as Array)[rule_x]) == "4"
	# ONE-TRUTH serializer round-trip: the museum WRITES maps now — parse ->
	# _jsonc -> parse must be data-identical, or a first save corrupts a map
	var rt := false
	var src := FileAccess.get_file_as_string("res://commons/maps/Point_One/map_data.json")
	var doc0: Variant = JSON.parse_string(src)
	if doc0 is Dictionary:
		var again: Variant = JSON.parse_string(String(inst.call("_jsonc", doc0, "")))
		rt = again is Dictionary and JSON.stringify(again) == JSON.stringify(doc0)
	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_string(JSON.stringify({"segments": segs, "shots": shots, "seam": seam, "cell_rule": cell_rule, "map_roundtrip": rt,
		"at": Time.get_datetime_string_from_system(false, true)}, " "))
	out.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	print("MAP HALLS: %d segment(s), %d shot(s)" % [segs.size(), shots.size()])
	quit(0)
