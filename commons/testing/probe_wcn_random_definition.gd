extends SceneTree
## Random_Definition pilot (doc/research/waves-chance-noise, 2026-09-10):
## does the same seed come back exactly, and does one extra draw break it?
##
## Stands up the ACTUAL museum hall WITH THE REAL HAND FILE — deliberately.
## Every probe before this handed the museum an empty necklace hand, and so
## none of them could see that a bench stamp from 2026-08-21 was claiming every
## body in this hall by token and building seed_replay_demo at the bead's
## cell instead of the map's. The map's museum.artifact_placement=map opt-in (endless_museum.gd,
## the hand lookup before the force stamp) is what this probe tests first: the
## demo must stand at its MAP cell.
##
##   godot --rendering-method gl_compatibility --path . --xr-mode off --script res://commons/testing/probe_wcn_random_definition.gd -- --capture
##
## Writes res://ada_run/waves_chance_noise/Random_Definition/probe_random_definition.json.
## Control path: the panel buttons' InteractableAreaButton.button_pressed is
## emitted programmatically; the slider is not driven. No tracked hand.
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "Random_Definition"
const OUT := "res://ada_run/waves_chance_noise/Random_Definition/"
## Screenshots and audio go to the evidence root, ada_encyclopedia/captures/ada-run/ (2026-09-14);
## the JSON record stays in OUT, where it is committed.
var _evidence: String = preload("res://commons/testing/evidence_root.gd").dir("waves_chance_noise/Random_Definition") + "/"

func _initialize() -> void: run.call_deferred()

## True under the live harness (probe_live.tscn, project startup with autoloads);
## false under --script, where the desktop rig cannot compile.
func _live() -> bool:
	return str(get_script().resource_path).ends_with("_live.gd")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-random] ", "PASS " if ok else "FAIL ", message)

func run() -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() == "headless":
		check(false, "PNG capture requires a rendered window; omit --headless, or omit --capture for logic only")
		_finish()
		return
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/waves_chance_noise/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused")
	# _hand_path is left at its default: res://ada_run/necklace_hand.json, the live stamps
	em.set("start_chapter", "randomness"); em.set("start_map", MAP)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "randomness", "dollhouse": 0, "grid_pack": 1})); f.close()
	root.add_child(em); current_scene = em
	await create_timer(1.0).timeout
	em.set_process(false); em.set_physics_process(false); em.call("flush_stamps")
	var player: Node = em.get("_player")
	if player != null: player.set_process(false); player.set_physics_process(false)
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map", "") == MAP: seg = rec.node; break
	check(seg != null, "the hall exists in the active museum")
	if seg == null:
		_finish(); return
	for i in range(30): await process_frame

	# ── 1. the map is the placement authority, with the real hand file loaded ──
	var source: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/" + MAP + "/map_data.json"))
	var want := Vector2i(-1, -1)
	var inter: Array = source.layers.interactables
	for z in range(inter.size()):
		for x in range(inter[z].size()):
			if str(inter[z][x]).begins_with("seed_replay_demo"): want = Vector2i(x, z)
	var vest: int = int(em.get("VESTIBULE_H"))
	var placed := Vector2i(-99, -99)
	for record: Dictionary in em.get("_edit_records"):
		var child: Node3D = record.get("node")
		if child == null or not is_instance_valid(child) or not seg.is_ancestor_of(child): continue
		if str(record.get("token", "")) == "seed_replay_demo" and (record.tile_cell as Array).size() >= 2:
			placed = Vector2i(int(record.tile_cell[0]), int(record.tile_cell[1]))
	measurements["map_cell"] = [want.x, want.y]; measurements["built_cell"] = [placed.x, placed.y]
	check(placed == Vector2i(want.x, want.y + vest) or placed == want, "seed_replay_demo stands at its MAP cell %s (built %s) — the bench stamp did not claim it" % [want, placed])
	var hand: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://ada_run/necklace_hand.json"))
	var stamped: bool = (hand.get("halls", {}) as Dictionary).has("randomness|random definition")
	check(stamped, "the live hand file still carries a stamp for this hall (so the exemption, not its absence, is what was tested)")

	# ── 2. the artifact ───────────────────────────────────────────────────────
	var demo: Node3D
	for n in seg.find_children("*", "Node3D", true, false):
		if n is SeedReplayDemo: demo = n; break
	check(demo != null, "seed_replay_demo is built")
	if demo == null:
		_finish(); return
	check(str(demo.get("comparison")) == "replicas", "placed with comparison=replicas")
	check(int(demo.call("column_count")) == 2, "two grids stand side by side")
	check(int(demo.call("draws_per_grid")) == 192, "192 draws per grid (3 per cell)")
	var a0: PackedColorArray = demo.call("column_colors", 0)
	var b0: PackedColorArray = demo.call("column_colors", 1)
	check(a0.size() == 64 and b0.size() == 64, "each grid has 64 sample colours")
	check(_same(a0, b0), "same seed, same draw order: all 64 colours match cell for cell")
	var seed0: int = int(demo.call("current_seed"))
	# REPLAY through the panel's own button signal
	var replay_area: Node = _button_area(demo, "Btn_0")
	check(replay_area != null, "the REPLAY button exists on the panel")
	if replay_area != null: replay_area.emit_signal("button_pressed", replay_area)
	await process_frame
	check(_same(demo.call("column_colors", 0), a0) and _same(demo.call("column_colors", 1), b0), "REPLAY reconstructs both grids exactly")
	# +1 DRAW
	var extra_area: Node = _button_area(demo, "Btn_2")
	check(extra_area != null, "the +1 DRAW button exists on the panel")
	if extra_area != null: extra_area.emit_signal("button_pressed", extra_area)
	await process_frame
	var b1: PackedColorArray = demo.call("column_colors", 1)
	var diff := 0
	for i in range(mini(b0.size(), b1.size())):
		if not b0[i].is_equal_approx(b1[i]): diff += 1
	measurements["cells_changed_by_one_extra_draw"] = diff
	check(bool(demo.call("extra_on")), "the extra draw is on")
	check(_same(demo.call("column_colors", 0), a0), "the left grid is untouched by the extra draw")
	check(diff >= 60, "one extra draw changes the right grid almost everywhere (%d of 64 cells)" % diff)
	check(int(demo.call("current_seed")) == seed0, "the seed did not change (%d)" % seed0)
	if extra_area != null: extra_area.emit_signal("button_pressed", extra_area)
	await process_frame
	check(_same(demo.call("column_colors", 1), b0), "pressing +1 DRAW again mends the match")
	# RANDOM, twice, and the global generator is left alone
	seed(4242); var g1: int = randi()
	var random_area: Node = _button_area(demo, "Btn_1")
	check(random_area != null, "the RANDOM button exists on the panel")
	seed(4242)
	if random_area != null: random_area.emit_signal("button_pressed", random_area)
	var g2: int = randi()
	check(g1 == g2, "RANDOM did not advance the game's global RNG")
	await process_frame
	var s1: int = int(demo.call("current_seed"))
	if random_area != null: random_area.emit_signal("button_pressed", random_area)
	await process_frame
	var s2: int = int(demo.call("current_seed"))
	measurements["seeds"] = [seed0, s1, s2]
	check(s1 != seed0 or s2 != seed0, "RANDOM chose another seed (%d -> %d -> %d)" % [seed0, s1, s2])
	check(_same(demo.call("column_colors", 0), demo.call("column_colors", 1)), "after RANDOM the two grids still match each other")
	var slider: Node = demo.find_child("Param_0", true, false)
	check(slider != null and slider.has_method("get_normalized_value"), "the seed slider exists")
	if slider != null:
		check(absf(float(slider.get_normalized_value()) - float(s2) / 999.0) < 0.01, "the slider followed the RANDOM seed")

	# ── 2b. the visual pass of 12 September: the action line at the panel's foot ──────────
	var aline: Label3D = demo.get_node_or_null("ActionLine")
	# the demo draws a seed on arrival, so the line's first word is RANDOM before anyone presses
	check(aline != null and (aline.text.begins_with("RANDOM · seed ") or aline.text.begins_with("ARRIVAL · seed ")) and aline.text.ends_with("grids equal"), "a cased action line at the panel's foot names the last action, the seed and the grids' agreement (%s)" % (aline.text if aline != null else "none"))
	var dpanel: Node3D = demo.get_node_or_null("Panel")
	check(dpanel != null and dpanel.scale.x > 1.4, "the panel is enlarged for its labels (scale %.2f)" % (dpanel.scale.x if dpanel != null else 0.0))
	# Astra's review of the visual pass: material and lettering contrast, not just size
	if dpanel != null:
		var dark_plates: int = 0
		var pale_plates: int = 0
		var lettered_tags: int = 0   # the rack's baked-text tags: black lettering baked into an off-white albedo texture
		var pale_paths: Array = []
		for mi in dpanel.find_children("*", "MeshInstance3D", true, false):
			var mat: Material = (mi as MeshInstance3D).material_override
			if mat == null and (mi as MeshInstance3D).mesh != null and (mi as MeshInstance3D).mesh.get_surface_count() > 0: mat = (mi as MeshInstance3D).mesh.surface_get_material(0)
			if mat is StandardMaterial3D:
				var c: Color = (mat as StandardMaterial3D).albedo_color
				var lum: float = (c.r + c.g + c.b) / 3.0
				if (mat as StandardMaterial3D).albedo_texture != null and lum >= 0.75:
					lettered_tags += 1
				elif lum >= 0.75:
					pale_plates += 1
					pale_paths.append([str((mi as Node).get_path()).right(40), (mi as MeshInstance3D).visible, snappedf(lum, 0.01)])
				elif lum < 0.25: dark_plates += 1
		measurements["panel_pale_meshes"] = pale_paths
		measurements["panel_lettered_tags"] = lettered_tags
		var light_labels: int = 0
		var labels: int = 0
		var smallest: int = 999
		for l in dpanel.find_children("*", "Label3D", true, false):
			labels += 1
			var lm: Color = (l as Label3D).modulate
			if (lm.r + lm.g + lm.b) / 3.0 > 0.85 and (l as Label3D).outline_size >= 4: light_labels += 1
			smallest = mini(smallest, (l as Label3D).font_size)
		measurements["panel_contrast"] = {"pale_plates": pale_plates, "dark_plates": dark_plates, "lettered_tags": lettered_tags, "labels": labels, "light_labels": light_labels, "smallest_font": smallest}
		check(pale_plates == 0 and dark_plates >= 1, "the panel's bare plates are dark (%d pale, %d dark)" % [pale_plates, dark_plates])
		check(lettered_tags >= 3, "the button names are baked tags, black lettering on off-white, kept pale on purpose (%d tags)" % lettered_tags)
		check(labels > 0 and light_labels == labels and smallest >= 16, "every label on it is light with a dark outline, none under 16 px (%d of %d, smallest %d)" % [light_labels, labels, smallest])

	# ── 3. reach and the recovered platforms ──────────────────────────────────
	var panel: Node3D = demo.find_child("Param_0", true, false)
	if panel != null:
		var ph: float = seg.to_local((panel as Node3D).global_position).y
		measurements["panel_height"] = ph
		check(ph > 0.6 and ph < 1.6, "the panel is at hand height (%.2f m above the deck)" % ph)
	var heights: Dictionary = seg.get_meta("em_heights", {})
	var structure: Array = source.layers.structure
	var plats := 0; var ok_plats := 0
	for z in range(structure.size()):
		for x in range(structure[z].size()):
			if str(structure[z][x]) == "2":
				plats += 1
				if is_equal_approx(float(heights.get(Vector2i(x, z), -1)), 1.0): ok_plats += 1
	measurements["platform_cells"] = plats; measurements["platform_cells_at_one_metre"] = ok_plats
	check(plats > 0 and ok_plats == plats, "the interior 2-cells are one-metre platforms (%d of %d), not walls" % [ok_plats, plats])

	# ── ACTUAL DESKTOP INPUT (live harness only: the desktop rig names autoloads) ──
	# The project's desktop rig stands where a visitor stands, looks at the RANDOM
	# button and left-clicks through the input pipeline; the artifact's seed must
	# change because the rig's pointer hit the button, not because a signal was emitted.
	if _live():
		var drv: Node = load("res://commons/testing/wcn_desktop_driver.gd").new()
		root.add_child(drv)   # a SceneTree has no add_child; the port maps root. to get_tree().root.
		var vest_d: int = int(em.get("VESTIBULE_H"))
		var origin_d: Vector3 = seg.to_local(demo.global_position)
		# the demo faces -x (rotation -90): a body stands one metre west of it
		var stand: Vector3 = seg.to_global(Vector3(origin_d.x - 1.1, 0.0, origin_d.z))
		drv.call("spawn", stand, em)
		await create_timer(0.5).timeout
		var random_btn: Node = demo.find_child("Btn_1", true, false)
		var seed_before_click: int = int(demo.call("current_seed"))
		var rec: Dictionary = await drv.call("press", random_btn, stand)
		await process_frame
		var seed_after_click: int = int(demo.call("current_seed"))
		measurements["desktop_input"] = {"press": rec, "seed_before": seed_before_click, "seed_after": seed_after_click,
			"log": drv.get("log"), "camera": "desktop rig at " + str(seg.to_local(stand))}
		check(str(rec.get("hover", "")).contains("Btn_1") or str(rec.get("hover", "")).contains("InteractableAreaButton"), "the desktop pointer had the RANDOM button under the crosshair (%s)" % str(rec.get("hover", "")))
		check(seed_after_click != seed_before_click, "a left click through the input pipeline changed the seed (%d -> %d): actual desktop input, not an emitted signal" % [seed_before_click, seed_after_click])
		if "--capture" in OS.get_cmdline_user_args():
			await create_timer(0.3).timeout
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_random_definition_desktop_close.png")
			# the approach: from the north end of the east half, looking south at the demo
			drv.get("rig").global_position = seg.to_global(Vector3(origin_d.x - 0.5, 0.05, origin_d.z - 6.0))
			await physics_frame
			drv.call("aim_at", demo.global_position + Vector3(0, 1.1, 0))
			for i in range(20): await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_random_definition_desktop_approach.png")
		await drv.call("teardown")
		measurements["desktop_input"]["log"] = drv.get("log")
		measurements["desktop_input"]["walker_cam_guard_stopped"] = drv.get("walker_cam_guard_stopped")
		await process_frame
	if "--capture" in OS.get_cmdline_user_args():
		var cam := Camera3D.new(); em.add_child(cam); cam.fov = 55
		# from where a body stands to use the panel (+z), at eye height; the old spot (0,0.9,1.4) was inside the dark sphere that stood south of the demo
		cam.global_position = demo.to_global(Vector3(0.25, 1.55, 1.75)); cam.look_at(demo.to_global(Vector3(0, 1.2, 0)))
		for i in range(30): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(_evidence + "probe_random_definition.png")
	_finish()

func _button_area(demo: Node, btn: String) -> Node:
	var b: Node = demo.find_child(btn, true, false)
	return b.get_node_or_null("InteractableAreaButton") if b != null else null

func _same(a: PackedColorArray, b: PackedColorArray) -> bool:
	if a.size() != b.size(): return false
	for i in range(a.size()):
		if not a[i].is_equal_approx(b[i]): return false
	return true

func _finish() -> void:
	var report := {"map": MAP, "checks": checks, "failures": failures, "measurements": measurements,
		"hand_file": "res://ada_run/necklace_hand.json (the live stamps, on purpose)",
		"control_path": "InteractableAreaButton.button_pressed emitted programmatically; slider read, not driven; no tracked hand",
		"headset_verified": false, "engine": Engine.get_version_info().string}
	var f := FileAccess.open(OUT + "probe_random_definition.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-random] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
