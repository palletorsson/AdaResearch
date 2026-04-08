# CreatureMorphology.gd — Generates creature meshes from CritterDNA
#
# Builds a segmented body with limbs/appendages. DNA genes map to:
#   segments    → body segment count (2-12)
#   symmetry    → limb pairs per segment (1-4 per side)
#   part_length → limb segment length
#   part_width  → limb thickness
#   part_curve  → body curvature (straight→arching→coiled)
#   part_taper  → body taper (head→tail narrowing)
#   part_twist  → body helical twist
#   part_tilt   → limb rest angle (splayed→tucked)
#   branch_angle → limb splay angle
#   branch_decay → limb taper per joint
#   mobility    → leg vs tentacle vs fin interpolation
#   aggression  → claw/horn/spike presence
#   pattern_type → surface pattern on body/limbs
#   phyllotaxis → limb arrangement (alternating vs opposite vs whorled)
#   edge_type   → limb tip shape (rounded→serrated→pointed)
#
# Architecture mirrors FlowerMorphology: static methods, RefCounted,
# returns Node3D creature under parent. Materials via CritterTraitMapper.

class_name CreatureMorphology
extends RefCounted

# ─────────────────────────────────────────────────────────────
#  LOD configuration
# ─────────────────────────────────────────────────────────────
const LOD_BODY_SIDES := [4, 6, 8, 12]        # Cross-section resolution
const LOD_LIMB_SIDES := [3, 4, 6, 8]         # Limb cross-section
const LOD_MAX_LIMBS := [8, 16, 32, 64]       # Max limbs per creature


# ═══════════════════════════════════════════════════════════════
# PUBLIC API
# ═══════════════════════════════════════════════════════════════

## Build a complete creature under `parent` from `dna`.
## Returns the root Node3D containing all creature geometry.
static func build(dna: CritterDNA, parent: Node3D, trait_mapper: CritterTraitMapper, lod: int = 2) -> Node3D:
	var creature_root := Node3D.new()
	creature_root.name = "Creature"
	parent.add_child(creature_root)

	lod = clampi(lod, 0, 3)
	var base_seed: int = creature_root.get_instance_id()

	# ── Build the segmented body spine ──
	var spine := _build_spine(dna, lod)

	# ── Build body segments along the spine ──
	_build_body_segments(dna, creature_root, trait_mapper, spine, base_seed, lod)

	# ── Build limbs/appendages ──
	_build_limbs(dna, creature_root, trait_mapper, spine, base_seed, lod)

	# ── Head (first segment gets special features) ──
	_build_head(dna, creature_root, trait_mapper, spine, base_seed, lod)

	# ── Tail (last segment gets tail/fin) ──
	if dna.segments > 3.0:
		_build_tail(dna, creature_root, trait_mapper, spine, base_seed, lod)

	return creature_root


# ═══════════════════════════════════════════════════════════════
# SPINE — the creature's central axis as a list of transforms
# ═══════════════════════════════════════════════════════════════

## Build a spine curve: a series of positions and radii along the body.
## The spine defines where each segment sits and how wide it is.
static func _build_spine(dna: CritterDNA, _lod: int) -> Array:
	var seg_count: int = clampi(roundi(dna.segments), 2, 12)
	var body_length: float = dna.part_length * dna.scale * 0.5 * seg_count
	var max_radius: float = dna.part_width * dna.scale * 0.12

	var curvature: float = dna.part_curve   # 0=straight, 1=coiled
	var taper: float = dna.part_taper        # How much the tail end narrows
	var twist: float = dna.part_twist        # Helical twist in degrees

	var spine: Array = []

	for i in seg_count:
		var t: float = float(i) / maxf(seg_count - 1.0, 1.0)

		# Position along body axis with curvature
		var z: float = t * body_length
		var y: float = curvature * sin(PI * t) * body_length * 0.15
		var x: float = 0.0

		# Helical twist
		if absf(twist) > 0.1:
			var twist_rad: float = deg_to_rad(twist * t)
			x = sin(twist_rad) * curvature * 0.1 * body_length
			y += cos(twist_rad) * curvature * 0.05 * body_length

		# Radius taper: thickest at ~30% (thorax), thinner at ends
		var radius_envelope: float = _body_radius_at_t(t, taper)
		var radius: float = max_radius * radius_envelope

		spine.append({
			"position": Vector3(x, y, z),
			"radius": radius,
			"t": t,
			"index": i,
		})

	return spine


## Body radius envelope. Widest at front-center, tapering to head and tail.
## taper controls how pointy the tail gets.
static func _body_radius_at_t(t: float, taper: float) -> float:
	# Bell curve centered at ~30% along body (thorax)
	var thorax_peak: float = 0.3
	var width_factor: float = 3.0  # Width of the bell

	var bell: float = exp(-width_factor * pow(t - thorax_peak, 2.0))

	# Tail taper
	if t > 0.5:
		var tail_t: float = (t - 0.5) / 0.5
		bell *= (1.0 - tail_t * taper)

	# Head doesn't taper as much
	if t < 0.15:
		bell = maxf(bell, 0.6)

	return clampf(bell, 0.15, 1.0)


# ═══════════════════════════════════════════════════════════════
# BODY SEGMENTS — tube sections along the spine
# ═══════════════════════════════════════════════════════════════

## Build the body tube segments, one MeshInstance3D per pair of spine points.
static func _build_body_segments(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		spine: Array, base_seed: int, lod: int) -> void:

	var body_sides: int = LOD_BODY_SIDES[lod]

	for i in range(spine.size() - 1):
		var seg_start: Dictionary = spine[i] as Dictionary
		var seg_end: Dictionary = spine[i + 1] as Dictionary

		var mesh: Mesh = _create_tube_mesh(
			seg_start["position"] as Vector3, seg_end["position"] as Vector3,
			seg_start["radius"] as float, seg_end["radius"] as float,
			body_sides
		)
		if not mesh:
			continue

		var inst := MeshInstance3D.new()
		inst.name = "Body_%d" % i
		inst.mesh = mesh

		# Material: scales surface with per-segment variation
		var mat := mapper.create_part_material(dna, CritterTraitMapper.PartType.TRUNK, base_seed + i)
		# Body segments alternate slightly darker
		if i % 2 == 1:
			mat.set_shader_parameter("primary_color", dna.primary_color.darkened(0.08))
		mapper.apply_variation(mat, base_seed + i * 13)
		inst.material_override = mat

		root.add_child(inst)


# ═══════════════════════════════════════════════════════════════
# LIMBS — legs/tentacles/fins placed along body segments
# ═══════════════════════════════════════════════════════════════

## Place limbs along the body. The type of limb (leg vs tentacle vs fin)
## interpolates with the mobility gene.
static func _build_limbs(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		spine: Array, base_seed: int, lod: int) -> void:

	var max_limbs: int = LOD_MAX_LIMBS[lod]
	var limb_sides: int = LOD_LIMB_SIDES[lod]

	# How many limb pairs and which segments get them
	var limb_pairs_per_seg: int = clampi(roundi(dna.symmetry), 1, 4)
	var phyllotaxis: float = dna.phyllotaxis
	var splay_angle: float = dna.branch_angle
	var limb_taper: float = dna.branch_decay
	var rest_angle: float = dna.part_tilt

	# Which segments get limbs? Skip head and tail-tip
	var limb_start: int = 1  # After head
	var limb_end: int = spine.size() - 1  # Before tail

	var limb_count: int = 0

	for seg_idx in range(limb_start, limb_end):
		if limb_count >= max_limbs:
			break

		var seg: Dictionary = spine[seg_idx] as Dictionary
		var seg_pos: Vector3 = seg["position"] as Vector3
		var seg_radius: float = seg["radius"] as float
		var seg_t: float = seg["t"] as float

		# Direction along spine for forward axis
		var forward: Vector3
		if seg_idx < spine.size() - 1:
			var next_seg: Dictionary = spine[seg_idx + 1] as Dictionary
			forward = ((next_seg["position"] as Vector3) - seg_pos).normalized()
		else:
			var prev_seg: Dictionary = spine[seg_idx - 1] as Dictionary
			forward = (seg_pos - (prev_seg["position"] as Vector3)).normalized()

		# Up and right vectors
		var up: Vector3 = Vector3.UP
		if absf(forward.dot(Vector3.UP)) > 0.99:
			up = Vector3.RIGHT
		var right: Vector3 = forward.cross(up).normalized()
		up = right.cross(forward).normalized()

		for pair_idx in limb_pairs_per_seg:
			if limb_count >= max_limbs:
				break

			# Calculate limb placement angle
			var base_angle: float
			if phyllotaxis < 0.33:
				# Alternating: offset each segment
				base_angle = (PI * 0.5) + (seg_idx * PI * 0.5) + (pair_idx * PI / limb_pairs_per_seg)
			elif phyllotaxis < 0.66:
				# Opposite: paired limbs
				base_angle = (pair_idx * PI / limb_pairs_per_seg)
			else:
				# Whorled: evenly distributed
				base_angle = (pair_idx * TAU / (limb_pairs_per_seg * 2))

			# Place limb on both sides (bilateral symmetry)
			for side in [-1.0, 1.0]:
				if limb_count >= max_limbs:
					break

				var limb_angle: float = base_angle * side
				var limb_dir: Vector3 = (right * cos(limb_angle) + up * sin(limb_angle)).normalized()

				# Splay outward and downward
				var splay_rad: float = deg_to_rad(splay_angle)
				var rest_rad: float = deg_to_rad(rest_angle * side)
				limb_dir = (limb_dir * cos(splay_rad) - Vector3.UP * sin(splay_rad)).normalized()
				limb_dir = limb_dir.rotated(forward, rest_rad)

				# Limb length scales with body radius
				var limb_length: float = dna.part_length * dna.scale * 0.15 * (1.0 + seg_radius * 3.0)
				var limb_radius: float = seg_radius * 0.3

				# Number of joints in the limb
				var joint_count: int = 2 if dna.mobility > 0.5 else 1

				# Build the limb segments
				_build_single_limb(dna, root, mapper,
					base_seed + seg_idx * 1000 + pair_idx * 100 + (1 if side > 0 else 0),
					seg_pos + limb_dir * seg_radius,  # Start at body surface
					limb_dir, limb_length, limb_radius,
					limb_taper, joint_count, limb_sides, lod)

				limb_count += 1


## Build a single multi-jointed limb.
static func _build_single_limb(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		seed_val: int, start_pos: Vector3, direction: Vector3,
		total_length: float, start_radius: float,
		taper: float, joint_count: int, sides: int, lod: int) -> void:

	var pos: Vector3 = start_pos
	var dir: Vector3 = direction
	var radius: float = start_radius

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	for joint_idx in joint_count:
		var joint_t: float = float(joint_idx) / float(joint_count)
		var seg_length: float = total_length / float(joint_count)
		var end_radius: float = radius * taper

		# Each joint bends slightly (gravity + mobility)
		var bend: float = 0.15 + dna.mobility * 0.2
		dir = (dir + Vector3.DOWN * bend * (1.0 + joint_t)).normalized()

		var end_pos: Vector3 = pos + dir * seg_length

		# Build the tube
		var mesh: Mesh = _create_tube_mesh(pos, end_pos, radius, end_radius, sides)
		if mesh:
			var inst := MeshInstance3D.new()
			inst.name = "Limb_%d_%d" % [seed_val, joint_idx]
			inst.mesh = mesh

			# Limb material: scale surface, different pattern from body
			var mat := mapper.create_part_material(dna, CritterTraitMapper.PartType.LIMB, seed_val + joint_idx * 10)
			mat.set_shader_parameter("primary_color", dna.primary_color.darkened(0.1))
			mat.set_shader_parameter("secondary_color", dna.secondary_color)
			mapper.apply_variation(mat, seed_val + joint_idx * 77)
			inst.material_override = mat

			root.add_child(inst)

		pos = end_pos
		radius = end_radius

	# Limb tip — claw/pad/fin based on edge_type and aggression
	_build_limb_tip(dna, root, mapper, seed_val + 5000, pos, dir, radius, lod)


## Build a limb tip (claw, pad, or fin).
static func _build_limb_tip(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		seed_val: int, pos: Vector3, dir: Vector3, radius: float, _lod: int) -> void:

	var tip_size: float = radius * 1.5

	var tip_mesh: Mesh
	if dna.aggression > 0.6 and dna.edge_type > 0.5:
		# Claw/spike: cone pointing forward
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = tip_size
		cone.height = tip_size * 3.0 * dna.aggression
		cone.radial_segments = 4
		tip_mesh = cone
	elif dna.mobility < 0.3:
		# Fin/paddle: flat wide shape
		var box := BoxMesh.new()
		box.size = Vector3(tip_size * 3.0, tip_size * 0.3, tip_size * 2.0)
		tip_mesh = box
	else:
		# Rounded pad/foot
		var sphere := SphereMesh.new()
		sphere.radius = tip_size
		sphere.height = tip_size * 1.5
		sphere.radial_segments = 6
		sphere.rings = 3
		tip_mesh = sphere

	var inst := MeshInstance3D.new()
	inst.name = "LimbTip_%d" % seed_val
	inst.mesh = tip_mesh
	inst.position = pos + dir * tip_size

	# Point in limb direction
	if dir.length() > 0.001:
		var look_target := pos + dir * 10.0
		# Use basis instead of look_at to avoid adding to tree first
		var z_axis := -dir.normalized()
		var x_axis: Vector3
		if absf(z_axis.dot(Vector3.UP)) < 0.99:
			x_axis = Vector3.UP.cross(z_axis).normalized()
		else:
			x_axis = Vector3.RIGHT.cross(z_axis).normalized()
		var y_axis := z_axis.cross(x_axis).normalized()
		inst.basis = Basis(x_axis, y_axis, z_axis)

	# Material: root/feet surface for paws/claws
	var mat := mapper.create_part_material(dna, CritterTraitMapper.PartType.ROOT, seed_val)
	if dna.aggression > 0.6:
		mat.set_shader_parameter("primary_color", dna.tertiary_color)
		mat.set_shader_parameter("roughness", 0.3)
	else:
		mat.set_shader_parameter("primary_color", dna.primary_color.lightened(0.1))
	mapper.apply_variation(mat, seed_val)
	inst.material_override = mat

	root.add_child(inst)


# ═══════════════════════════════════════════════════════════════
# HEAD — special features on the first segment
# ═══════════════════════════════════════════════════════════════

## Build head features: eyes, mouth/mandibles, antennae.
static func _build_head(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		spine: Array, base_seed: int, lod: int) -> void:

	if spine.is_empty():
		return

	var head_seg: Dictionary = spine[0] as Dictionary
	var head_pos: Vector3 = head_seg["position"] as Vector3
	var head_radius: float = head_seg["radius"] as float

	# Forward direction (toward body start)
	var forward: Vector3
	if spine.size() > 1:
		var second_seg: Dictionary = spine[1] as Dictionary
		forward = (head_pos - (second_seg["position"] as Vector3)).normalized()
	else:
		forward = Vector3.FORWARD

	var up: Vector3 = Vector3.UP
	var right: Vector3 = forward.cross(up).normalized()
	if right.length() < 0.5:
		right = Vector3.RIGHT
	up = right.cross(forward).normalized()

	# Head dome (slightly enlarged first segment)
	var head_mesh := SphereMesh.new()
	head_mesh.radius = head_radius * 1.3
	head_mesh.height = head_radius * 2.2
	head_mesh.radial_segments = LOD_BODY_SIDES[lod]
	head_mesh.rings = LOD_BODY_SIDES[lod] / 2

	var head_inst := MeshInstance3D.new()
	head_inst.name = "Head"
	head_inst.mesh = head_mesh
	head_inst.position = head_pos + forward * head_radius * 0.3

	var head_mat := mapper.create_part_material(dna, CritterTraitMapper.PartType.HEAD, base_seed + 30000)
	mapper.apply_variation(head_mat, base_seed + 30001)
	head_inst.material_override = head_mat
	root.add_child(head_inst)

	# ── Eyes ──
	var eye_count: int = clampi(roundi(dna.curiosity * 4.0), 1, 4)
	var eye_radius: float = head_radius * 0.2 * (0.5 + dna.curiosity * 0.5)

	for i in eye_count:
		var eye_angle: float
		if eye_count == 1:
			eye_angle = 0.0  # Cyclops
		elif eye_count == 2:
			eye_angle = (float(i) - 0.5) * 0.6  # Bilateral
		else:
			eye_angle = (float(i) / float(eye_count) - 0.5) * 1.2  # Spread

		var eye_pos := head_pos + forward * head_radius * 1.1 + right * eye_angle * head_radius + up * head_radius * 0.3

		var eye_mesh := SphereMesh.new()
		eye_mesh.radius = eye_radius
		eye_mesh.height = eye_radius * 2.0
		eye_mesh.radial_segments = 6
		eye_mesh.rings = 3

		var eye_inst := MeshInstance3D.new()
		eye_inst.name = "Eye_%d" % i
		eye_inst.mesh = eye_mesh
		eye_inst.position = eye_pos

		# Eyes: dark with slight emission
		var eye_mat := mapper.create_material_from_dna(dna, base_seed + 31000 + i)
		eye_mat.set_shader_parameter("primary_color", Color(0.05, 0.05, 0.1))
		eye_mat.set_shader_parameter("secondary_color", dna.tertiary_color)
		eye_mat.set_shader_parameter("emission_energy", 0.15 + dna.curiosity * 0.2)
		eye_mat.set_shader_parameter("roughness", 0.05)
		eye_inst.material_override = eye_mat
		root.add_child(eye_inst)

	# ── Antennae/horns (if curiosity or aggression is high) ──
	if dna.curiosity > 0.5 or dna.aggression > 0.5:
		var horn_count: int = 2
		var horn_length: float = head_radius * 2.0 * (dna.aggression + dna.curiosity) * 0.5

		for i in horn_count:
			var side: float = (float(i) - 0.5) * 2.0
			var horn_base := head_pos + forward * head_radius * 0.5 + right * side * head_radius * 0.6 + up * head_radius * 1.0

			var horn_dir: Vector3
			if dna.aggression > dna.curiosity:
				# Horns: forward and slightly up
				horn_dir = (forward + up * 0.5 + right * side * 0.3).normalized()
			else:
				# Antennae: upward and slightly forward
				horn_dir = (up + forward * 0.3 + right * side * 0.2).normalized()

			var horn_end := horn_base + horn_dir * horn_length
			var horn_radius: float = head_radius * 0.08

			var horn_mesh := _create_tube_mesh(horn_base, horn_end, horn_radius, horn_radius * 0.2, LOD_LIMB_SIDES[lod])
			if horn_mesh:
				var horn_inst := MeshInstance3D.new()
				horn_inst.name = "Horn_%d" % i
				horn_inst.mesh = horn_mesh

				var horn_mat := mapper.create_material_from_dna(dna, base_seed + 32000 + i)
				if dna.aggression > dna.curiosity:
					horn_mat.set_shader_parameter("primary_color", dna.tertiary_color)
				else:
					horn_mat.set_shader_parameter("primary_color", dna.secondary_color)
				horn_mat.set_shader_parameter("roughness", 0.4)
				mapper.apply_variation(horn_mat, base_seed + 32000 + i)
				horn_inst.material_override = horn_mat
				root.add_child(horn_inst)


# ═══════════════════════════════════════════════════════════════
# TAIL — posterior features
# ═══════════════════════════════════════════════════════════════

## Build tail at the end of the body.
static func _build_tail(dna: CritterDNA, root: Node3D, mapper: CritterTraitMapper,
		spine: Array, base_seed: int, lod: int) -> void:

	if spine.size() < 2:
		return

	var tail_seg: Dictionary = spine[-1]
	var prev_seg: Dictionary = spine[-2]
	var tail_pos: Vector3 = tail_seg["position"]
	var tail_radius: float = tail_seg["radius"]

	var backward: Vector3 = (tail_pos - (prev_seg["position"] as Vector3)).normalized()
	var tail_length: float = dna.part_length * dna.scale * 0.2

	if dna.mobility > 0.5:
		# Active tail: tapered extension
		var tail_segments: int = 3
		var pos: Vector3 = tail_pos
		var dir: Vector3 = backward
		var radius: float = tail_radius

		for i in tail_segments:
			var seg_length: float = tail_length / float(tail_segments)
			var end_pos: Vector3 = pos + dir * seg_length
			var end_radius: float = radius * 0.6

			# Tail curves downward slightly
			dir = (dir + Vector3.DOWN * 0.15).normalized()

			var mesh: Mesh = _create_tube_mesh(pos, end_pos, radius, end_radius, LOD_LIMB_SIDES[lod])
			if mesh:
				var inst := MeshInstance3D.new()
				inst.name = "Tail_%d" % i
				inst.mesh = mesh

				var mat := mapper.create_material_from_dna(dna, base_seed + 40000 + i)
				mat.set_shader_parameter("primary_color", dna.primary_color.darkened(0.05 * i))
				mapper.apply_variation(mat, base_seed + 40000 + i)
				inst.material_override = mat
				root.add_child(inst)

			pos = end_pos
			radius = end_radius
	else:
		# Passive tail: fin or fan
		var fin := BoxMesh.new()
		fin.size = Vector3(tail_radius * 4.0, tail_radius * 3.0, tail_radius * 0.3)

		var fin_inst := MeshInstance3D.new()
		fin_inst.name = "TailFin"
		fin_inst.mesh = fin
		fin_inst.position = tail_pos + backward * tail_radius

		var fin_mat := mapper.create_material_from_dna(dna, base_seed + 40000)
		fin_mat.set_shader_parameter("primary_color", dna.tertiary_color)
		fin_mat.set_shader_parameter("transparency", 0.3)
		mapper.apply_variation(fin_mat, base_seed + 40001)
		fin_inst.material_override = fin_mat
		root.add_child(fin_inst)


# ═══════════════════════════════════════════════════════════════
# TUBE MESH — shared utility for body segments and limbs
# ═══════════════════════════════════════════════════════════════

## Create a tapered tube mesh between two points using SurfaceTool.
static func _create_tube_mesh(start: Vector3, end: Vector3,
		start_radius: float, end_radius: float, sides: int) -> Mesh:

	var forward: Vector3 = end - start
	var length: float = forward.length()
	if length < 0.001:
		return null
	forward = forward.normalized()

	var right: Vector3
	if absf(forward.dot(Vector3.UP)) < 0.99:
		right = forward.cross(Vector3.UP).normalized()
	else:
		right = forward.cross(Vector3.RIGHT).normalized()
	var up: Vector3 = right.cross(forward).normalized()

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var rings: int = 2
	var ring_verts: Array = []

	for ri in rings:
		var t: float = float(ri) / float(rings - 1)
		var pos: Vector3 = start.lerp(end, t)
		var radius: float = lerpf(start_radius, end_radius, t)

		var ring: Array = []
		for si in sides:
			var angle: float = TAU * float(si) / float(sides)
			var offset: Vector3 = (right * cos(angle) + up * sin(angle)) * radius
			ring.append(pos + offset)
		ring_verts.append(ring)

	# Triangulate
	for ri in range(rings - 1):
		var ring_a: Array = ring_verts[ri] as Array
		var ring_b: Array = ring_verts[ri + 1] as Array
		for si in range(sides):
			var si_next: int = (si + 1) % sides

			var v00: Vector3 = ring_a[si] as Vector3
			var v01: Vector3 = ring_a[si_next] as Vector3
			var v10: Vector3 = ring_b[si] as Vector3
			var v11: Vector3 = ring_b[si_next] as Vector3

			var t0: float = float(ri) / float(rings - 1)
			var t1: float = float(ri + 1) / float(rings - 1)
			var s0: float = float(si) / float(sides)
			var s1: float = float(si + 1) / float(sides)

			var n1: Vector3 = (v10 - v00).cross(v01 - v00).normalized()
			st.set_normal(n1); st.set_uv(Vector2(s0, t0)); st.add_vertex(v00)
			st.set_normal(n1); st.set_uv(Vector2(s0, t1)); st.add_vertex(v10)
			st.set_normal(n1); st.set_uv(Vector2(s1, t0)); st.add_vertex(v01)

			var n2: Vector3 = (v11 - v01).cross(v10 - v01).normalized()
			st.set_normal(n2); st.set_uv(Vector2(s1, t0)); st.add_vertex(v01)
			st.set_normal(n2); st.set_uv(Vector2(s0, t1)); st.add_vertex(v10)
			st.set_normal(n2); st.set_uv(Vector2(s1, t1)); st.add_vertex(v11)

	st.generate_normals()
	return st.commit()


