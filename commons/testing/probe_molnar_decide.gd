extends SceneTree
## molnar_cube_study's frame poses, headless: every site's four nested frames with all three
## amounts at 1, written to ada_run/molnar/poses_<label>.json. Run once before a change and once
## after to prove the default byte for byte; with a decide word, to see what the rule does.
##   godot --headless --script res://commons/testing/probe_molnar_decide.gd -- <label> [decide]


func _init() -> void:
	var args := OS.get_cmdline_user_args()
	var label: String = args[0] if args.size() > 0 else "now"
	var study: Node3D = load("res://commons/artifacts/molnar_cube_study/molnar_cube_study.tscn").instantiate()
	if args.size() > 1:
		study.set_meta("config_decide", args[1])
	root.add_child(study)
	for i in 3:
		await process_frame
	study.set("amount", Vector3.ONE)
	var poses: Array = []
	var cells: Array = study.get("cells")
	for i in cells.size():
		for shell in 4:
			var t: Transform3D = study.call("frame_pose", i, shell)
			poses.append([t.basis.x.x, t.basis.x.y, t.basis.x.z, t.basis.y.x, t.basis.y.y, t.basis.y.z,
				t.basis.z.x, t.basis.z.y, t.basis.z.z, t.origin.x, t.origin.y, t.origin.z])
	var dir := ProjectSettings.globalize_path("res://ada_run/molnar")
	DirAccess.make_dir_recursive_absolute(dir)
	var f := FileAccess.open(dir.path_join("poses_%s.json" % label), FileAccess.WRITE)
	f.store_string(JSON.stringify({"label": label, "decide": study.get("decide") if "decide" in study else "chance (no option)", "sites": cells.size(), "poses": poses}))
	f.close()
	quit(0)
