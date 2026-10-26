extends SceneTree
## Probe: every field term's mesh asserted against the field that made it (26 Oct). For each term
## whose build is a field: (1) every vertex lies within one cell of the surface (signed-distance
## fields only: metaballs, blobs and terrain are not distances); (2) every edge is shared by exactly
## two triangles — a closed body; (3) the winding is outward: every edge is walked once each way
## (consistent), the signed volume says outward, and — by GODOT's convention — Plane(a, b, c).normal
## agrees with the field's gradient at the centroid for every triangle larger than a sliver — the
## few that do not are FOLDS (a facet tipped where a wall is a few cells thin), held under 1 %;
## (4) its connected bodies are counted. Then the CARVE test on bool_subtract (a sphere bored from a box): the box's far corner
## survives, nothing lies inside the cutter, vertices lie ON the cutter — and the same test must
## FAIL on the intersection of the same two, or it cannot tell a bore from its inverse.
##
##   python tools/godot_watchdog.py --expect=ada_run/field_probe.json --grace=120 --stall=90 -- \n##     godot --headless --path . --xr-mode off --script res://commons/testing/probe_field.gd
##   (the gyroid alone is ~95k triangles, each checked against the field: a term can take over 16 s)
## Report: res://ada_run/field_probe.json; the exit code is the number of failures.

const ModField := preload("res://commons/modular/mod_field.gd")
const TERMS := "res://commons/modular/terms.json"
const OUT := "res://ada_run/field_probe.json"
const NOT_DISTANCE := ["metaballs", "blobs", "terrain"]


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(TERMS))
	var report := {"terms": {}, "carve": {}}
	var fails := 0
	for id in doc["terms"]:
		var b: Dictionary = doc["terms"][id]["build"]
		if str(b.get("op", "")) != "field":
			continue
		var r := _check(b)
		report["terms"][id] = r
		fails += int(r["fails"])
		_write(report, fails)   # after every term: the watchdog sees progress, a kill keeps what was measured
		print("FIELD %s tris=%d far=%d open=%d nonmanifold=%d inconsistent=%d volume=%.4f inward=%d slivers=%d bodies=%d" % [id, r["triangles"], r["far_vertices"], r["open_edges"], r["nonmanifold_edges"], r["inconsistent_edges"], r["signed_volume"], r["inward"], r["slivers"], r["bodies"]])
	if doc["terms"].has("bool_subtract"):
		var sub: Dictionary = doc["terms"]["bool_subtract"]["build"]
		var parts: Array = sub["fn"]["subtract"]
		var bore := _carve(sub, parts[0], parts[1])
		var inv: Dictionary = sub.duplicate(true)
		inv["fn"] = {"intersect": [parts[0], parts[1]]}
		var inverse := _carve(inv, parts[0], parts[1])
		report["carve"] = {"bore": bore, "intersection_must_fail": inverse}
		if not bore["passes"]:
			fails += 1
		if inverse["passes"]:
			fails += 1   # the test cannot tell a bore from its inverse
		print("CARVE bore passes=%s  intersection passes=%s (must be false)" % [bore["passes"], inverse["passes"]])
	report["done"] = true
	_write(report, fails)
	print("FIELD_PROBE fails=%d" % fails)
	quit(fails)


func _write(report: Dictionary, fails: int) -> void:
	report["fails"] = fails
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(report, " "))
	f.close()


func _mesh(expr: Dictionary) -> Dictionary:
	var root: Node3D = ModField.build(expr)
	var mi: MeshInstance3D = root.get_node("surface")
	var out := {"meta": mi.get_meta("field"), "V": PackedVector3Array(), "I": PackedInt32Array()}
	if mi.mesh != null:
		var arrays := mi.mesh.surface_get_arrays(0)
		out["V"] = arrays[Mesh.ARRAY_VERTEX]
		out["I"] = arrays[Mesh.ARRAY_INDEX]
	root.free()
	return out


func _uses(f: Variant, keys: Array) -> bool:
	if f is Dictionary:
		for k in (f as Dictionary).keys():
			if keys.has(k) or _uses(f[k], keys):
				return true
	elif f is Array:
		for x in f:
			if _uses(x, keys):
				return true
	return false


func _check(expr: Dictionary) -> Dictionary:
	var m := _mesh(expr)
	var V: PackedVector3Array = m["V"]
	var I: PackedInt32Array = m["I"]
	var meta: Dictionary = m["meta"]
	var f: Dictionary = meta["fn"]
	var c: Vector3 = meta["center"]
	var h: Vector3 = meta["half"]
	var cs: float = meta["cell"]
	var far := 0
	if not _uses(f, NOT_DISTANCE):
		for v in V:
			if absf(ModField.capped(f, c, h, cs, v)) > cs:
				far += 1
	var edges := {}
	var directed := {}
	var inward := 0
	var slivers := 0
	var volume := 0.0
	var parent := range(V.size())
	for t in range(0, I.size(), 3):
		var ids := [I[t], I[t + 1], I[t + 2]]
		for e in [[ids[0], ids[1]], [ids[1], ids[2]], [ids[2], ids[0]]]:
			var key := "%d_%d" % [mini(e[0], e[1]), maxi(e[0], e[1])]
			edges[key] = int(edges.get(key, 0)) + 1
			var dkey := "%d>%d" % [e[0], e[1]]
			directed[dkey] = int(directed.get(dkey, 0)) + 1
		var a: Vector3 = V[ids[0]]
		var b: Vector3 = V[ids[1]]
		var cc: Vector3 = V[ids[2]]
		volume += a.dot(b.cross(cc)) / 6.0   # textbook orientation: negative when Godot's winding is outward
		var area: float = (b - a).cross(cc - a).length() * 0.5
		if area < 0.05 * cs * cs:
			slivers += 1
		else:
			# the field's own gradient at the centroid, at a twentieth of a cell: a 0.35-cell step went
			# THROUGH walls thinner than that (noise_blobs) and called a correct triangle inward
			var n: Vector3 = Plane(a, b, cc).normal
			var mid: Vector3 = (a + b + cc) / 3.0
			var e: float = cs * 0.05
			var g := Vector3(ModField.capped(f, c, h, cs, mid + Vector3(e, 0, 0)) - ModField.capped(f, c, h, cs, mid - Vector3(e, 0, 0)),
				ModField.capped(f, c, h, cs, mid + Vector3(0, e, 0)) - ModField.capped(f, c, h, cs, mid - Vector3(0, e, 0)),
				ModField.capped(f, c, h, cs, mid + Vector3(0, 0, e)) - ModField.capped(f, c, h, cs, mid - Vector3(0, 0, e)))
			if n.dot(g) <= 0.0:
				inward += 1
		_union(parent, ids[0], ids[1])
		_union(parent, ids[1], ids[2])
	var open_e := 0
	var multi := 0
	for k in edges:
		if edges[k] == 1:
			open_e += 1
		elif edges[k] > 2:
			multi += 1
	var inconsistent := 0   # an edge walked twice the same way: two neighbours disagree on which side is out
	for dk in directed:
		if directed[dk] > 1:
			inconsistent += 1
	var roots := {}
	for i in range(V.size()):
		roots[_find(parent, i)] = true
	# the winding is proven by consistency + volume; what the gradient test still catches is a FOLD — a
	# facet tipped over where a wall is a few cells thin. Measured, and held under 1 % of the facets
	var judged: int = I.size() / 3 - slivers
	var fold_rate: float = float(inward) / maxf(1.0, float(judged))
	var fails := int(I.size() == 0) + int(far > 0) + int(open_e > 0) + int(multi > 0) + int(inconsistent > 0) + int(volume >= 0.0) + int(fold_rate > 0.01)
	return {"triangles": I.size() / 3, "vertices": V.size(), "cell": cs, "far_vertices": far, "open_edges": open_e,
		"nonmanifold_edges": multi, "inconsistent_edges": inconsistent, "signed_volume": volume, "inward": inward,
		"fold_rate": fold_rate, "slivers": slivers, "bodies": roots.size(), "fails": fails}


func _carve(expr: Dictionary, body: Dictionary, cutter: Dictionary) -> Dictionary:
	var m := _mesh(expr)
	var V: PackedVector3Array = m["V"]
	var cs: float = m["meta"]["cell"]
	var bc := Vector3(float(body["at"][0]), float(body["at"][1]), float(body["at"][2]))
	var bh := Vector3(float(body["box"][0]), float(body["box"][1]), float(body["box"][2]))
	var sc := Vector3(float(cutter["at"][0]), float(cutter["at"][1]), float(cutter["at"][2]))
	var r: float = float(cutter["sphere"])
	# the corner of the box farthest from the cutter
	var far_corner := bc + Vector3(-signf(sc.x - bc.x) * bh.x, -signf(sc.y - bc.y) * bh.y, -signf(sc.z - bc.z) * bh.z)
	var near_far := false
	var inside := 0
	var on_cutter := 0
	for v in V:
		if v.distance_to(far_corner) < 2.0 * cs:
			near_far = true
		var d: float = v.distance_to(sc)
		if d < r - cs:
			inside += 1
		if absf(d - r) < cs and ModField.box_sdf(v - bc, bh) < cs:
			on_cutter += 1
	return {"far_corner_survives": near_far, "vertices_inside_cutter": inside, "vertices_on_cutter": on_cutter,
		"passes": near_far and inside == 0 and on_cutter > 10}


func _find(p: Array, i: int) -> int:
	while p[i] != i:
		p[i] = p[p[i]]
		i = p[i]
	return i


func _union(p: Array, a: int, b: int) -> void:
	var ra := _find(p, a)
	var rb := _find(p, b)
	if ra != rb:
		p[ra] = rb
