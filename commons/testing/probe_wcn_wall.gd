extends SceneTree
## Noise_6_Wall, batch N5 (doc/research/waves-chance-noise, 2026-09-12, the fifth hall of Astra's
## noise arc): which layer of a surface are you attending to?
##
## Stands up the ACTUAL museum hall with its artifacts, hands the museum the REAL necklace hand
## file, and tests the sample panel as the map stages it (shader_noise_space:180#stand:panel at
## (9,2), with the immersive room at (6,6)): four patches of ONE field at 1, 2, 4 and 6 layers,
## at one seed, one coordinate frame, one contrast, one colour and one clock, differing only in
## how many terms are summed — with the weight each term carries declared on the plate, because
## the left patch IS darker and that is the whole of the difference.
##
## What it checks. The shader source: the accumulation's loop bound is a uniform (the room was
## named for six scales and had them hardcoded), `show_term` opens the sum on its own, and both
## default to the shipped picture. The panel: four patches whose every parameter but `layers`
## matches. FREEZE: every animated term the comparison uses stops together — the shader's clock,
## the colour cycling, the density breathing — not one parameter at zero. Material isolation: the
## room's ShaderMaterial is per-instance, so a uniform set in this hall cannot reach another's
## walls, and the layer control speaks only to rooms under this hall. And the doorways: the
## museum's own tile is read to confirm both door rows are clear of the staging.
##
##   godot --rendering-method gl_compatibility --path . --xr-mode off --script res://commons/testing/probe_wcn_wall.gd -- --capture
##
## Writes res://ada_run/waves_chance_noise/Noise_6_Wall/probe_wall.json
## (and probe_wall*.png under --capture). Exit code 1 on any failed check.
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "Noise_6_Wall"
const OUT := "res://ada_run/waves_chance_noise/Noise_6_Wall/"
## Screenshots and audio go to the evidence root, ada_encyclopedia/captures/ada-run/ (2026-09-14);
## the JSON record stays in OUT, where it is committed.
var _evidence: String = preload("res://commons/testing/evidence_root.gd").dir("waves_chance_noise/Noise_6_Wall") + "/"
const MAP_CELL := Vector2i(9, 2)
const SHADER_PATH := "res://algorithms/randomness/shadernoisespace/WallNoiseShader.gdshader"
const SPOT := Vector3(9.5, 0.0, 1.5)
const EYE_H := 1.6

func _initialize() -> void: run.call_deferred()

func _live() -> bool:
	return str(get_script().resource_path).ends_with("_live.gd")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-wall] ", "PASS " if ok else "FAIL ", message)

func note(message: String) -> void:
	print("[wcn-wall] note: ", message)

func run() -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() == "headless":
		check(false, "PNG capture requires a rendered window; omit --headless, or omit --capture for logic only")
		_finish(); return

	# ── 0. the shader, read as source ───────────────────────────────────────
	var src: String = FileAccess.get_file_as_string(SHADER_PATH)
	measurements["shader"] = {"bytes": src.length(),
		"layers_uniform": src.contains("uniform int layers"),
		"loop_bound": src.contains("for (int i = 0; i < layers; i++)"),
		"hardcoded_six": src.contains("for (int i = 0; i < 6; i++)"),
		"show_term": src.contains("uniform int show_term"),
		"defaults": src.contains("uniform int layers : hint_range(1, 6) = 6") and src.contains("uniform int show_term : hint_range(0, 1) = 0")}
	check(bool(measurements["shader"]["layers_uniform"]) and bool(measurements["shader"]["loop_bound"]),
		"the accumulation's loop bound is a uniform: a visitor can take a layer away")
	check(not bool(measurements["shader"]["hardcoded_six"]), "and no hardcoded six is left in that loop")
	check(bool(measurements["shader"]["show_term"]), "the sum can be shown on its own, apart from the turbulence and the colour")
	check(bool(measurements["shader"]["defaults"]), "and both default to the shipped picture: six layers, full mix")

	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/waves_chance_noise/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused")
	em.set("_hand_path", "res://ada_run/necklace_hand.json")   # the REAL hand, on purpose
	em.set("start_chapter", "noise"); em.set("start_map", MAP)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "noise", "dollhouse": 0, "grid_pack": 1})); f.close()
	root.add_child(em); current_scene = em
	await create_timer(1.2).timeout
	em.set_process(false); em.call("flush_stamps")
	var player: Node = em.get("_player")
	if player != null: player.set_process(false); player.set_physics_process(false)
	var seg: Node3D
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map", "") == MAP: seg = rec.node; break
	check(seg != null, "the hall exists in the active museum")
	if seg == null:
		_finish(); return
	for i in range(30): await process_frame
	var vest: int = int(em.get("VESTIBULE_H"))
	var capture: bool = "--capture" in OS.get_cmdline_user_args()
	var cam: Camera3D
	if capture:
		var wc: Camera3D = em.get("_cam")
		if wc != null and is_instance_valid(wc):
			for c in wc.get_children():
				if c is Timer: (c as Timer).stop()
		cam = Camera3D.new(); em.add_child(cam); cam.fov = 62
	measurements["captures"] = {}

	# ── 1. the hall, the panel and the room ─────────────────────────────────
	var tile: Array = seg.get_meta("em_tile", [])
	var tile_rows: Array = []
	for row in tile:
		var line := ""
		for c in row: line += str(c)
		tile_rows.append(line)
	measurements["tile"] = tile_rows
	for r in range(tile_rows.size()): note("tile %2d %s" % [r, tile_rows[r]])
	var bodies: Array = []
	var panel_body: Node3D
	var room_body: Node3D
	var panel_at := Vector3.ZERO
	var panel_cell_rec: Array = []
	for record: Dictionary in em.get("_edit_records"):
		var node: Node = record.get("node")
		if node == null or not (node is Node3D) or not seg.is_ancestor_of(node): continue
		if str(record.get("token", "")) == "": continue
		var lp: Vector3 = seg.to_local((node as Node3D).global_position)
		var sp: String = str(node.get_script().resource_path).get_file() if node.get_script() != null else "-"
		bodies.append({"token": record.get("token"), "script": sp, "cell": record.get("tile_cell", []), "at": [snappedf(lp.x, 0.01), snappedf(lp.y, 0.01), snappedf(lp.z - vest, 0.01)]})
		if sp == "noiseroom.gd":
			if node.get("stand") == "panel":
				panel_body = node
				panel_at = Vector3(snappedf(lp.x, 0.01), snappedf(lp.y, 0.01), snappedf(lp.z - vest, 0.01))
				panel_cell_rec = record.get("tile_cell", [])
			else: room_body = node
	measurements["bodies"] = bodies
	for b in bodies:
		if not str(b["token"]).begins_with("lobby") and str(b["token"]) != "showing": note("body %-34s %-16s cell %s" % [str(b["token"]), str(b["script"]), str(b["cell"])])
	check(panel_body != null, "the sample panel is built at the entrance")
	check(room_body != null, "and the immersive room stands where it always did")
	if panel_body == null:
		_finish(); return
	await create_timer(0.4).timeout
	var walk_sev: Array = em.get("_walk_severed") if em.get("_walk_severed") != null else []
	var mine: Array = []
	for e in walk_sev:
		if str((e as Dictionary).get("hall", "")).contains(MAP): mine.append(e)
	measurements["museum_walk_severed"] = mine
	check(mine.is_empty(), "the museum walks this hall door to door with both in it (%s)" % str(mine))
	# both doorways clear: the tile's first and last rows, and nothing of ours standing in them
	var doors: Dictionary = {"north": [], "south": []}
	if tile_rows.size() > 1:
		for x in range(str(tile_rows[0]).length()):
			if str(tile_rows[0])[x] == "1": (doors["north"] as Array).append(x)
		var last_row: String = str(tile_rows[tile_rows.size() - 1])
		for x in range(last_row.length()):
			if last_row[x] == "1": (doors["south"] as Array).append(x)
	var panel_cell: Array = panel_cell_rec
	measurements["doorways"] = {"north": doors["north"], "south": doors["south"], "panel_cell": panel_cell}
	check((doors["north"] as Array).size() > 0 and (doors["south"] as Array).size() > 0,
		"both doorways are open in the museum's own tile (north %s, south %s)" % [str(doors["north"]), str(doors["south"])])
	check(panel_cell.size() < 2 or int(panel_cell[1]) > 0, "and the panel does not stand in one of them (%s)" % str(panel_cell))

	# THE MAP'S CELL, OR A SLIDE NOBODY READ (2026-09-12). The first staging stood the board
	# across the entrance corridor. The museum said so in its own log — "seals 2 cell(s), the
	# route is severed" — and its reach repair slid the body two cells east and one north to
	# reopen the walk. Every text still said (7,3). A board beside the path stands where the
	# map put it, and this is the number that says so.
	var want := Vector2(float(MAP_CELL.x) + 0.5, float(MAP_CELL.y) + 0.5)
	var got := Vector2(panel_at.x, panel_at.z)
	measurements["placement"] = {"cell": [MAP_CELL.x, MAP_CELL.y], "want": [want.x, want.y],
		"got": [got.x, got.y], "drift": snappedf(got.distance_to(want), 0.01)}
	note("placement " + JSON.stringify(measurements["placement"]))
	check(got.distance_to(want) < 0.26, "the board stands on the cell the map named — the museum did not slide it (%s, wanted %s)" % [str(got), str(want)])

	# THE ROOM IS LARGER THAN THE HALL IT STANDS IN. Measured here, not fixed: the scene's
	# enclosure is 27 m deep and 13.5 m tall, the hall is 13 cells wide with 3 m walls, so in
	# the museum its walls stand OUTSIDE the hall's own walls and its ceiling above the hall's
	# ceiling. A visitor in this hall does not enter the cloud — they pass a board about it.
	# The scene is placed in 12 maps; resizing it is not a panel pass.
	var encl := AABB()
	var first_box := true
	if room_body != null:
		# GEOMETRY ONLY: an OmniLight3D's AABB is its range, and a lit radius is not a wall.
		for n in room_body.find_children("*", "GeometryInstance3D", true, false):
			var vi: GeometryInstance3D = n
			var box: AABB = (room_body.global_transform.affine_inverse() * vi.global_transform) * vi.get_aabb()
			if first_box:
				encl = box; first_box = false
			else:
				encl = encl.merge(box)
	var ball: Node = room_body.get_node_or_null("RoomContainer/MainRoomBody/RoomShape") if room_body != null else null
	measurements["enclosure"] = {"room_extent": [snappedf(encl.size.x, 0.1), snappedf(encl.size.y, 0.1), snappedf(encl.size.z, 0.1)],
		"sphere_radius": float(ball.get("radius")) if ball != null else -1.0,
		"hall_cells": [str(tile_rows[0]).length() if not tile_rows.is_empty() else 0, tile_rows.size()],
		"panel_carries_enclosure": panel_body.get_node_or_null("WallsContainer") != null or panel_body.get_node_or_null("RoomContainer") != null}
	note("the room's enclosure measures %.1f x %.1f x %.1f m in a hall %d cells wide — walls outside walls, ceiling above ceiling; the sphere inside it is %.2f m in radius" % [
		encl.size.x, encl.size.y, encl.size.z, int((measurements["enclosure"] as Dictionary)["hall_cells"][0]),
		float((measurements["enclosure"] as Dictionary)["sphere_radius"])])
	check(not bool((measurements["enclosure"] as Dictionary)["panel_carries_enclosure"]),
		"the staged body is a BOARD: it does not drag the enclosure behind it")

	# ── 2. four patches, one field ──────────────────────────────────────────
	var st: Dictionary = panel_body.call("panel_state")
	measurements["panel"] = st
	note("panel " + JSON.stringify(st))
	var patches: Array = st["patches"]
	check(patches.size() == 4, "four patches stand on the board (%d)" % patches.size())
	var counts: Array = []
	for p in patches: counts.append(int((p as Dictionary)["layers"]))
	check(counts == [1, 2, 4, 6], "at one, two, four and six layers (%s)" % str(counts))
	var same := {"show_term": [], "time_scale": [], "cloud_scale": [], "cloud_density": [], "noise_basis": [], "shader": []}
	for p in patches:
		for k in same.keys():
			(same[k] as Array).append((p as Dictionary)[k])
	var differing: Array = []
	for k in same.keys():
		var vals: Array = same[k]
		for v in vals:
			if str(v) != str(vals[0]): differing.append(k)
	measurements["patch_parameters"] = same
	check(differing.is_empty(), "and every other parameter is identical across them — the comparison is fair (%s)" % str(differing))
	check(int((patches[0] as Dictionary)["show_term"]) == 1, "each shows the accumulation alone, without the turbulence or the colour the room paints over it")
	var weights: Array = st["weights"]
	check(weights.size() == 4 and abs(float(weights[0]) - 0.5) < 0.001 and abs(float(weights[3]) - 0.984375) < 0.0001,
		"the weights are declared: %s — which is why the left patch is darker and not otherwise different" % str(weights))
	var ro: Label3D = panel_body.get_node_or_null("SamplePanel/Readout/Text")
	check(ro != null, "the plate is cased under the board")
	if ro != null:
		measurements["readout"] = ro.text.split("\n")
		for l in ro.text.split("\n"): note("plate | " + l)
		check(ro.text.contains("weight"), "and prints those weights")
		check(ro.text.contains("one seed") and ro.text.contains("one clock"), "and what is held fixed across the four")

	# ── 3. every instance its own material ──────────────────────────────────
	measurements["isolation"] = {"room_material_local": bool(st["room_material_local"]), "wall_material_local": bool(st["wall_material_local"]),
		"patches_local": patches.all(func(p): return bool((p as Dictionary)["local"]))}
	check(bool(st["room_material_local"]) and bool(st["wall_material_local"]),
		"the room's materials are this instance's own: a uniform set here cannot reach another hall's walls")
	check(patches.all(func(p): return bool((p as Dictionary)["local"])), "and so is every patch's")

	# ── 4. the layer control, and its reach ─────────────────────────────────
	var before_layers: int = int(st["layers"])
	check(_press(panel_body, "Btn_0"), "LAYERS pressed through the button's signal (one argument)")
	await create_timer(0.4, true, false, true).timeout
	var after: Dictionary = panel_body.call("panel_state")
	measurements["layers_press"] = {"was": before_layers, "now": int(after["layers"]),
		"room": int(after["room_layers"]), "wall": int(after["wall_layers"]), "broadcast": after["broadcast"]}
	note("layers " + JSON.stringify(measurements["layers_press"]))
	check(int(after["layers"]) != before_layers, "the walls take another count (%d → %d)" % [before_layers, int(after["layers"])])
	check(int(after["wall_layers"]) == int(after["layers"]) and int(after["room_layers"]) == int(after["layers"]),
		"and the uniform actually carries it into both materials (%d / %d)" % [int(after["room_layers"]), int(after["wall_layers"])])
	var bc: Dictionary = after["broadcast"]
	check(not bc.is_empty() and str(bc.get("hall", "")) != "", "the control records which hall it spoke to (%s)" % JSON.stringify(bc))
	if room_body != null:
		check(int(room_body.get("layers")) == int(after["layers"]), "and the room across the hall hears it (%s)" % str(room_body.get("layers")))

	# ── 5. a freeze that covers every animated term ─────────────────────────
	check(_press(panel_body, "Btn_2"), "FREEZE pressed")
	await create_timer(0.5, true, false, true).timeout
	var frozen: Dictionary = panel_body.call("panel_state")
	measurements["freeze"] = {"animation": str(frozen["animation"]), "animation_enabled": bool(frozen["animation_enabled"]),
		"color_cycling": bool(frozen["color_cycling"]), "cloud_density_animation": bool(frozen["cloud_density_animation"]),
		"wall_time_scale": float(frozen["wall_time_scale"]), "patch_time_scale": float((frozen["patches"][0] as Dictionary)["time_scale"])}
	note("freeze " + JSON.stringify(measurements["freeze"]))
	check(str(frozen["animation"]) == "frozen" and not bool(frozen["animation_enabled"]),
		"the room's own animation stops")
	check(not bool(frozen["color_cycling"]) and not bool(frozen["cloud_density_animation"]),
		"the colour cycling and the density breathing stop with it")
	check(is_equal_approx(float(frozen["wall_time_scale"]), 0.0) and is_equal_approx(float((frozen["patches"][0] as Dictionary)["time_scale"]), 0.0),
		"and the shader's own clock is zero on the walls and on every patch — not one parameter at zero, all of them")

	# ── 6. the basis is its own comparison ──────────────────────────────────
	var basis_before: String = str(panel_body.call("panel_state")["generator"])
	var layers_before: int = int(panel_body.call("panel_state")["layers"])
	check(_press(panel_body, "Btn_1"), "BASIS pressed")
	await create_timer(0.4, true, false, true).timeout
	var basis_after: Dictionary = panel_body.call("panel_state")
	measurements["basis"] = {"was": basis_before, "now": str(basis_after["generator"]),
		"layers_was": layers_before, "layers_now": int(basis_after["layers"]), "touched": str(basis_after["last_touched"])}
	check(str(basis_after["generator"]) != basis_before, "the generator changes (%s → %s)" % [basis_before, str(basis_after["generator"])])
	check(int(basis_after["layers"]) == layers_before, "and the number of layers does not: they are two comparisons, not one (%d)" % layers_before)
	check(str(basis_after["last_touched"]).contains("BASIS"), "and the plate says which was touched")

	# ── 7. captures, and the desktop rig in the live port ───────────────────
	if capture:
		var board: Node3D = panel_body.get_node_or_null("SamplePanel")
		if board != null:
			cam.fov = 60
			cam.global_position = board.global_position + seg.global_transform.basis * Vector3(0.0, 1.30, -1.45)
			cam.look_at(board.global_position + Vector3(0, 1.28, 0))
			for i in range(18): cam.make_current(); await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_wall.png")
			measurements["captures"]["primary"] = _cam_pose(cam)
			var rn: Node3D = board.get_node_or_null("Readout")
			if rn != null:
				cam.global_position = rn.global_position + seg.global_transform.basis * Vector3(0.0, 0.22, -0.66)
				cam.look_at(rn.global_position)
				for i in range(14): cam.make_current(); await process_frame
				await create_timer(0.25, true, false, true).timeout
				root.get_texture().get_image().save_png(_evidence + "probe_wall_readout.png")
				measurements["captures"]["readout"] = _cam_pose(cam)
		if room_body != null:
			# NOT "inside the room" — there is no inside to stand in here (see the enclosure
			# measurement above). This is the hall as a visitor meets it: from the reading
			# landing, past the board, down the hall the room is supposed to line.
			cam.global_position = seg.to_global(Vector3(SPOT.x - 1.0, 1.6, SPOT.z + vest - 0.4))
			cam.look_at(seg.to_global(Vector3(6.5, 1.2, 8.0 + vest)))
			for i in range(14): cam.make_current(); await process_frame
			await create_timer(0.25, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_wall_interior.png")
			measurements["captures"]["interior"] = _cam_pose(cam)
		# UNDER the room's ceiling (6.75 m, 16 x 24 m): a plan shot from 12 m photographed it.
		cam.global_position = seg.to_global(Vector3(6.5, 5.6, 6.5 + vest))
		cam.look_at(seg.to_global(Vector3(6.48, 0.0, 6.4 + vest)))
		for i in range(14): cam.make_current(); await process_frame
		await create_timer(0.25, true, false, true).timeout
		root.get_texture().get_image().save_png(_evidence + "probe_wall_plan.png")
		measurements["captures"]["plan"] = _cam_pose(cam)

	if _live():
		var drv: Node = load("res://commons/testing/wcn_desktop_driver.gd").new()
		root.add_child(drv)
		var stand_at: Vector3 = seg.to_global(Vector3(SPOT.x, 0.05, SPOT.z + vest))
		drv.call("spawn", stand_at, em)
		for i in range(20): await process_frame
		check(bool(drv.call("is_ready")), "the desktop rig stands before the panel")
		measurements["desktop_input"] = {"stand_pose": drv.call("pose")}
		var rack: Node = panel_body.find_child("Panel", true, false)
		var press_from: Vector3 = stand_at
		if rack != null:
			var pl: Vector3 = seg.to_local((rack as Node3D).global_position)
			press_from = seg.to_global(Vector3(pl.x, 0.05, pl.z - 0.45))
		measurements["desktop_input"]["press_from"] = [snappedf(press_from.x, 0.01), snappedf(press_from.z, 0.01)]
		for pair in [["Btn_0", "LAYERS", "layers"], ["Btn_2", "FREEZE", "frozen"]]:
			var btn: Node = rack.find_child(pair[0], true, false) if rack != null else null
			var was = panel_body.call("panel_state")[pair[2]]
			# stand in front of THIS button, not of the panel: the buttons sit on two rows and
			# a stand aimed from the panel's centre reached the upper one and missed the lower
			var from_here: Vector3 = press_from
			if btn != null:
				var bl: Vector3 = seg.to_local((btn as Node3D).global_position)
				from_here = seg.to_global(Vector3(bl.x, 0.05, bl.z - 0.45))
			# COUNT THE EMISSIONS. A press that hovers the right button and moves nothing fired
			# zero times or twice, and "was == now" cannot tell those apart.
			var area: Node = btn.find_child("InteractableAreaButton", true, false) if btn != null else null
			var tally := {"n": 0}
			if area != null and area.has_signal("button_pressed"):
				area.connect("button_pressed", func(_b): tally["n"] = int(tally["n"]) + 1)
			var rec: Dictionary = await drv.call("press", btn, from_here) if btn != null else {}
			await create_timer(0.4, true, false, true).timeout
			var now = panel_body.call("panel_state")[pair[2]]
			measurements["desktop_input"]["press_%s" % pair[1]] = {"hover": rec.get("hover", "-"), "was": was, "now": now,
				"emissions": int(tally["n"]), "ray": rec.get("ray", {})}
			note("press %s %s" % [pair[1], JSON.stringify(measurements["desktop_input"]["press_%s" % pair[1]])])
			check(int(tally["n"]) == 1, "%s takes exactly one press from one click (%d)" % [pair[1], int(tally["n"])])
			check(now != was, "%s pressed through the pointer changes what it says it changes (%s → %s)" % [pair[1], str(was), str(now)])
		if capture:
			var board2: Node3D = panel_body.get_node_or_null("SamplePanel")
			# BACK TO THE READING LANDING. The rig was last standing at a button, 0.45 m from
			# the board and off to one side; aiming from there photographs the board as a wedge.
			# This is the view a body has while READING it.
			var rig3: CharacterBody3D = drv.get("rig")
			if rig3 != null:
				rig3.global_position = seg.to_global(Vector3(SPOT.x, 0.05, SPOT.z + vest))
				rig3.velocity = Vector3.ZERO
			for i in range(8): await process_frame
			drv.call("aim_at", board2.global_position + Vector3(0, 1.28, 0) if board2 != null else stand_at)
			for i in range(8): await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_wall_desktop_front.png")
			measurements["desktop_input"]["front_pose"] = drv.call("pose")
		drv.call("teardown")

	_finish()

func _press(body: Node, btn_name: String) -> bool:
	var rack: Node = body.find_child("Panel", true, false)
	if rack == null: return false
	var btn: Node = rack.find_child(btn_name, true, false)
	if btn == null: return false
	var area: Node = btn.get_node_or_null("InteractableAreaButton")
	if area == null or not area.has_signal("button_pressed"): return false
	area.emit_signal("button_pressed", area)
	return true

func _cam_pose(cam: Camera3D) -> Dictionary:
	var cur: Camera3D = root.get_camera_3d()
	var fwd: Vector3 = -cam.global_transform.basis.z
	return {"current_camera": str(cur.get_path()).right(50) if cur != null else "none", "is_ours": cur == cam,
		"at": [snappedf(cam.global_position.x, 0.01), snappedf(cam.global_position.y, 0.01), snappedf(cam.global_position.z, 0.01)],
		"forward": [snappedf(fwd.x, 0.01), snappedf(fwd.y, 0.01), snappedf(fwd.z, 0.01)]}

func _finish() -> void:
	var report := {"map": MAP, "checks": checks, "failures": failures, "measurements": measurements,
		"control_path": "LAYERS / BASIS / FREEZE through InteractableAreaButton.button_pressed (one argument); the live port presses LAYERS and FREEZE through the desktop pointer from arm's length",
		"hand_file": "ada_run/necklace_hand.json (real)", "headset_verified": false,
		"engine": Engine.get_version_info().string, "physics_fps": Engine.physics_ticks_per_second}
	var f := FileAccess.open(OUT + "probe_wall.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-wall] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
