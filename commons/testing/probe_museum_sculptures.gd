extends SceneTree

## Does every hall get its dream body, and does the museum keep its own rules
## while doing it? (2026-08-29, Palle: "put them in the museum")
##
## Boots the museum at two chapters under a trial control, and for every hall
## built asserts:
##   one statue, from a family that has a builder on disk, on a plinth, standing
##     on the plinth's top, carrying enough geometry to be a body — many parts or
##     one marched surface, see _body_ok()
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
const BODY_DIR := "res://commons/artifacts/dream_bodies/bodies/"

## THE FAMILY LIST IS READ OFF DISK, NOT WRITTEN DOWN HERE (2026-09-03).
## This probe used to carry its own copy of the names — 37 of them, a third
## transcription of a fact that already lived in bodies/ and in dream_bodies.gd.
## It is used below for one thing: deciding whether the figure a hall dealt is a
## family the project HAS. A hand-typed list gets that wrong in the silent
## direction — a family added after the list was typed reads as "unknown figure"
## and the probe fails a hall that is perfectly correct. That is exactly what
## fetish_idol would have done here on the day it was pinned into a chapter.
## bodies/ is the truth; adding a file there is adding a family.
##
## NOTE the museum's own SCULPT_FIGURES (endless_museum.gd) is deliberately NOT
## this list and must not be made to match it: the family a chapter deals is
## `allowed[hash(chapter) % allowed.size()]`, so appending one name reassigns the
## statue in every chapter at once and stales the whole bake. New families reach
## the museum by a per-chapter PIN instead. So this probe checks that a dealt
## figure EXISTS, never that every family is dealt.
const MIN_FAMILIES := 40   # bodies/ held 42 on 2026-09-03

## The mesh-count floor that used to live at `meshes.size() >= 40` is gone; see
## _body_ok() below for what replaced it and why.
## THE SAME FOUR NUMBERS probe_dream_bodies.gd derives and prints. They are
## repeated rather than imported because these two probes boot different scenes
## and neither should load the other; if they ever disagree, that probe is the
## one that measured them. MIN_BIG_MESH_TRIS in particular sits between two
## measured values — 4,224 (a stock SphereMesh, so no off-the-shelf primitive can
## pass for a marched body) and 6,532 (fetish_idol at the coarsest cell its own
## clamp allows the museum to hand it, which is the thinnest marched body that
## can ever reach a hall).
const MAX_MESHES := 260
const MIN_MESHES := 30
const MIN_TRIS := 400
const MIN_BIG_MESH_TRIS := 5000

var _lines: Array[String] = []
var _fails: Array[String] = []
var _seeds: Dictionary = {}
var _figures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_figures = _families()
	# A DIRECTORY READ HAS A FAILURE MODE A CONST DOES NOT: it can come back
	# EMPTY, and then every "is this a known figure" test below compares against
	# nothing. That direction fails loudly here rather than quietly there.
	_check(_figures.size() >= MIN_FAMILIES,
		"%d families read from %s" % [_figures.size(), BODY_DIR],
		"bodies/ yielded %d families, expected at least %d — every figure the museum deals would read as unknown" % [_figures.size(), MIN_FAMILIES])
	if _figures.size() < MIN_FAMILIES:
		_finish()
		return
	for chapter in ["primitives", "color"]:
		await _walk(chapter)
	_finish()


func _finish() -> void:
	var ok: bool = _fails.is_empty()
	_lines.append("[probe] %s%s" % ["PASS" if ok else "FAIL", "" if ok else " — " + ", ".join(_fails)])
	var f := FileAccess.open(REPORT, FileAccess.WRITE)
	if f != null:
		f.store_string(String.chr(10).join(PackedStringArray(_lines)) + String.chr(10))
		f.close()
	for l in _lines:
		print(l)
	quit(0 if ok else 1)


## bodies/ is the family list. Reads .gd and, so an exported build measures the
## same corpus as a run from source, .gd.remap — in a .pck the script itself is
## packed and only the remap stub is visible to DirAccess.
func _families() -> Array[String]:
	var out: Array[String] = []
	for f in DirAccess.get_files_at(BODY_DIR):
		var n: String = String(f)
		if n.ends_with(".gd.remap"):
			n = n.substr(0, n.length() - 6)
		if not n.ends_with(".gd"):
			continue      # skips the .gd.uid siblings, which do not end in .gd
		out.append(n.substr(0, n.length() - 3))
	out.sort()
	return out


## DID A BODY ACTUALLY BUILD ON THIS PLINTH? (2026-09-03)
## This line used to read `meshes.size() >= 40`, and it was right while every
## dream body was a stack of primitives: a hall with fewer than 40 MeshInstance3D
## under its statue node had a plinth and nothing on it.
##
## Two things broke it on the same day. fetish_idol is ONE marched isosurface
## plus a slab — TWO meshes, ~15,000 triangles — and 40 would have failed it. And
## the museum now deals AXIS VALUES per hall (_sculpt_axis_deal in
## endless_museum.gd), so eleven older families also stand at their marched value
## in real halls: measured on the bench, vasarely_beast tube=fused drops from 54
## meshes to 42 and clay_splash clay=fused from 111 to 45. The old floor sat two
## meshes under a body the museum was already standing.
##
## So the floor moved off the count and onto the geometry: a body is MANY PARTS
## or ONE BIG SURFACE, it carries triangles either way, and it still fits the
## draw-call budget. An empty plinth is 0 meshes and 0 triangles and fails every
## arm; the ArtPlinth itself is a sibling node, not a child of the statue, so it
## cannot pad these numbers. Constants and their headroom are derived in
## probe_dream_bodies.gd, which measures all 42 families at two seeds and prints
## the two extremes on its last line — including fetish_idol at the coarsest cell
## the museum is allowed to hand it, which is what MIN_BIG_MESH_TRIS sits under.
func _body_ok(meshes: Array) -> Dictionary:
	var tris: int = 0
	var big: int = 0
	for mi_v in meshes:
		var mi: MeshInstance3D = mi_v
		if mi.mesh == null:
			continue
		var t: int = mi.mesh.get_faces().size() / 3
		tris += t
		big = maxi(big, t)
	var n: int = meshes.size()
	var ok: bool = n <= MAX_MESHES and tris >= MIN_TRIS \
		and (n >= MIN_MESHES or big >= MIN_BIG_MESH_TRIS)
	return {"ok": ok, "n": n, "tris": tris, "big": big}


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
		_check(_figures.has(fig), "%s: figure %s, seed %d, at %s" % [tag, fig, sd, str(p)],
			"%s: figure %s has no builder in %s" % [tag, fig, BODY_DIR])
		families[fig] = true
		_check(not _seeds.has(sd), "%s: seed %d is new" % [tag, sd], "%s: two halls share a seed" % tag)
		_seeds[sd] = true
		var meshes: Array = []
		_collect(b, meshes)
		var body: Dictionary = _body_ok(meshes)
		_check(bool(body["ok"]),
			"%s: %d mesh(es), %d triangles, biggest %d" % [tag, int(body["n"]), int(body["tris"]), int(body["big"])],
			("%s: the body did not build — %d mesh(es), %d triangles, biggest mesh %d. "
				+ "Wanted at most %d meshes, at least %d triangles, and either %d+ meshes or "
				+ "a single mesh of %d+ triangles (an empty plinth is 0 and 0).")
				% [tag, int(body["n"]), int(body["tris"]), int(body["big"]),
					MAX_MESHES, MIN_TRIS, MIN_MESHES, MIN_BIG_MESH_TRIS])
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
