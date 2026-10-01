extends SceneTree
## PROBE — does the grid read every numeric DNA axis as a VALUE? (2026-10-01)
##
## The grid's token parser treats `#key:<number>` as tutorial shorthand (an id plus
## a yaw in degrees) unless `key` is in GridInteractablesComponent.CONFIG_PARAM_NAMES.
## An artifact whose declared axis takes numbers, with the key unlisted, is therefore
## handed `true` and turned by the number. Measured on `pyramid#base_sides:8` in
## Point_Animatedcube: the grid lane built a tetrahedron turned 8 degrees (int(true)
## is 1, clamped to 3 sides) while the museum, which keeps the value, built an
## octagon. One token, two bodies, and nothing failed loudly.
##
## This probe reads every registry file, takes each declared axis whose values are
## all numbers, builds the token `<artifact>#<key>:<first value>`, runs it through
## the real parser, and fails when the key did not arrive as that value or when a
## rotation was invented. Exit code = number of failing axes, so it gates.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_numeric_axis_keys.gd

const REGISTRY := "res://commons/artifacts/registry"


func _initialize() -> void:
	var comp = load("res://commons/grid/GridInteractablesComponent.gd").new()
	var checked := 0
	var failed := 0
	var seen := {}
	var dir := DirAccess.open(REGISTRY)
	if dir == null:
		print("[numeric-axis] cannot open ", REGISTRY)
		quit(1)
		return
	var files := dir.get_files()
	files.sort()
	for f in files:
		if not f.ends_with(".json"):
			continue
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(REGISTRY + "/" + f))
		if not parsed is Dictionary:
			continue
		var entries: Dictionary = parsed.get("artifacts", parsed) if parsed.get("artifacts", parsed) is Dictionary else {}
		for token in entries:
			var e: Variant = entries[token]
			if not e is Dictionary or not (e as Dictionary).get("dna") is Dictionary:
				continue
			var axes: Variant = (e["dna"] as Dictionary).get("axes")
			if not axes is Dictionary:
				continue
			for key in axes:
				var values: Variant = axes[key]
				if not values is Array or (values as Array).is_empty():
					continue
				var numeric := true
				for v in values:
					if not (v is float or v is int) or v is bool:
						numeric = false
						break
				if not numeric:
					continue
				var id := "%s.%s" % [token, key]
				if seen.has(id):
					continue
				seen[id] = true
				checked += 1
				var value: String = str(values[0])
				if values[0] is float and float(values[0]) == floorf(float(values[0])):
					value = str(int(values[0]))
				var map_token := "%s#%s:%s" % [token, key, value]
				var r: Dictionary = comp._parse_config_token(map_token)
				var cfg: Dictionary = r.get("config_data", {})
				var ov: Dictionary = r.get("overrides", {})
				var got: Variant = cfg.get(key)
				var ok: bool = cfg.has(key) and not (got is bool) and str(got) == value and not ov.has("rotation_y_degrees")
				if not ok:
					failed += 1
					print("[numeric-axis] FAIL ", map_token, " -> config=", cfg, " overrides=", ov, "  (", f, ")")
	comp.free()
	print("[numeric-axis] %d numeric axes checked, %d misread" % [checked, failed])
	quit(mini(failed, 100))
