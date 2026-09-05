extends SceneTree

## THE INTEGRATED GALLERIES (2026-09-05, Palle: "make these maps showcase all
## kinds of transformations like integrated galleries"). Trans_Translation,
## Trans_AxisDecomposition and Trans_Scale carry, in their utility layer, the
## whole ride vocabulary: translation along x, y and z, the diagonal, translation
## with a quarter turn, translation with the space growing or shrinking, a
## rotation plank, a scale cube, a bridge - and captions naming each. This probe
## LOADS each map in the grid through the catalog and checks that every ride
## and caption the cells ask for stands, with the parameters the cells say.
##
## Run:  godot --path . --xr-mode off --no-window --script res://commons/testing/probe_transformation_galleries.gd

const CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const MAPS := ["Trans_Pre", "Trans_Translation", "Trans_AxisDecomposition", "Trans_Scale", "Trans_Rotation", "Trans_RotationSpectacle"]
const SCRIPT_OF := {"tc": "transport_cube.gd", "rc": "rotation_cube.gd", "sc": "scale_cube.gd", "br": "bridge_path.gd", "3t": "word_is.gd"}

var _fails := 0


func _initialize() -> void:
	_run.call_deferred()


func _check(cond: bool, what: String) -> void:
	if cond:
		print("  ok   ", what)
	else:
		_fails += 1
		print("  FAIL ", what)


func _cells(map_name: String) -> Dictionary:
	var out := {}
	for code in SCRIPT_OF.keys():
		out[code] = []
	var doc = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json" % map_name))
	var layers: Dictionary = (doc as Dictionary).get("layers", doc)
	for row in layers.get("utilities", []):
		for cell in row:
			var c := str(cell).strip_edges()
			var code := c.split(":")[0].split("#")[0]
			if out.has(code):
				out[code].append(c)
	return out


func _bodies(n: Node, found: Dictionary) -> void:
	var sp := ""
	if n.get_script() != null:
		sp = str((n.get_script() as Script).resource_path).to_lower()
	for code in SCRIPT_OF.keys():
		if sp.ends_with("/" + SCRIPT_OF[code]):
			found[code].append(n)
	for c in n.get_children():
		_bodies(c, found)


func _count_by_lookup(n: Node, out: Dictionary) -> void:
	# a placement is the OUTERMOST node wearing the lookup name: a synthesis stand
	# builds its subject (a pick_up_cube) inside itself, and that one is the
	# stand's, not a cell's
	if n.has_meta("artifact_lookup_name"):
		var k := str(n.get_meta("artifact_lookup_name"))
		out[k] = int(out.get(k, 0)) + 1
		return
	for c in n.get_children():
		_count_by_lookup(c, out)


func _run() -> void:
	print("[probe_transformation_galleries]")
	var err: int = change_scene_to_file(CATALOG)
	if err != OK:
		_check(false, "the catalog scene loads")
		_finish()
		return
	await process_frame
	await process_frame
	for map_name in MAPS:
		var cells := _cells(map_name)
		var ok: bool = bool(current_scene.call("load_map_fresh", map_name))
		_check(ok, "%s: load_map_fresh" % map_name)
		for i in range(200):
			await process_frame
		var found := {}
		for code in SCRIPT_OF.keys():
			found[code] = []
		_bodies(root, found)
		var counts: Array[String] = []
		var all_match := true
		for code in ["tc", "rc", "sc", "br", "3t"]:
			counts.append("%s %d/%d" % [code, (found[code] as Array).size(), (cells[code] as Array).size()])
			if (found[code] as Array).size() != (cells[code] as Array).size():
				all_match = false
		_check(all_match, "%s: one body per cell - %s" % [map_name, ", ".join(counts)])
		# the composed rides carry their tails
		var want_rot := 0
		var want_scale := 0
		for c in cells["tc"]:
			if "#rot" in c:
				want_rot += 1
			if "#scale" in c:
				want_scale += 1
		var got_rot := 0
		var got_scale := 0
		for n in found["tc"]:
			if not is_zero_approx(float(n.get("ride_rotation_degrees"))):
				got_rot += 1
			if not is_equal_approx(float(n.get("ride_scale")), 1.0):
				got_scale += 1
		_check(got_rot == want_rot and got_scale == want_scale,
			"%s: composed rides - %d turning (cells say %d), %d scaling the space (cells say %d)" % [map_name, got_rot, want_rot, got_scale, want_scale])
		# every rotation cube is in the mode and at the angle (or speed) its cell says
		if not (cells["rc"] as Array).is_empty():
			var want_rc: Array = []
			for c in cells["rc"]:
				var r: Dictionary = UtilityRegistry.rotation_params(UtilityRegistry.parse_utility_cell(c)["parameters"])
				want_rc.append("continuous %.0f" % float(r["continuous_speed"]) if String(r["mode"]) == "continuous" else "step %.0f" % float(r["angle"]))
			var got_rc: Array = []
			for n in found["rc"]:
				got_rc.append("continuous %.0f" % float(n.get("continuous_speed")) if int(n.get("mode")) == 1 else "step %.0f" % float(n.get("rotation_angle")))
			want_rc.sort()
			got_rc.sort()
			_check(want_rc == got_rc, "%s: the rotation cubes are what their cells say - %s" % [map_name, str(got_rc)])
		for n in found["sc"]:
			_check(float(n.get("min_scale")) > 0.0 and absf(float(n.get("max_scale")) - 3.0) < 1e-6, "%s: the scale cube grows to 3 from %.3f" % [map_name, float(n.get("min_scale"))])
		# the places reached and the gates: one body per exhibit cell for the Mario cubes,
		# the blocks that open walls, and the pick-ups the gate counts
		var want_art := {}
		var doc_a = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json" % map_name))
		var layers_a: Dictionary = (doc_a as Dictionary).get("layers", doc_a)
		for row in layers_a.get("interactables", []):
			for cell in row:
				var head := str(cell).strip_edges().split(":")[0].split("#")[0]
				if head in ["mario_cube", "pusher_block", "sweeper_block", "grower_block", "pick_up_cube"]:
					want_art[head] = int(want_art.get(head, 0)) + 1
		var got_art := {}
		_count_by_lookup(root, got_art)
		var art_ok := true
		var art_parts: Array[String] = []
		for head in want_art.keys():
			var g: int = int(got_art.get(head, 0))
			art_parts.append("%s %d/%d" % [head, g, int(want_art[head])])
			if g != int(want_art[head]):
				art_ok = false
		_check(art_ok, "%s: the places reached and the gates stand - %s" % [map_name, ", ".join(art_parts)])
		# every caption stands with its words
		var caps: Array = []
		for n in found["3t"]:
			# the grid writes the words onto the TextMesh and a display_text meta, not the export
			caps.append(str(n.get_meta("display_text")) if n.has_meta("display_text") else str(n.get("text")))
		var missing: Array = []
		for c in cells["3t"]:
			var words: String = str(c).substr(3).replace("_", " ").strip_edges()
			var hit := false
			for t in caps:
				if str(t).to_lower().strip_edges() == words.to_lower():
					hit = true
			if not hit:
				missing.append(words)
		_check(missing.is_empty(), "%s: %d captions stand with their words%s" % [map_name, caps.size(), "" if missing.is_empty() else " - missing " + str(missing)])
	_finish()


func _finish() -> void:
	print("[probe_transformation_galleries] %s (%d failures)" % ["PASS" if _fails == 0 else "FAIL", _fails])
	quit(0 if _fails == 0 else 1)
