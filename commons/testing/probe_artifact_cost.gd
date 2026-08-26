extends SceneTree
## WHAT ONE ARTIFACT COSTS (2026-08-26). The grid hall's whole build is its
## interactables pass - structure 0 ms, utilities 0 ms, interactables 1281 ms
## for thirteen - so the question is which artifacts, and whether it is the
## LOAD (disk, dependencies) or the _ready (procedural geometry).
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_artifact_cost.gd -- --map=Trans_Translation

const OUT := "res://ada_run/artifact_cost.txt"


func _initialize() -> void:
	call_deferred("_run")


func _arg(n: String, fb: String) -> String:
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--%s=" % n):
			return String(a).substr(n.length() + 3)
	return fb


## the registry files are not flat: some hold their entries a level or two
## down, and a top-level-only walk found none of the thirteen tokens
func _harvest(d: Dictionary, out: Dictionary) -> void:
	for k in d:
		var v: Variant = d[k]
		if not (v is Dictionary):
			continue
		var e: Dictionary = v
		var sp := String(e.get("scene", ""))
		if sp == "":
			sp = String(e.get("scene_path", ""))
		if sp != "" and not out.has(String(k)):
			out[String(k)] = sp
		_harvest(e, out)


func _run() -> void:
	var map_name := _arg("map", "Trans_Translation")
	var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(
		"res://commons/maps/%s/map_data.json" % map_name))
	var tokens: Array = []
	if doc is Dictionary:
		for row in (((doc as Dictionary)["layers"] as Dictionary).get("interactables", []) as Array):
			for cell in (row as Array):
				var t := String(cell).strip_edges()
				if t != "" and not t.begins_with("#"):
					tokens.append(t.split("#")[0].split(":")[0])
	# the registry, to turn a token into a scene
	var reg: Dictionary = {}
	var d := DirAccess.open("res://commons/artifacts/registry")
	if d:
		d.list_dir_begin()
		var f := d.get_next()
		while f != "":
			if f.ends_with(".json"):
				var j: Variant = JSON.parse_string(FileAccess.get_file_as_string(
					"res://commons/artifacts/registry/" + f))
				if j is Dictionary:
					_harvest(j as Dictionary, reg)
			f = d.get_next()
	var rep := "WHAT ONE ARTIFACT COSTS — %s, %d token(s)\n\n" % [map_name, tokens.size()]
	var rows: Array = []
	var host := Node3D.new()
	get_root().add_child(host)
	for tok in tokens:
		var path := String(reg.get(tok, ""))
		if path == "":
			rows.append({"tok": tok, "note": "not in registry"})
			continue
		if not ResourceLoader.exists(path):
			rows.append({"tok": tok, "note": "scene missing: " + path})
			continue
		var t0 := Time.get_ticks_usec()
		var ps: PackedScene = load(path) as PackedScene
		var t1 := Time.get_ticks_usec()
		var n: Node = ps.instantiate() if ps != null else null
		var t2 := Time.get_ticks_usec()
		if n != null:
			host.add_child(n)          # _ready runs here: the procedural build
		var t3 := Time.get_ticks_usec()
		rows.append({"tok": tok, "load": (t1 - t0) / 1000.0,
			"inst": (t2 - t1) / 1000.0, "ready": (t3 - t2) / 1000.0, "note": ""})
	# a single-line lambda: a multi-line one is a parse error here
	for r_v0 in rows:
		var r0: Dictionary = r_v0
		r0["total"] = float(r0.get("load", 0.0)) + float(r0.get("inst", 0.0)) + float(r0.get("ready", 0.0))
	rows.sort_custom(func(a, b): return float(a["total"]) > float(b["total"]))
	var tl := 0.0
	var ti := 0.0
	var tr := 0.0
	rep += "  %-30s %8s %8s %8s\n" % ["token", "load", "instant", "_ready"]
	for r_v in rows:
		var r: Dictionary = r_v
		if String(r.get("note", "")) != "":
			rep += "  %-30s %s\n" % [r["tok"], r["note"]]
			continue
		tl += float(r["load"]); ti += float(r["inst"]); tr += float(r["ready"])
		rep += "  %-30s %8.1f %8.1f %8.1f\n" % [r["tok"], r["load"], r["inst"], r["ready"]]
	rep += "\n  totals: load %.0f ms, instantiate %.0f ms, _ready %.0f ms  (sum %.0f ms)\n" % [
		tl, ti, tr, tl + ti + tr]
	rep += "  the dearest single artifact is %s\n" % String((rows[0] as Dictionary).get("tok", "?"))
	var f2 := FileAccess.open(OUT, FileAccess.WRITE)
	f2.store_string(rep)
	f2.close()
	print(rep)
	quit(0)
