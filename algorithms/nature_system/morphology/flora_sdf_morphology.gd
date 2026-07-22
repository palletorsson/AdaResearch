# FloraSdfMorphology.gd — a tree as ONE continuous SDF surface.
#
# TreeMorphology draws each branch as its own tube; at a fork the child tubes
# don't fuse with the parent, so the joints seam. This builder grows a branch
# SKELETON (a recursive list of tapered capsules) and expresses it as a signed
# distance field: smin over every capsule, with a SMALL blend so branches keep
# their identity but WELD seamlessly where they meet the trunk. Leaf clusters
# are soft ellipsoid blobs at the tips, lightly unioned so the canopy reads as
# mass, not a thousand cards. Meshed by SdfMesher (marching tetrahedra).
#
# DNA → form:
#   segments     → recursion depth (how many fork generations)
#   part_length  → branch length      part_width → trunk thickness
#   branch_angle → fork splay          part_curve → branch bend/lean
#   scale        → overall size        secondary_color → leaf tint
# Same build() signature as TreeMorphology.

class_name FloraSdfMorphology
extends RefCounted

const Mesher = preload("res://algorithms/nature_system/morphology/sdf_mesher.gd")

const RES_BY_LOD: Array = [18, 24, 32, 40]
const MAX_CAPSULES: int = 48   # perf: the field iterates all of these per sample


static func build(dna: CritterDNA, parent: Node3D, _trait_mapper: CritterTraitMapper, lod: int = 2) -> Node3D:
	lod = clampi(lod, 0, 3)
	var root := Node3D.new()
	root.name = "FloraSDF"
	parent.add_child(root)

	var scale: float = maxf(dna.scale, 0.2)
	var depth: int = clampi(roundi(dna.segments) - 1, 2, 4)
	var trunk_len: float = clampf(dna.part_length, 0.3, 1.2) * scale * 0.55
	var trunk_r: float = clampf(dna.part_width, 0.4, 1.0) * scale * 0.05
	var splay: float = deg_to_rad(clampf(dna.branch_angle, 15.0, 55.0))
	var bend: float = dna.part_curve * 0.4
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(dna) if dna != null else 12345

	# grow the skeleton: [{a, b, ra, rb}]
	var caps: Array = []
	var leaves: Array = []   # {c, r} soft canopy blobs at tips
	_grow(caps, leaves, Vector3.ZERO, Vector3.UP, trunk_len, trunk_r, depth, splay, bend, rng)
	if caps.is_empty():
		return root
	if caps.size() > MAX_CAPSULES:
		caps.resize(MAX_CAPSULES)

	var k: float = trunk_r * 1.1   # small: branches weld at joints, keep identity
	var leaf_k: float = trunk_r * 4.0
	# a solid canopy, not a shell of merged tip-blobs with windows: add ONE
	# central fill blob at the leaves' centroid, sized to their spread, so the
	# interior is full mass. The tip blobs then just give the outline its lumps.
	if leaves.size() >= 2:
		var cen := Vector3.ZERO
		for lf in leaves:
			cen += lf["c"]
		cen /= float(leaves.size())
		var spread: float = 0.0
		for lf in leaves:
			spread = maxf(spread, (lf["c"] as Vector3).distance_to(cen))
		leaves.append({"c": cen, "r": maxf(spread * 0.85, trunk_r * 4.0)})

	var field := func(p: Vector3) -> float:
		var d: float = 1e9
		for c in caps:
			d = Mesher.smin(d, Mesher.sd_capsule_tapered(p, c["a"], c["b"], c["ra"], c["rb"]), k)
		return d

	# bounds from the skeleton
	var lo := Vector3(1e9, 0.0, 1e9)
	var hi := Vector3(-1e9, 0.0, -1e9)
	for c in caps:
		lo = lo.min(c["a"]).min(c["b"]); hi = hi.max(c["a"]).max(c["b"])
	var pad := Vector3.ONE * (trunk_r * 3.0)
	var mesh: ArrayMesh = Mesher.mesh_field(field, lo - pad, hi + pad, RES_BY_LOD[lod])
	if mesh != null:
		var mi := MeshInstance3D.new()
		mi.name = "Trunk"
		mi.mesh = mesh
		var mat := StandardMaterial3D.new()
		mat.albedo_color = dna.primary_color
		mat.roughness = 0.9
		mi.material_override = mat
		root.add_child(mi)

	# canopy: soft leaf blobs at the tips, their own SDF (green), lightly blended
	if not leaves.is_empty():
		var leaf_field := func(p: Vector3) -> float:
			var d: float = 1e9
			for lf in leaves:
				d = Mesher.smin(d, Mesher.sd_sphere(p, lf["c"], lf["r"]), leaf_k)
			return d
		var llo := Vector3(1e9, 1e9, 1e9)
		var lhi := Vector3(-1e9, -1e9, -1e9)
		for lf in leaves:
			llo = llo.min(lf["c"] - Vector3.ONE * lf["r"])
			lhi = lhi.max(lf["c"] + Vector3.ONE * lf["r"])
		var leaf_mesh: ArrayMesh = Mesher.mesh_field(leaf_field, llo, lhi, RES_BY_LOD[lod])
		if leaf_mesh != null:
			var lmi := MeshInstance3D.new()
			lmi.name = "Canopy"
			lmi.mesh = leaf_mesh
			var lmat := StandardMaterial3D.new()
			lmat.albedo_color = dna.secondary_color if dna.secondary_color.g > 0.0 else Color(0.2, 0.5, 0.2)
			lmat.roughness = 0.85
			lmi.material_override = lmat
			root.add_child(lmi)
	return root


# recursive branch growth: append tapered capsules; drop leaf blobs at tips.
static func _grow(caps: Array, leaves: Array, base: Vector3, dir: Vector3,
		length: float, radius: float, depth: int, splay: float, bend: float,
		rng: RandomNumberGenerator) -> void:
	if depth <= 0 or caps.size() >= MAX_CAPSULES or length < 0.01:
		# a leaf blob at the tip — the canopy's lumpy outline (a central fill
		# blob added in build() makes the mass solid)
		leaves.append({"c": base, "r": maxf(length * 1.3, radius * 3.5)})
		return
	var tip: Vector3 = base + dir.normalized() * length
	var rb: float = radius * 0.68
	caps.append({"a": base, "b": tip, "ra": radius, "rb": rb})
	# 2-3 children, splayed around the parent direction
	var children: int = 2 if depth <= 2 else 3
	var up: Vector3 = dir.normalized()
	var side: Vector3 = up.cross(Vector3.RIGHT)
	if side.length_squared() < 0.01:
		side = up.cross(Vector3.FORWARD)
	side = side.normalized()
	for i in children:
		var az: float = TAU * float(i) / float(children) + rng.randf_range(-0.4, 0.4)
		var axis: Vector3 = (side * cos(az) + up.cross(side).normalized() * sin(az)).normalized()
		var child_dir: Vector3 = up.rotated(axis, splay + rng.randf_range(-0.2, 0.2))
		# a little upward bias + lean
		child_dir = (child_dir + Vector3.UP * bend).normalized()
		_grow(caps, leaves, tip, child_dir, length * rng.randf_range(0.6, 0.78),
			rb, depth - 1, splay, bend, rng)
