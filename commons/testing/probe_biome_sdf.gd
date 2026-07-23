# probe_biome_sdf.gd — the gate the SDF bodies never had.
#
# The SDF morphology system (creature / fungus / flora — one continuous
# smooth-unioned body meshed by SdfMesher's marching tetrahedra) shipped bugs
# caught by EYE with nothing locking them. This probe turns the ones that
# actually govern the LOOK into measured invariants over the real built meshes.
#
# HARD GATE (these are the visible contract for a double-sided decorative body):
#   OUTWARD   — signed volume V = (1/6)Σ v0·(v1×v2) must be > 0. A body encloses
#               positive volume only when every triangle faces out; the old
#               "see-through body" winding bug (d24676155) drove V toward zero /
#               negative. Locks the winding fix.
#   MANIFOLD  — no edge shared by >2 triangles. A grid-aligned body (the fungus
#               stem and creature head both sit at the origin) used to land edge
#               crossings ON grid vertices, welding several edges into one hub —
#               non-manifold, garbage averaged normals, speckle even double-sided.
#               The mesher's isolevel bias fixes it; this locks it at zero.
#   SOLID     — mesh non-null and a real vertex count (not a collapsed sliver).
#
# REPORTED, NOT FAILED — boundary edges (an edge with 1 triangle = a micro-crack).
# Marching-tetrahedra here is not conforming, so the skin carries a lattice of
# hairline cracks. They are INVISIBLE: every SDF skin is cull_mode = DISABLED
# (double-sided), so a crack shows the backface, not a hole. True closure would
# need a conforming re-mesh — tracked as a known simplification, not chased here.
# The probe prints the crack load so it is honest, never hidden.
#
# Runs standalone (no map, no dispatcher) — the mesher + morphology are where the
# bugs live.

extends SceneTree

const CreatureSdf = preload("res://algorithms/nature_system/morphology/creature_sdf_morphology.gd")
const FungusSdf = preload("res://algorithms/nature_system/morphology/fungus_sdf_morphology.gd")
const FloraSdf = preload("res://algorithms/nature_system/morphology/flora_sdf_morphology.gd")
const DNA = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const TraitMapper = preload("res://algorithms/nature_system/dna/critter_trait_mapper.gd")

var _fail: int = 0


func _init() -> void:
	var mapper: CritterTraitMapper = TraitMapper.new()

	print("── probe_biome_sdf ──")
	# creature grub — mirrors the dispatcher's biome recipe (compact walker)
	var grub: CritterDNA = DNA.new()
	grub.body_type = 1.0
	grub.segments = 5.5
	grub.scale = 0.9
	grub.part_length = 0.39
	grub.part_width = 0.94
	grub.part_curve = 0.35
	grub.part_taper = 0.8
	grub.symmetry = 3.0
	grub.mobility = 0.9
	grub.branch_angle = 30.0
	grub.primary_color = Color(0.7, 0.5, 0.4)
	grub.iridescence = 0.2
	grub.roughness = 0.6

	# fungus — mirrors _spawn_sdf_organism's derived mushroom DNA
	var shroom: CritterDNA = DNA.new()
	shroom.body_type = 3.0
	shroom.scale = 1.0
	shroom.part_length = 0.9
	shroom.part_width = 0.9
	shroom.part_curve = 0.7
	shroom.part_taper = 0.5
	shroom.primary_color = Color.from_hsv(0.09, 0.35, 0.85)
	shroom.roughness = 0.6

	# flora — a branching tree DNA
	var tree: CritterDNA = DNA.new()
	tree.body_type = 0.0
	tree.segments = 5.0
	tree.scale = 1.0
	tree.part_length = 0.9
	tree.part_width = 0.8
	tree.branch_angle = 35.0
	tree.part_curve = 0.4
	tree.primary_color = Color(0.4, 0.28, 0.18)
	tree.secondary_color = Color(0.2, 0.5, 0.2)

	# LODs 2 and 3 are what the biome spawns for t>=3; LOD 1 probes the thin-
	# feature edge case (the invisible-body bug lived at low res).
	_probe("creature", CreatureSdf, grub, mapper, [1, 2, 3])
	_probe("fungus", FungusSdf, shroom, mapper, [1, 2, 3])
	_probe("flora", FloraSdf, tree, mapper, [1, 2, 3])

	print("PROBE " + ("PASS" if _fail == 0 else "FAIL (%d)" % _fail))
	quit(0 if _fail == 0 else 1)


func _probe(label: String, cls, dna: CritterDNA, mapper: CritterTraitMapper, lods: Array) -> void:
	for lod in lods:
		var holder := Node3D.new()
		root.add_child(holder)
		var built: Node3D = cls.build(dna, holder, mapper, lod)
		var meshes: Array = _collect_meshes(built if built != null else holder)
		if meshes.is_empty():
			_bad("%s lod%d: NO mesh built" % [label, lod])
			holder.free()
			continue
		# aggregate every SDF surface this body produced (flora has trunk+canopy)
		var v_total: int = 0
		var boundary: int = 0
		var nonman: int = 0
		var volume: float = 0.0
		for m in meshes:
			var r: Dictionary = _inspect(m)
			v_total += int(r["verts"])
			boundary += int(r["boundary"])
			nonman += int(r["nonmanifold"])
			volume += float(r["volume"])
		# hard gate = the visible contract; boundary cracks are reported, not failed
		var ok: bool = v_total > 200 and nonman == 0 and volume > 0.0
		if not ok:
			_fail += 1
		var skin: String = "watertight" if boundary == 0 else "double-sided (%d crack edges)" % boundary
		var tag: String = "  ok   " if ok else "  FAIL "
		print("%s%s lod%d — %d verts, %d surf, V=%.5f %s, %s%s" % [
			tag, label, lod, v_total, meshes.size(), volume,
			"outward" if volume > 0.0 else "INWARD/DEGENERATE",
			skin, (", %d NON-MANIFOLD" % nonman) if nonman > 0 else ""])
		holder.free()


func _collect_meshes(n: Node) -> Array:
	# only ArrayMesh surfaces — the SDF skins. SphereMesh eyes are excluded on
	# purpose: they sit ON the body as a detail, not part of the closed field.
	var out: Array = []
	if n is MeshInstance3D and (n as MeshInstance3D).mesh is ArrayMesh:
		out.append((n as MeshInstance3D).mesh)
	for c in n.get_children():
		out.append_array(_collect_meshes(c))
	return out


func _inspect(mesh: ArrayMesh) -> Dictionary:
	var arrays: Array = mesh.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var idx: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	if idx.is_empty():
		# non-indexed: sequential triples
		idx = PackedInt32Array()
		for i in range(verts.size()):
			idx.append(i)
	var edges: Dictionary = {}
	var volume: float = 0.0
	var ti: int = 0
	while ti + 2 < idx.size():
		var a: int = idx[ti]
		var b: int = idx[ti + 1]
		var c: int = idx[ti + 2]
		ti += 3
		var va: Vector3 = verts[a]
		var vb: Vector3 = verts[b]
		var vc: Vector3 = verts[c]
		volume += va.dot(vb.cross(vc)) / 6.0
		for e in [[a, b], [b, c], [c, a]]:
			var lo: int = mini(e[0], e[1])
			var hi: int = maxi(e[0], e[1])
			var key: int = lo * 1000000 + hi
			edges[key] = int(edges.get(key, 0)) + 1
	var boundary: int = 0
	var nonman: int = 0
	for k in edges:
		var cnt: int = int(edges[k])
		if cnt == 1:
			boundary += 1
		elif cnt > 2:
			nonman += 1
	return {"verts": verts.size(), "boundary": boundary, "nonmanifold": nonman, "volume": volume}


func _bad(msg: String) -> void:
	_fail += 1
	print("  FAIL " + msg)
