# FungusMorphology.gd — Generates fungus/mushroom meshes from CritterDNA
#
# Builds mushroom-like forms: cap + stem + gills/pores + spore clusters.
# DNA genes map to:
#   part_curve     → cap dome shape (flat→convex→conical→inverted)
#   part_width     → cap diameter
#   part_length    → stem height
#   part_taper     → stem taper (thick base→thin top or vice versa)
#   part_tilt      → cap tilt angle
#   symmetry       → gill/pore count
#   leaf_density   → spore density under cap
#   transparency   → cap translucency (bioluminescent species)
#   sociality      → colony clustering (single→ring→cluster)
#   inflorescence  → colony pattern (fairy ring, shelf, cluster)
#   pattern_type   → cap surface pattern (smooth→spotted→scaled)
#   segments       → shelf/bracket count for bracket fungi
#   edge_type      → cap edge style (smooth→wavy→serrated)
#   iridescence    → bioluminescent glow
#
# Architecture mirrors FlowerMorphology: static methods, RefCounted,
# returns Node3D fungus under parent. Materials via CritterTraitMapper.

class_name FungusMorphology
extends RefCounted

# ─────────────────────────────────────────────────────────────
#  LOD configuration
# ─────────────────────────────────────────────────────────────
const LOD_CAP_SEGMENTS := [6, 12, 20, 32]    # Cap radial segments
const LOD_CAP_RINGS := [3, 5, 8, 12]         # Cap concentric rings
const LOD_STEM_SIDES := [4, 6, 8, 12]        # Stem cross-section
const LOD_GILL_COUNT := [0, 4, 8, 16]        # Under-cap gill meshes


# ═══════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════

## Build a complete fungus under `parent` from `dna`.
## Returns the root Node3D containing all fungus geometry.
static func build(dna: CritterDNA, parent: Node3D, trait_mapper: CritterTraitMapper, lod: int = 2) -> Node3D:
	var fungus_root := Node3D.new()
	fungus_root.name = "Fungus"
	parent.add_child(fungus_root)

	lod = clampi(lod, 0, 3)
	var base_seed: int = fungus_root.get_instance_id()

	# Colony or single?
	if dna.sociality > 0.5 and dna.inflorescence > 0.2:
		_build_colony(dna, fungus_root, trait_mapper, base_seed, lod)
	else:
		_build_single_mushroom(dna, fungus_root, trait_mapper, base_seed, 1.0, lod)

	return fungus_root


# ═══════════════════════════════════════════════════════════════
# SINGLE MUSHROOM — cap + stem + gills
# ═══════════════════════════════════════════════════════════════

static func _build_single_mushroom(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		seed_val: int, scale_factor: float, lod: int) -> void:

	# ── Stem ──
	_build_stem(dna, root, mapper, seed_val, scale_factor, lod)

	# ── Cap ──
	var stem_height: float = dna.part_length * dna.scale * 0.3 * scale_factor
	_build_cap(dna, root, mapper, seed_val + 1000, stem_height, scale_factor, lod)

	# ── Gills / Pores (under cap) ──
	if lod >= 1:
		_build_gills(dna, root, mapper, seed_val + 2000, stem_height, scale_factor, lod)

	# ── Spore cloud (particles or small spheres at tips) ──
	if dna.leaf_density > 0.4 and lod >= 2:
		_build_spores(dna, root, mapper, seed_val + 3000, stem_height, scale_factor, lod)


# ═══════════════════════════════════════════════════════════════
# STEM — central stalk
# ═══════════════════════════════════════════════════════════════

static func _build_stem(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		seed_val: int, scale_factor: float, lod: int) -> void:

	var stem_height: float = dna.part_length * dna.scale * 0.3 * scale_factor
	var stem_radius_bottom: float = dna.part_width * dna.scale * 0.04 * scale_factor
	var stem_radius_top: float

	# Taper direction: some mushrooms are wider at base, some at top (bulbous)
	if dna.part_taper > 0.5:
		# Wider at base, narrow at top (classic mushroom)
		stem_radius_top = stem_radius_bottom * (1.0 - (dna.part_taper - 0.5) * 1.2)
	else:
		# Wider at top (bulbous stem)
		stem_radius_top = stem_radius_bottom * (1.0 + (0.5 - dna.part_taper) * 0.8)

	stem_radius_top = maxf(stem_radius_top, stem_radius_bottom * 0.2)

	var stem_sides: int = LOD_STEM_SIDES[lod]

	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = stem_radius_top
	stem_mesh.bottom_radius = stem_radius_bottom
	stem_mesh.height = stem_height
	stem_mesh.radial_segments = stem_sides
	stem_mesh.rings = 2

	var stem_inst := MeshInstance3D.new()
	stem_inst.name = "Stem"
	stem_inst.mesh = stem_mesh
	stem_inst.position = Vector3(0.0, stem_height * 0.5, 0.0)

	# Stem material: secondary color, fibrous texture
	var mat := mapper.create_material_from_dna(dna, seed_val)
	mat.set_shader_parameter("primary_color", dna.secondary_color)
	mat.set_shader_parameter("secondary_color", dna.secondary_color.lightened(0.15))
	mat.set_shader_parameter("roughness", clampf(dna.roughness + 0.1, 0.3, 1.0))
	mat.set_shader_parameter("pattern_density", 0.2)
	mapper.apply_variation(mat, seed_val)
	stem_inst.material_override = mat

	root.add_child(stem_inst)

	# ── Optional skirt/ring (annulus) around stem ──
	if dna.edge_type > 0.5 and lod >= 2:
		var ring_y: float = stem_height * 0.6
		var ring_radius: float = stem_radius_bottom * 2.5

		var ring_mesh := TorusMesh.new()
		ring_mesh.inner_radius = stem_radius_bottom * 1.1
		ring_mesh.outer_radius = ring_radius
		ring_mesh.ring_segments = LOD_CAP_SEGMENTS[lod]
		ring_mesh.rings = 4

		var ring_inst := MeshInstance3D.new()
		ring_inst.name = "StemRing"
		ring_inst.mesh = ring_mesh
		ring_inst.position = Vector3(0.0, ring_y, 0.0)
		ring_inst.rotation.x = PI * 0.5  # Lay flat

		var ring_mat := mapper.create_material_from_dna(dna, seed_val + 500)
		ring_mat.set_shader_parameter("primary_color", dna.secondary_color.lightened(0.2))
		ring_mat.set_shader_parameter("transparency", 0.2)
		ring_inst.material_override = ring_mat
		root.add_child(ring_inst)


# ═══════════════════════════════════════════════════════════════
# CAP — the mushroom's cap via SurfaceTool
# ═══════════════════════════════════════════════════════════════

## Build a mushroom cap. shape controlled by part_curve:
##   0.0 = flat disc
##   0.3 = convex dome (classic)
##   0.6 = conical (pointed)
##   1.0 = inverted/funnel
static func _build_cap(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		seed_val: int, stem_height: float, scale_factor: float, lod: int) -> void:

	var cap_radius: float = dna.part_width * dna.scale * 0.15 * scale_factor
	var cap_height: float = cap_radius * 0.6 * (0.3 + dna.part_curve)
	var dome_shape: float = dna.part_curve  # 0=flat, 0.3=dome, 0.6=conical, 1.0=funnel

	var segments: int = LOD_CAP_SEGMENTS[lod]
	var rings: int = LOD_CAP_RINGS[lod]

	# Build cap with SurfaceTool for custom shape
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var ring_verts: Array = []  # Array of Array[Vector3]

	for ri in rings:
		var rt: float = float(ri) / float(rings - 1)  # 0=center, 1=edge

		# Radius at this ring
		var ring_radius: float = cap_radius * rt

		# Height profile based on dome_shape
		var ring_y: float
		if dome_shape < 0.3:
			# Flat: slight dome
			ring_y = cap_height * (1.0 - rt * rt) * 0.3
		elif dome_shape < 0.6:
			# Convex dome
			ring_y = cap_height * sqrt(maxf(1.0 - rt * rt, 0.0))
		elif dome_shape < 0.8:
			# Conical
			ring_y = cap_height * (1.0 - rt)
		else:
			# Funnel (inverted edges)
			ring_y = cap_height * (1.0 - rt)
			if rt > 0.6:
				ring_y -= cap_height * 0.3 * (rt - 0.6) / 0.4

		# Edge waviness from edge_type
		var edge_wave: float = 0.0
		if rt > 0.7 and dna.edge_type > 0.3:
			edge_wave = sin(rt * PI * 8.0 * dna.edge_type) * cap_height * 0.1 * dna.edge_type

		ring_y += edge_wave

		var ring: Array = []
		for si in segments:
			var angle: float = TAU * float(si) / float(segments)
			var x: float = cos(angle) * ring_radius
			var z: float = sin(angle) * ring_radius

			# UV
			var u: float = float(si) / float(segments)
			var v: float = rt

			st.set_uv(Vector2(u, v))
			st.set_normal(Vector3(0, 1, 0))  # Will be regenerated
			ring.append(Vector3(x, ring_y, z))

		ring_verts.append(ring)

	# Add center vertex
	var center_y: float = cap_height if dome_shape > 0.3 else cap_height * 0.3
	var center_vert: Vector3 = Vector3(0, center_y, 0)

	# Triangulate rings
	for ri in range(rings - 1):
		var ring_cur: Array = ring_verts[ri] as Array
		var ring_nxt: Array = ring_verts[ri + 1] as Array
		for si in range(segments):
			var si_next: int = (si + 1) % segments

			# If innermost ring, connect to center
			if ri == 0 and (ring_cur[0] as Vector3).length() < 0.001:
				# Skip degenerate center ring
				continue

			var v00: Vector3 = ring_cur[si] as Vector3
			var v01: Vector3 = ring_cur[si_next] as Vector3
			var v10: Vector3 = ring_nxt[si] as Vector3
			var v11: Vector3 = ring_nxt[si_next] as Vector3

			var n1: Vector3 = (v10 - v00).cross(v01 - v00)
			if n1.length() > 0.001:
				n1 = n1.normalized()
			else:
				n1 = Vector3.UP

			st.set_normal(n1)
			st.set_uv(Vector2(float(si) / segments, float(ri) / rings))
			st.add_vertex(v00)

			st.set_normal(n1)
			st.set_uv(Vector2(float(si) / segments, float(ri + 1) / rings))
			st.add_vertex(v10)

			st.set_normal(n1)
			st.set_uv(Vector2(float(si_next) / segments, float(ri) / rings))
			st.add_vertex(v01)

			var n2: Vector3 = (v11 - v01).cross(v10 - v01)
			if n2.length() > 0.001:
				n2 = n2.normalized()
			else:
				n2 = Vector3.UP

			st.set_normal(n2)
			st.set_uv(Vector2(float(si_next) / segments, float(ri) / rings))
			st.add_vertex(v01)

			st.set_normal(n2)
			st.set_uv(Vector2(float(si) / segments, float(ri + 1) / rings))
			st.add_vertex(v10)

			st.set_normal(n2)
			st.set_uv(Vector2(float(si_next) / segments, float(ri + 1) / rings))
			st.add_vertex(v11)

	# Center fan for the top
	if ring_verts.size() > 0 and (ring_verts[0] as Array).size() > 0:
		var first_ring: Array = ring_verts[0] as Array
		for si in segments:
			var si_next: int = (si + 1) % segments
			var edge_v0: Vector3 = first_ring[si] as Vector3
			var edge_v1: Vector3 = first_ring[si_next] as Vector3

			var fan_n: Vector3 = (edge_v0 - center_vert).cross(edge_v1 - center_vert)
			if fan_n.length() > 0.001:
				fan_n = fan_n.normalized()
			else:
				fan_n = Vector3.UP

			st.set_normal(fan_n)
			st.set_uv(Vector2(0.5, 0.0))
			st.add_vertex(center_vert)

			st.set_normal(fan_n)
			st.set_uv(Vector2(float(si) / segments, 0.1))
			st.add_vertex(edge_v0)

			st.set_normal(fan_n)
			st.set_uv(Vector2(float(si_next) / segments, 0.1))
			st.add_vertex(edge_v1)

	st.generate_normals()
	st.generate_tangents()

	var mesh: Mesh = st.commit()
	if not mesh:
		# Fallback: sphere cap
		var fallback := SphereMesh.new()
		fallback.radius = cap_radius
		fallback.height = cap_height * 2.0
		fallback.is_hemisphere = true
		mesh = fallback

	var cap_inst := MeshInstance3D.new()
	cap_inst.name = "Cap"
	cap_inst.mesh = mesh
	cap_inst.position = Vector3(0.0, stem_height, 0.0)

	# Cap tilt
	if absf(dna.part_tilt) > 1.0:
		cap_inst.rotation.z = deg_to_rad(dna.part_tilt * 0.3)

	# Cap material: primary color, with pattern
	var mat := mapper.create_material_from_dna(dna, seed_val)
	mapper.apply_variation(mat, seed_val)

	# Translucency for bioluminescent fungi
	if dna.transparency > 0.2:
		mat.set_shader_parameter("transparency", dna.transparency * 0.5)
	if dna.iridescence > 0.3:
		mat.set_shader_parameter("emission_energy", dna.iridescence * 0.4)

	cap_inst.material_override = mat
	root.add_child(cap_inst)


# ═══════════════════════════════════════════════════════════════
# GILLS — radial fins under the cap
# ═══════════════════════════════════════════════════════════════

static func _build_gills(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		seed_val: int, stem_height: float, scale_factor: float, lod: int) -> void:

	var gill_count: int = LOD_GILL_COUNT[lod]
	if gill_count == 0:
		return

	# Use symmetry to determine actual gill count
	gill_count = clampi(roundi(dna.symmetry * float(gill_count) * 0.5), 4, gill_count * 2)

	var cap_radius: float = dna.part_width * dna.scale * 0.15 * scale_factor
	var gill_depth: float = cap_radius * 0.4
	var gill_inner: float = cap_radius * 0.15  # Inner edge near stem

	for i in gill_count:
		var angle: float = TAU * float(i) / float(gill_count)

		# Gill as a thin quad
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)

		var inner_x: float = cos(angle) * gill_inner
		var inner_z: float = sin(angle) * gill_inner
		var outer_x: float = cos(angle) * cap_radius * 0.9
		var outer_z: float = sin(angle) * cap_radius * 0.9

		var top_y: float = 0.0
		var bottom_y: float = -gill_depth

		# Two triangles forming a quad
		var v0: Vector3 = Vector3(inner_x, top_y, inner_z)
		var v1: Vector3 = Vector3(outer_x, top_y, outer_z)
		var v2: Vector3 = Vector3(inner_x, bottom_y, inner_z)
		var v3: Vector3 = Vector3(outer_x, bottom_y * 0.5, outer_z)  # Shorter at edge

		var gill_normal: Vector3 = Vector3(-sin(angle), 0, cos(angle))

		# Front face
		st.set_normal(gill_normal)
		st.set_uv(Vector2(0, 0)); st.add_vertex(v0)
		st.set_normal(gill_normal)
		st.set_uv(Vector2(0, 1)); st.add_vertex(v2)
		st.set_normal(gill_normal)
		st.set_uv(Vector2(1, 0)); st.add_vertex(v1)

		st.set_normal(gill_normal)
		st.set_uv(Vector2(1, 0)); st.add_vertex(v1)
		st.set_normal(gill_normal)
		st.set_uv(Vector2(0, 1)); st.add_vertex(v2)
		st.set_normal(gill_normal)
		st.set_uv(Vector2(1, 1)); st.add_vertex(v3)

		# Back face
		st.set_normal(-gill_normal)
		st.set_uv(Vector2(0, 0)); st.add_vertex(v0)
		st.set_normal(-gill_normal)
		st.set_uv(Vector2(1, 0)); st.add_vertex(v1)
		st.set_normal(-gill_normal)
		st.set_uv(Vector2(0, 1)); st.add_vertex(v2)

		st.set_normal(-gill_normal)
		st.set_uv(Vector2(1, 0)); st.add_vertex(v1)
		st.set_normal(-gill_normal)
		st.set_uv(Vector2(1, 1)); st.add_vertex(v3)
		st.set_normal(-gill_normal)
		st.set_uv(Vector2(0, 1)); st.add_vertex(v2)

		var gill_mesh: Mesh = st.commit()
		if not gill_mesh:
			continue

		var gill_inst := MeshInstance3D.new()
		gill_inst.name = "Gill_%d" % i
		gill_inst.mesh = gill_mesh
		gill_inst.position = Vector3(0.0, stem_height, 0.0)

		# Gill material: tertiary color, slightly translucent
		var mat := mapper.create_material_from_dna(dna, seed_val + i)
		mat.set_shader_parameter("primary_color", dna.tertiary_color)
		mat.set_shader_parameter("secondary_color", dna.tertiary_color.darkened(0.15))
		mat.set_shader_parameter("roughness", 0.3)
		if dna.leaf_density > 0.6:
			mat.set_shader_parameter("emission_energy", dna.leaf_density * 0.1)
		mapper.apply_variation(mat, seed_val + i * 7)
		gill_inst.material_override = mat
		root.add_child(gill_inst)


# ═══════════════════════════════════════════════════════════════
# SPORES — small spheres floating near cap
# ═══════════════════════════════════════════════════════════════

static func _build_spores(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		seed_val: int, stem_height: float, scale_factor: float, _lod: int) -> void:

	var spore_count: int = clampi(roundi(dna.leaf_density * 12.0), 2, 16)
	var cap_radius: float = dna.part_width * dna.scale * 0.15 * scale_factor
	var spore_radius: float = 0.005 * dna.scale * scale_factor

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	for i in spore_count:
		var angle: float = rng.randf() * TAU
		var radial_dist: float = rng.randf_range(cap_radius * 0.3, cap_radius * 1.2)
		var height_offset: float = rng.randf_range(-cap_radius * 0.8, cap_radius * 0.2)

		var spore_pos: Vector3 = Vector3(
			cos(angle) * radial_dist,
			stem_height + height_offset,
			sin(angle) * radial_dist
		)

		var spore_mesh := SphereMesh.new()
		spore_mesh.radius = spore_radius * rng.randf_range(0.5, 1.5)
		spore_mesh.height = spore_mesh.radius * 2.0
		spore_mesh.radial_segments = 4
		spore_mesh.rings = 2

		var spore_inst := MeshInstance3D.new()
		spore_inst.name = "Spore_%d" % i
		spore_inst.mesh = spore_mesh
		spore_inst.position = spore_pos

		# Spore material: tertiary color with slight glow
		var mat := mapper.create_material_from_dna(dna, seed_val + i * 100)
		mat.set_shader_parameter("primary_color", dna.tertiary_color.lightened(0.3))
		mat.set_shader_parameter("emission_energy", 0.1 + dna.iridescence * 0.3)
		mat.set_shader_parameter("transparency", 0.3)
		spore_inst.material_override = mat
		root.add_child(spore_inst)


# ═══════════════════════════════════════════════════════════════
# COLONY — multiple mushrooms arranged by inflorescence gene
# ═══════════════════════════════════════════════════════════════

static func _build_colony(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		base_seed: int, lod: int) -> void:

	var colony_count: int = clampi(roundi(dna.sociality * 8.0), 3, 12)
	var spread: float = dna.scale * 0.3

	var rng := RandomNumberGenerator.new()
	rng.seed = base_seed

	if dna.inflorescence < 0.4:
		# FAIRY RING — circle arrangement
		var ring_radius: float = spread * (1.0 + float(colony_count) * 0.1)

		for i in colony_count:
			var angle: float = TAU * float(i) / float(colony_count) + rng.randf_range(-0.1, 0.1)
			var pos: Vector3 = Vector3(
				cos(angle) * ring_radius,
				0.0,
				sin(angle) * ring_radius
			)

			var sub_root := Node3D.new()
			sub_root.name = "Colony_%d" % i
			sub_root.position = pos
			# Slight random rotation for organic feel
			sub_root.rotation.y = rng.randf() * TAU
			root.add_child(sub_root)

			var sub_scale: float = rng.randf_range(0.5, 1.0)
			_build_single_mushroom(dna, sub_root, mapper, base_seed + i * 100, sub_scale, maxi(lod - 1, 0))

	elif dna.inflorescence < 0.7:
		# SHELF / BRACKET — stacked horizontally (like shelf fungi on a tree)
		var bracket_count: int = clampi(roundi(dna.segments * 0.5), 2, 6)

		for i in bracket_count:
			var y_offset: float = float(i) * spread * 0.3
			var x_offset: float = rng.randf_range(-spread * 0.1, spread * 0.1)

			var sub_root := Node3D.new()
			sub_root.name = "Bracket_%d" % i
			sub_root.position = Vector3(x_offset, y_offset, 0.0)
			# Tilt outward like shelf fungi
			sub_root.rotation.z = deg_to_rad(rng.randf_range(10.0, 30.0))
			root.add_child(sub_root)

			var sub_scale: float = 1.0 - float(i) * 0.1
			_build_single_mushroom(dna, sub_root, mapper, base_seed + i * 100, sub_scale, maxi(lod - 1, 0))

	else:
		# DENSE CLUSTER — random grouping
		for i in colony_count:
			var pos: Vector3 = Vector3(
				rng.randf_range(-spread, spread),
				0.0,
				rng.randf_range(-spread, spread)
			)

			var sub_root := Node3D.new()
			sub_root.name = "Colony_%d" % i
			sub_root.position = pos
			sub_root.rotation.y = rng.randf() * TAU
			root.add_child(sub_root)

			var sub_scale: float = rng.randf_range(0.3, 1.0)
			_build_single_mushroom(dna, sub_root, mapper, base_seed + i * 100, sub_scale, maxi(lod - 1, 0))
