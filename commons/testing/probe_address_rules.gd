extends SceneTree
## The Godot side of tools/address_rules_crosscheck.py: reads the cases the TypeScript side
## evaluated (ada_run/address_rules/ts.json), evaluates the same cases with address_rules.gd and
## writes ada_run/address_rules/gd.json. With --images it also writes the tiling hall's six
## rule fields as PNGs (tiling_pattern.gd rule_image), CPU only, so it runs headless.

const Rules := preload("res://commons/artifacts/regularity/address_rules.gd")


func _init() -> void:
	var dir := ProjectSettings.globalize_path("res://ada_run/address_rules")
	var src := FileAccess.get_file_as_string(dir.path_join("ts.json"))
	var parsed: Variant = JSON.parse_string(src)
	if not (parsed is Dictionary):
		push_error("probe_address_rules: no ts.json in " + dir)
		quit(2)
		return
	var cases: Array = []
	for c in (parsed as Dictionary).get("cases", []):
		var states := PackedInt32Array()
		var size: int = int(c["size"])
		for x in size:
			for z in size:
				states.append(Rules.state(str(c["rule"]), x, z, int(c["n"]), size, int(c["a"]), int(c["b"])))
		cases.append({"rule": c["rule"], "size": size, "n": c["n"], "a": c["a"], "b": c["b"], "states": Array(states)})
	var out := {"rules": Array(Rules.NAMES), "cases": cases}
	if "--images" in OS.get_cmdline_user_args():
		var Pattern := load("res://commons/artifacts/regularity/tiling_pattern.gd")
		var Principles := load("res://commons/artifacts/regularity/tiling_principles.gd")
		var written: Array = []
		for i in Principles.RULE_FIELDS.size():
			var f: Array = Principles.RULE_FIELDS[i]
			var img: Image = Pattern.rule_image(f[0], f[1], f[2], 0, 8, 8, 32)
			var path := dir.path_join("rule_field_%d.png" % i)
			img.save_png(path)
			written.append(path)
		out["images"] = written
	var f := FileAccess.open(dir.path_join("gd.json"), FileAccess.WRITE)
	f.store_string(JSON.stringify(out))
	f.close()
	print("PROBE_ADDRESS_RULES cases=%d" % cases.size())
	quit(0)
