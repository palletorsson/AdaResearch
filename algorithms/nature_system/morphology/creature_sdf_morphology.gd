# CreatureSdfMorphology.gd — the creature body as ONE continuous surface.
#
# The segmented builder (CreatureMorphology) chains a separate tube mesh per
# spine segment; the tubes don't merge at joints and limbs poke out as their
# own meshes, so the body reads with gaps — the "holes". This builder keeps
# the SAME spine (position + radius per point) but expresses the body as a
# signed distance field: a smooth-union (smin) of tapered capsules between
# consecutive spine points plus a head sphere. The field has no joints, so its
# surface — meshed by SdfMesher (marching tetrahedra) — is one watertight skin.
#
# Same signature as CreatureMorphology.build, so the dispatcher can pick either.
# Limbs are added to the FIELD as short blended nubs (they melt into the body
# instead of intersecting it), so even the appendages are seamless.

class_name CreatureSdfMorphology
extends RefCounted

const SpineSource = preload("res://algorithms/nature_system/morphology/creature_morphology.gd")
const Mesher = preload("res://algorithms/nature_system/morphology/sdf_mesher.gd")

# grid resolution by LOD. Higher than before: a thin-necked grub needs enough
# cells that the neck/tail are captured (each feature clamped to >=1.6 cells).
const RES_BY_LOD: Array = [24, 32, 42, 52]


static func build(dna: CritterDNA, parent: Node3D, trait_mapper: CritterTraitMapper, lod: int = 2) -> Node3D:
	lod = clampi(lod, 0, 3)
	var root := Node3D.new()
	root.name = "CreatureSDF"
	parent.add_child(root)

	var spine: Array = SpineSource._build_spine(dna, lod)
	if spine.size() < 2:
		return root

	# body radius sets the blend amount
	var max_r: float = 0.0
	for s in spine:
		max_r = maxf(max_r, float((s as Dictionary)["radius"]))
	if max_r <= 0.0:
		max_r = 0.05
	var head_c: Vector3 = spine[0]["position"]
	var head_r: float = float(spine[0]["radius"]) * 1.35   # a rounded head bulge
	var legs: Array = _leg_nubs(dna, spine)
	var smooth_k: float = max_r * 0.9

	# DECLARE the body as primitives; SdfMesher.mesh_primitives clamps every
	# radius to the sample grid and caps the resolution — the two laws that used
	# to live here and that the tree builder once forgot. This body cannot forget
	# them because it no longer owns them.
	var prims: Array = [{"kind": "sphere", "c": head_c, "r": head_r}]
	for i in range(spine.size() - 1):
		prims.append({"kind": "capsule",
			"a": spine[i]["position"], "b": spine[i + 1]["position"],
			"ra": float(spine[i]["radius"]), "rb": float(spine[i + 1]["radius"])})
	for leg in legs:
		prims.append({"kind": "capsule", "a": leg["a"], "b": leg["b"],
			"ra": float(leg["r"]), "rb": float(leg["r"])})
	var mesh: ArrayMesh = Mesher.mesh_primitives(prims, smooth_k, RES_BY_LOD[lod])
	if mesh == null:
		return root

	var mi := MeshInstance3D.new()
	mi.name = "Body"
	mi.mesh = mesh
	# THE BODY BREATHES. The DNA shader carries vertex animation the whole nature
	# system already uses — breathing along the normal, body undulation scaled by
	# mobility, tension shimmer from volatility — and CritterTraitMapper sets all
	# of it per kingdom. The SDF builders were the only organisms handing back a
	# plain StandardMaterial3D, so they were the only ones standing perfectly
	# still. The shader is `cull_disabled`, which is the same double-siding the
	# static skin needed ("never see-through"), so nothing regresses there.
	# It is GPU/TIME-driven, so it costs no per-frame CPU and keeps animating even
	# when chunk_lod freezes a distant organism's process_mode.
	mi.material_override = _skin(dna, trait_mapper)
	root.add_child(mi)

	# eyes still read the head — two small spheres on the head bulge (they sit
	# ON the continuous body, a deliberate detail, not a seam)
	_add_eyes(root, dna, head_c, head_r, spine)
	return root


static func _leg_nubs(dna: CritterDNA, spine: Array) -> Array:
	# short paired capsules splaying down/out from mid-body segments; they blend
	# into the body via smin so there is no attachment seam. Count from symmetry.
	var out: Array = []
	var pairs: int = clampi(roundi(dna.symmetry), 0, 4)
	if pairs == 0 or dna.mobility < 0.15:
		return out
	var splay: float = 0.35 + 0.5 * clampf(dna.branch_angle / 60.0, 0.0, 1.0)
	for i in range(1, spine.size() - 1):
		if i % 2 == 1:
			continue  # every other segment carries legs
		var c: Vector3 = spine[i]["position"]
		var r: float = float(spine[i]["radius"])
		var leg_len: float = r * (2.2 + 2.0 * dna.part_length)
		var leg_r: float = maxf(r * 0.35, 0.006)
		for side in [-1.0, 1.0]:
			var dir := Vector3(side, -0.55, 0.0).normalized()
			dir = dir.lerp(Vector3(side, -0.2, 0.0).normalized(), splay).normalized()
			out.append({"a": c, "b": c + dir * leg_len, "r": leg_r})
	return out


## The living skin: the DNA shader when a mapper is available (it carries the
## breathing / undulation / tension the rest of the nature system animates with),
## falling back to the static StandardMaterial3D when it is not — probes and
## tools may build a body without a mapper, and a still body beats no body.
static func _skin(dna: CritterDNA, trait_mapper: CritterTraitMapper = null) -> Material:
	if trait_mapper != null:
		var shaded: ShaderMaterial = trait_mapper.create_part_material(
			dna, CritterTraitMapper.PartType.TRUNK, 0)
		if shaded != null and shaded.shader != null:
			return shaded
	var mat := StandardMaterial3D.new()
	mat.albedo_color = dna.primary_color
	mat.roughness = clampf(dna.roughness, 0.3, 0.95)
	mat.metallic = clampf(dna.iridescence * 0.4, 0.0, 0.5)
	# double-sided: insurance so no thin or edge triangle can read as a hole,
	# whatever the mesh resolution — an organic body should never be see-through
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	if dna.iridescence > 0.4:
		mat.emission_enabled = true
		mat.emission = dna.primary_color * 0.25
	return mat


static func _add_eyes(root: Node3D, dna: CritterDNA, head_c: Vector3, head_r: float, spine: Array) -> void:
	# forward direction from head → second spine point
	var fwd := Vector3.FORWARD
	if spine.size() > 1:
		fwd = ((spine[1]["position"] as Vector3) - head_c).normalized()
	var right: Vector3 = fwd.cross(Vector3.UP).normalized()
	if right.length_squared() < 0.01:
		right = Vector3.RIGHT
	var eye_r: float = head_r * 0.28
	for side in [-1.0, 1.0]:
		var mi := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = eye_r
		sm.height = eye_r * 2.0
		sm.radial_segments = 6
		sm.rings = 4
		mi.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.05, 0.05, 0.08)
		mat.metallic = 0.6
		mat.roughness = 0.2
		mi.material_override = mat
		# forward on the head, out to each side, slightly up
		mi.position = head_c - fwd * head_r * 0.5 + right * side * head_r * 0.55 + Vector3.UP * head_r * 0.4
		root.add_child(mi)
