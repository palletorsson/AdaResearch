# FungusSdfMorphology.gd — a mushroom as ONE continuous SDF surface.
#
# FungusMorphology assembles a cap mesh + a stem mesh + gill meshes; where the
# cap meets the stem there can be a seam, and the gills are separate discs.
# This builder expresses the whole mushroom as a signed distance field:
# smin(stem tapered-capsule, cap ellipsoid) → one watertight skin, cap flowing
# into stem with no join. Meshed by SdfMesher (marching tetrahedra).
#
# DNA → form (same genes FungusMorphology reads):
#   part_length → stem height        part_width  → cap diameter
#   part_curve  → cap dome height     part_taper  → stem taper (base→top)
#   scale       → overall size        iridescence → glow
# Same build() signature as FungusMorphology, so the dispatcher can pick either.

class_name FungusSdfMorphology
extends RefCounted

const Mesher = preload("res://algorithms/nature_system/morphology/sdf_mesher.gd")

const RES_BY_LOD: Array = [16, 22, 30, 38]


static func build(dna: CritterDNA, parent: Node3D, _trait_mapper: CritterTraitMapper, lod: int = 2) -> Node3D:
	lod = clampi(lod, 0, 3)
	var root := Node3D.new()
	root.name = "FungusSDF"
	parent.add_child(root)

	var scale: float = maxf(dna.scale, 0.2)
	var stem_h: float = clampf(dna.part_length, 0.3, 1.4) * scale * 0.5
	var stem_r: float = clampf(dna.part_width, 0.3, 1.0) * scale * 0.06
	var stem_top_r: float = stem_r * clampf(1.0 - dna.part_taper * 0.5, 0.35, 1.0)
	var cap_r: float = clampf(dna.part_width, 0.3, 1.0) * scale * 0.18
	var cap_dome: float = cap_r * clampf(0.35 + dna.part_curve * 0.9, 0.3, 1.3)
	var cap_c := Vector3(0.0, stem_h, 0.0)
	var stem_a := Vector3.ZERO
	var stem_b := cap_c
	var k: float = cap_r * 0.5   # blend cap into stem

	var field := func(p: Vector3) -> float:
		var d_stem: float = Mesher.sd_capsule_tapered(p, stem_a, stem_b, stem_r, stem_top_r)
		# cap = a dome: an ellipsoid wide in XZ, short in Y, sitting on the stem
		var d_cap: float = Mesher.sd_ellipsoid(p, cap_c + Vector3(0, cap_dome * 0.2, 0),
			Vector3(cap_r, cap_dome, cap_r))
		return Mesher.smin(d_stem, d_cap, k)

	var lo := Vector3(-cap_r, -stem_r, -cap_r) - Vector3.ONE * cap_r * 0.5
	var hi := Vector3(cap_r, stem_h + cap_dome, cap_r) + Vector3.ONE * cap_r * 0.5
	var mesh: ArrayMesh = Mesher.mesh_field(field, lo, hi, RES_BY_LOD[lod])
	if mesh == null:
		return root

	var mi := MeshInstance3D.new()
	mi.name = "Mushroom"
	mi.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = dna.primary_color
	mat.roughness = clampf(dna.roughness, 0.4, 0.95)
	if dna.iridescence > 0.4:
		mat.emission_enabled = true
		mat.emission = dna.primary_color * 0.3
	mi.material_override = mat
	root.add_child(mi)
	return root
