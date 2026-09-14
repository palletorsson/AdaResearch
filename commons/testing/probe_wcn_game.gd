extends SceneTree
## Random_Game, batch R5 (doc/research/waves-chance-noise, 2026-09-12, Astra's thread after
## Random_Mushrooms; Palle: "be bold here, this needs to be more like a Lara Croft adventure"):
## how can you plan when the next state is known but its timing is not?
##
## Stands up the ACTUAL museum hall with its artifacts, hands the museum the REAL necklace hand
## file, and tests the crossing as the map stages it (r_c:0:-0.5#stand:chasm#cue:advance at
## (3,4), placement authority with the map): the hall's own five-by-three pit left as the void
## the museum lays no floor on, the artifact's bed one metre down inside it, the way out of the
## bed, the cut sides and the broken kerbs, three cycling stones across it (this tile the middle
## one), the carved stele (the ORDER: it stands, it leaves, it is gone, it returns), the live
## tablet (the DRAWN wait of each stone and the time left of it), REPLAY · NEW SEED · CUE, and
## the idol at the far lip with the crossing's five-digit seed cut into it.
##
## What it checks, beyond the staging's parts: that the gap has NO unintended supporting museum
## tile (a ray down the pit finds the artifact's bed and nothing else) and that the fall is one
## metre onto a floor; that the order is fixed while only the waits are drawn (each step's draw
## lands in its band, and the stored deadline does not move while the step runs — a countdown
## and not a fresh dice roll wearing a clock's face); that the collider follows the state, which
## is the support claim a body pays for; that the advance cue lights while the stone STILL
## stands and the shipped beacon does not; that REPLAY brings the same rhythm back and NEW SEED
## names another; and that the hall is walkable door to door without the stones at all — the
## bypass Astra asked for, which here is the map's own corridor east of the wall.
##
##   godot --rendering-method gl_compatibility --path . --xr-mode off --script res://commons/testing/probe_wcn_game.gd -- --capture
##
## Writes res://ada_run/waves_chance_noise/Random_Game/probe_game.json
## (and probe_game*.png under --capture). Exit code 1 on any failed check.
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "Random_Game"
const OUT := "res://ada_run/waves_chance_noise/Random_Game/"
## Screenshots and audio go to the evidence root, ada_encyclopedia/captures/ada-run/ (2026-09-14);
## the JSON record stays in OUT, where it is committed.
var _evidence: String = preload("res://commons/testing/evidence_root.gd").dir("waves_chance_noise/Random_Game") + "/"
const MAP_CELL := Vector2i(3, 4)
const PIT_X0 := 1      # the map's void: cells x 1..5, z 3..5
const PIT_X1 := 5
const PIT_Z0 := 3
const PIT_Z1 := 5
const NEAR_LIP := 2.6  # seg-local z of a standing spot on the near lip, before the vestibule
const EYE_H := 1.6

func _initialize() -> void: run.call_deferred()

func _live() -> bool:
	return str(get_script().resource_path).ends_with("_live.gd")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-game] ", "PASS " if ok else "FAIL ", message)

func note(message: String) -> void:
	print("[wcn-game] note: ", message)

func run() -> void:
	if "--capture" in OS.get_cmdline_user_args() and DisplayServer.get_name() == "headless":
		check(false, "PNG capture requires a rendered window; omit --headless, or omit --capture for logic only")
		_finish(); return
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl := "res://ada_run/waves_chance_noise/wcn-probe-control.json"
	em.set("EM_CONTROL", ctl); em.set("_overrides_path", ctl + ".unused")
	em.set("_hand_path", "res://ada_run/necklace_hand.json")   # the REAL hand, on purpose
	em.set("start_chapter", "randomness"); em.set("start_map", MAP)
	var layout: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/em_layout.json"))
	layout.get_or_add("stream", {})["bodies"] = 1
	em.set("_layout", layout)
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": "randomness", "dollhouse": 0, "grid_pack": 1})); f.close()
	root.add_child(em); current_scene = em
	await create_timer(1.0).timeout
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
		cam = Camera3D.new(); em.add_child(cam); cam.fov = 68
	measurements["captures"] = {}

	# ── 0. the hall: tile, bodies, plinths, the walk ─────────────────────────
	var tile: Array = seg.get_meta("em_tile", [])
	var tile_rows: Array = []
	for row in tile:
		var line := ""
		for c in row: line += str(c)
		tile_rows.append(line)
	measurements["tile"] = tile_rows
	for r in range(tile_rows.size()): note("tile %2d %s" % [r, tile_rows[r]])
	var bodies: Array = []
	var prim: Node3D
	var by_token: Dictionary = {}
	for record: Dictionary in em.get("_edit_records"):
		var node: Node = record.get("node")
		if node == null or not (node is Node3D) or not seg.is_ancestor_of(node): continue
		if str(record.get("token", "")) == "": continue
		var lp: Vector3 = seg.to_local((node as Node3D).global_position)
		var sp: String = str(node.get_script().resource_path).get_file() if node.get_script() != null else "-"
		var ent := {"token": record.get("token"), "script": sp, "cell": record.get("tile_cell", []), "at": [snappedf(lp.x, 0.01), snappedf(lp.y, 0.01), snappedf(lp.z - vest, 0.01)], "scale": snappedf((node as Node3D).scale.x, 0.01)}
		bodies.append(ent)
		by_token[str(record.get("token"))] = ent
		if sp == "random_cycle_cube.gd" and node.get("stand") == "chasm": prim = node
	measurements["bodies"] = bodies
	for b in bodies:
		if not str(b["token"]).begins_with("lobby") and str(b["token"]) != "showing": note("body %-30s %-26s cell %-8s at %s scale %s" % [str(b["token"]), str(b["script"]), str(b["cell"]), str(b["at"]), str(b["scale"])])
	check(prim != null, "the cycling tile is built in the hall, staged as the crossing")
	if prim == null:
		_finish(); return
	var me: Dictionary = by_token.get("r_c", {})
	check(me.get("cell", []) == [MAP_CELL.x, MAP_CELL.y], "the tile stands at its map cell (3,4), the pit's own centre (%s)" % str(me.get("cell")))
	check(is_equal_approx(float(me.get("scale", 0.0)), 1.0), "it stands at scale 1, not shrunk by the lane (%s)" % str(me.get("scale")))
	# a floor tile's top must be the floor: the token sinks it half its height
	var top_y: float = prim.global_position.y - seg.global_position.y + 0.5
	measurements["tile_top_above_floor"] = snappedf(top_y, 0.03)
	check(top_y > 0.1 and top_y < 0.34, "the row stands as stepping stones, a step over the hall floor and no more (%.2f m)" % top_y)
	var plinths: Array = []
	var plinths_in_rect: int = 0
	for n in seg.find_children("ArtPlinth*", "", true, false):
		var pl2: Vector3 = seg.to_local((n as Node3D).global_position)
		var cx: int = int(floor(pl2.x)); var cz: int = int(floor(pl2.z)) - vest
		plinths.append([n.name, cx, cz, snappedf(pl2.y, 0.01)])
		if cx >= 1 and cx <= 6 and cz >= 2 and cz <= 7: plinths_in_rect += 1
	measurements["plinths"] = plinths
	check(plinths_in_rect == 0, "no dealt plinth stands in the cleared rect x 1..6, z 2..7 (%s)" % str(plinths))
	await create_timer(0.3).timeout
	var severed: Array = em.get("_seg_severed") if em.get("_seg_severed") != null else []
	measurements["museum_severed"] = severed
	var walk_sev: Array = em.get("_walk_severed") if em.get("_walk_severed") != null else []
	var mine_sev: Array = []
	for e in walk_sev:
		if str((e as Dictionary).get("hall", "")).contains(MAP): mine_sev.append(e)
	measurements["museum_walk_severed"] = mine_sev
	check(mine_sev.is_empty(), "the museum walks this hall door to door, and it does not use the stones to do it (severed: %s; seals: %s)" % [str(mine_sev), str(severed)])

	# ── 1. the crossing as the map stages it ─────────────────────────────────
	var cs: Dictionary = prim.call("crossing_state")
	measurements["crossing"] = cs
	note("crossing " + JSON.stringify(cs))
	var geo: Dictionary = cs["geometry"]
	check(int(geo["stone_count"]) == 3 and (cs["stones"] as Array).size() == 3, "three stones stand in the row, this tile the middle one (%s)" % str((cs["stones"] as Array).size()))
	var seeds: Array = []
	for s in cs["stones"]: seeds.append(int((s as Dictionary)["seed"]))
	check(seeds.size() == 3 and seeds[0] != seeds[1] and seeds[1] != seeds[2] and seeds[0] != seeds[2], "each stone draws its own waits from its own seed (%s)" % str(seeds))
	check(int(cs["seed"]) >= 10000 and int(cs["seed"]) <= 99999, "the crossing is named by a five-digit seed a visitor can read and repeat (%s)" % str(cs["seed"]))
	check(str(cs["cue"]) == "advance" and float(cs["advance_seconds"]) > 0.5, "the map asked for the advance cue and got it (%s, %.1f s)" % [str(cs["cue"]), float(cs["advance_seconds"])])
	check(abs(float(geo["drop"]) - 1.02) < 0.06, "the fall from the floor is one metre, not a disappearance (%.2f m)" % float(geo["drop"]))
	check(abs(float(geo["proud"]) - float(geo["sink"]) + float(geo["drop"]) + 0.02) < 0.06, "a sunken stone comes to rest on the bed: it is the floor you land on (proud %.2f, sink %.2f, drop %.2f)" % [float(geo["proud"]), float(geo["sink"]), float(geo["drop"])])
	check(abs(float(geo["gap"]) - 0.12) < 0.02, "the gaps between standing stones are a step, not a jump (%.2f m)" % float(geo["gap"]))
	check(abs(float(geo["pit_along"]) - 3.0) < 0.15 and abs(float(geo["pit_across"]) - 5.0) < 0.15, "the staging's pit is the map's own five by three (%s x %s)" % [str(geo["pit_across"]), str(geo["pit_along"])])
	var cross: Node3D = prim.get_node_or_null("Crossing")
	check(cross != null, "the staging stands under the tile as one node")
	if cross == null:
		_finish(); return
	var want_nodes := ["Bed", "BedCollider", "Side_west", "Side_east", "End_near", "End_far", "WayOut", "Threshold_near", "Threshold_far", "Stele", "Tablet", "Controls", "Idol", "Stone_0", "Stone_2"]
	var missing: Array = []
	for n in want_nodes:
		if cross.get_node_or_null(n) == null: missing.append(n)
	check(missing.is_empty(), "the crossing is built: bed, the way out, cut sides, stele, tablet, controls, idol, both sibling stones (missing %s)" % str(missing))
	check(cross.find_children("Kerb_*", "", false, false).size() == 4, "kerbs at both lips, broken for the row's width (%d)" % cross.find_children("Kerb_*", "", false, false).size())
	check(cross.find_children("Brazier_*", "", false, false).size() == 2, "a brazier at each end (%d)" % cross.find_children("Brazier_*", "", false, false).size())

	# ── 2. the gap has no unintended support, and the bed is under it ────────
	var space := prim.get_world_3d().direct_space_state
	var probes: Array = []
	var bed_hits: int = 0
	var floor_y: float = seg.global_position.y
	for spot in [Vector3(4.4, 0.0, 4.5), Vector3(2.0, 0.0, 3.6), Vector3(3.5, 0.0, 4.5)]:
		var from: Vector3 = seg.to_global(Vector3(spot.x, 0.25, spot.z + vest))
		var to: Vector3 = seg.to_global(Vector3(spot.x, -2.4, spot.z + vest))
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
		var nm: String = str((hit.collider as Node).name) if not hit.is_empty() and hit.collider is Node else "nothing"
		var depth: float = snappedf(floor_y - float(hit.position.y), 0.02) if not hit.is_empty() else -1.0
		probes.append({"at": [spot.x, spot.z], "hit": nm, "below_floor": depth})
		if nm.begins_with("BedCollider") or nm.begins_with("Collider"):
			bed_hits += 1
	# the eye's own line down the row: what a standing visitor sees where the bed should be
	var eye: Vector3 = seg.to_global(Vector3(3.62, 1.6, 2.05 + vest))
	var into: Vector3 = seg.to_global(Vector3(3.5, -0.9, 5.2 + vest))
	var look: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(eye, into))
	var look_name: String = str((look.collider as Node).name) if not look.is_empty() and look.collider is Node else "nothing"
	probes.append({"at": "standing eye down the row", "hit": look_name, "below_floor": snappedf(floor_y - float(look.position.y), 0.02) if not look.is_empty() else -1.0})
	check(look_name != "nothing", "a standing eye looking into the pit meets the crossing, not the museum's sky under the floor (%s)" % look_name)
	measurements["pit_rays"] = probes
	note("pit rays " + JSON.stringify(probes))
	check(bed_hits >= 2, "a ray down the pit finds the artifact's own bed — no museum tile is holding the gap up (%s)" % JSON.stringify(probes))
	for p in probes:
		if str((p as Dictionary)["hit"]) != "nothing" and float((p as Dictionary)["below_floor"]) > 0.2:
			check(abs(float((p as Dictionary)["below_floor"]) - 1.02) < 0.25, "what a fall lands on is one metre down (%s)" % JSON.stringify(p))
			break

	# ── 3. the ORDER is fixed; only the waits are drawn ──────────────────────
	var watch: Array = []
	var seen_steps: Array = []
	var draws := {"stands": [], "gone": []}
	var deadline_moved: int = 0
	var last: Dictionary = {}
	for i in range(88):                      # 22 seconds at 0.25 s
		var st: Dictionary = prim.call("step_state")
		watch.append({"t": snappedf(float(i) * 0.25, 0.01), "step": st["step"], "wait": st["wait"], "left": st["left"],
			"standing": st["standing"], "supports": st["supports"], "crown": st["crown"], "cycles": st["cycles"]})
		if i % 8 == 0:
			note("watch %5.1f s  %-6s drawn %4.1f  left %4.1f  supports %s  crown %s" % [float(i) * 0.25, str(st["step"]), float(st["wait"]), float(st["left"]), str(st["supports"]), str(st["crown"])])
		if str(st["step"]) != "" and (seen_steps.is_empty() or str(seen_steps[seen_steps.size() - 1]) != str(st["step"])):
			seen_steps.append(str(st["step"]))
			if draws.has(str(st["step"])):
				(draws[str(st["step"])] as Array).append(float(st["wait"]))
		elif not last.is_empty() and str(last["step"]) == str(st["step"]):
			# the deadline that one draw set must not move while that step runs
			if abs(float(last["wait"]) - float(st["wait"])) > 0.001 and float(last["left"]) > 0.3:
				deadline_moved += 1
		last = st
		await create_timer(0.25, true, false, true).timeout
	measurements["watch"] = watch
	measurements["draws"] = draws
	check(seen_steps.size() >= 4, "more than one full cycle was watched (%s)" % str(seen_steps))
	check(deadline_moved == 0, "the wait is drawn ONCE and its deadline stands still while the step runs (%d moves)" % deadline_moved)
	var band_ok := true
	var band_bad: Array = []
	for w in draws["stands"]:
		if float(w) < float((cs["stands_band"] as Array)[0]) - 0.05 or float(w) > float((cs["stands_band"] as Array)[1]) + 0.05:
			band_ok = false; band_bad.append(["stands", w])
	for w in draws["gone"]:
		if float(w) < float((cs["gone_band"] as Array)[0]) - 0.05 or float(w) > float((cs["gone_band"] as Array)[1]) + 0.05:
			band_ok = false; band_bad.append(["gone", w])
	check(band_ok, "every drawn wait lands in the band the crossing set: stands %s, gone %s (outside: %s)" % [str(cs["stands_band"]), str(cs["gone_band"]), str(band_bad)])
	var support_true_standing: int = 0
	var support_false_gone: int = 0
	var support_wrong: Array = []
	for w in watch:
		var e: Dictionary = w
		if bool(e["standing"]) and bool(e["supports"]): support_true_standing += 1
		if str(e["step"]) == "gone" and not bool(e["supports"]): support_false_gone += 1
		if bool(e["standing"]) and not bool(e["supports"]): support_wrong.append(e)
	check(support_true_standing > 0 and support_false_gone > 0 and support_wrong.is_empty(),
		"the collider follows the state: it holds while the stone stands and is gone while the stone is (%d standing, %d gone, %d wrong)" % [support_true_standing, support_false_gone, support_wrong.size()])
	var one_full: bool = int((watch[watch.size() - 1] as Dictionary)["cycles"]) >= 1
	check(one_full, "the tile completed at least one whole cycle under the crossing's timing (%s cycles)" % str((watch[watch.size() - 1] as Dictionary)["cycles"]))

	# ── 4. the cue: notice BEFORE the floor goes, against the shipped beacon ─
	var crown_moments: Array = []
	for w in watch:
		var e: Dictionary = w
		if bool(e["crown"]):
			crown_moments.append({"left": e["left"], "step": e["step"], "supports": e["supports"]})
	measurements["crown_moments"] = crown_moments
	var crown_ok: bool = not crown_moments.is_empty()
	for c in crown_moments:
		var e: Dictionary = c
		if str(e["step"]) != "stands" or not bool(e["supports"]) or float(e["left"]) > float(cs["advance_seconds"]) + 0.3:
			crown_ok = false
	check(crown_ok, "the advance cue lights while the stone STILL stands, inside its notice window (%d moments: %s)" % [crown_moments.size(), JSON.stringify(crown_moments.slice(0, 3))])
	var ind: Node3D = prim.get_node_or_null("StateIndicator")
	var beacon_while_standing: int = 0
	if ind != null:
		for i in range(24):
			var st2: Dictionary = prim.call("step_state")
			if bool(st2["standing"]) and (ind as MeshInstance3D).visible: beacon_while_standing += 1
			await create_timer(0.2, true, false, true).timeout
	check(beacon_while_standing == 0, "the shipped beacon says nothing while the stone stands — it lights as the floor leaves, which is the difference (%d)" % beacon_while_standing)

	# ── 5. REPLAY brings the same rhythm back; NEW SEED names another ────────
	var panel: Node = cross.get_node_or_null("Controls")
	check(panel != null, "the controls stand on the near lip where the planning happens")
	var seed_a: int = int(cs["seed"])
	check(_press(panel, "Btn_0"), "REPLAY pressed through the button's signal (one argument)")
	await create_timer(0.4, true, false, true).timeout
	var run_a: Array = _seeds_of(prim)
	check(_press(panel, "Btn_0"), "REPLAY pressed again")
	await create_timer(0.4, true, false, true).timeout
	var run_b: Array = _seeds_of(prim)
	measurements["replay"] = {"first": run_a, "second": run_b, "seed": seed_a}
	check(run_a == run_b and run_a.size() == 3, "REPLAY deals the same rhythm to the same stones: one number brings the whole crossing back (%s vs %s)" % [str(run_a), str(run_b)])
	check(int(prim.call("crossing_state")["seed"]) == seed_a, "REPLAY keeps the crossing's name (%s)" % str(seed_a))
	check(_press(panel, "Btn_1"), "NEW SEED pressed")
	await create_timer(0.4, true, false, true).timeout
	var cs2: Dictionary = prim.call("crossing_state")
	var run_c: Array = _seeds_of(prim)
	measurements["new_seed"] = {"was": seed_a, "now": int(cs2["seed"]), "stone_seeds": run_c}
	check(int(cs2["seed"]) != seed_a and int(cs2["seed"]) >= 10000, "NEW SEED names another crossing (%d → %d)" % [seed_a, int(cs2["seed"])])
	check(run_c != run_a, "and deals another rhythm with it (%s → %s)" % [str(run_a), str(run_c)])
	var cut: Label3D = cross.get_node_or_null("Idol/SeedCut/Text")
	check(cut != null and cut.text.contains(str(int(cs2["seed"]))), "the seed cut into the idol is the crossing you are standing in (%s)" % (cut.text.replace("\n", " / ") if cut != null else "-"))

	# ── 6. the two surfaces: the ORDER in stone, the DRAWN waits live ────────
	var stele: Node3D = cross.get_node_or_null("Stele")
	var carved: int = stele.get_children().size() if stele != null else 0
	measurements["stele_children"] = carved
	check(carved >= 6, "the order is cut in stone on the near lip: a head, four steps and a foot (%d pieces)" % carved)
	var tab: Label3D = cross.get_node_or_null("Tablet/Text")
	check(tab != null, "the live tablet stands at the lip")
	if tab != null:
		var lines: PackedStringArray = tab.text.split("\n")
		measurements["tablet"] = tab.text.split("\n")
		for l in lines: note("tablet | " + l)
		check(lines.size() >= 4, "one line per stone and a foot naming the seed and the cue (%d lines)" % lines.size())
		check(tab.text.contains("drawn") and tab.text.contains("left"), "each line says what was DRAWN and what is LEFT of it")
		check(tab.text.contains(str(int(cs2["seed"]))), "and the foot names the crossing (%s)" % lines[lines.size() - 1])
		check(tab.font_size >= 18 and tab.outline_size >= 3 and (tab.modulate.r + tab.modulate.g + tab.modulate.b) / 3.0 > 0.8, "the tablet reads from a standing eye: light, outlined, %d px" % tab.font_size)

	# ── 7. the bypass: the hall is crossable WITHOUT the stones ──────────────
	var md: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json" % MAP))
	var grid: Array = (md["layers"] as Dictionary)["structure"]
	var reach: Dictionary = _flood(grid, Vector2i(7, 1))
	var far_lip: bool = reach.has("3,6") or reach.has("2,6") or reach.has("4,6")
	var idol_side: bool = reach.has("3,7")
	var pit_cells: Array = []
	for z in range(PIT_Z0, PIT_Z1 + 1):
		for x in range(PIT_X0, PIT_X1 + 1):
			pit_cells.append(str(grid[z][x]))
	measurements["bypass"] = {"reached_cells": reach.size(), "far_lip_reached": far_lip, "pit_cells": pit_cells, "doorway": str(grid[2][6])}
	check(pit_cells.all(func(c): return str(c) == "0"), "the pit is still the hall's own void, floored by nothing (%s)" % str(pit_cells))
	check(str(grid[2][6]) == "1", "the wall stub carries a doorway at (6,2), so the near lip is not a trap (%s)" % str(grid[2][6]))
	check(far_lip and idol_side, "the far lip is reachable without crossing: the corridor east of the wall is the bypass (%d cells walkable from the north door)" % reach.size())

	# ── 8. captures, and the desktop rig in the live port ───────────────────
	if capture:
		await _when_standing(prim, 1.4)
		var lip_at: Vector3 = seg.to_global(Vector3(3.15, EYE_H, 1.85 + vest))
		var stones_at: Vector3 = seg.to_global(Vector3(3.5, 0.05, 5.4 + vest))
		# the standing view: the tablet at the near lip's west, the row, the far lip and
		# the idol in one frame, from an eye a stride north of the lip
		cam.fov = 78
		cam.global_position = lip_at
		cam.look_at(stones_at)
		for i in range(20): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(_evidence + "probe_game.png")
		measurements["captures"]["primary"] = _cam_pose(cam)
		cam.fov = 68
		# the approach, from the hall's north door
		cam.global_position = seg.to_global(Vector3(7.0, EYE_H, 1.2 + vest))
		cam.look_at(seg.to_global(Vector3(3.6, 0.5, 4.5 + vest)))
		for i in range(16): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(_evidence + "probe_game_approach.png")
		measurements["captures"]["approach"] = _cam_pose(cam)
		# the tablet and the stele from the reading eye
		var tnode: Node3D = cross.get_node_or_null("Tablet")
		if tnode != null:
			cam.global_position = tnode.global_position + seg.global_transform.basis * Vector3(0.0, 0.42, -0.72)
			cam.look_at(tnode.global_position)
			for i in range(16): cam.make_current(); await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_game_tablet.png")
			measurements["captures"]["tablet"] = _cam_pose(cam)
		# the row along the crossing, from the lip at knee height: the gaps and the bed
		cam.global_position = seg.to_global(Vector3(3.5, 0.55, 2.35 + vest))
		cam.look_at(seg.to_global(Vector3(3.5, -0.3, 6.2 + vest)))
		for i in range(16): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(_evidence + "probe_game_row.png")
		measurements["captures"]["row"] = _cam_pose(cam)
		# the carved order, from the eye that reads it
		var stele_node: Node3D = cross.get_node_or_null("Stele")
		if stele_node != null:
			cam.global_position = stele_node.global_position + stele_node.global_transform.basis * Vector3(0.0, 1.30, 1.15)
			cam.look_at(stele_node.global_position + Vector3(0, 0.78, 0))
			for i in range(16): cam.make_current(); await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_game_stele.png")
			measurements["captures"]["stele"] = _cam_pose(cam)
		# from the bed, looking up at what left you
		cam.global_position = seg.to_global(Vector3(2.1, -0.55, 4.5 + vest))
		cam.look_at(seg.to_global(Vector3(3.5, 0.4, 4.5 + vest)))
		for i in range(16): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(_evidence + "probe_game_bed.png")
		measurements["captures"]["bed"] = _cam_pose(cam)
		# the idol at the far lip, with its seed
		var idol: Node3D = cross.get_node_or_null("Idol")
		if idol != null:
			cam.global_position = idol.global_position + seg.global_transform.basis * Vector3(0.0, 1.05, -1.35)
			cam.look_at(idol.global_position + Vector3(0, 0.85, 0))
			for i in range(16): cam.make_current(); await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_game_idol.png")
			measurements["captures"]["idol"] = _cam_pose(cam)
		# the whole hall in plan, so the pit, the corridor and the arena read together
		cam.global_position = seg.to_global(Vector3(6.5, 15.0, 7.0 + vest))
		cam.look_at(seg.to_global(Vector3(6.4, 0.0, 7.2 + vest)))
		for i in range(16): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(_evidence + "probe_game_plan.png")
		measurements["captures"]["plan"] = _cam_pose(cam)

	if _live():
		var drv: Node = load("res://commons/testing/wcn_desktop_driver.gd").new()
		root.add_child(drv)
		var stand_at: Vector3 = seg.to_global(Vector3(3.5, 0.05, NEAR_LIP - 0.5 + vest))
		drv.call("spawn", stand_at, em)
		for i in range(20): await process_frame
		check(bool(drv.call("is_ready")), "the desktop rig stands on the near lip")
		var tablet_node: Node3D = cross.get_node_or_null("Tablet")
		drv.call("aim_at", tablet_node.global_position if tablet_node != null else seg.to_global(Vector3(3.5, 0.5, 4.5 + vest)))
		for i in range(6): await process_frame
		measurements["desktop_input"] = {"stand_pose": drv.call("pose")}
		# the three controls, pressed through the pointer
		var b0: Node = panel.find_child("Btn_0", true, false) if panel != null else null
		var b1: Node = panel.find_child("Btn_1", true, false) if panel != null else null
		var b2: Node = panel.find_child("Btn_2", true, false) if panel != null else null
		var seed_before: int = int(prim.call("crossing_state")["seed"])
		var rec1: Dictionary = await drv.call("press", b1, stand_at) if b1 != null else {}
		await create_timer(0.4, true, false, true).timeout
		var seed_after: int = int(prim.call("crossing_state")["seed"])
		measurements["desktop_input"]["press_new_seed"] = rec1
		check(seed_after != seed_before, "NEW SEED pressed through the pointer names another crossing (%d → %d)" % [seed_before, seed_after])
		var cue_before: float = float(prim.call("crossing_state")["advance_seconds"])
		var rec2: Dictionary = await drv.call("press", b2, stand_at) if b2 != null else {}
		await create_timer(0.4, true, false, true).timeout
		var cue_after: float = float(prim.call("crossing_state")["advance_seconds"])
		measurements["desktop_input"]["press_cue"] = rec2
		check(cue_after != cue_before, "CUE pressed through the pointer changes what the stones tell you (%.1f → %.1f s)" % [cue_before, cue_after])
		var rec2b: Dictionary = await drv.call("press", b2, stand_at) if b2 != null else {}
		await create_timer(0.3, true, false, true).timeout
		check(is_equal_approx(float(prim.call("crossing_state")["advance_seconds"]), cue_before), "and pressing it again gives the notice back")
		var rec0: Dictionary = await drv.call("press", b0, stand_at) if b0 != null else {}
		measurements["desktop_input"]["press_replay"] = rec0
		check(not rec0.is_empty(), "REPLAY pressed through the pointer")

		# THE CROSSING: walk south onto the row and report what the body got —
		# the far lip, or the bed. Either is evidence; falling through the world is not.
		drv.call("aim_at", seg.to_global(Vector3(3.5, 0.9, 7.0 + vest)))
		for i in range(6): await process_frame
		var legs: Array = []
		for step in range(7):
			var st3: Dictionary = prim.call("step_state")
			await drv.call("walk", "ui_up", 18)
			var p: Dictionary = drv.call("pose")
			var row_now: Array = []
			for s3 in (prim.call("crossing_state")["stones"] as Array):
				row_now.append("%s %.1f" % [str((s3 as Dictionary)["step"]), float((s3 as Dictionary)["left"])])
			legs.append({"leg": step, "row": row_now, "middle_stone": st3["step"], "left": st3["left"],
				"at": p["rig"], "seg_z": snappedf(seg.to_local(Vector3(float(p["rig"][0]), float(p["rig"][1]), float(p["rig"][2]))).z - float(vest), 0.02)})
		measurements["desktop_input"]["crossing"] = legs
		note("crossing legs " + JSON.stringify(legs))
		var end: Dictionary = legs[legs.size() - 1]
		var end_local: Vector3 = seg.to_local(Vector3(float((end["at"] as Array)[0]), float((end["at"] as Array)[1]), float((end["at"] as Array)[2])))
		var end_z: float = end_local.z - float(vest)
		var end_y: float = end_local.y
		measurements["desktop_input"]["crossing_end"] = {"z": snappedf(end_z, 0.02), "y": snappedf(end_y, 0.02)}
		check(end_y > -1.35, "the body that walked the row is either on the far side or on the bed — the pit has a floor (y %.2f, z %.2f)" % [end_y, end_z])
		var crossed: bool = end_z > 6.0
		var in_bed: bool = end_y < -0.6
		check(crossed or in_bed or end_z > 3.0, "the walk moved onto the crossing (z %.2f, y %.2f: %s)" % [end_z, end_y, ("the far lip" if crossed else ("the bed" if in_bed else "the row"))])
		if capture:
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_game_desktop_crossing.png")
			measurements["desktop_input"]["crossing_capture_pose"] = drv.call("pose")
		# THE FALL, on purpose: stand on the middle stone, wait for it to go, and read
		# what caught the body. A crossing that only sometimes drops you is not evidence.
		await _when_standing(prim, 2.0)
		drv.call("spawn", seg.to_global(Vector3(3.5, 0.12, 4.5 + vest)), em)
		await create_timer(0.45, true, false, true).timeout
		var stood: Dictionary = drv.call("pose")
		var stood_y: float = seg.to_local(Vector3(float((stood["rig"] as Array)[0]), float((stood["rig"] as Array)[1]), float((stood["rig"] as Array)[2]))).y
		var fell_at: float = 99.0
		for i in range(90):
			var sy: Dictionary = prim.call("step_state")
			var pp: Dictionary = drv.call("pose")
			var py: float = seg.to_local(Vector3(float((pp["rig"] as Array)[0]), float((pp["rig"] as Array)[1]), float((pp["rig"] as Array)[2]))).y
			if py < -0.55:
				fell_at = py
				break
			if i % 12 == 0: note("standing on the middle stone: %s, left %.1f, body y %.2f" % [str(sy["step"]), float(sy["left"]), py])
			await create_timer(0.12, true, false, true).timeout
		measurements["desktop_input"]["fall"] = {"stood_y": snappedf(stood_y, 0.02), "fell_to": snappedf(fell_at, 0.02)}
		check(stood_y > -0.3, "a body stands ON the middle stone while it stands (y %.2f)" % stood_y)
		check(fell_at < -0.55 and fell_at > -1.35, "when that stone leaves, the body falls one metre and the bed catches it (y %.2f)" % fell_at)
		if capture:
			await create_timer(0.2, true, false, true).timeout
			root.get_texture().get_image().save_png(_evidence + "probe_game_desktop_fallen.png")
			measurements["desktop_input"]["fall"]["capture_pose"] = drv.call("pose")
		# and out of the bed: to the ramp's foot, then up it
		var in_bed_now: bool = fell_at < -0.55
		if in_bed_now:
			# the ramp is at the pit's west third: to its foot first, then up it
			# the ramp's foot is at the pit's south-WEST (it climbs northward), so the
			# body crosses the bed to the foot first and only then turns up the slope
			drv.call("aim_at", seg.to_global(Vector3(1.85, -1.0, 5.65 + vest)))
			for i in range(6): await process_frame
			await drv.call("walk", "ui_up", 40)
			var foot: Dictionary = drv.call("pose")
			measurements["desktop_input"]["ramp_foot"] = foot["rig"]
			drv.call("aim_at", seg.to_global(Vector3(1.85, 0.15, 2.4 + vest)))
			for i in range(6): await process_frame
			await drv.call("walk", "ui_up", 40)
			await drv.call("walk", "ui_up", 40)
			var out_p: Dictionary = drv.call("pose")
			var out_local: Vector3 = seg.to_local(Vector3(float((out_p["rig"] as Array)[0]), float((out_p["rig"] as Array)[1]), float((out_p["rig"] as Array)[2])))
			measurements["desktop_input"]["way_out"] = {"at": out_p["rig"], "y": snappedf(out_local.y, 0.02)}
			check(out_local.y > -0.55, "the way out of the bed climbs, so a fall costs the walk back and nothing else (y %.2f → %.2f)" % [fell_at, out_local.y])
		drv.call("teardown")

	# ── 9. the hall rebuilt: the staging comes back with it ─────────────────
	em.call("flush_stamps")
	_finish()

## Wait until the tile stands with at least `margin` seconds of its drawn wait left, so a
## still is taken of a crossing and not of three sunken stones (the first live capture).
func _when_standing(prim: Node, margin: float) -> void:
	for i in range(80):
		var st: Dictionary = prim.call("step_state")
		if str(st["step"]) == "stands" and float(st["left"]) >= margin and bool(st["supports"]):
			return
		await create_timer(0.1, true, false, true).timeout

func _seeds_of(prim: Node) -> Array:
	var out: Array = []
	for s in (prim.call("crossing_state")["stones"] as Array):
		out.append(int((s as Dictionary)["seed"]))
	return out

## Flood fill the map's own structure from a cell, walking only height-1 floor —
## the claim that the far lip is reachable without a single stone.
func _flood(grid: Array, from: Vector2i) -> Dictionary:
	var seen: Dictionary = {}
	var queue: Array = [from]
	while not queue.is_empty():
		var c: Vector2i = queue.pop_front()
		var key: String = "%d,%d" % [c.x, c.y]
		if seen.has(key): continue
		if c.y < 0 or c.y >= grid.size(): continue
		var row: Array = grid[c.y]
		if c.x < 0 or c.x >= row.size(): continue
		if str(row[c.x]) != "1": continue
		seen[key] = true
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			queue.append(c + d)
	return seen

func _press(panel: Node, btn_name: String) -> bool:
	if panel == null: return false
	var btn: Node = panel.find_child(btn_name, true, false)
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
		"control_path": "REPLAY / NEW SEED / CUE through InteractableAreaButton.button_pressed (one argument); the live port presses all three through the desktop pointer and walks the row",
		"hand_file": "ada_run/necklace_hand.json (real)", "headset_verified": false,
		"engine": Engine.get_version_info().string, "physics_fps": Engine.physics_ticks_per_second}
	var f := FileAccess.open(OUT + "probe_game.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-game] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
