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
	var inst: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	var plan := PLAN
	if OS.get_cmdline_user_args().has("--live"):
		plan = "res://ada_run/em_plan.json"
	inst.set("_plan_path", plan)
	inst.set("EM_CONTROL", CTL)
	inst.set("_overrides_path", "res://ada_run/_trial_map_overrides.json")
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
	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_string(JSON.stringify({"segments": segs, "shots": shots,
		"at": Time.get_datetime_string_from_system(false, true)}, " "))
	out.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(CTL))
	print("MAP HALLS: %d segment(s), %d shot(s)" % [segs.size(), shots.size()])
	quit(0)
