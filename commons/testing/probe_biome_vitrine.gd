extends SceneTree
## probe_biome_vitrine.gd — the glass cage builds the biome the stage says, and nothing else.
##
##   Godot_v4.6-stable_win64.exe --headless --path . --xr-mode off --script res://commons/testing/probe_biome_vitrine.gd
##
## Checks: the stage table matches soft_stages.json; a grey stage seeds only coloured cubes
## and grass; colour brings the first flower; randomness brings fungus and respects the caps;
## L-systems brings LIVE creatures that a manual evolution step breeds and culls within
## bounds; the cage has six panes and no roof (four with the doorways off); the same seed
## paints the same cells and a different seed does not; apply_grid_config before the tree
## wins over the exports; the record file is written; presence covers the floor.
## Nothing here reads a MultiMesh instance back, so --headless is fine. The XR Tools compile
## errors at boot (XRToolsUserSettings is an autoload a SceneTree probe cannot see) are the
## probe lane's, not the cage's: the pickable still instantiates and answers pick_up.

const VITRINE := preload("res://commons/artifacts/biome_vitrine/biome_vitrine.gd")
const STAGES := "res://commons/maps/soft_stages.json"

var _checks := 0
var _fails := 0
var _root: Node3D


func _check(ok: bool, msg: String) -> void:
	_checks += 1
	if not ok:
		_fails += 1
		print("  FAIL  ", msg)


func _init() -> void:
	_root = Node3D.new()
	get_root().add_child(_root)
	_run()


func _run() -> void:
	# 1. the stage table
	var stages: Dictionary = (JSON.parse_string(FileAccess.get_file_as_string(STAGES)) as Dictionary)["stages"]
	for key in ["primitives", "color", "randomness", "lsystems"]:
		var info: Dictionary = VITRINE._stage_info(key)
		var st: Dictionary = stages[key]
		_check(bool(info["known"]), "%s known" % key)
		_check(int(info["order"]) == int(round(float(st["order"]))), "%s order" % key)
		_check(str(info["kingdoms"]) == str(st["ecosystem"]["nature_kingdoms"]), "%s kingdoms" % key)
		_check(is_equal_approx(float(info["density"]), float(st["ecosystem"]["vegetation_density"])), "%s density" % key)
	_check(not bool(VITRINE._stage_info("no_such_stage")["known"]), "unknown stage is not known")

	# 2. four stages, one cage each
	var grey = await _cage("primitives", 7, {})
	_check(grey.stage_key() == "primitives", "grey: stage key")
	_check(grey.get_state()["kingdoms"].is_empty(), "grey: no kingdoms")
	# under the strict ladder `primitives` = the whole sequence learned: the grey garden, no kingdoms
	_check(bool(grey.get_state()["grey"]), "grey: the primitives cage is the grey grammar")
	_check(_seed_total(grey) == 0, "grey: nothing painted (%d seeds)" % _seed_total(grey))
	_check(_count_cubes(grey) == 0, "grey: no coloured cubes (%d)" % _count_cubes(grey))
	var gg: Dictionary = grey.get_state()["grammar"]
	_check(int(gg.get("ornament", 0)) == 1 and int(gg.get("solids", 0)) > 0, "grey: the whole primitives garden stands (%s)" % str(gg))
	# density 0.0 at primitives: a clinical floor, no ground cover at all
	_check(int(grey.get_state()["cover"]) == 0, "grey: no ground cover at density 0 (%d)" % int(grey.get_state()["cover"]))
	_check(grey.get_node_or_null("Patch/CoverFoliage_grass") == null, "grey: no grass cover")
	_check(grey.get_node_or_null("Patch/CoverFoliage_flower") == null, "grey: no flower cover")
	_check(int(grey.get_state()["live"]) == 0, "grey: no live creatures")

	var colour = await _cage("color", 7, {})
	_check(str(colour.get_state()["kingdoms"]) == str(["flower"]), "colour: flower only")
	_check(colour.get_node_or_null("Patch/CoverFoliage_flower") != null, "colour: flower cover")
	_check(colour.get_node_or_null("Patch/CoverFoliage_grass") != null, "colour: grass cover arrives with the first kingdom")
	_check(_count_cubes(colour) == 0, "colour: no locked cubes (%d)" % _count_cubes(colour))
	_check(_count_built(colour) >= 1, "colour: at least one flower built (%d organisms)" % _count_built(colour))

	var rnd = await _cage("randomness", 7, {})
	var rs: Dictionary = rnd.get_state()
	# the closure's kingdom words: flower (with the rainbow) and fungus (with randomness); trees wait for L-systems
	_check(str(rs["kingdoms"]) == str(["flower", "fungus"]), "randomness: kingdoms %s" % str(rs["kingdoms"]))
	_check(int(rs["seeds"]["tree"]) == 0, "randomness: no trees before L-systems")
	for k in ["tree", "flower", "fungus"]:
		_check(int(rs["seeds"][k]) <= int(VITRINE.CAPS[k]), "randomness: %s within cap" % k)
	_check(int(rs["seeds"]["creature"]) == 0, "randomness: no creature seeds")
	_check(rnd.get_node_or_null("Patch/CoverFoliage_mushroom") != null, "randomness: mushroom cover")
	_check(int(rs["live"]) == 0, "randomness: no live creatures")
	_check(int(rs["cover"]) > 0, "randomness: ground cover (%d)" % int(rs["cover"]))
	var cov: Dictionary = rs["presence"]
	_check(float(cov["flower"]) + float(cov["tree"]) + float(cov["fungus"]) > 0.0, "randomness: the floor remembers (%s)" % str(cov))

	var lsys = await _cage("lsystems", 7, {})
	var ls: Dictionary = lsys.get_state()
	_check("creature" in ls["kingdoms"], "lsystems: creature kingdom")
	var live0: int = int(ls["live"])
	_check(live0 > 0 and live0 <= int(VITRINE.CAPS["creature"]), "lsystems: live creatures %d" % live0)
	# the strict ladder: creatures wander at L-systems, but nothing SELECTS before machinelearning
	_check(not bool(ls["evolving"]), "lsystems: not evolving before machinelearning")
	_check(lsys._evo != null and lsys._spawner != null, "lsystems: evolution wired, not running")
	var ml = await _cage("machinelearning", 7, {})
	_check(bool(ml.get_state()["evolving"]), "machinelearning: evolving")
	_check("select" in ml.closure()["does"], "machinelearning: closure has select")
	lsys._evo.evolve_step()
	var ls2: Dictionary = lsys.get_state()
	_check(int(ls2["generation"]) == 1, "lsystems: one generation stepped")
	_check(int(ls2["live"]) >= int(lsys._evo.min_population) and int(ls2["live"]) <= int(lsys._evo.max_population),
		"lsystems: population %d within [%d, %d]" % [int(ls2["live"]), lsys._evo.min_population, lsys._evo.max_population])
	_check((ls2["history"] as Array).size() == 1, "lsystems: history has the generation")

	# 3. the cage
	var panes: int = _count_panes(rnd)
	_check(panes == 6, "cage: six panes with doorways (%d)" % panes)
	_check(not _has_roof(rnd), "cage: no roof")
	_check(_count_labels(rnd) == 2, "cage: two titles")
	var shut = await _cage("randomness", 7, {"entry": "off"})
	_check(_count_panes(shut) == 4, "cage: four panes when shut (%d)" % _count_panes(shut))

	# 4. determinism
	var twin = await _cage("randomness", 7, {})
	_check(str(twin.get_tiles()) == str(rnd.get_tiles()), "same seed paints the same cells")
	var other = await _cage("randomness", 8, {})
	_check(str(other.get_tiles()) != str(rnd.get_tiles()), "another seed paints other cells")

	# 5. config before the tree
	var cfg = await _cage("randomness", 7, {"stage": "noise", "size": "6", "seed": "3", "evolve": "off", "duration": "5", "record": "off"})
	_check(cfg.stage_key() == "noise", "config: stage noise (%s)" % cfg.stage_key())
	_check(int(cfg.size) == 6, "config: size 6")
	_check(int(cfg.seed) == 3, "config: seed 3")
	_check(cfg.evolve == "off", "config: evolve off")
	_check(is_equal_approx(float(cfg.duration), 5.0), "config: duration 5")
	_check(cfg._record_where == "", "config: record off writes nothing")

	# 6. the record
	var rec_path := ""
	for p in ["res://ada_run/biome_vitrines.json", "user://biome_vitrines.json"]:
		if FileAccess.file_exists(p):
			rec_path = p
			break
	_check(rec_path != "", "record file exists")
	if rec_path != "":
		var doc: Variant = JSON.parse_string(FileAccess.get_file_as_string(rec_path))
		_check(doc is Dictionary, "record parses")
		if doc is Dictionary:
			var found := 0
			for k in (doc as Dictionary).keys():
				if String(k).begins_with("lsystems|") or String(k).begins_with("randomness|"):
					found += 1
			_check(found >= 2, "record holds this run's cages (%d)" % found)
			var any_key: String = ""
			for k in (doc as Dictionary).keys():
				if String(k).begins_with("lsystems|"):
					any_key = String(k)
			if any_key != "":
				var st: Dictionary = (doc as Dictionary)[any_key]
				for f in ["stage", "order", "kingdoms", "density", "seeds", "live", "generation", "presence", "history", "at"]:
					_check(st.has(f), "record field %s" % f)

	# 7. readbacks
	_check(rnd.status_line().begins_with("BIOME · RANDOMNESS"), "status line names the stage")
	_check(rnd.is_in_group("biome_vitrine"), "in the query group")

	# 8. the primitives ladder — the grey grammar, one word per hall
	var G = load("res://commons/biome_layers/biome_grammar.gd")
	var c1: Dictionary = G.closure("Point_One")
	_check(str(c1["made_of"]) == str(["point"]) and str(c1["does"]) == str(["hand"]) and (c1["knows"] as Array).is_empty(), "closure Point_One = point / hand / —")
	var c5: Dictionary = G.closure("Point_Triangle_Context")
	_check(str(c5["made_of"]) == str(["point", "line", "lattice", "face"]), "closure after the triangle map: %s" % str(c5["made_of"]))
	_check("trace" in c5["knows"], "closure after the triangle map knows trace")
	var c10: Dictionary = G.closure("Primitives_Melencolia")
	_check("ornament" in c10["made_of"] and "self_move" in c10["does"] and not ("colour" in c10["made_of"]), "closure at the end of primitives: no colour yet")
	_check("colour" in G.closure("color")["made_of"] and "point" in G.closure("color")["made_of"], "closure at colour carries the primitives")
	_check(not bool(G.position_of("No_Such_Hall")["known"]), "unknown hall is not known")
	_check(int(G.position_of("Point_Lines")["hall"]) == 1 and int(G.position_of("Point_Lines")["spine"]) == 0, "Point_Lines is hall 1 of spine 0")

	var one = await _cage("Point_One", 7, {"size": "5"})
	_check(one.stage_key() == "Point_One", "Point_One: stage key")
	_check(bool(one.get_state()["grey"]), "Point_One: grey grammar")
	var pts: Array = one.free_points()
	_check(pts.size() == 1, "Point_One: exactly one point (%d)" % pts.size())
	_check(pts.size() == 1 and pts[0].has_method("pick_up") and pts[0] is RigidBody3D, "Point_One: the point is a pickable body")
	_check(pts.size() == 1 and (pts[0] as RigidBody3D).freeze, "Point_One: the point stays where it is put")
	_check(one.get_node_or_null("Patch/Garden/Line_0") == null, "Point_One: no line")
	_check(one.get_node_or_null("Patch/Garden/Lattice") == null, "Point_One: no lattice")
	_check(one._presence == null, "Point_One: the floor does not remember yet")
	_check(one.get_node_or_null("Patch/Dispatcher") == null and one.get_node_or_null("Patch/CoverFoliage_grass") == null, "Point_One: no painted kingdoms, no cover")
	_check(_all_grey(one), "Point_One: nothing has a colour")

	var two = await _cage("Point_Lines", 7, {"size": "5"})
	_check(two.free_points().size() == 2, "Point_Lines: two points")
	_check(two.get_node_or_null("Patch/Garden/Line_0") != null, "Point_Lines: the line")
	_check(two._presence == null, "Point_Lines: still no trace")
	# move a point; the line follows
	var p1: Node3D = two.free_points()[1]
	p1.global_position = p1.global_position + Vector3(0.7, 0.0, 0.3)
	await process_frame
	var ln: MeshInstance3D = two.get_node("Patch/Garden/Line_0")
	var mid: Vector3 = (two.free_points()[0].global_position + p1.global_position) * 0.5
	_check(ln.global_position.distance_to(mid) < 0.05, "Point_Lines: the line follows the moved point")

	var three = await _cage("Point_Trace", 7, {"size": "5"})
	_check(three._presence != null, "Point_Trace: the floor remembers")
	_check(is_equal_approx(float(three._ground_mat.get_shader_parameter("mono")), 1.0), "Point_Trace: it remembers in grey")
	_check(float(three.presence_coverage()["creature"]) > 0.0, "Point_Trace: the points have left a mark")

	var five = await _cage("Point_Triangle_Context", 7, {"size": "5"})
	_check(five.get_node_or_null("Patch/Garden/Lattice") != null and five.get_node_or_null("Patch/Garden/LatticeLines") != null, "triangle map: the lattice stands")
	_check(five.get_node_or_null("Patch/Garden/Faces") != null, "triangle map: faces")
	_check(five.get_node_or_null("Patch/Garden/Solid_0") == null, "triangle map: no bodies yet")
	_check(_all_grey(five), "triangle map: still no colour")

	var six = await _cage("Primitives_Polythedra", 7, {"size": "5"})
	_check(six.get_node_or_null("Patch/Garden/Solid_0") != null, "polyhedra: bodies")
	_check(int(six.get_state()["grammar"]["movers"]) == 0, "polyhedra: nothing moves by itself yet")
	var seven = await _cage("Point_Animatedcube", 7, {"size": "5"})
	_check(int(seven.get_state()["grammar"]["movers"]) > 0, "animated cube: bodies move by themselves")
	var eight = await _cage("Primitives_Ignorance", 7, {"size": "5"})
	_check(eight.get_node_or_null("Patch/Garden/Sphere_0") != null, "ignorance: spheres")
	var nine = await _cage("Primitives_Portals", 7, {"size": "5"})
	_check(nine.get_node_or_null("Patch/Garden/Subdivided") != null, "portals: a divided body")
	var ten = await _cage("Primitives_Melencolia", 7, {"size": "5"})
	_check(ten.get_node_or_null("Patch/Garden/Ornament") != null, "melencolia: the ornament")
	_check(_all_grey(ten), "end of primitives: still no colour")
	_check(ten.status_line().find("beyond:") >= 0, "the screen says what lies beyond the text")

	# `hall` reads the hall the cage stands in (museum em_map meta)
	var seg := Node3D.new()
	seg.set_meta("em_map", "Point_Lines")
	seg.set_meta("em_chapter", "primitives")
	_root.add_child(seg)
	var h = VITRINE.new()
	h.stage = "hall"
	h.size = 5
	h.position = Vector3(float(_slot) * 20.0, 0.0, 40.0)
	_slot += 1
	seg.add_child(h)
	await process_frame
	await process_frame
	await process_frame
	_check(h.stage_key() == "Point_Lines", "stage `hall` resolves the museum's em_map (%s)" % h.stage_key())

	# 9. transformation and colour — what the bodies may DO, then colour
	var cr: Dictionary = G.closure("Trans_Rotation")
	_check("rotate" in cr["does"] and "translate" in cr["does"] and not ("scale" in cr["does"]), "closure Trans_Rotation: rotate and translate, not yet scale")
	_check("pickup" in G.closure("Trans_Pre")["does"] and not ("pickup" in G.closure("Primitives_Melencolia")["does"]), "pickup arrives with Trans_Pre")
	_check(not ("colour" in G.closure("Trans_Pit")["made_of"]), "no colour at the end of transformation")
	var pre = await _cage("Trans_Pre", 7, {"size": "5"})
	var s0: Node = pre.get_node_or_null("Patch/Garden/Solid_0")
	_check(s0 != null and s0 is RigidBody3D and s0.has_method("pick_up"), "Trans_Pre: the bodies can be taken")
	_check(_all_grey(pre), "Trans_Pre: still grey")
	var intro = await _cage("Trans_Introduction", 7, {"size": "5"})
	_check(intro.get_node_or_null("Patch/Garden/Loop") != null, "Trans_Introduction: a movement left running")
	var tr = await _cage("Trans_Translation", 7, {"size": "5"})
	var carrier: Node3D = tr.get_node("Patch/Garden/Carrier")
	var z0: float = carrier.position.z
	await process_frame
	await process_frame
	await process_frame
	_check(not is_equal_approx(carrier.position.z, z0), "Trans_Translation: the carrier moves")
	var ro = await _cage("Trans_Rotation", 7, {"size": "5"})
	var spoke: Node3D = ro.get_node("Patch/Garden/Spoke")
	var r0: float = spoke.rotation.y
	await process_frame
	await process_frame
	_check(not is_equal_approx(spoke.rotation.y, r0), "Trans_Rotation: the spoke turns about one end")
	_check(ro.get_node_or_null("Patch/Garden/Pulse") == null, "Trans_Rotation: nothing scales yet")
	var sc = await _cage("Trans_Scale", 7, {"size": "5"})
	_check(sc.get_node_or_null("Patch/Garden/Pulse") != null, "Trans_Scale: a body that swells and shrinks")
	var bo = await _cage("Trans_Body", 7, {"size": "5"})
	_check(bo.get_node_or_null("Patch/Garden/BodyPost") != null and bo.status_line().find("body 1.65") >= 0, "Trans_Body: the measure, drawn")
	var pit = await _cage("Trans_Pit", 7, {"size": "5"})
	_check(pit.get_node_or_null("Patch/Garden/Boundary") != null, "Trans_Pit: a boundary that moves")
	_check(_all_grey(pit), "end of transformation: still no colour")
	_check(int(pit.get_state()["grammar"]["rules"]) == 5, "end of transformation: five rules (%d)" % int(pit.get_state()["grammar"]["rules"]))

	var cc = await _cage("Color_Context_Placed", 7, {"size": "5"})
	_check(not _all_grey(cc), "Color_Context_Placed: the bodies have colour")
	_check(cc.get_state()["kingdoms"].is_empty() and cc.get_node_or_null("Patch/Dispatcher") == null, "Color_Context_Placed: no living things yet")
	var ll: MultiMeshInstance3D = cc.get_node("Patch/Garden/LatticeLines")
	_check(not ll.multimesh.use_colors, "Color_Context_Placed: the lattice is still grey")
	_check(is_equal_approx(float(cc._ground_mat.get_shader_parameter("mono")), 1.0), "Color_Context_Placed: the floor still remembers in grey")
	var fl = await _cage("Color_Flashlight", 7, {"size": "5"})
	_check(fl.get_node_or_null("Patch/Lamp_0") is OmniLight3D, "Color_Flashlight: lamps make pools")
	var na = await _cage("Color_Nails", 7, {"size": "5"})
	var pm: Material = (na.free_points()[0].get_node("Mesh") as MeshInstance3D).material_override
	_check(pm is StandardMaterial3D and (pm as StandardMaterial3D).albedo_color.s > 0.5, "Color_Nails: the point you move is coloured")
	var rb = await _cage("Color_Rainbow", 7, {"size": "5"})
	_check(str(rb.get_state()["kingdoms"]) == str(["flower"]) and int(rb.get_state()["seeds"]["flower"]) > 0, "Color_Rainbow: the first flowers, dressed (%s)" % str(rb.get_state()["seeds"]))
	var pi_ = await _cage("Color_Pillar", 7, {"size": "5"})
	_check((pi_.get_node("Patch/Garden/LatticeLines") as MultiMeshInstance3D).multimesh.use_colors, "Color_Pillar: a gradient on the lattice")
	_check(not _planes_differ(pi_), "Color_Pillar: the planes still share one colour")
	var gp = await _cage("Color_Grid_Pallet", 7, {"size": "5"})
	_check(_planes_differ(gp), "Color_Grid_Pallet: every plane has its address's colour")
	var pa = await _cage("Color_Paint", 7, {"size": "5"})
	_check(is_equal_approx(float(pa._ground_mat.get_shader_parameter("mono")), 0.0), "Color_Paint: the floor remembers in colour")
	var wa = await _cage("Color_Walls", 7, {"size": "5"})
	_check(_glass_alpha(wa) > 0.12, "Color_Walls: the glass has colour (alpha %.2f)" % _glass_alpha(wa))
	_check(_glass_alpha(pa) < 0.12, "Color_Paint: the glass was still clear")
	var ch = await _cage("Chamber_Color", 7, {"size": "5"})
	_check(ch.status_line().find("when:") >= 0, "Chamber_Color: what remains is when")

	# 10. families and the STAGE rack
	var fams := {}
	for s in range(1, 31):
		var v = VITRINE.new()
		v.seed = s
		v.size = 5
		var score_d: Dictionary = v._layout_score()
		fams[String(score_d["family"])] = true
		v.free()
	_check(fams.size() == 3, "thirty seeds reach all three families (%s)" % str(fams.keys()))
	_check(rnd.family_name() in VITRINE.FAMILIES, "the state names the family (%s)" % rnd.family_name())
	var nb: Dictionary = G.neighbours("Point_One")
	_check(String(nb["prev"]) == "" and String(nb["next"]) == "Point_Lines", "walk: Point_One's neighbours")
	_check(String(G.neighbours("Primitives_Melencolia")["next"]) == "Trans_Pre", "walk: Melencolia steps to Trans_Pre, not the ladder room")
	_check(String(G.neighbours("wavefunctions")["next"]) == "Random_Definition", "walk: a wordless sequence is one stage, and it steps into the randomness halls")
	_check(String(G.neighbours("Random_Game")["next"]) == "noise", "walk: Random_Game steps to noise, past the cage and the ladder room")
	var scrub = await _cage("Point_Lines", 7, {"size": "5", "controls": "panel"})
	_check(scrub.get_node_or_null("StatusHolder/StagePanel") != null, "controls: the STAGE rack stands")
	scrub.press_control("next")
	await process_frame
	await process_frame
	_check(scrub.stage_key() == "Point_Trace", "STAGE + walks to Point_Trace (%s)" % scrub.stage_key())
	_check(scrub._presence != null, "STAGE +: the rebuilt cage remembers")
	scrub.press_control("prev")
	await process_frame
	scrub.press_control("prev")
	await process_frame
	await process_frame
	_check(scrub.stage_key() == "Point_One" and scrub.free_points().size() == 1, "STAGE - twice: back to one point")
	scrub.press_control("prev")
	await process_frame
	_check(scrub.stage_key() == "Point_One", "STAGE - at the start stays")

	# 11. the lineage log, the counterfactual word, GEN +
	var lin_before: int = _lineage_rows()
	var dream = await _cage("lsystems", 7, {"size": "8", "run": "probe", "evolve": "off"})
	var st0: Dictionary = dream.get_state()
	_check(String(st0["lineage"]["where"]) != "", "lineage: the cage writes its log (%s)" % String(st0["lineage"]["where"]))
	var rows_after_build: int = _lineage_rows()
	_check(rows_after_build > lin_before, "lineage: build rows appended (%d)" % (rows_after_build - lin_before))
	var mine: Array = _lineage_of(String(st0["lineage"]["session"]), "probe")
	var ev := {}
	for r in mine:
		ev[String(r.get("event", ""))] = int(ev.get(String(r.get("event", "")), 0)) + 1
	_check(int(ev.get("cage", 0)) >= 1 and int(ev.get("seeded", 0)) > 0 and int(ev.get("spawned", 0)) > 0, "lineage: cage, seeded and spawned rows (%s)" % str(ev))
	dream.press_control("gen")
	await process_frame
	var st1: Dictionary = dream.get_state()
	_check(int(st1["generation"]) == 1, "GEN +: one generation passed by hand")
	mine = _lineage_of(String(st0["lineage"]["session"]), "probe")
	ev = {}
	for r in mine:
		ev[String(r.get("event", ""))] = int(ev.get(String(r.get("event", "")), 0)) + 1
	_check(int(ev.get("generation", 0)) == 1, "lineage: a generation row (forced)")
	_check(int(ev.get("born", 0)) + int(ev.get("culled", 0)) > 0, "lineage: births or culls recorded (%s)" % str(ev))
	var gen_rows: Array = mine.filter(func(r): return String(r.get("event", "")) == "generation")
	_check(gen_rows.size() == 1 and bool(gen_rows[0].get("forced", false)), "lineage: the forced step says so")
	var cage_row: Dictionary = mine.filter(func(r): return String(r.get("event", "")) == "cage")[0]
	_check(int(cage_row.get("rng_seed", 0)) != 0 and String(cage_row.get("fitness_fn", "")) == "default", "lineage: the breeder's seed and the fitness name are recorded")
	# the same seed replays: a second cage, same stage and seed, one step — same births by kingdom
	var twin_d = await _cage("lsystems", 7, {"size": "8", "run": "probe-twin", "evolve": "off"})
	twin_d.press_control("gen")
	await process_frame
	var b1: Dictionary = {}
	var b2: Dictionary = {}
	for r in _lineage_of(String(st0["lineage"]["session"]), "probe"):
		if String(r.get("event", "")) == "born":
			b1[String(r.get("kingdom", ""))] = int(b1.get(String(r.get("kingdom", "")), 0)) + 1
	for r in _lineage_of(String(st0["lineage"]["session"]), "probe-twin"):
		if String(r.get("event", "")) == "born":
			b2[String(r.get("kingdom", ""))] = int(b2.get(String(r.get("kingdom", "")), 0)) + 1
	_check(str(b1) == str(b2), "lineage: the same seed breeds the same kingdoms (%s vs %s)" % [str(b1), str(b2)])
	# the counterfactual word
	var cf = await _cage("Point_One", 7, {"size": "5", "allow": "line"})
	_check(cf.free_points().size() == 2 and cf.get_node_or_null("Patch/Garden/Line_0") != null, "allow: Point_One granted `line` draws the line")
	_check("line" in cf.closure()["made_of"] and cf.get_state()["allow"] == "line", "allow: the state says the word was granted")
	var cf_rows: Array = _lineage_of(String(st0["lineage"]["session"]), "").filter(func(r): return String(r.get("stage", "")) == "Point_One" and String(r.get("allow", "")) == "line")
	_check(cf_rows.size() >= 1, "allow: the log carries the granted word")

	# 12. randomness, hall by hall — what chance may change
	_check("sample" in G.closure("Random_Definition")["made_of"] and not ("fungus" in G.closure("Random_Definition")["made_of"]), "closure Random_Definition: a sample, no fungus yet")
	_check("fungus" in G.closure("Random_Mushrooms")["made_of"] and "ring" in G.closure("Random_Mushrooms")["made_of"], "closure Random_Mushrooms: fungus arrives, in a ring")
	_check("drip" in G.closure("Random_Game")["made_of"] and "absent" in G.closure("Random_Game")["does"], "closure Random_Game: the examples' words and absence")
	var rdef = await _cage("Random_Definition", 7, {"size": "5"})
	_check(rdef.get_node_or_null("Patch/Garden/Reel") != null and int(rdef.get_state()["grammar"]["reel"]) == 5, "Random_Definition: the reel of five")
	_check(rdef.get_state()["kingdoms"].size() == 1 and "flower" in rdef.get_state()["kingdoms"], "Random_Definition: only the colour sequence's flowers live here")
	var rent = await _cage("Random_Entropy", 7, {"size": "5"})
	_check(rent.get_node_or_null("Patch/Garden/Entropy") != null, "Random_Entropy: the grid, disordered")
	var rrem = await _cage("Random_Remove", 7, {"size": "5"})
	var removed: int = int(rrem.get_state()["grammar"].get("removed", 0))
	_check(removed > 0 and removed < 20, "Random_Remove: chance removed %d of 20 lattice cubes" % removed)
	_check(int(rent.get_state()["grammar"].get("removed", 0)) == 0, "Random_Entropy: nothing removed before Random_Remove")
	var rtp = await _cage("Randomness_10_PRINT_Algorithm", 7, {"size": "5"})
	_check(rtp.get_node_or_null("Patch/Garden/TenPrint") != null and int(rtp.get_state()["grammar"]["ten_print"]) > 0, "10 PRINT: the band of slabs")
	var rwalk = await _cage("Random_Walk", 7, {"size": "8"})
	var p0: Vector3 = rwalk.free_points()[0].global_position
	await create_timer(1.2).timeout
	_check(rwalk.free_points()[0].global_position.distance_to(p0) > 0.05, "Random_Walk: the point walks by itself")
	_check(rwalk.status_line().find("walk:") >= 0, "Random_Walk: the screen counts the steps")
	var rga = await _cage("Random_Gaussian", 7, {"size": "8"})
	_check(str(rga.get_tiles()) != str(rwalk.get_tiles()), "Random_Gaussian: the count changed the painting (same seed, same size, different cells)")
	var rmu = await _cage("Random_Mushrooms", 7, {"size": "8"})
	_check(int(rmu.get_state()["seeds"]["fungus"]) > 0, "Random_Mushrooms: fungus in the cage (%d)" % int(rmu.get_state()["seeds"]["fungus"]))
	_check(int(rga.get_state()["seeds"]["fungus"]) == 0, "Random_Gaussian: no fungus before the mushrooms")
	var rex = await _cage("Randomness_Examples_of_Randomness", 7, {"size": "8"})
	var gx: Dictionary = rex.get_state()["grammar"]
	_check(rex.get_node_or_null("Patch/Garden/Drips") != null and int(gx.get("drips", 0)) > 0, "examples: Pollock's drips")
	_check(rex.get_node_or_null("Patch/Garden/Dartboard") != null and int(gx.get("darts", 0)) == 40, "examples: forty darts")
	_check(rex.status_line().find("π ≈ 4 ×") >= 0, "examples: the estimate on the screen")
	_check(rex.get_node_or_null("Patch/Garden/Pipe") != null and int(gx.get("pipe", 0)) > 10, "examples: the pipe grew (%d segments)" % int(gx.get("pipe", 0)))
	var rgame = await _cage("Random_Game", 7, {"size": "8"})
	_check(rgame._absent != null, "Random_Game: a body that may not be there")
	var twin_r = await _cage("Randomness_Examples_of_Randomness", 7, {"size": "8"})
	_check(str(twin_r.get_state()["grammar"]) == str(gx), "examples: the same seed draws the same drips, darts and pipe")

	# 13. the composition families — three built in, four from files, one contract
	var builtin: Array = ["diagonal", "vertical", "split"]
	var fam_pts: Dictionary = {}
	for fam in builtin + Array(VITRINE.FILE_FAMILIES):
		var fc = await _cage("Random_Game", 7, {"size": "8", "family": fam})
		_check(fc.family_name() == fam, "family %s: pinned by the token (got %s)" % [fam, fc.family_name()])
		var from_file: bool = fam in VITRINE.FILE_FAMILIES
		_check((fc._fam != null) == from_file, "family %s: %s" % [fam, "loaded from its file" if from_file else "built in"])
		fam_pts[fam] = fc._free_points[0].position if not fc._free_points.is_empty() else Vector3(INF, INF, INF)
		var cube: Node3D = fc.get_node_or_null("Patch/Garden/Solid_0")
		_check(cube != null and absf(cube.position.x) <= 3.6 and absf(cube.position.z) <= 3.6, "family %s: the cube stands inside the 8 m cage" % fam)
	var coincide := 0
	for f1 in fam_pts:
		for f2 in fam_pts:
			if String(f1) < String(f2) and (fam_pts[f1] as Vector3).distance_to(fam_pts[f2] as Vector3) < 0.05:
				coincide += 1
	_check(coincide == 0, "families: seven families put the point in seven places (%d coincide)" % coincide)
	var dflt = await _cage("Random_Game", 7, {"size": "8"})
	_check(dflt.family_name() in builtin, "family seed (the default): the seed picks a built-in (%s)" % dflt.family_name())
	var anyf = await _cage("Random_Game", 7, {"size": "8", "family": "any"})
	_check(anyf.family_name() in builtin + Array(VITRINE.FILE_FAMILIES), "family any: one of the seven (%s)" % anyf.family_name())
	var bad = await _cage("Random_Game", 7, {"size": "8", "family": "picasso"})
	_check(bad.family_name() in builtin and bad._fam == null, "family picasso: no such file — a built-in stands in (%s)" % bad.family_name())
	for fam in VITRINE.FILE_FAMILIES:
		var small = await _cage("Random_Game", 7, {"size": "5", "family": fam})
		var fp0: Vector3 = small._free_points[0].position
		_check(absf(fp0.x) <= 2.05 and absf(fp0.z) <= 2.05, "family %s: the point stays inside the 5 m cage (%.2f, %.2f)" % [fam, fp0.x, fp0.z])
		var ftwin = await _cage("Random_Game", 7, {"size": "5", "family": fam})
		_check(ftwin._free_points[0].position.is_equal_approx(fp0), "family %s: the same seed composes the same" % fam)
	print("[probe_biome_vitrine] %d checks, %d failed" % [_checks, _fails])
	quit(0 if _fails == 0 else 1)


var _slot := 0


func _cage(stage: String, seed: int, config: Dictionary):
	var v = VITRINE.new()
	v.stage = stage
	v.seed = seed
	v.size = 8
	v.position = Vector3(float(_slot) * 20.0, 0.0, 0.0)
	_slot += 1
	if not config.is_empty():
		v.apply_grid_config(config)
	_root.add_child(v)
	await process_frame
	await process_frame
	await process_frame
	return v


func _seed_total(v) -> int:
	var n := 0
	for k in v.get_state()["seeds"].values():
		n += int(k)
	return n


func _count_cubes(v) -> int:
	var n := 0
	var patch: Node = v.get_node("Patch")
	for c in patch.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is BoxMesh:
			n += 1
	return n


func _count_built(v) -> int:
	# organisms the dispatcher built: anything under Patch that is not ground, cover, cube or the dispatcher
	var n := 0
	var patch: Node = v.get_node("Patch")
	for c in patch.get_children():
		if c.name == "Ground" or c.name == "Dispatcher" or String(c.name).begins_with("CoverFoliage_"):
			continue
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is BoxMesh:
			continue
		n += 1
	return n


func _count_panes(v) -> int:
	var n := 0
	for c in v.get_node("Cage").get_children():
		if c is MeshInstance3D and c.get_child_count() > 0 and c.get_child(0) is StaticBody3D:
			n += 1
	return n


func _has_roof(v) -> bool:
	var s: float = float(v.size)
	for c in v.get_node("Cage").get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh is BoxMesh:
			var sz: Vector3 = ((c as MeshInstance3D).mesh as BoxMesh).size
			if sz.x > s - 0.2 and sz.z > s - 0.2 and sz.y < 0.1:
				return true
	return false


## rows in the lineage log (res:// first, else user://)
func _lineage_path() -> String:
	for p in ["res://ada_run/biome_lineage.jsonl", "user://biome_lineage.jsonl"]:
		if FileAccess.file_exists(p):
			return p
	return ""


func _lineage_rows() -> int:
	var p := _lineage_path()
	if p == "":
		return 0
	return FileAccess.get_file_as_string(p).split("\n", false).size()


func _lineage_of(session: String, run: String) -> Array:
	var out: Array = []
	var p := _lineage_path()
	if p == "":
		return out
	for line in FileAccess.get_file_as_string(p).split("\n", false):
		var v: Variant = JSON.parse_string(line)
		if v is Dictionary and String((v as Dictionary).get("session", "")) == session and (run == "" or String((v as Dictionary).get("run", "")) == run):
			out.append(v)
	return out


## do the two planes of the composition wear different colours?
func _planes_differ(v) -> bool:
	var a: MeshInstance3D = v.get_node_or_null("Patch/Garden/Faces/Plane_0")
	var b: MeshInstance3D = v.get_node_or_null("Patch/Garden/Faces/Plane_1")
	if a == null or b == null:
		return false
	var ma: StandardMaterial3D = a.material_override
	var mb: StandardMaterial3D = b.material_override
	return not ma.albedo_color.is_equal_approx(mb.albedo_color)


## the alpha of the first glass pane (a box with a StaticBody3D child) in the cage
func _glass_alpha(v) -> float:
	for c in v.get_node("Cage").get_children():
		if c is MeshInstance3D and c.get_child_count() > 0 and c.get_child(0) is StaticBody3D:
			var m: Material = (c as MeshInstance3D).material_override
			if m is StandardMaterial3D:
				return (m as StandardMaterial3D).albedo_color.a
	return -1.0


## every material under the patch is grey: r == g == b within a hair
func _all_grey(v) -> bool:
	var ok := true
	for n in v.get_node("Patch").find_children("*", "GeometryInstance3D", true, false):
		var m: Material = (n as GeometryInstance3D).material_override
		if m is StandardMaterial3D:
			var c: Color = (m as StandardMaterial3D).albedo_color
			if absf(c.r - c.g) > 0.02 or absf(c.g - c.b) > 0.02:
				ok = false
	return ok


func _count_labels(v) -> int:
	var n := 0
	for c in v.get_node("Cage").get_children():
		if c is Label3D:
			n += 1
	return n
