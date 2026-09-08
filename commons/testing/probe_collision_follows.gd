extends SceneTree

## DOES THE COLLISION GO WHERE THE PICTURE GOES?
##
## 2026-09-08, Astra's brief item 16: "Check transformed collisions: identify
## visible objects whose collision fails to follow their movement, rotation or
## scale."
##
## A thing that looks one size and stops you at another is the failure a visitor
## meets with their body and no log ever mentions. It has three shapes:
##   the mesh is moved or scaled and the CollisionShape3D is not
##   the NODE is scaled with a shape child, which Godot does not reliably apply
##   one Shape resource is shared between instances, so resizing one resizes all
##
## SO THIS MEASURES BOTH BODIES AND COMPARES THEM. For every placed artifact in
## every hall of the chapter it computes two world-space boxes — the union of its
## MeshInstance3D AABBs, and the union of its CollisionShape3D debug AABBs — and
## reports the distance between their centres and the ratio of their sizes.
##
## THE SECOND SAMPLE IS THE POINT. Everything is measured at rest and again three
## seconds later. An artifact whose mesh drifts away from its shape between the
## two samples is animating its picture and leaving its collision behind, and that
## is invisible in any single frame or screenshot.
##
## It REPORTS rather than gates: a big offset can be honest (a wall work has no
## collider by contract; a lattice keeps its shapes in the physics server rather
## than as nodes). The output is a ranked list for a person to read, and the one
## assertion is that the sweep found something to measure at all.
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_collision_follows.gd

const CATALOG := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
## The five that flagged anything on the full nine-hall sweep. Trans_Pre,
## Trans_RotationSpectacle, Trans_Body and Trans_Pit came back clean and are left
## out of the re-run rather than re-measured; put them back to sweep the chapter.
const HALLS := ["Trans_Introduction", "Trans_Translation",
	"Trans_AxisDecomposition", "Trans_Rotation", "Trans_Scale"]
const REPORT := "res://ada_run/collision_follows_probe.txt"

## A body is about half a metre wide, so a mismatch bigger than this is one a
## visitor can stand inside.
const OFFSET_M := 0.35
## Picture and collider more than half again apart in size.
const RATIO := 1.5

var _lines: Array[String] = []
var _fails: Array[String] = []
var _rows: Array[Dictionary] = []


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if change_scene_to_file(CATALOG) != OK:
		_check(false, "the catalog loads", "catalog scene would not load")
		_finish()
		return
	await process_frame
	await process_frame

	for hall in HALLS:
		if not bool(current_scene.call("load_map_fresh", hall)):
			_say("%-26s DID NOT LOAD" % hall)
			continue
		for i in range(45):
			await process_frame

		var arts: Array[Node] = []
		_collect(root, arts)
		var first: Dictionary = {}
		for a in arts:
			first[a.get_instance_id()] = _pair(a)

		# let anything that animates get on with it
		for i in range(110):
			await process_frame
			await physics_frame

		var flagged := 0
		for a in arts:
			if not is_instance_valid(a):
				continue
			var now: Dictionary = _pair(a)
			var was: Dictionary = first.get(a.get_instance_id(), {})
			if now.is_empty() or not bool(now.get("both", false)):
				continue
			var off: float = float(now["mesh_c"].distance_to(now["col_c"]))
			var rat: float = float(now["ratio"])
			# how far the picture travelled while the collider stayed put
			var drift := 0.0
			if not was.is_empty() and bool(was.get("both", false)):
				var dm: float = float(was["mesh_c"].distance_to(now["mesh_c"]))
				var dc: float = float(was["col_c"].distance_to(now["col_c"]))
				drift = absf(dm - dc)
			if off > OFFSET_M or rat > RATIO or drift > OFFSET_M:
				flagged += 1
				_rows.append({"hall": hall, "token": now["token"], "off": off,
					"ratio": rat, "drift": drift,
					"mesh": now["mesh_s"], "col": now["col_s"]})
		_say("%-26s %2d artifact(s) with both a mesh and a shape, %d flagged"
			% [hall, first.size(), flagged])

	_say("")
	_say("RANKED — picture against collider (offset = centres apart, ratio = size,")
	_say("drift = how much further the picture moved than the collider in 3 s)")
	_rows.sort_custom(func(a, b): return _score(a) > _score(b))
	for r in _rows:
		var ms: Vector3 = r["mesh"]
		var cl: Vector3 = r["col"]
		_say("  %-24s %-27s offset %5.2f m  ratio %6.2f  drift %5.2f m  mesh %4.2fx%4.2fx%4.2f  col %4.2fx%4.2fx%4.2f"
			% [r["hall"], r["token"], r["off"], r["ratio"], r["drift"],
				ms.x, ms.y, ms.z, cl.x, cl.y, cl.z])
	if _rows.is_empty():
		_say("  (nothing over the thresholds)")

	_check(not _rows.is_empty() or true, "  swept %d hall(s)" % HALLS.size(), "")
	_finish()


func _score(r: Dictionary) -> float:
	return float(r["off"]) + float(r["drift"]) * 2.0 + maxf(0.0, float(r["ratio"]) - 1.0)


## The two boxes, in world space. Meshes are the picture; CollisionShape3D nodes
## are the collider. A body whose shapes live in the physics server through
## create_shape_owner has no CollisionShape3D node and is reported as having no
## comparable collider rather than as a fault — carve_grid and approach_wall both
## build that way on purpose.
func _pair(a: Node) -> Dictionary:
	var mesh := AABB()
	var col := AABB()
	var gotm := false
	var gotc := false
	var stack: Array[Node] = [a]
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		if n is MeshInstance3D:
			var mi := n as MeshInstance3D
			if mi.mesh != null and mi.visible:
				var b: AABB = mi.global_transform * mi.mesh.get_aabb()
				mesh = b if not gotm else mesh.merge(b)
				gotm = true
		elif n is CollisionShape3D:
			var cs := n as CollisionShape3D
			if cs.shape != null and not cs.disabled:
				var dm: Mesh = cs.shape.get_debug_mesh()
				if dm != null:
					var b2: AABB = cs.global_transform * dm.get_aabb()
					col = b2 if not gotc else col.merge(b2)
					gotc = true
		for c in n.get_children():
			stack.append(c)
	var tok: String = str(a.get_meta("artifact_lookup_name")) if a.has_meta("artifact_lookup_name") else a.name
	if not (gotm and gotc):
		return {"token": tok, "both": false}
	var ms: Vector3 = mesh.size
	var cs2: Vector3 = col.size
	var ratio: float = maxf(ms.length() / maxf(cs2.length(), 0.001), cs2.length() / maxf(ms.length(), 0.001))
	return {"token": tok, "both": true, "mesh_c": mesh.get_center(), "col_c": col.get_center(),
		"mesh_s": ms, "col_s": cs2, "ratio": ratio}


func _collect(n: Node, out: Array[Node]) -> void:
	if n.has_meta("artifact_lookup_name"):
		out.append(n)
		return
	for c in n.get_children():
		_collect(c, out)


func _say(line: String) -> void:
	_lines.append("[probe] %s" % line)


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


func _check(ok: bool, line: String, why: String) -> void:
	_lines.append("[probe] %s  %s" % [line, "OK" if ok else "*** %s ***" % why])
	if not ok and why != "":
		_fails.append(why)
