extends SceneTree
## Random_Mushrooms, batch R4 (doc/research/waves-chance-noise, 2026-09-12, Astra's thread from
## Random_Gaussian: a population of forms grown from draws): which parts of this population were
## allowed to vary?
##
## Stands up the ACTUAL museum hall with its artifacts, hands the museum the REAL necklace hand
## file, and tests the meadow as the map stages it (mushrooms:180#stand:specimen#size:6 at
## (6,7), placement authority with the map): the bed (its ground lifted clear of the deck, the
## kerb), the specimen table at the north edge (six type specimens, the housed readout, the
## SHOW · KIND · SIZE / REGROW · NEW SEED panel), the population's bookkeeping (candidates
## requested, accepted, rejected; rings and clusters requested and placed; templates; lit
## lights under the cap), REGROW as an exact replay (every instance's template, kind, position,
## yaw and scale; the ground's heights), NEW SEED as a different population, the seed set back
## as the first population again, SIZE off as the same population at scale 1, SHOW and KIND as
## the highlight's counts, the walk (the door to the visitor's spot, the west margin, the south
## margin to the door; the table and the bed stop a walker), the floor under the bed and the
## teleporter cell, the templates freed with the hall, and captures from the visitor's eye.
## The live port adds the desktop rig: REGROW, SHOW and NEW SEED pressed through the pointer,
## and the walk on ui_up.
##
##   godot --rendering-method gl_compatibility --path . --xr-mode off --script res://commons/testing/probe_wcn_mushrooms.gd -- --capture
##
## Writes res://ada_run/waves_chance_noise/Random_Mushrooms/probe_mushrooms.json
## (and probe_mushrooms*.png under --capture). Exit code 1 on any failed check.
var checks := 0
var failures: Array[String] = []
var measurements: Dictionary = {}
const MAP := "Random_Mushrooms"
const OUT := "res://ada_run/waves_chance_noise/Random_Mushrooms/"
const MAP_CELL := Vector2i(6, 7)
const SPOT := Vector3(6.5, 0.0, 2.3)      # the visitor's spot: 0.8 m before the table's face
const EYE_H := 1.6
const BED := 6.0

func _initialize() -> void: run.call_deferred()

func _live() -> bool:
	return str(get_script().resource_path).ends_with("_live.gd")

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message)
	print("[wcn-mush] ", "PASS " if ok else "FAIL ", message)

func note(message: String) -> void:
	print("[wcn-mush] note: ", message)

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
		cam = Camera3D.new(); em.add_child(cam); cam.fov = 62
	measurements["captures"] = {}

	# ── 0. the hall: tile, bodies, plinths, the walk ────────────────────────
	var tile: Array = seg.get_meta("em_tile", [])
	var tile_rows: Array = []
	for row in tile:
		var line := ""
		for c in row: line += str(c)
		tile_rows.append(line)
	measurements["tile"] = tile_rows
	for r in range(tile_rows.size()): note("tile %2d %s" % [r, tile_rows[r]])
	check(tile_rows.size() > 12 and tile_rows[12].length() > 8 and tile_rows[12][8] == "1", "row 12 col 8, the teleporter's void cell, is FLOOR in the museum's tile (museum.floor_cells)")
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
		if sp == "mushrooms.gd": prim = node
	measurements["bodies"] = bodies
	for b in bodies:
		if not str(b["token"]).begins_with("lobby") and str(b["token"]) != "showing": note("body %-36s %-28s cell %-8s at %s scale %s" % [str(b["token"]), str(b["script"]), str(b["cell"]), str(b["at"]), str(b["scale"])])
	check(prim != null, "mushrooms is built in the hall")
	if prim == null:
		_finish(); return
	var me: Dictionary = by_token.get("mushrooms", {})
	check(me.get("cell", []) == [MAP_CELL.x, MAP_CELL.y] and abs(float(me["at"][0]) - 6.5) < 0.05 and abs(float(me["at"][2]) - 7.5) < 0.05, "the meadow stands at its map cell (6,7), not slid by the dealt lane (%s)" % str(me.get("at")))
	check(is_equal_approx(float(me.get("scale", 0.0)), 1.0), "the meadow stands at scale 1 (the map's size, not the lane's shrink; %s)" % str(me.get("scale")))
	for expect in [["dark_sphere", 10, 2], ["bubbles_random", 10, 4], ["random_number_book_page_collection", 10, 7], ["bubble_particles", 10, 9], ["reaction_diffusion_intro", 9, 11]]:
		var e: Dictionary = by_token.get(expect[0], {})
		check(not e.is_empty() and e.get("cell", []) == [expect[1], expect[2]], "%s stands at its map cell (%d,%d) (%s)" % [expect[0], expect[1], expect[2], str(e.get("cell"))])
	var plinths: Array = []
	var plinths_in_rect: int = 0
	for n in seg.find_children("ArtPlinth*", "", true, false):
		var pl2: Vector3 = seg.to_local((n as Node3D).global_position)
		var cx: int = int(floor(pl2.x)); var cz: int = int(floor(pl2.z)) - vest
		plinths.append([n.name, cx, cz, snappedf(pl2.y, 0.01)])
		if cx >= 3 and cx <= 9 and cz >= 1 and cz <= 11: plinths_in_rect += 1
	measurements["plinths"] = plinths
	check(plinths_in_rect == 0, "no dealt plinth stands in the cleared rect x 3..9, z 1..11 (%s)" % str(plinths))
	await create_timer(0.3).timeout
	var severed: Array = em.get("_seg_severed") if em.get("_seg_severed") != null else []
	measurements["museum_severed"] = severed
	var walk_sev: Array = em.get("_walk_severed") if em.get("_walk_severed") != null else []
	var mine_sev: Array = []
	for e in walk_sev:
		if str((e as Dictionary).get("hall", "")).contains(MAP): mine_sev.append(e)
	measurements["museum_walk_severed"] = mine_sev
	check(mine_sev.is_empty(), "the museum walks this hall door to door (severed: %s; seals: %s)" % [str(mine_sev), str(severed)])

	# ── 1. the meadow as the map stages it ───────────────────────────────────
	var st: Dictionary = prim.call("get_specimen_state")
	measurements["state0"] = _brief(st)
	note("state %s" % str(measurements["state0"]))
	check(str(prim.get("stand")) == "specimen", "the map's #stand:specimen reached the meadow (stand = %s)" % str(prim.get("stand")))
	check(is_equal_approx(float(prim.get("meadow_size")), BED), "the map's #size:6 reached the meadow (meadow_size = %s)" % str(prim.get("meadow_size")))
	var seed0: int = int(st["seed"])
	check(seed0 >= 10000 and seed0 <= 99999, "the stand named a five-digit population seed (%d)" % seed0)
	check(is_equal_approx(float(st["bed_lift"]), float(prim.get("ground_random_amplitude"))), "the bed is lifted by the ground's amplitude (%s)" % str(st["bed_lift"]))
	check(int(st["max_glow_lights"]) == 12, "the stand caps the glow lights at 12 (%s)" % str(st["max_glow_lights"]))
	var table: Node3D = prim.get_node_or_null("SpecimenTable")
	check(table != null, "the specimen table stands")
	if table == null:
		_finish(); return
	var meadow_l: Vector3 = seg.to_local(prim.global_position)
	var tl: Vector3 = seg.to_local(table.global_position)
	measurements["table_local"] = [snappedf(tl.x, 0.01), snappedf(tl.y, 0.01), snappedf(tl.z - vest, 0.01)]
	check(tl.z < meadow_l.z - (BED * 0.5 + 0.5) and abs(tl.x - meadow_l.x) < 0.05, "the table stands at the bed's NORTH edge, toward the door (table z %.2f, meadow z %.2f)" % [tl.z - vest, meadow_l.z - vest])
	var readout: Label3D = table.get_node_or_null("Readout/Text")
	check(readout != null, "the housed readout exists")
	var lines: Array = st["lines"]
	measurements["readout_lines"] = lines
	for l in lines: note("readout | " + str(l))
	var longest: int = 0
	for l in lines: longest = maxi(longest, str(l).length())
	check(lines.size() == 6 and longest <= 46, "the readout has six lines of at most 46 characters (longest %d)" % longest)
	if readout != null:
		check(readout.text == "\n".join(PackedStringArray(lines)), "the plate shows the readout's lines")
	var specimens: int = 0
	for c in table.get_node("Specimens").get_children():
		if str(c.name).begins_with("Specimen_"): specimens += 1
	check(specimens == 6, "six type specimens stand on the table (%d)" % specimens)
	# the visual pass of 12 September: the shown specimen's disc wears the highlight's colour
	var dring: MeshInstance3D = table.get_node_or_null("Specimens/DiscRing")
	check(dring != null and dring.visible and abs(dring.position.x - (-0.55)) < 0.01, "a ring on disc 0 marks the shown template on the table (x %.2f)" % (dring.position.x if dring != null else 99.0))
	var tag0: Label3D = table.get_node_or_null("Specimens/Tag_0")
	check(tag0 != null and tag0.font_size >= 20, "the disc numbers are readable from standing (font %d)" % (tag0.font_size if tag0 != null else -1))
	var kerb: Node = prim.get_node_or_null("Kerb")
	check(kerb != null and kerb.get_child_count() == 4, "the bed has its four kerb boards")
	var panel: Node = table.get_node_or_null("Panel")
	check(panel != null, "the SHOW · KIND · SIZE / REGROW · NEW SEED panel exists")
	if panel == null:
		_finish(); return
	var wired: int = 0
	for i in range(5):
		var btn: Node = panel.find_child("Btn_%d" % i, true, false)
		var area: Node = btn.get_node_or_null("InteractableAreaButton") if btn != null else null
		if area != null and area.get_signal_connection_list("button_pressed").size() >= 1: wired += 1
	check(wired == 5, "all five buttons are wired to the meadow (%d)" % wired)
	# the ground collider: lifted clear of the deck, inside the bed's square
	var ground: Node3D = prim.get("ground")
	var gcol: CollisionShape3D = ground.find_child("GroundCollision", true, false) if ground != null else null
	var gaabb: Array = []
	if gcol != null and gcol.shape is ConcavePolygonShape3D:
		var faces: PackedVector3Array = (gcol.shape as ConcavePolygonShape3D).get_faces()
		var gmin := Vector3(1e9, 1e9, 1e9)
		var gmax := Vector3(-1e9, -1e9, -1e9)
		for v in faces:
			var gv: Vector3 = seg.to_local(gcol.global_transform * v)
			gmin = gmin.min(gv); gmax = gmax.max(gv)
		gaabb = [[snappedf(gmin.x, 0.01), snappedf(gmin.y, 0.001), snappedf(gmin.z - vest, 0.01)], [snappedf(gmax.x, 0.01), snappedf(gmax.y, 0.001), snappedf(gmax.z - vest, 0.01)], faces.size() / 3]
	measurements["ground_collider"] = gaabb
	note("ground collider %s" % str(gaabb))
	check(gaabb.size() == 3 and float(gaabb[0][1]) >= -0.005 and float(gaabb[1][1]) <= 0.40, "the bed's ground stands on or above the deck and under 0.40 m (%s)" % str(gaabb))
	check(gaabb.size() == 3 and abs(float(gaabb[0][0]) - 3.5) < 0.05 and abs(float(gaabb[1][0]) - 9.5) < 0.05 and abs(float(gaabb[0][2]) - 4.5) < 0.05 and abs(float(gaabb[1][2]) - 10.5) < 0.05, "the bed spans x 3.5..9.5, z 4.5..10.5 (%s)" % str(gaabb))
	# lights and bodies, bounded
	var lit: int = 0
	var glow_lights: int = 0
	var field: Node = prim.get_node_or_null("MushroomField")
	if field != null:
		for l in field.find_children("GlowLight", "OmniLight3D", true, false):
			glow_lights += 1
			if (l as OmniLight3D).visible: lit += 1
	var meshes: int = prim.find_children("*", "MeshInstance3D", true, false).size()
	var mms: int = prim.find_children("*", "MultiMeshInstance3D", true, false).size()
	measurements["meadow"] = {"mushrooms": (prim.get("mushrooms") as Array).size(), "templates": int(st["templates"]), "glow_lights_in_field": glow_lights, "lit": lit, "mesh_instances": meshes, "multimeshes": mms}
	note("meadow %s" % str(measurements["meadow"]))
	check(lit == int(st["lit_lights"]) and lit <= 12, "the lit lights in the bed match the readout and stay under the cap (%d lit of %d glowing)" % [lit, glow_lights])
	check(glow_lights == int(st["glow_instances"]), "the glowing instances are counted (%d)" % glow_lights)

	# ── 2. the population's bookkeeping ──────────────────────────────────────
	var inst0: Array = st["instances"]
	var kinds := _kinds(inst0)
	var accepted: int = int(kinds["scattered"])
	measurements["kinds0"] = kinds
	check(int(st["candidates"]) == 80, "eighty candidates were requested (count 100 × density 0.8; %d)" % int(st["candidates"]))
	check(accepted + int(st["rejected"]) == 80, "accepted + rejected = the candidates (%d + %d)" % [accepted, int(st["rejected"])])
	check(int(kinds["scattered"]) + int(kinds["ring"]) + int(kinds["cluster"]) == inst0.size() and inst0.size() == (prim.get("mushrooms") as Array).size(), "every instance is scattered, ring or cluster (%s)" % str(kinds))
	var rings: Array = st["rings"]
	var ring_ok: bool = rings.size() == int(BED / 5)
	for rr in rings:
		if int(rr["placed"]) > int(rr["requested"]) or int(rr["requested"]) != int(float(rr["radius"]) * 8): ring_ok = false
	check(ring_ok, "int(size / 5) = %d fairy ring(s), each int(radius × 8) requested and no more placed (%s)" % [int(BED / 5), str(rings)])
	var clusters: Array = st["clusters"]
	var cl_ok: bool = clusters.size() == int(BED / 3)
	var ring_members: int = 0
	var cluster_members: int = 0
	for rr in rings: ring_members += int(rr["placed"])
	for cc in clusters:
		cluster_members += int(cc["placed"])
		if int(cc["placed"]) > int(cc["requested"]) or int(cc["requested"]) < 5 or int(cc["requested"]) > 14: cl_ok = false
	check(cl_ok, "int(size / 3) = %d clusters, 5..14 requested each and no more placed (%s)" % [int(BED / 3), str(clusters)])
	check(ring_members == int(kinds["ring"]) and cluster_members == int(kinds["cluster"]), "the rings' and clusters' placed counts match the instances (%d/%d, %d/%d)" % [ring_members, int(kinds["ring"]), cluster_members, int(kinds["cluster"])])
	check(int(st["templates"]) == 6, "six templates (five kinds and the glowing one; %d)" % int(st["templates"]))
	check(str(lines[1]) == "candidates 80 · accepted %d · rejected %d" % [accepted, int(st["rejected"])], "the readout's second line states the candidates, the accepted and the rejected")
	var tmpl_counts: Array = []
	for t in range(6):
		var c: int = 0
		for i in inst0: if int(i["template"]) == t: c += 1
		tmpl_counts.append(c)
	measurements["template_counts0"] = tmpl_counts
	var ground0: Dictionary = st["ground"]
	check(int(ground0["cells"]) > 100 and float(ground0["min"]) >= -0.181 and float(ground0["max"]) <= 0.181, "the ground's heights lie within ±amplitude (%s)" % str(ground0))

	# ── 3. REGROW replays, NEW SEED differs, the seed set back replays ────────
	check(_press(panel, "Btn_3"), "REGROW pressed through the button's signal (one argument)")
	await process_frame; await process_frame
	var st1: Dictionary = prim.call("get_specimen_state")
	var same1: Dictionary = _same(inst0, st1["instances"], true)
	measurements["regrow"] = {"seed_after": int(st1["seed"]), "same": same1, "ground_same": int(st1["ground"]["hash"]) == int(ground0["hash"])}
	check(int(st1["seed"]) == seed0, "REGROW keeps the seed (%d)" % int(st1["seed"]))
	check(bool(same1["same"]), "REGROW grows the SAME population: every instance's template, kind, position, yaw and scale (%s)" % str(same1))
	check(int(st1["ground"]["hash"]) == int(ground0["hash"]), "REGROW makes the same ground (hash %d)" % int(ground0["hash"]))
	check(_press(panel, "Btn_4"), "NEW SEED pressed")
	await process_frame; await process_frame
	var st2: Dictionary = prim.call("get_specimen_state")
	var same2: Dictionary = _same(inst0, st2["instances"], true)
	measurements["new_seed"] = {"seed_after": int(st2["seed"]), "same": same2, "ground_same": int(st2["ground"]["hash"]) == int(ground0["hash"]), "kinds": _kinds(st2["instances"])}
	check(int(st2["seed"]) != seed0 and int(st2["seed"]) >= 10000, "NEW SEED names another seed (%d → %d)" % [seed0, int(st2["seed"])])
	check(not bool(same2["same"]), "NEW SEED grows a DIFFERENT population (%s)" % str(same2.get("first_diff", "")))
	check(int(st2["ground"]["hash"]) != int(ground0["hash"]), "NEW SEED makes a different ground")
	prim.call("set_population_seed", seed0)
	await process_frame; await process_frame
	var st3: Dictionary = prim.call("get_specimen_state")
	var same3: Dictionary = _same(inst0, st3["instances"], true)
	measurements["seed_back"] = {"same": same3, "ground_same": int(st3["ground"]["hash"]) == int(ground0["hash"])}
	check(bool(same3["same"]) and int(st3["ground"]["hash"]) == int(ground0["hash"]), "the first seed set back grows the first population again, ground and all (%s)" % str(same3))

	# ── 4. SIZE: the rule off, the rest of the population unchanged ──────────
	check(_press(panel, "Btn_2"), "SIZE pressed")
	await process_frame; await process_frame
	var st4: Dictionary = prim.call("get_specimen_state")
	var same4: Dictionary = _same(inst0, st4["instances"], false)
	var all_one: bool = not (st4["instances"] as Array).is_empty()
	for i in st4["instances"]:
		if not is_equal_approx(float(i["scale"]), 1.0): all_one = false
	measurements["size_off"] = {"size_variation": st4["size_variation"], "same_but_scale": same4, "all_scale_one": all_one, "line": st4["lines"][4]}
	check(not bool(st4["size_variation"]) and all_one, "SIZE off stands every mushroom at scale 1")
	check(bool(same4["same"]), "SIZE off keeps every template, kind, position and yaw — the draws are still made (%s)" % str(same4))
	check(str(st4["lines"][4]) == "SIZE off · every mushroom at 1 · same seed", "the readout says SIZE off (%s)" % str(st4["lines"][4]))
	check(_press(panel, "Btn_2"), "SIZE pressed again")
	await process_frame; await process_frame
	var st5: Dictionary = prim.call("get_specimen_state")
	var same5: Dictionary = _same(inst0, st5["instances"], true)
	check(bool(st5["size_variation"]) and bool(same5["same"]), "SIZE on again restores the first population's sizes (%s)" % str(same5))

	# ── 5. SHOW and KIND: the highlight's counts ─────────────────────────────
	check(str(st5["kind"]) == "template" and int(st5["show_template"]) == 0 and int(st5["highlighted"]) == int(tmpl_counts[0]), "at rest the highlight rings every instance of template 0 (%d of %s)" % [int(st5["highlighted"]), str(tmpl_counts)])
	check(_press(panel, "Btn_0"), "SHOW pressed")
	await process_frame
	var st6: Dictionary = prim.call("get_specimen_state")
	check(int(st6["show_template"]) == 1 and int(st6["highlighted"]) == int(tmpl_counts[1]), "SHOW moves to template 1 and rings its %d instances (%d)" % [int(tmpl_counts[1]), int(st6["highlighted"])])
	var dring1: MeshInstance3D = table.get_node_or_null("Specimens/DiscRing")
	check(dring1 != null and abs(dring1.position.x - (-0.33)) < 0.01, "…and the disc ring moves to disc 1 (x %.2f)" % (dring1.position.x if dring1 != null else 99.0))
	check(str(st6["lines"][3]) == "SHOW template 1 · %d instances ringed" % int(tmpl_counts[1]), "the readout names the shown template and its count (%s)" % str(st6["lines"][3]))
	var kind_seq: Array = []
	var kind_ok: bool = true
	var expect_counts := {"scattered": accepted, "rings": ring_members, "clusters": cluster_members, "rejected": 80 - accepted, "template": int(tmpl_counts[1])}
	for step in ["scattered", "rings", "clusters", "rejected", "template"]:
		_press(panel, "Btn_1")
		await process_frame
		var sk: Dictionary = prim.call("get_specimen_state")
		kind_seq.append([sk["kind"], int(sk["highlighted"])])
		if str(sk["kind"]) != step or int(sk["highlighted"]) != int(expect_counts[step]): kind_ok = false
	measurements["kind_cycle"] = kind_seq
	check(kind_ok, "KIND cycles scattered · rings · clusters · rejected · template with the highlight counting each (%s)" % str(kind_seq))
	# the rejected candidates, marked in the bed for a capture
	_press(panel, "Btn_1"); _press(panel, "Btn_1"); _press(panel, "Btn_1"); _press(panel, "Btn_1")
	await process_frame
	var hl: MultiMeshInstance3D = prim.get_node_or_null("Highlight")
	var pins: MultiMeshInstance3D = prim.get_node_or_null("Pins")
	var hl_in_bed: bool = hl != null and hl.multimesh.instance_count == 80 - accepted and pins != null and pins.multimesh.instance_count == 80 - accepted
	if hl != null:
		for i in range(hl.multimesh.instance_count):
			var p: Vector3 = seg.to_local(hl.to_global(hl.multimesh.get_instance_transform(i).origin))
			if p.x < 3.4 or p.x > 9.6 or p.z - vest < 4.4 or p.z - vest > 10.6 or p.y < -0.01 or p.y > 0.45: hl_in_bed = false
	check(hl_in_bed, "the rejected candidates are marked inside the bed, on the lifted ground, a ring and a pin each (%d marks)" % (hl.multimesh.instance_count if hl != null else -1))
	if capture:
		cam.global_position = seg.to_global(Vector3(6.5, 2.4, 2.2 + vest)); cam.look_at(seg.to_global(Vector3(6.5, 0.3, 7.5 + vest)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_mushrooms_rejected.png")
		measurements["captures"]["rejected"] = _cam_pose(cam)
	_press(panel, "Btn_1")   # back to the template
	await process_frame

	# ── 5b. the edible ones (Palle, 12 September: "add the eatable mushroom to the mushroom landscape") ──
	await create_timer(1.0).timeout   # the pickables settle onto the bed's ground
	var est: Dictionary = prim.call("edibles_state")
	measurements["edibles"] = est
	check(int(est["planted"]) == 3 and int(est["present"]) == 3, "three edible mushrooms are planted in the bed under #edible:some (%s)" % str({"planted": est["planted"], "present": est["present"]}))
	var ed_ok: bool = int(est["present"]) == 3
	var ed_local: Array = []
	for e in prim.get("_edibles"):
		if not is_instance_valid(e): continue
		var gl: Vector3 = seg.to_local((e as Node3D).global_position)
		var lx: float = gl.x; var lz: float = gl.z - vest
		ed_local.append([snappedf(lx, 0.01), snappedf(gl.y, 0.01), snappedf(lz, 0.01)])
		var near_west: bool = lx >= 3.5 and lx <= 3.95
		var near_south: bool = lz >= 10.05 and lz <= 10.5
		var inside: bool = lx >= 3.5 and lx <= 9.5 and lz >= 4.5 and lz <= 10.5
		if not (inside and (near_west or near_south)): ed_ok = false
		if gl.y < -0.02 or gl.y > 0.55: ed_ok = false
		var sp2: String = str((e as Node).get_script().resource_path) if (e as Node).get_script() != null else ""
		if not sp2.ends_with("edible_mushroom.gd") or not (e as Node).is_in_group("edible"): ed_ok = false
	measurements["edibles_local"] = ed_local
	check(ed_ok, "each stands inside the bed within a third of a metre of the west or south kerb, on the lifted ground, and is the project's EdibleMushroom (%s)" % str(ed_local))
	var st_e: Dictionary = prim.call("get_specimen_state")
	check(str((st_e["lines"] as Array)[5]).ends_with("· edible 3"), "the plate's last line counts the edible ones (%s)" % str((st_e["lines"] as Array)[5]))
	var planted_before: Array = (est["planted_at"] as Array).duplicate(true)
	_press(panel, "Btn_3")   # REGROW
	await process_frame; await process_frame
	var est2: Dictionary = prim.call("edibles_state")
	check(int(est2["present"]) == 3 and str(est2["planted_at"]) == str(planted_before), "REGROW plants the edible ones again at the same places (%s)" % str(est2["planted_at"]))
	_press(panel, "Btn_4")   # NEW SEED
	await process_frame; await process_frame
	var est3: Dictionary = prim.call("edibles_state")
	check(int(est3["present"]) == 3 and str(est3["planted_at"]) != str(planted_before), "NEW SEED plants them elsewhere (%s)" % str(est3["planted_at"]))
	prim.call("set_population_seed", seed0)
	await process_frame; await process_frame
	await create_timer(1.0).timeout

	# ── 6. the floor and the walk ─────────────────────────────────────────────
	var pspace := seg.get_world_3d().direct_space_state
	for spot in [[6.5, 7.5, "the bed centre", "GroundCollision"], [5.0, 6.0, "the bed north-west", "GroundCollision"], [SPOT.x, SPOT.z, "the visitors spot", "Collision"], [6.5, 3.35, "the table", "Collider"], [8.5, 12.5, "the teleporter cell", "Collision"], [2.0, 7.5, "the west margin", "Collision"], [6.5, 11.4, "the south margin", "Collision"]]:
		var from: Vector3 = seg.to_global(Vector3(spot[0], 4.0, spot[1] + vest))
		var to: Vector3 = seg.to_global(Vector3(spot[0], -3.0, spot[1] + vest))
		var rq := PhysicsRayQueryParameters3D.create(from, to)
		var hit: Dictionary = pspace.intersect_ray(rq)
		var key: String = "floor_" + str(spot[2]).replace(" ", "_")
		var y: float = seg.to_local(hit["position"]).y if not hit.is_empty() else -99.0
		var who: String = str((hit.get("collider") as Node).get_path()).right(48) if not hit.is_empty() else "nothing"
		measurements[key] = [snappedf(y, 0.001), who]
		note("floor at %s: %s" % [spot[2], str(measurements[key])])
		if str(spot[3]) == "GroundCollision":
			check(who.contains("Ground"), "under %s the bed's own ground carries (hit %s at %.3f)" % [spot[2], who, y])
			check(y >= -0.005 and y <= 0.40, "the bed's ground at %s stands above the deck (%.3f)" % [spot[2], y])
		elif str(spot[3]) == "Collider":
			check(y > 0.85 and y < 0.95, "the table's collider tops at 0.90 (%.3f)" % y)
		else:
			check(abs(y) < 0.01 and not who.contains("Ground"), "the deck carries at %s (%.3f, %s)" % [spot[2], y, who])
	var capsule := CapsuleShape3D.new(); capsule.radius = 0.22; capsule.height = 1.6
	var wq := PhysicsShapeQueryParameters3D.new(); wq.shape = capsule
	var routes := [["from the north door to the visitors spot", Vector3(6.5, 0.81, 0.6), Vector3(0, 0, SPOT.z - 0.6), 1.0, "full"],
		["from the visitors spot into the table", Vector3(SPOT.x, 0.81, SPOT.z), Vector3(0, 0, 1.5), 0.6, "stopped"],
		["south down the west margin", Vector3(2.0, 0.81, 1.5), Vector3(0, 0, 9.8), 1.0, "full"],
		["east along the south margin to the door", Vector3(2.0, 0.81, 11.4), Vector3(4.5, 0, 0), 1.0, "full"],
		["east into the bed from the west margin", Vector3(2.0, 0.81, 7.5), Vector3(3.0, 0, 0), 0.7, "stopped"]]
	for route in routes:
		wq.transform = Transform3D(Basis.IDENTITY, seg.to_global(Vector3(route[1].x, route[1].y, route[1].z + vest)))
		wq.motion = route[2]
		var frac: float = pspace.cast_motion(wq)[0]
		var key: String = "walk_" + str(route[0]).replace(" ", "_")
		measurements[key] = snappedf(frac, 0.001)
		note("walk %s: %.3f" % [route[0], frac])
		if str(route[4]) == "full":
			check(frac >= 0.99, "a walker passes %s (%.2f)" % [route[0], frac])
		else:
			check(frac < float(route[3]), "a walker is stopped %s (%.2f of the way)" % [route[0], frac])

	# ── 7. the desktop rig (live lane only) ──────────────────────────────────
	if _live():
		var drv: Node = load("res://commons/testing/wcn_desktop_driver.gd").new()
		root.add_child(drv)   # a SceneTree has no add_child; the port maps root. to get_tree().root.
		var stand: Vector3 = seg.to_global(Vector3(SPOT.x, 0.0, SPOT.z + vest))
		drv.call("spawn", stand, em)
		await create_timer(0.5).timeout
		var snap: Array = (prim.call("get_specimen_state") as Dictionary)["instances"]
		var seed_b: int = int(prim.get("population_seed"))
		var b3: Node3D = panel.find_child("Btn_3", true, false)
		var rec3: Dictionary = await drv.call("press", b3, stand) if b3 != null else {}
		await process_frame; await process_frame
		var after3: Dictionary = prim.call("get_specimen_state")
		measurements["desktop_input"] = {"press_regrow": rec3, "regrow_same": _same(snap, after3["instances"], true)}
		check(str(rec3.get("hover", "")).contains("Btn_3") or str(rec3.get("hover", "")).contains("InteractableAreaButton"), "the desktop pointer had REGROW under the crosshair (%s)" % str(rec3.get("hover", "")))
		check(bool((measurements["desktop_input"]["regrow_same"] as Dictionary)["same"]) and int(after3["seed"]) == seed_b, "REGROW pressed through the pointer grows the same population again")
		var b0: Node3D = panel.find_child("Btn_0", true, false)
		var show_b: int = int(after3["show_template"])
		var rec0: Dictionary = await drv.call("press", b0, stand) if b0 != null else {}
		await process_frame; await process_frame
		var after0: Dictionary = prim.call("get_specimen_state")
		measurements["desktop_input"]["press_show"] = rec0
		check(int(after0["show_template"]) == (show_b + 1) % 6, "SHOW pressed through the pointer moves to the next template (%d → %d)" % [show_b, int(after0["show_template"])])
		var b4: Node3D = panel.find_child("Btn_4", true, false)
		var rec4: Dictionary = await drv.call("press", b4, stand) if b4 != null else {}
		await process_frame; await process_frame
		var after4: Dictionary = prim.call("get_specimen_state")
		measurements["desktop_input"]["press_new_seed"] = rec4
		measurements["desktop_input"]["seed_before"] = seed_b
		measurements["desktop_input"]["seed_after"] = int(after4["seed"])
		check(int(after4["seed"]) != seed_b, "NEW SEED pressed through the pointer names another seed (%d → %d)" % [seed_b, int(after4["seed"])])
		if capture:
			drv.call("aim_at", table.to_global(Vector3(0.0, 0.85, 0.3)))
			for i in range(12): await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(OUT + "probe_mushrooms_desktop_front.png")
			measurements["desktop_input"]["front_capture_pose"] = drv.call("pose")
		# the edible one at the west kerb: the rig stands on the west margin beside it, grabs
		# it with the pointer's carry (right button), and it is eaten when it comes within the
		# artifact's own eat_distance of the camera — if the pointer holds it farther than that,
		# the eat is called as the desktop stand-in for bringing it to the face, and said so
		var ed_target: Node3D = null
		for e in prim.get("_edibles"):
			if is_instance_valid(e) and seg.to_local((e as Node3D).global_position).x < 4.0: ed_target = e; break
		measurements["desktop_input"]["edible"] = {}
		if ed_target != null:
			var el: Vector3 = seg.to_local(ed_target.global_position)
			drv.get("rig").global_position = seg.to_global(Vector3(2.7, 0.05, el.z))
			await physics_frame
			drv.call("aim_at", ed_target.global_position)
			var seen_e: Node = await drv.call("hover_target")
			var hov: String = str(seen_e.get_path()).right(50) if seen_e != null else "nothing"
			# the pointer's own grab ray (GRAB_MASK: layer 3, the pickable layer this mushroom is on),
			# aimed at the cap rather than the base
			drv.call("aim_at", ed_target.global_position + Vector3(0.0, 0.12, 0.0))
			await process_frame
			var ptr: Node = drv.get("pointer")
			var found: Node = ptr.call("_find_grabbable") if ptr != null and ptr.has_method("_find_grabbable") else null
			await drv.call("press_down", MOUSE_BUTTON_RIGHT)
			for i in range(8): await process_frame
			# the desktop pointer carries by freezing and moving the body (_grab_held), without
			# XR Tools' pick_up: the pointer's own _held is the truth
			var held: bool = (ptr != null and ptr.get("_held") == ed_target) or (ed_target.has_method("is_picked_up") and bool(ed_target.call("is_picked_up")))
			var cam_d: float = ed_target.global_position.distance_to((drv.get("cam") as Camera3D).global_position) if drv.get("cam") != null else -1.0
			measurements["desktop_input"]["edible"] = {"hover": hov, "grab_ray_found": str(found.get_path()).right(40) if found != null else "nothing", "held": held, "distance_to_camera_when_held": snappedf(cam_d, 0.01)}
			check(found == ed_target, "the desktop pointer's grab ray finds the edible mushroom under the crosshair (%s)" % measurements["desktop_input"]["edible"]["grab_ray_found"])
			check(held, "…and the right button carries it (held %s)" % str(held))
			var eaten_by_rule: bool = false
			if held:
				for i in range(20):
					await process_frame
					if bool(ed_target.get("_is_eaten")): eaten_by_rule = true; break
			if not eaten_by_rule and is_instance_valid(ed_target) and not bool(ed_target.get("_is_eaten")):
				ed_target.call("_eat")
				measurements["desktop_input"]["edible"]["eat_path"] = "called _eat(): the desktop carry holds it %.2f m from the camera, past eat_distance 0.25 — a headset brings it to the face" % cam_d
			else:
				measurements["desktop_input"]["edible"]["eat_path"] = "eaten by the artifact's own rule (within eat_distance of the camera)"
			await process_frame
			var effect: Node = null
			for n in root.find_children("*", "Node3D", true, false):
				if n.is_in_group("mushroom_effect"): effect = n; break
			var tripping: bool = effect != null and effect.has_method("is_tripping") and bool(effect.call("is_tripping"))
			measurements["desktop_input"]["edible"]["effect"] = {"found": effect != null, "tripping": tripping, "path": str(effect.get_path()).right(50) if effect != null else "none"}
			check(tripping, "eating it starts the perception effect (a MushroomEffect in the tree, tripping)")
			if capture:
				for i in range(12): await process_frame
				await create_timer(0.3, true, false, true).timeout
				root.get_texture().get_image().save_png(OUT + "probe_mushrooms_eaten.png")
				measurements["desktop_input"]["edible"]["capture_pose"] = drv.call("pose")
			await drv.call("release", MOUSE_BUTTON_RIGHT)
			await create_timer(0.7).timeout
			var est_after: Dictionary = prim.call("edibles_state")
			measurements["desktop_input"]["edible"]["after"] = {"present": est_after["present"], "eaten": est_after["eaten"]}
			check(int(est_after["present"]) == 2 and int(est_after["eaten"]) == 1, "the eaten one dissolves and the plate counts two (%s)" % str(measurements["desktop_input"]["edible"]["after"]))
		else:
			check(false, "an edible mushroom stands at the west kerb for the rig to reach")
		drv.get("rig").global_position = seg.to_global(Vector3(6.5, 0.05, 0.6 + vest))
		await physics_frame
		drv.call("aim_at", seg.to_global(Vector3(6.5, 1.2, 8.0 + vest)))
		var moved_v: Vector3 = await drv.call("walk", "ui_up", 40)
		var ml: Vector3 = seg.global_transform.basis.inverse() * moved_v
		measurements["desktop_input"]["walk_south_from_the_door"] = [snappedf(ml.x, 0.01), snappedf(ml.z, 0.01)]
		check(ml.z > 1.2 and ml.z < 2.7, "the rig walks south from the door and is stopped by the table (%.2f m of a possible 2.75)" % ml.z)
		drv.get("rig").global_position = seg.to_global(Vector3(2.0, 0.05, 1.5 + vest))
		await physics_frame
		drv.call("aim_at", seg.to_global(Vector3(2.0, 1.2, 11.0 + vest)))
		moved_v = await drv.call("walk", "ui_up", 30)
		ml = seg.global_transform.basis.inverse() * moved_v
		measurements["desktop_input"]["walk_west_margin"] = [snappedf(ml.x, 0.01), snappedf(ml.z, 0.01)]
		check(ml.z > 2.0, "the rig walks the west margin past the bed on ui_up (%.2f m in half a second)" % ml.z)
		await drv.call("teardown")
		measurements["desktop_input"]["log"] = drv.get("log")
		measurements["desktop_input"]["walker_cam_guard_stopped"] = drv.get("walker_cam_guard_stopped")
		await process_frame

	# ── 8. captures from the visitor's eye ───────────────────────────────────
	if capture:
		await create_timer(0.3).timeout
		var tgt: Vector3 = table.to_global(Vector3(0.0, 0.85, 0.2))
		cam.global_position = seg.to_global(Vector3(SPOT.x, EYE_H, SPOT.z + vest)); cam.look_at(tgt)
		for i in range(20): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_mushrooms.png")
		measurements["captures"]["primary"] = _cam_pose(cam)
		cam.global_position = table.to_global(Vector3(-0.30, 1.15, 0.95)); cam.look_at(readout.global_position)
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_mushrooms_readout.png")
		measurements["captures"]["readout"] = _cam_pose(cam)
		cam.global_position = table.to_global(Vector3(0.0, 1.30, 0.85)); cam.look_at(table.to_global(Vector3(0.0, 0.95, -0.04)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_mushrooms_specimens.png")
		measurements["captures"]["specimens"] = _cam_pose(cam)
		cam.global_position = table.to_global(Vector3(0.47, 1.25, 0.95)); cam.look_at((panel as Node3D).global_position)
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_mushrooms_panel.png")
		measurements["captures"]["panel"] = _cam_pose(cam)
		cam.global_position = seg.to_global(Vector3(6.5, 2.4, 2.2 + vest)); cam.look_at(seg.to_global(Vector3(6.5, 0.3, 7.5 + vest)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_mushrooms_bed.png")
		measurements["captures"]["bed"] = _cam_pose(cam)
		cam.global_position = seg.to_global(Vector3(6.5, 1.6, 0.3 + vest)); cam.look_at(seg.to_global(Vector3(6.5, 0.6, 7.5 + vest)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_mushrooms_north_door.png")
		measurements["captures"]["north_door"] = _cam_pose(cam)
		cam.global_position = seg.to_global(Vector3(6.5, 1.6, 12.2 + vest)); cam.look_at(seg.to_global(Vector3(6.5, 0.4, 6.0 + vest)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_mushrooms_south_door.png")
		measurements["captures"]["south_door"] = _cam_pose(cam)
		var ed_first: Node3D = null
		for e in prim.get("_edibles"):
			if is_instance_valid(e) and not bool((e as Node).get("_is_eaten")) and seg.to_local((e as Node3D).global_position).x < 4.0: ed_first = e; break
		if ed_first != null:
			var efl: Vector3 = seg.to_local(ed_first.global_position)
			cam.global_position = seg.to_global(Vector3(2.4, 1.35, efl.z - 0.9)); cam.look_at(ed_first.global_position)
			for i in range(15): cam.make_current(); await process_frame
			await create_timer(0.3, true, false, true).timeout
			root.get_texture().get_image().save_png(OUT + "probe_mushrooms_edibles.png")
			measurements["captures"]["edibles"] = _cam_pose(cam)
		cam.global_position = seg.to_global(Vector3(2.0, 1.6, 2.0 + vest)); cam.look_at(seg.to_global(Vector3(9.0, 0.4, 8.0 + vest)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_mushrooms_west_margin.png")
		measurements["captures"]["west_margin"] = _cam_pose(cam)
		cam.global_position = seg.to_global(Vector3(6.5, 14.0, 6.5 + vest)); cam.look_at(seg.to_global(Vector3(6.5, 0.0, 6.51 + vest)))
		for i in range(15): cam.make_current(); await process_frame
		await create_timer(0.3, true, false, true).timeout
		root.get_texture().get_image().save_png(OUT + "probe_mushrooms_plan.png")
		measurements["captures"]["plan"] = _cam_pose(cam)
		cam.queue_free()

	# ── 8b. the shipped default plants none ──────────────────────────────────
	var bare: Node3D = load("res://algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.tscn").instantiate()
	bare.position = Vector3(60.0, -60.0, 60.0)
	em.add_child(bare)
	await process_frame; await process_frame
	var bare_e: Dictionary = bare.call("edibles_state")
	check(str(bare.get("edible")) == "none" and int(bare_e["planted"]) == 0 and str(bare.get("stand")) == "none", "a token without #edible plants no edible mushroom and builds no table (%s, %s)" % [str(bare.get("edible")), str(bare_e["planted"])])
	em.remove_child(bare)
	bare.queue_free()
	await process_frame

	# ── 9. the templates go with the hall ────────────────────────────────────
	var refs: Array = []
	for t in prim.get("mushroom_types"): refs.append(weakref(t))
	var seg_i: int = -1
	var segs: Array = em.get("_segments")
	for i in range(segs.size()):
		if (segs[i] as Dictionary).node == seg: seg_i = i
	var freed_templates: int = -1
	if seg_i >= 0:
		seg.get_parent().remove_child(seg)
		seg.queue_free()
		segs.remove_at(seg_i)
		for i in range(4): await process_frame
		freed_templates = 0
		for w in refs:
			if (w as WeakRef).get_ref() == null: freed_templates += 1
	measurements["templates_freed_with_the_hall"] = [freed_templates, refs.size()]
	check(freed_templates == refs.size() and refs.size() == 6, "the six templates are freed with the hall (%d of %d; 51 objects leaked at exit before)" % [freed_templates, refs.size()])
	_finish()

## Pressing a panel button the way the museum's pointer does: the area's own signal, one argument.
func _press(panel: Node, btn_name: String) -> bool:
	if panel == null: return false
	var btn: Node = panel.find_child(btn_name, true, false)
	var area: Node = btn.get_node_or_null("InteractableAreaButton") if btn != null else null
	if area == null: return false
	area.emit_signal("button_pressed", area)
	return true

func _kinds(inst: Array) -> Dictionary:
	var k := {"scattered": 0, "ring": 0, "cluster": 0}
	for i in inst:
		var kind: String = str(i["kind"])
		if k.has(kind): k[kind] += 1
	return k

## Two populations compared instance by instance: template, kind, group, position, yaw and
## (unless told otherwise) scale.
func _same(a: Array, b: Array, scale_too: bool) -> Dictionary:
	if a.size() != b.size(): return {"same": false, "first_diff": "count %d vs %d" % [a.size(), b.size()]}
	for i in range(a.size()):
		var p: Dictionary = a[i]; var q: Dictionary = b[i]
		if int(p["template"]) != int(q["template"]) or str(p["kind"]) != str(q["kind"]) or int(p["group"]) != int(q["group"]):
			return {"same": false, "first_diff": "instance %d: %s vs %s" % [i, str(p), str(q)]}
		for key in ["x", "y", "z", "yaw"]:
			if abs(float(p[key]) - float(q[key])) > 0.0005:
				return {"same": false, "first_diff": "instance %d %s: %s vs %s" % [i, key, str(p[key]), str(q[key])]}
		if scale_too and abs(float(p["scale"]) - float(q["scale"])) > 0.0005:
			return {"same": false, "first_diff": "instance %d scale: %s vs %s" % [i, str(p["scale"]), str(q["scale"])]}
	return {"same": true, "compared": a.size()}

func _brief(st: Dictionary) -> Dictionary:
	var out: Dictionary = st.duplicate()
	out.erase("instances")
	out["instances"] = (st["instances"] as Array).size()
	return out

## Which camera the viewport draws from at a capture, and where it stands and looks.
func _cam_pose(cam: Camera3D) -> Dictionary:
	var cur: Camera3D = root.get_camera_3d()
	var fwd: Vector3 = -cam.global_transform.basis.z
	return {"current_camera": str(cur.get_path()).right(50) if cur != null else "none", "is_ours": cur == cam,
		"at": [snappedf(cam.global_position.x, 0.01), snappedf(cam.global_position.y, 0.01), snappedf(cam.global_position.z, 0.01)],
		"forward": [snappedf(fwd.x, 0.01), snappedf(fwd.y, 0.01), snappedf(fwd.z, 0.01)]}

func _finish() -> void:
	var report := {"map": MAP, "checks": checks, "failures": failures, "measurements": measurements,
		"control_path": "REGROW / NEW SEED / SIZE / SHOW / KIND through InteractableAreaButton.button_pressed (one argument); set_population_seed by call; the live port presses REGROW, SHOW and NEW SEED through the desktop pointer",
		"hand_file": "ada_run/necklace_hand.json (real)", "headset_verified": false,
		"engine": Engine.get_version_info().string, "physics_fps": Engine.physics_ticks_per_second}
	var f := FileAccess.open(OUT + "probe_mushrooms.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  ")); f.close()
	print("[wcn-mush] ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
