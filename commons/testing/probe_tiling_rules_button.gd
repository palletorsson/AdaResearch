extends SceneTree
## tiling_principles' RULES button, headless: the hall at load shows the six fields image_for has
## always drawn; RULES changes all six fields and their titles; RULES again restores them byte for
## byte. Floor and walls mode both. Writes ada_run/address_rules/rules_button.json; exit 1 on a fail.

const Pattern := preload("res://commons/artifacts/regularity/tiling_pattern.gd")


func _init() -> void:
	var report := {"checks": [], "pass": true}
	for mode in ["floor", "walls"]:
		var hall: Node3D = load("res://commons/artifacts/regularity/tiling_principles.tscn").instantiate()
		hall.set_meta("config_mode", mode)
		root.add_child(hall)
		await process_frame
		var at_load := _fields(hall)
		var titles_at_load := _titles(hall)
		var legacy: Array = []
		for i in 6:
			legacy.append(Pattern.image_for(i, 0, false).get_data())
		_check(report, mode, "fields at load are image_for's six", at_load == legacy)
		hall.call("toggle_rules")
		var ruled := _fields(hall)
		var changed := 0
		for i in 6:
			if ruled[i] != at_load[i]:
				changed += 1
		_check(report, mode, "RULES changes all six fields (%d changed)" % changed, changed == 6)
		_check(report, mode, "RULES retitles the fields", _titles(hall) != titles_at_load and _titles(hall)[0] == "TRUCHET / CHANCE TURNS")
		hall.call("toggle_rules")
		_check(report, mode, "RULES again restores the hall byte for byte", _fields(hall) == at_load and _titles(hall) == titles_at_load)
		hall.queue_free()
		await process_frame
	var f := FileAccess.open(ProjectSettings.globalize_path("res://ada_run/address_rules/rules_button.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("PROBE_TILING_RULES pass=%s" % report["pass"])
	quit(0 if report["pass"] else 1)


func _fields(hall: Node3D) -> Array:
	var out: Array = []
	for s in hall.get("surfaces"):
		out.append((s.material_override.albedo_texture as ImageTexture).get_image().get_data())
	return out


func _titles(hall: Node3D) -> Array:
	var out: Array = []
	for t in hall.get("titles"):
		out.append(t.text)
	return out


func _check(report: Dictionary, mode: String, what: String, ok: bool) -> void:
	report["checks"].append({"mode": mode, "check": what, "pass": ok})
	print("%s  %-6s %s" % ["PASS" if ok else "FAIL", mode, what])
	if not ok:
		report["pass"] = false
