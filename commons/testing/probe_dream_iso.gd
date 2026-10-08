extends SceneTree

## Does the iso source actually mesh a field, and is the surface the field said?
## (2026-09-03)
##
## dream_iso.gd marches tetrahedra over a composed SDF. Every failure mode of
## that algorithm is silent in a screenshot: a winding bug makes half the
## triangles face inward (the body photographs with holes in it and reads as a
## style choice), an interpolation bug puts the surface a whole cell off (the
## statue is simply fatter than asked), a table typo drops one tet case (pinholes
## nobody counts). So the geometry is measured against the field it came from,
## which is the one thing a picture cannot check:
##
##   a sphere of r 0.30 meshes, and EVERY vertex lies within a cell of |p| = 0.30
##   the mesh is closed: every edge is shared by exactly two triangles
##   normals point OUT: for a sphere, dot(normal, p) > 0 on every triangle
##   a smooth union of two spheres is ONE surface, and it is fatter at the waist
##     than either sphere alone (the fillet exists)
##   a subtracted torus leaves a hole: no vertex inside the carved ring
##   the field's own zero crossing agrees with the mesh's AABB
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_dream_iso.gd

const Iso := preload("res://commons/artifacts/dream_bodies/dream_iso.gd")
const Gloss := preload("res://commons/artifacts/dream_bodies/dream_skin.gd")
const REPORT := "res://ada_run/dream_iso_probe.txt"

var _lines: Array[String] = []
var _fails: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cell: float = 0.05

	# ── 1. a sphere, measured against its own radius ────────────────────
	var sphere_parts: Array = [Iso.sphere(Vector3.ZERO, 0.30)]
	var m1: ArrayMesh = Iso.mesh_of(sphere_parts, cell, 0.0)
	_check(m1 != null, "a sphere meshes: %s" % ("yes" if m1 != null else "NOTHING"), "the mesher returned nothing")
	if m1 == null:
		_finish()
		return
	var arr: Array = m1.surface_get_arrays(0)
	var verts: PackedVector3Array = arr[Mesh.ARRAY_VERTEX]
	var norms: PackedVector3Array = arr[Mesh.ARRAY_NORMAL]
	_check(verts.size() >= 300, "%d vertices" % verts.size(), "too few vertices to be a sphere")
	var worst: float = 0.0
	for v in verts:
		worst = maxf(worst, absf(v.length() - 0.30))
	_check(worst <= cell * 1.05, "worst vertex is %.4f m off the true surface (cell %.3f)" % [worst, cell],
		"the surface is not where the field says it is")

	# normals out
	var out_ok: int = 0
	for i in range(verts.size()):
		if norms[i].dot(verts[i].normalized()) > 0.0:
			out_ok += 1
	_check(out_ok == verts.size(), "normals outward %d/%d" % [out_ok, verts.size()], "some triangles face inward")

	# closed: every edge shared exactly twice
	var edges: Dictionary = {}
	for i in range(0, verts.size(), 3):
		for e in [[i, i + 1], [i + 1, i + 2], [i + 2, i]]:
			var a: Vector3 = verts[int(e[0])].snapped(Vector3(0.0001, 0.0001, 0.0001))
			var b: Vector3 = verts[int(e[1])].snapped(Vector3(0.0001, 0.0001, 0.0001))
			var key: String = "%s|%s" % [str(a), str(b)] if str(a) < str(b) else "%s|%s" % [str(b), str(a)]
			edges[key] = int(edges.get(key, 0)) + 1
	var open_edges: int = 0
	for k in edges:
		if int(edges[k]) != 2:
			open_edges += 1
	_check(open_edges == 0, "%d open edge(s) of %d" % [open_edges, edges.size()], "the surface is not closed")

	# ── 2. the fillet: two spheres, smoothly joined ─────────────────────
	var two: Array = [Iso.sphere(Vector3(-0.16, 0, 0), 0.20), Iso.sphere(Vector3(0.16, 0, 0), 0.20)]
	var hard: ArrayMesh = Iso.mesh_of(two, cell, 0.0)
	var soft: ArrayMesh = Iso.mesh_of(two, cell, 0.14)
	_check(hard != null and soft != null, "two spheres mesh both ways", "the union did not mesh")
	if hard != null and soft != null:
		# at the waist (x = 0) the blended surface must be FATTER
		var hr: float = _waist(hard)
		var sr: float = _waist(soft)
		_check(sr > hr + 0.01, "waist radius hard %.3f -> blended %.3f m" % [hr, sr], "the blend did not fillet")

	# ── 3. a carved hole ────────────────────────────────────────────────
	#
	# THE FIRST VERSION OF THIS TEST WAS VACUOUS AND PASSED A SIGN ERROR. It cut a
	# TORUS from a slab and asserted that no vertex sat at radius 0.14 with
	# |z| < 0.02 — but a torus of minor radius 0.05 has no surface there under
	# EITHER behaviour: at z = 0 its surface is at radius 0.09 and 0.19, and at
	# radius 0.14 it is at z = +-0.05. So the check could not tell a bored hole
	# from its exact inverse, and `cut()` shipped keeping only the hole.
	#
	# A carve test has to assert BOTH halves: the body is still there, and the
	# cutter's interior is not. A sphere through a box says both in one shape.
	var carved: Array = [Iso.box(Vector3.ZERO, Vector3(0.30, 0.30, 0.10), 0.02),
		Iso.cut(Iso.sphere(Vector3(0.10, 0.0, 0.0), 0.16))]
	var m3: ArrayMesh = Iso.mesh_of(carved, cell, 0.05)
	_check(m3 != null, "the carved slab meshes", "carving produced nothing")
	if m3 != null:
		var vs: PackedVector3Array = m3.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		# the slab survives: its far corner is untouched by a hole on the near side
		var far: float = -1.0e9
		var inside: int = 0
		for v in vs:
			far = maxf(far, -v.x)
			# strictly inside the cutter, allowing one cell for the blend's lip
			if (v - Vector3(0.10, 0.0, 0.0)).length() < 0.16 - cell * 1.5:
				inside += 1
		_check(far > 0.25, "the slab keeps its far edge (x reaches -%.2f m of -0.30)" % far,
			"the cut ate the body — this is an INTERSECTION, not a subtraction")
		_check(inside == 0, "%d vertex/vertices sit inside the cutter" % inside, "the cut did not carve")
		# and the hole's wall must actually be on the sphere
		var on_wall: int = 0
		for v in vs:
			if absf((v - Vector3(0.10, 0.0, 0.0)).length() - 0.16) < cell * 1.2:
				on_wall += 1
		_check(on_wall > 20, "%d vertices lie on the hole's wall" % on_wall,
			"nothing was bored: no surface follows the cutter")

	# ── 4. the gloss library ────────────────────────────────────────────
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var bad: Array[String] = []
	for f in Gloss.FINISHES:
		var mat: StandardMaterial3D = Gloss.skin(String(f), Color(1.0, 0.2, 0.6), rng)
		if mat == null:
			bad.append(String(f))
	_check(bad.is_empty(), "%d finish(es) build" % Gloss.FINISHES.size(), "a finish returned nothing: " + ", ".join(bad))
	var kit: Dictionary = Gloss.outfit(rng)
	_check(kit.has("skin") and kit["skin"] is StandardMaterial3D and String(kit.get("finish", "")) != "",
		"an outfit deals a finish (%s) and two materials" % String(kit.get("finish", "?")), "outfit is incomplete")
	# the loud ones must actually be loud: emission on, and a texture where claimed
	var holo: StandardMaterial3D = Gloss.skin("holo", Color(1.0, 0.2, 0.6), rng)
	_check(holo.emission_enabled and holo.albedo_texture != null and holo.uv1_triplanar,
		"holo: emission %s, sweep texture %s, triplanar %s" % [str(holo.emission_enabled),
			str(holo.albedo_texture != null), str(holo.uv1_triplanar)], "holo is not holographic")
	var chrome: StandardMaterial3D = Gloss.skin("chrome", Color(0.8, 0.8, 0.9), rng)
	_check(chrome.metallic >= 0.99 and chrome.albedo_texture != null,
		"chrome: metallic %.2f with a brushed texture (so it cannot photograph black)" % chrome.metallic,
		"chrome has nothing to be bright with")
	_finish()


## The mesh's radius in the y-z plane near x = 0 — the waist of a two-sphere union.
func _waist(m: ArrayMesh) -> float:
	var best: float = 0.0
	for v in (m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array):
		if absf(v.x) < 0.02:
			best = maxf(best, Vector2(v.y, v.z).length())
	return best


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
	if not ok:
		_fails.append(why)
