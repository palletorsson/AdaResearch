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
	_check(str(rs["kingdoms"]) == str(["flower", "tree", "fungus"]), "randomness: kingdoms")
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
