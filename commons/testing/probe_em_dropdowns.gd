extends SceneTree
## The Inspector dropdowns: start_chapter / start_map carry ENUM hints filled
## from the spine and the chapter's sequence file.
func _initialize() -> void:
	call_deferred("_run")
func _run() -> void:
	var scr: Script = load("res://commons/scenes/endless_museum.gd")
	var n: Node3D = Node3D.new(); n.set_script(scr)
	n.set("start_chapter", "primitives")
	var fails: Array[String] = []
	var seen := {}
	for p in n.get_property_list():
		if String(p.name) in ["start_chapter", "start_map"]:
			seen[String(p.name)] = p
	for k in ["start_chapter", "start_map"]:
		if not seen.has(k): fails.append("no property " + k); continue
		var p: Dictionary = seen[k]
		if int(p.hint) != PROPERTY_HINT_ENUM: fails.append(k + " is not an enum dropdown (hint %d)" % int(p.hint))
		var vals: PackedStringArray = String(p.hint_string).split(",")
		print("  %s: %d choices — %s…" % [k, vals.size(), ",".join(vals.slice(0, 5))])
		if k == "start_chapter" and not vals.has("noise"): fails.append("chapter dropdown lacks noise")
		if k == "start_map" and not vals.has("Point_Lines"): fails.append("map dropdown for primitives lacks Point_Lines")
	n.free()
	if fails.is_empty(): print("EM DROPDOWNS: PASS")
	else:
		print("EM DROPDOWNS: FAIL %d" % fails.size()); for x in fails: print("  - " + x)
	quit(0 if fails.is_empty() else 1)
