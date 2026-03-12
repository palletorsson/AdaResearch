# FlowerMorphology.gd — Generates flower meshes from CritterDNA
#
# Reads a CritterDNA and builds:
#   - Concentric petal rings (1-3 rings with per-ring angle/size falloff)
#   - Per-petal Bézier curve geometry with twist, taper, curvature
#   - Center/stamen cluster
#   - Stem
#   - Inflorescence (when inflorescence > 0): multiple sub-flowers on a stem
#
# Petals use MultiMeshInstance3D — one draw call for all petals in a bloom.
# Per-petal color variation is encoded via MultiMesh instance COLOR,
# and pattern rotation via INSTANCE_CUSTOM.r. The critter_dna.gdshader
# reads these varyings to produce per-petal uniqueness.
#
# Adapted from queerbreader's PetalGenerator.gd — same Bézier approach
# but driven by CritterDNA Resource fields instead of individual exports.

class_name FlowerMorphology
extends RefCounted

# ─────────────────────────────────────────────────────────────
#  LOD configuration
# ─────────────────────────────────────────────────────────────
const LOD_SEGMENTS := [5, 10, 20, 32]   # Lengthwise divisions per LOD level
const LOD_SIDES := [4, 6, 8, 12]         # Cross-section sides per LOD level


# ═══════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════

## Build a complete flower under `parent` from `dna`.
## Returns the root Node3D containing all flower geometry.
static func build(dna: CritterDNA, parent: Node3D, trait_mapper: CritterTraitMapper, lod: int = 2) -> Node3D:
	var flower_root := Node3D.new()
	flower_root.name = "Flower"
	parent.add_child(flower_root)

	# If inflorescence > threshold, build a multi-flower stem
	if dna.inflorescence > 0.05:
		_build_inflorescence(dna, flower_root, trait_mapper, lod)
	else:
		_build_single_bloom(dna, flower_root, trait_mapper, lod, 1.0)

	return flower_root


# ═══════════════════════════════════════════════════════════════
# SINGLE BLOOM — one flower head with petal rings + center + stem
# ═══════════════════════════════════════════════════════════════

static func _build_single_bloom(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper, lod: int, scale_factor: float) -> void:
	var base_seed: int = root.get_instance_id()

	# ── Stem ──
	_build_stem(dna, root, mapper, base_seed, scale_factor)

	# ── Petal rings → MultiMesh ──
	var ring_count := clampi(roundi(dna.segments), 1, 3)
	var petals_per_ring := clampi(roundi(dna.symmetry), 3, 12)
	var total_petals: int = ring_count * petals_per_ring
	var petal_mesh: Mesh = _generate_petal_mesh(dna, lod)

	# Collect per-petal data before creating MultiMesh
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	var custom_data: Array[Color] = []

	var rng := RandomNumberGenerator.new()
	rng.seed = base_seed

	for ring_idx in ring_count:
		var ring_t: float = float(ring_idx) / maxf(ring_count - 1.0, 1.0)

		# Per-ring falloff: outer ring is widest, inner is most closed
		var ring_angle_deg: float = dna.branch_angle * (1.0 - ring_t * 0.6)
		var ring_scale: float = scale_factor * (1.0 - ring_t * (1.0 - dna.branch_decay))
		var ring_tilt_offset: float = dna.part_tilt * ring_t

		# Offset rotation between rings for organic look
		var ring_rotation_offset: float = (TAU / petals_per_ring) * 0.5 * ring_idx

		for petal_idx in petals_per_ring:
			var angle: float = (TAU / petals_per_ring) * petal_idx + ring_rotation_offset

			# Build transform: rotate around Y, then tilt outward, then scale
			var tilt_rad: float = deg_to_rad(ring_angle_deg + ring_tilt_offset)
			var basis := Basis.from_euler(Vector3(tilt_rad, angle, 0.0))
			basis = basis.scaled(Vector3.ONE * ring_scale)
			transforms.append(Transform3D(basis, Vector3.ZERO))

			# Per-petal color drift (±0.04 RGB, was apply_variation)
			var drift_r: float = rng.randf_range(-0.04, 0.04)
			var drift_g: float = rng.randf_range(-0.04, 0.04)
			var drift_b: float = rng.randf_range(-0.04, 0.04)
			colors.append(Color(
				clampf(1.0 + drift_r, 0.0, 1.1),
				clampf(1.0 + drift_g, 0.0, 1.1),
				clampf(1.0 + drift_b, 0.0, 1.1),
				1.0
			))

			# Per-petal pattern rotation (0-1 maps to 0-TAU in shader)
			var pattern_rot: float = rng.randf()
			custom_data.append(Color(pattern_rot, 0.0, 0.0, 0.0))

	# Build MultiMesh
	if total_petals > 0:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = petal_mesh
		mm.instance_count = total_petals  # Must be set AFTER mesh/format/flags

		for i in total_petals:
			mm.set_instance_transform(i, transforms[i])
			mm.set_instance_color(i, colors[i])
			mm.set_instance_custom_data(i, custom_data[i])

		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Petals"
		mmi.multimesh = mm

		# Shared material for all petals — base DNA material, no per-instance variation
		var mat: ShaderMaterial = mapper.create_material_from_dna(dna, base_seed)
		mmi.material_override = mat

		root.add_child(mmi)

	# ── Center / stamen ──
	_build_center(dna, root, mapper, base_seed, scale_factor)


# ═══════════════════════════════════════════════════════════════
# INFLORESCENCE — multiple sub-flowers arranged on a stem axis
# ═══════════════════════════════════════════════════════════════

static func _build_inflorescence(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper, lod: int) -> void:
	var base_seed: int = root.get_instance_id()

	# How many sub-flowers based on segments (reinterpreted for inflorescence)
	var flower_count := clampi(roundi(dna.segments * 2.0), 3, 24)

	# Stem height scales with scent_strength
	var stem_height: float = dna.scent_strength * 1.5 + 0.3

	# Sub-flower scale — smaller than a single bloom
	var sub_scale: float = 0.3 + 0.2 * (1.0 - dna.inflorescence)

	# Build the main inflorescence stem
	_build_stem(dna, root, mapper, base_seed, 1.0, stem_height)

	var rng := RandomNumberGenerator.new()
	rng.seed = base_seed

	if dna.inflorescence < 0.25:
		# RACEME — flowers along stem axis
		for i in flower_count:
			var t: float = float(i) / maxf(flower_count - 1.0, 1.0)
			var y_pos: float = stem_height * (0.3 + t * 0.7)  # Start 30% up

			var sub_root := Node3D.new()
			sub_root.name = "SubFlower_%d" % i
			sub_root.position = Vector3(0.0, y_pos, 0.0)

			# Tilt outward based on part_tilt
			var tilt: float = deg_to_rad(dna.part_tilt + rng.randf_range(-5.0, 5.0))
			var angle: float = TAU * (float(i) / flower_count) * (137.5 / 360.0)  # Golden angle
			sub_root.rotation = Vector3(tilt, angle, 0.0)

			root.add_child(sub_root)
			_build_single_bloom(dna, sub_root, mapper, maxi(lod - 1, 0), sub_scale)

	elif dna.inflorescence < 0.6:
		# UMBEL — all radiate from one point at the top
		var umbel_origin := Vector3(0.0, stem_height, 0.0)

		for i in flower_count:
			var angle: float = TAU * float(i) / flower_count
			var tilt: float = deg_to_rad(dna.branch_angle * 0.8 + rng.randf_range(-10.0, 10.0))

			var sub_root := Node3D.new()
			sub_root.name = "SubFlower_%d" % i
			sub_root.position = umbel_origin
			sub_root.rotation = Vector3(tilt, angle, 0.0)

			# Small stalk per sub-flower
			var stalk_length: float = 0.1 + rng.randf_range(0.0, 0.05)
			sub_root.position += Vector3(sin(angle) * sin(tilt), cos(tilt), cos(angle) * sin(tilt)) * stalk_length

			root.add_child(sub_root)
			_build_single_bloom(dna, sub_root, mapper, maxi(lod - 1, 0), sub_scale * 0.8)

	else:
		# HEAD / PANICLE — dense cluster at the top
		var head_origin := Vector3(0.0, stem_height, 0.0)
		var head_radius: float = 0.08 * dna.scale

		for i in flower_count:
			# Fibonacci sphere distribution
			var golden_ratio: float = (1.0 + sqrt(5.0)) / 2.0
			var theta: float = acos(1.0 - 2.0 * (float(i) + 0.5) / flower_count)
			var phi: float = TAU * float(i) / golden_ratio

			var pos := Vector3(
				sin(theta) * cos(phi),
				cos(theta),
				sin(theta) * sin(phi)
			) * head_radius

			var sub_root := Node3D.new()
			sub_root.name = "SubFlower_%d" % i
			sub_root.position = head_origin + pos
			# Point outward from center (add to tree first so look_at works)
			root.add_child(sub_root)
			sub_root.look_at(sub_root.global_position + pos.normalized(), Vector3.UP)
			_build_single_bloom(dna, sub_root, mapper, maxi(lod - 2, 0), sub_scale * 0.5)


# ═══════════════════════════════════════════════════════════════
# STEM — a simple cylinder mesh
# ═══════════════════════════════════════════════════════════════

static func _build_stem(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper, seed_val: int, scale_factor: float, height_override: float = -1.0) -> void:
	var stem_height: float = height_override if height_override > 0.0 else (dna.scent_strength * 0.8 + 0.15) * scale_factor
	var stem_radius: float = 0.015 * scale_factor

	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = stem_radius * 0.7
	stem_mesh.bottom_radius = stem_radius
	stem_mesh.height = stem_height
	stem_mesh.radial_segments = 6
	stem_mesh.rings = 2

	var stem_node := MeshInstance3D.new()
	stem_node.name = "Stem"
	stem_node.mesh = stem_mesh
	stem_node.position = Vector3(0.0, -stem_height * 0.5, 0.0)

	# Stem material: secondary color (green), low pattern
	var stem_mat := mapper.create_material_from_dna(dna, seed_val + 9999)
	# Override colors for stem — use secondary as primary
	stem_mat.set_shader_parameter("primary_color", dna.secondary_color)
	stem_mat.set_shader_parameter("secondary_color", dna.secondary_color.darkened(0.3))
	stem_mat.set_shader_parameter("pattern_type", 0.1)
	stem_mat.set_shader_parameter("pattern_density", 0.3)
	stem_node.material_override = stem_mat

	root.add_child(stem_node)


# ═══════════════════════════════════════════════════════════════
# CENTER / STAMEN — sphere cluster at the flower's heart
# ═══════════════════════════════════════════════════════════════

static func _build_center(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper, seed_val: int, scale_factor: float) -> void:
	if dna.leaf_density < 0.1:
		return  # No stamen for very low density

	var center_radius: float = 0.04 * scale_factor * (0.5 + dna.leaf_density * 0.5)

	var center_mesh := SphereMesh.new()
	center_mesh.radius = center_radius
	center_mesh.height = center_radius * 1.6
	center_mesh.radial_segments = 8
	center_mesh.rings = 4

	var center_node := MeshInstance3D.new()
	center_node.name = "Center"
	center_node.mesh = center_mesh
	center_node.position = Vector3(0.0, center_radius * 0.3, 0.0)

	# Center material: tertiary color (stamen color)
	var center_mat := mapper.create_material_from_dna(dna, seed_val + 5555)
	center_mat.set_shader_parameter("primary_color", dna.tertiary_color)
	center_mat.set_shader_parameter("secondary_color", dna.tertiary_color.lightened(0.2))
	# Slight emission for nectar glow
	if dna.nectar_quality > 0.5:
		center_mat.set_shader_parameter("emission_energy", dna.nectar_quality * 0.3)
	center_node.material_override = center_mat

	root.add_child(center_node)


# ═══════════════════════════════════════════════════════════════
# PETAL MESH — Bézier curve petal via SurfaceTool
# ═══════════════════════════════════════════════════════════════

## Generate a single petal mesh from DNA geometry genes.
## The mesh is shared across all petals in a ring (instanced with unique materials).
static func _generate_petal_mesh(dna: CritterDNA, lod: int) -> Mesh:
	lod = clampi(lod, 0, 3)
	var segments: int = LOD_SEGMENTS[lod]
	var sides: int = LOD_SIDES[lod]

	var length: float = dna.part_length
	var width: float = dna.part_width
	var curvature: float = dna.part_curve
	var taper: float = dna.part_taper
	var twist_deg: float = dna.part_twist
	var thickness: float = 0.005 * dna.scale

	# Generate profile curve (Bézier)
	var profile := _bezier_profile(segments, length, curvature)

	# Generate cross-section (ellipse)
	var cross_section := _ellipse_cross_section(sides)

	# Build mesh with SurfaceTool
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var vertex_ring: Array = []  # Array of Array[Vector3]

	for seg_idx in segments:
		var t: float = float(seg_idx) / maxf(segments - 1.0, 1.0)
		var point: Vector3 = profile[seg_idx]

		# Tangent along the profile
		var tangent: Vector3
		if seg_idx == 0:
			tangent = (profile[1] - profile[0]).normalized()
		elif seg_idx == segments - 1:
			tangent = (profile[seg_idx] - profile[seg_idx - 1]).normalized()
		else:
			tangent = (profile[seg_idx + 1] - profile[seg_idx - 1]).normalized()

		# Build local coordinate frame
		var up: Vector3 = Vector3.UP if absf(tangent.dot(Vector3.UP)) < 0.99 else Vector3.RIGHT
		var normal: Vector3 = tangent.cross(up).normalized()
		var binormal: Vector3 = normal.cross(tangent).normalized()

		# Twist rotation
		var twist_rad: float = deg_to_rad(twist_deg * t)
		var twist_basis := Basis().rotated(tangent, twist_rad)

		# Width taper: sine envelope with tip pointiness
		var width_scale: float = _width_at_t(t, taper) * width
		var thick_scale: float = thickness

		var ring: Array = []
		for side_idx in sides:
			var cs: Vector3 = cross_section[side_idx] as Vector3
			var local_offset: Vector3 = binormal * cs.x * width_scale + normal * cs.y * thick_scale
			var rotated: Vector3 = twist_basis * local_offset
			ring.append(point + rotated)
		vertex_ring.append(ring)

	# Triangulate between rings
	for seg_idx in range(segments - 1):
		var ring_a: Array = vertex_ring[seg_idx] as Array
		var ring_b: Array = vertex_ring[seg_idx + 1] as Array
		for side_idx in range(sides - 1):
			var v00: Vector3 = ring_a[side_idx] as Vector3
			var v01: Vector3 = ring_a[side_idx + 1] as Vector3
			var v10: Vector3 = ring_b[side_idx] as Vector3
			var v11: Vector3 = ring_b[side_idx + 1] as Vector3

			var t0: float = float(seg_idx) / maxf(segments - 1.0, 1.0)
			var t1: float = float(seg_idx + 1) / maxf(segments - 1.0, 1.0)
			var s0: float = float(side_idx) / maxf(sides - 1.0, 1.0)
			var s1: float = float(side_idx + 1) / maxf(sides - 1.0, 1.0)

			# Triangle 1
			var n1: Vector3 = (v10 - v00).cross(v01 - v00).normalized()
			st.set_normal(n1); st.set_uv(Vector2(s0, t0)); st.add_vertex(v00)
			st.set_normal(n1); st.set_uv(Vector2(s0, t1)); st.add_vertex(v10)
			st.set_normal(n1); st.set_uv(Vector2(s1, t0)); st.add_vertex(v01)

			# Triangle 2
			var n2: Vector3 = (v11 - v01).cross(v10 - v01).normalized()
			st.set_normal(n2); st.set_uv(Vector2(s1, t0)); st.add_vertex(v01)
			st.set_normal(n2); st.set_uv(Vector2(s0, t1)); st.add_vertex(v10)
			st.set_normal(n2); st.set_uv(Vector2(s1, t1)); st.add_vertex(v11)

	st.generate_normals()
	st.generate_tangents()
	var mesh: Mesh = st.commit()

	if not mesh:
		# Fallback
		var fallback := SphereMesh.new()
		fallback.radius = length * 0.1
		fallback.height = length * 0.1 * 2.0
		return fallback

	return mesh


# ═══════════════════════════════════════════════════════════════
# GEOMETRY HELPERS
# ═══════════════════════════════════════════════════════════════

## Cubic Bézier profile curve from base to tip.
## curvature controls the upward bow.
static func _bezier_profile(segments: int, length: float, curvature: float) -> Array:
	var p0 := Vector3.ZERO
	var p1 := Vector3(0.0, length * curvature * 0.5, length * 0.25)
	var p2 := Vector3(0.0, length * curvature * 0.8, length * 0.75)
	var p3 := Vector3(0.0, 0.0, length)

	var points: Array = []
	for i in segments:
		var t: float = float(i) / maxf(segments - 1.0, 1.0)
		# De Casteljau
		var a := p0.lerp(p1, t)
		var b := p1.lerp(p2, t)
		var c := p2.lerp(p3, t)
		var d := a.lerp(b, t)
		var e := b.lerp(c, t)
		points.append(d.lerp(e, t))
	return points


## Ellipse cross-section for the petal tube.
static func _ellipse_cross_section(sides: int) -> Array:
	var points: Array = []
	for i in sides:
		var angle: float = TAU * float(i) / float(sides)
		points.append(Vector3(cos(angle) * 0.5, sin(angle) * 0.3, 0.0))
	return points


## Width envelope along petal length. Sine bell with tip taper.
static func _width_at_t(t: float, taper: float) -> float:
	var base_width: float = sin(PI * t)
	var tip_influence: float = 1.0 - taper
	var width_at_tip: float = lerpf(0.01, 0.5, tip_influence)

	if t > 0.8:
		var tip_t: float = (t - 0.8) / 0.2
		base_width = lerpf(base_width, width_at_tip, tip_t)

	return clampf(base_width, 0.01, 1.0)
