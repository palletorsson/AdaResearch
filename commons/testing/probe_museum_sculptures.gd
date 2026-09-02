extends SceneTree

## Does every hall get its dream body, and does the museum keep its own rules
## while doing it? (2026-08-29, Palle: "put them in the museum")
##
## Boots the museum at two chapters under a trial control, and for every hall
## built asserts:
##   one statue, from the six families, on a plinth, standing on the plinth's top
##   its cell is out of the walk map, marked "art:dream_bodies", so the walker
##     never plans a route through a sculpture
##   it stands at least sculptures.clear_m from the hall's save point
##   the FAMILY follows the chapter (one family per chapter) and the SEED does
##     not repeat between halls — a room of relatives, no twins
##   a hall dealt the relief hangs it on a wall instead of a plinth
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_museum_sculptures.gd

const MUSEUM := "res://commons/scenes/endless_museum.tscn"
const TRIAL := "res://ada_run/_trial_art_control.json"
const REPORT := "res://ada_run/museum_sculptures_probe.txt"
const FIGURES := ["rocaille", "stijl_robot", "panel_robot", "dragon", "sea_forms",
	"coral_polyp", "tube_reef", "david_drape", "dubuffet", "garet_still", "kruger_suit",
	"oni_dragon", "lava_bloom", "stella_wall"]

var _lines: Array[String] = []
var _fails: Array[String] = []
var _seeds: Dictionary = {}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	for chapter in ["primitives", "color"]:
		await _walk(chapter)
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


func _walk(chapter: String) -> void:
	var ctl := FileAccess.open(TRIAL, FileAccess.WRITE)
	ctl.store_string(JSON.stringify({"first_chapter": chapter, "dollhouse": 0, "grid_pack": 1}, " "))
	ctl.close()
	var inst: Node3D = (load(MUSEUM) as PackedScene).instantiate() as Node3D
	inst.set("EM_CONTROL", TRIAL)
	inst.set("_overrides_path", "res://ada_run/_trial_art_overrides.json")
	inst.set("_hand_path", "res://ada_run/_trial_art_hand.json")
	inst.set("start_chapter", chapter)
	inst.set("start_map", "")
	get_root().add_child(inst)
	await create_timer(1.0).timeout
	inst.set("MIN_SEGMENTS", 99)
	inst.set("KEEP_AHEAD_M", 99999.0)
	inst.set("KEEP_BEHIND_M", 99999.0)
	for i in range(3):
		if (inst.get("_segments") as Array).size() >= 3:
			break
		inst.call("_build_segment")
		await create_timer(0.3).timeout
	inst.call("flush_stamps")
	await create_timer(0.9).timeout    # the relief hangs one physics frame later
	var walk: Dictionary = inst.get("_walk_cells")
	var erased: Dictionary = inst.get("_walk_erased")
	var clear_m: float = float(inst.call("_L", "sculptures", "clear_m", 3.0))
	var plinth_m: float = float(inst.call("_L", "sculptures", "plinth_m", 0.42))
	var families: Dictionary = {}
	for s_v in (inst.get("_segments") as Array):
		var s: Dictionary = s_v
		var node: Node3D = s.get("node") as Node3D
		if node == null or not is_instance_valid(node):
			continue
		var ch: String = String(node.get_meta("em_chapter")) if node.has_meta("em_chapter") else ""
		var tag: String = "%s|%s" % [ch, str(node.get_meta("em_pearl")) if node.has_meta("em_pearl") else ""]
		if ch != chapter:
			continue
		var bodies: Array = []
		var plinths: int = 0
		for c in node.get_children():
			if c.has_meta("em_sculpture") and c is Node3D:
				bodies.append(c)
			if String(c.name).begins_with("ArtPlinth"):
				plinths += 1
		_check(bodies.size() == 1, "%s: %d statue(s)" % [tag, bodies.size()], "%s: not one statue" % tag)
		if bodies.is_empty():
			continue
		var b: Node3D = bodies[0]
		var fig: String = str(b.get("figure"))
		var sd: int = int(b.get("seed"))
		var p: Vector3 = b.global_position
		_check(FIGURES.has(fig), "%s: figure %s, seed %d, at %s" % [tag, fig, sd, str(p)], "%s: unknown figure" % tag)
		families[fig] = true
		_check(not _seeds.has(sd), "%s: seed %d is new" % [tag, sd], "%s: two halls share a seed" % tag)
		_seeds[sd] = true
		var meshes: Array = []
		_collect(b, meshes)
		_check(meshes.size() >= 40, "%s: %d mesh(es) built" % [tag, meshes.size()], "%s: the body did not build" % tag)
		if fig == "stella_wall":
			# a wall work: no plinth, and turned to face along x
			_check(plinths == 0 and absf(absf(b.rotation_degrees.y) - 90.0) < 1.0,
				"%s: relief on the wall (plinths %d, yaw %.0f)" % [tag, plinths, b.rotation_degrees.y], "%s: the relief took a plinth" % tag)
			continue
		_check(plinths == 1, "%s: %d plinth(s)" % [tag, plinths], "%s: no plinth" % tag)
		_check(absf(p.y - plinth_m) < 0.02, "%s: stands at y %.2f (plinth top %.2f)" % [tag, p.y, plinth_m], "%s: not on its plinth" % tag)
		var cell := Vector2i(int(floor(p.x)), int(floor(p.z)))
		_check(not walk.has(cell) and String(erased.get(cell, "")) == "art:dream_bodies",
			"%s: cell %s out of the walk map (%s)" % [tag, str(cell), String(erased.get(cell, "—"))], "%s: the walker can walk through it" % tag)
		var w: int = int(s.get("w", 0))
		var save := Vector2(float(w) / 2.0 + 0.5, float(s.get("z0", 0.0)) + 4.0 - 1.5)
		var d: float = Vector2(p.x, p.z).distance_to(save)
		_check(d >= clear_m - 0.01, "%s: %.2f m from the save point (clear_m %.1f)" % [tag, d, clear_m], "%s: a statue in the doorway" % tag)
	_check(families.size() == 1, "%s: %d family/families across its halls (%s)" % [chapter, families.size(), str(families.keys())], "%s: a chapter deals more than one family" % chapter)
	inst.queue_free()
	await create_timer(0.5).timeout


func _collect(n: Node, out: Array) -> void:
	if n is MeshInstance3D:
		out.append(n)
	for c in n.get_children():
		_collect(c, out)


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok:
		_fails.append(why)
