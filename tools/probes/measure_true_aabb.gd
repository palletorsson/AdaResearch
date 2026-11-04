extends SceneTree
## The bounds an artifact really occupies: every GeometryInstance3D (CSG, MultiMesh, Label3D included), not only
## MeshInstance3D - the candidate probe reads a CSG corridor as a one-metre box. Settled 1.5 s, measured in the
## artifact's own frame. Run: godot --headless --path . --script res://tools/probes/measure_true_aabb.gd -- --out=<dir> --tokens=a,b
var out := "user://"

func _initialize() -> void:
	_run.call_deferred()

func _scene(token: String) -> String:
	for file in DirAccess.get_files_at("res://commons/artifacts/registry"):
		if not file.ends_with(".json"): continue
		var reg = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/registry".path_join(file)))
		if reg is Dictionary:
			var arts = reg.get("artifacts", reg)
			if arts is Dictionary and arts.has(token) and arts[token] is Dictionary and str(arts[token].get("scene", "")) != "": return str(arts[token].scene)
	return ""

func _run() -> void:
	var tokens: PackedStringArray = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--tokens="): tokens = arg.trim_prefix("--tokens=").split(",")
	var report := {}
	for token in tokens:
		var path := _scene(token)
		if path == "" or not ResourceLoader.exists(path): report[token] = {"error": "no scene"}; continue
		var art: Node3D = (load(path) as PackedScene).instantiate()
		root.add_child(art)
		for i in 90: await process_frame
		var box := AABB(); var first := true; var kinds := {}
		for g in art.find_children("*", "GeometryInstance3D", true, false):
			if not (g as Node3D).is_visible_in_tree(): continue
			var local: AABB = art.global_transform.affine_inverse() * (g as GeometryInstance3D).global_transform * (g as GeometryInstance3D).get_aabb()
			if local.size.length() < .001: continue
			kinds[g.get_class()] = int(kinds.get(g.get_class(), 0)) + 1
			box = local if first else box.merge(local); first = false
		report[token] = {"size": [box.size.x, box.size.y, box.size.z], "centre": [box.get_center().x, box.get_center().y, box.get_center().z], "kinds": kinds}
		print("AABB ", token, " ", report[token])
		art.queue_free(); await process_frame
	FileAccess.open(out.path_join("aabb.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	quit(0)
